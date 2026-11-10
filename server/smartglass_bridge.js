const http = require('http');
const url = require('url');
const Smartglass = require('xbox-smartglass-core-node');
const SystemInput = require('xbox-smartglass-core-node/src/channels/systeminput');
const SystemMedia = require('xbox-smartglass-core-node/src/channels/systemmedia');
const Packer = require('xbox-smartglass-core-node/src/packet/packer');

const PORT = 5555;
let currentSg = null;
let currentInput = null;
let currentMedia = null;
let connectedIp = '192.168.1.70';
let connectedName = 'XBOX';
let keepAliveTimer = null;
let isReconnecting = false;

function sendJson(res, statusCode, data) {
    res.writeHead(statusCode, {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type'
    });
    res.end(JSON.stringify(data));
}

function parseBody(req) {
    return new Promise((resolve, reject) => {
        let body = '';
        req.on('data', chunk => body += chunk);
        req.on('end', () => {
            try {
                resolve(body ? JSON.parse(body) : {});
            } catch (e) {
                resolve({});
            }
        });
        req.on('error', reject);
    });
}

function startKeepAlive() {
    stopKeepAlive();
    keepAliveTimer = setInterval(() => {
        if (currentSg && currentSg.isConnected() && currentSg._console) {
            try {
                // Send periodic SmartGlass ACK / Heartbeat to prevent session timeout
                const ack = Packer('message.acknowledge');
                const reqNum = currentSg._console.get_requestnum();
                ack.set('low_watermark', reqNum);
                const ackMsg = ack.pack(currentSg._console);
                currentSg._send(ackMsg);
            } catch (e) {
                console.log('[Bridge] Keepalive notice:', e.message);
            }
        } else if (connectedIp && !isReconnecting) {
            // Auto reconnect in background if dropped
            console.log('[Bridge] Conexión inactiva detectada por keepalive, reconectando...');
            connectXbox(connectedIp).catch(() => {});
        }
    }, 3500);
}

function stopKeepAlive() {
    if (keepAliveTimer) {
        clearInterval(keepAliveTimer);
        keepAliveTimer = null;
    }
}

async function connectXbox(targetIp) {
    if (isReconnecting) return false;
    isReconnecting = true;

    try {
        if (currentSg) {
            try { currentSg.disconnect(); } catch (_) {}
        }

        currentSg = Smartglass();
        currentInput = SystemInput();
        currentMedia = SystemMedia();

        await currentSg.connect(targetIp);
        currentInput.load(currentSg, 1);
        currentMedia.load(currentSg, 2);

        connectedIp = targetIp;
        connectedName = 'XBOX';

        // Wait a brief moment for channels to register
        await new Promise(r => setTimeout(r, 400));

        startKeepAlive();
        console.log(`[Bridge] Conectado exitosamente y keepalive activado para ${targetIp}`);
        isReconnecting = false;
        return true;
    } catch (err) {
        console.error(`[Bridge] Error al conectar a ${targetIp}:`, err.message || err);
        isReconnecting = false;
        return false;
    }
}

async function ensureConnected() {
    if (currentSg && currentSg.isConnected() && currentInput) {
        return true;
    }
    if (!connectedIp) return false;
    console.log(`[Bridge] Re-estableciendo sesión con ${connectedIp}...`);
    return await connectXbox(connectedIp);
}

const server = http.createServer(async (req, res) => {
    const parsedUrl = url.parse(req.url, true);
    const pathname = parsedUrl.pathname;

    if (req.method === 'OPTIONS') {
        res.writeHead(204, {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        });
        res.end();
        return;
    }

    try {
        if (pathname === '/status' && req.method === 'GET') {
            const isConn = currentSg ? currentSg.isConnected() : false;
            sendJson(res, 200, {
                connected: isConn,
                ip: connectedIp,
                name: connectedName
            });
        }
        else if (pathname === '/discover' && req.method === 'GET') {
            const sg = Smartglass();
            const targetIp = parsedUrl.query.ip || connectedIp || '192.168.1.70';
            
            try {
                const consoles = await sg.discovery(targetIp);
                const formatted = consoles.map(c => ({
                    ip: c.remote.address,
                    name: c.message.name || 'XBOX',
                    uuid: c.message.uuid || '',
                    port: c.remote.port || 5050
                }));
                sendJson(res, 200, { consoles: formatted });
            } catch (err) {
                // Return default known console if UDP discovery packet times out
                sendJson(res, 200, {
                    consoles: [{
                        ip: '192.168.1.70',
                        name: 'XBOX',
                        port: 5050
                    }]
                });
            }
        }
        else if (pathname === '/connect' && req.method === 'POST') {
            const body = await parseBody(req);
            const targetIp = body.ip || connectedIp || '192.168.1.70';

            const ok = await connectXbox(targetIp);
            if (ok) {
                sendJson(res, 200, {
                    status: 'connected',
                    ip: targetIp,
                    name: connectedName
                });
            } else {
                sendJson(res, 500, { status: 'error', message: 'No se pudo conectar a la Xbox' });
            }
        }
        else if (pathname === '/button' && req.method === 'POST') {
            const body = await parseBody(req);
            const button = (body.button || '').toLowerCase();

            const isOk = await ensureConnected();
            if (!isOk) {
                return sendJson(res, 400, { status: 'error', message: 'No se pudo conectar a la consola' });
            }

            try {
                await currentInput.sendCommand(button);
                sendJson(res, 200, { status: 'ok', button: button });
            } catch (err) {
                console.log(`[Bridge] Error enviando botón ${button}, reintentando reconexión...`);
                // Reconnect and retry once
                await connectXbox(connectedIp);
                try {
                    await currentInput.sendCommand(button);
                    sendJson(res, 200, { status: 'ok', button: button, retry: true });
                } catch (retryErr) {
                    sendJson(res, 500, { status: 'error', error: retryErr.toString() });
                }
            }
        }
        else if (pathname === '/media' && req.method === 'POST') {
            const body = await parseBody(req);
            const command = (body.command || '').toLowerCase();

            const isOk = await ensureConnected();
            if (!isOk) {
                return sendJson(res, 400, { status: 'error', message: 'No se pudo conectar a la consola' });
            }

            try {
                await currentMedia.sendCommand(command);
                sendJson(res, 200, { status: 'ok', command: command });
            } catch (err) {
                console.log(`[Bridge] Error enviando comando media ${command}, reintentando...`);
                await connectXbox(connectedIp);
                try {
                    await currentMedia.sendCommand(command);
                    sendJson(res, 200, { status: 'ok', command: command, retry: true });
                } catch (retryErr) {
                    sendJson(res, 500, { status: 'error', error: retryErr.toString() });
                }
            }
        }
        else if (pathname === '/disconnect' && req.method === 'POST') {
            stopKeepAlive();
            if (currentSg) {
                try { currentSg.disconnect(); } catch (_) {}
            }
            currentSg = null;
            currentInput = null;
            currentMedia = null;
            sendJson(res, 200, { status: 'disconnected' });
        }
        else {
            sendJson(res, 404, { error: 'Not found' });
        }
    } catch (globalErr) {
        sendJson(res, 500, { error: globalErr.toString() });
    }
});

server.listen(PORT, '127.0.0.1', () => {
    console.log(`[SmartGlass Bridge] Corriendo en http://127.0.0.1:${PORT}`);
    // Auto-connect to Xbox immediately on startup!
    connectXbox(connectedIp).then(() => {
        console.log('[Bridge] Auto-conexión inicial completada');
    }).catch(() => {});
});
