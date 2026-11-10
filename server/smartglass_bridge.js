const http = require('http');
const url = require('url');
const Smartglass = require('xbox-smartglass-core-node');
const SystemInput = require('xbox-smartglass-core-node/src/channels/systeminput');
const SystemMedia = require('xbox-smartglass-core-node/src/channels/systemmedia');

const PORT = 5555;
let currentSg = null;
let currentInput = null;
let currentMedia = null;
let connectedIp = null;
let connectedName = 'Xbox Console';

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
            sendJson(res, 200, {
                connected: currentSg ? currentSg.isConnected() : false,
                ip: connectedIp,
                name: connectedName
            });
        }
        else if (pathname === '/discover' && req.method === 'GET') {
            const sg = Smartglass();
            const targetIp = parsedUrl.query.ip || '192.168.1.70';
            
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
                sendJson(res, 200, { consoles: [] });
            }
        }
        else if (pathname === '/connect' && req.method === 'POST') {
            const body = await parseBody(req);
            const targetIp = body.ip || '192.168.1.70';

            if (currentSg) {
                try { currentSg.disconnect(); } catch (_) {}
            }

            currentSg = Smartglass();
            currentInput = SystemInput();
            currentMedia = SystemMedia();

            try {
                await currentSg.connect(targetIp);
                currentInput.load(currentSg, 1);
                currentMedia.load(currentSg, 2);
                connectedIp = targetIp;
                connectedName = 'XBOX';

                console.log(`[Bridge] Conectado exitosamente a Xbox en ${targetIp}`);
                sendJson(res, 200, {
                    status: 'connected',
                    ip: targetIp,
                    name: connectedName
                });
            } catch (err) {
                console.error(`[Bridge] Error al conectar a ${targetIp}:`, err);
                sendJson(res, 500, { status: 'error', error: err.toString() });
            }
        }
        else if (pathname === '/button' && req.method === 'POST') {
            const body = await parseBody(req);
            const button = (body.button || '').toLowerCase();

            if (!currentSg || !currentSg.isConnected() || !currentInput) {
                return sendJson(res, 400, { status: 'error', message: 'Not connected to Xbox' });
            }

            try {
                await currentInput.sendCommand(button);
                sendJson(res, 200, { status: 'ok', button: button });
            } catch (err) {
                sendJson(res, 500, { status: 'error', error: err.toString() });
            }
        }
        else if (pathname === '/media' && req.method === 'POST') {
            const body = await parseBody(req);
            const command = (body.command || '').toLowerCase();

            if (!currentSg || !currentSg.isConnected() || !currentMedia) {
                return sendJson(res, 400, { status: 'error', message: 'Not connected to Xbox' });
            }

            try {
                await currentMedia.sendCommand(command);
                sendJson(res, 200, { status: 'ok', command: command });
            } catch (err) {
                sendJson(res, 500, { status: 'error', error: err.toString() });
            }
        }
        else if (pathname === '/disconnect' && req.method === 'POST') {
            if (currentSg) {
                try { currentSg.disconnect(); } catch (_) {}
            }
            currentSg = null;
            currentInput = null;
            currentMedia = null;
            connectedIp = null;
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
});
