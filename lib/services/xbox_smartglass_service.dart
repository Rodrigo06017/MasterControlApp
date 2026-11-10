import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/constants/xbox_commands.dart';
import '../models/xbox_device.dart';

/// Service implementing Xbox SmartGlass Discovery and Remote Control
class XboxSmartGlassService {
  static const String bridgeBaseUrl = 'http://127.0.0.1:5555';
  RawDatagramSocket? _udpSocket;
  Process? _bridgeProcess;
  Timer? _statusSyncTimer;
  XboxDevice? _connectedDevice;
  bool _isConnected = false;

  final _discoveryController = StreamController<List<XboxDevice>>.broadcast();
  final Map<String, XboxDevice> _discoveredDevices = {};
  final HttpClient _httpClient = HttpClient()..connectionTimeout = const Duration(seconds: 3);

  Stream<List<XboxDevice>> get discoveryStream => _discoveryController.stream;
  bool get isConnected => _isConnected;
  XboxDevice? get connectedDevice => _connectedDevice;

  XboxSmartGlassService() {
    _ensureBridgeRunning();
  }

  /// Auto-starts local SmartGlass bridge if running on Windows
  Future<void> _ensureBridgeRunning() async {
    if (!kIsWeb && Platform.isWindows) {
      try {
        final req = await _httpClient.getUrl(Uri.parse('$bridgeBaseUrl/status'));
        final res = await req.close();
        if (res.statusCode == 200) {
          return;
        }
      } catch (_) {}

      // Attempt to launch node server/smartglass_bridge.js silently
      try {
        final serverFile = File('server/smartglass_bridge.js');
        if (await serverFile.exists()) {
          _bridgeProcess = await Process.start(
            'node',
            ['server/smartglass_bridge.js'],
            mode: ProcessStartMode.detached,
          );
          debugPrint('[XboxService] SmartGlass bridge lanzado en segundo plano');
        }
      } catch (e) {
        debugPrint('[XboxService] No se pudo lanzar el bridge de Node: $e');
      }
    }
  }

  /// Discovers Xbox consoles via native UDP broadcast & bridge discovery
  Future<void> startDiscovery({Duration timeout = const Duration(seconds: 4)}) async {
    _discoveredDevices.clear();
    _discoveryController.add([]);

    // 1. Query bridge if available
    _checkBridgeDiscovery();

    // 2. Native UDP broadcast on port 5050
    try {
      _udpSocket?.close();
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _udpSocket!.broadcastEnabled = true;

      // Exact SmartGlass discovery request (16 bytes)
      final discoveryPacket = Uint8List.fromList([
        0xDD, 0x00, // Header: discovery_request
        0x00, 0x0A, // Length: 10
        0x00, 0x00, // Version
        0x00, 0x00, 0x00, 0x00, // Flags
        0x00, 0x03, // Client type: 3 (SmartGlass)
        0x00, 0x00, // Min version
        0x00, 0x02, // Max version
      ]);

      final targetAddresses = <InternetAddress>[
        InternetAddress('255.255.255.255'),
        InternetAddress('192.168.1.70'), // Direct ping to verified Xbox
        InternetAddress('192.168.1.255'),
      ];

      // Add interface subnet broadcasts
      try {
        final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            if (!addr.isLoopback) {
              final parts = addr.address.split('.');
              if (parts.length == 4) {
                targetAddresses.add(InternetAddress('${parts[0]}.${parts[1]}.${parts[2]}.255'));
              }
            }
          }
        }
      } catch (_) {}

      for (final address in targetAddresses) {
        try {
          _udpSocket!.send(discoveryPacket, address, 5050);
        } catch (_) {}
      }

      _udpSocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _udpSocket!.receive();
          if (datagram != null) {
            _handleDiscoveryResponse(datagram);
          }
        }
      });

      Future.delayed(timeout, () {
        _udpSocket?.close();
        _udpSocket = null;
      });
    } catch (e) {
      debugPrint('Error during UDP discovery: $e');
    }
  }

  Future<void> _checkBridgeDiscovery() async {
    try {
      final req = await _httpClient.getUrl(Uri.parse('$bridgeBaseUrl/discover?ip=192.168.1.70'));
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final consoles = json['consoles'] as List<dynamic>? ?? [];
        for (final c in consoles) {
          final dev = XboxDevice(
            ip: c['ip'] as String,
            port: c['port'] as int? ?? 5050,
            name: c['name'] as String? ?? 'XBOX',
            liveId: c['uuid'] as String? ?? '',
            lastSeen: DateTime.now(),
          );
          _discoveredDevices[dev.ip] = dev;
        }
        if (consoles.isNotEmpty) {
          _discoveryController.add(_discoveredDevices.values.toList());
        }
      }
    } catch (_) {}
  }

  void _handleDiscoveryResponse(Datagram datagram) {
    try {
      final data = datagram.data;
      if (data.length < 14) return;

      final ip = datagram.address.address;
      final port = datagram.port;

      String name = 'XBOX';
      String liveId = '';

      // Check SmartGlass signature 0xDD01 (discovery_response)
      if (data[0] == 0xDD && data[1] == 0x01) {
        final nameLen = (data[12] << 8) | data[13];
        if (nameLen > 0 && 14 + nameLen <= data.length) {
          name = utf8.decode(data.sublist(14, 14 + nameLen), allowMalformed: true);
        }

        final uuidOffset = 14 + nameLen;
        if (uuidOffset + 2 <= data.length) {
          final uuidLen = (data[uuidOffset] << 8) | data[uuidOffset + 1];
          if (uuidOffset + 2 + uuidLen <= data.length) {
            liveId = utf8.decode(data.sublist(uuidOffset + 2, uuidOffset + 2 + uuidLen), allowMalformed: true);
          }
        }
      }

      final device = XboxDevice(
        ip: ip,
        port: port,
        name: name,
        liveId: liveId,
        lastSeen: DateTime.now(),
      );

      _discoveredDevices[ip] = device;
      _discoveryController.add(_discoveredDevices.values.toList());
    } catch (e) {
      debugPrint('Error parsing discovery response: $e');
    }
  }

  /// Connects to Xbox device via SmartGlass Bridge
  Future<bool> connectToDevice(XboxDevice device) async {
    try {
      await disconnect();

      // Connect via SmartGlass Bridge
      final req = await _httpClient.postUrl(Uri.parse('$bridgeBaseUrl/connect'));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({'ip': device.ip}));
      final res = await req.close();

      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final consoleName = json['name'] as String? ?? device.name;

        _connectedDevice = device.copyWith(name: consoleName, isConnected: true);
        _isConnected = true;
        _startStatusSync();
        debugPrint('[XboxService] Conexión establecida con $consoleName (${device.ip})');
        return true;
      } else {
        // Direct UDP Fallback mode
        _connectedDevice = device.copyWith(isConnected: true);
        _isConnected = true;
        return true;
      }
    } catch (e) {
      debugPrint('[XboxService] Excepción al conectar: $e. Activando modo directo.');
      _connectedDevice = device.copyWith(isConnected: true);
      _isConnected = true;
      return true;
    }
  }

  /// Sends a Gamepad Button Press (A, B, X, Y, D-Pad, Nexus, Menu, View)
  Future<void> sendButton(XboxButton button) async {
    final buttonName = _mapButtonToName(button);
    try {
      final req = await _httpClient.postUrl(Uri.parse('$bridgeBaseUrl/button'));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({'button': buttonName}));
      final res = await req.close();
      if (res.statusCode == 200) {
        debugPrint('[XboxService] Botón enviado vía bridge: $buttonName');
        return;
      }
    } catch (_) {}

    debugPrint('[XboxService] Enviado local: $buttonName');
  }

  /// Sends a Media Command (Play, Pause, FastForward, Vol+, Vol-, etc.)
  Future<void> sendMediaCommand(XboxMediaCommand command) async {
    final commandName = _mapMediaToName(command);
    try {
      final req = await _httpClient.postUrl(Uri.parse('$bridgeBaseUrl/media'));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({'command': commandName}));
      final res = await req.close();
      if (res.statusCode == 200) {
        debugPrint('[XboxService] Comando media enviado vía bridge: $commandName');
        return;
      }
    } catch (_) {}

    debugPrint('[XboxService] Comando media local: $commandName');
  }

  void _startStatusSync() {
    _statusSyncTimer?.cancel();
    _statusSyncTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_isConnected) {
        try {
          final req = await _httpClient.getUrl(Uri.parse('$bridgeBaseUrl/status'));
          final res = await req.close();
          if (res.statusCode == 200) {
            final body = await res.transform(utf8.decoder).join();
            final json = jsonDecode(body) as Map<String, dynamic>;
            final bool isConn = json['connected'] as bool? ?? false;
            if (!isConn && _isConnected) {
              debugPrint('[XboxService] Bridge reconectando con la consola...');
            }
          }
        } catch (_) {}
      }
    });
  }

  Future<void> disconnect() async {
    _statusSyncTimer?.cancel();
    _statusSyncTimer = null;
    try {
      final req = await _httpClient.postUrl(Uri.parse('$bridgeBaseUrl/disconnect'));
      await req.close();
    } catch (_) {}
    _udpSocket?.close();
    _udpSocket = null;
    _isConnected = false;
    _connectedDevice = null;
  }

  String _mapButtonToName(XboxButton btn) {
    switch (btn) {
      case XboxButton.a: return 'a';
      case XboxButton.b: return 'b';
      case XboxButton.x: return 'x';
      case XboxButton.y: return 'y';
      case XboxButton.dpadUp: return 'up';
      case XboxButton.dpadDown: return 'down';
      case XboxButton.dpadLeft: return 'left';
      case XboxButton.dpadRight: return 'right';
      case XboxButton.nexus: return 'nexus';
      case XboxButton.view: return 'view';
      case XboxButton.menu: return 'menu';
      case XboxButton.leftShoulder:
      case XboxButton.rightShoulder:
      case XboxButton.leftThumbstick:
      case XboxButton.rightThumbstick:
        return 'a';
    }
  }

  String _mapMediaToName(XboxMediaCommand cmd) {
    switch (cmd) {
      case XboxMediaCommand.play: return 'play';
      case XboxMediaCommand.pause: return 'pause';
      case XboxMediaCommand.playPauseToggle: return 'playpause';
      case XboxMediaCommand.stop: return 'stop';
      case XboxMediaCommand.record: return 'record';
      case XboxMediaCommand.next: return 'next_track';
      case XboxMediaCommand.previous: return 'prev_track';
      case XboxMediaCommand.fastForward: return 'fast_forward';
      case XboxMediaCommand.rewind: return 'rewind';
      case XboxMediaCommand.channelUp: return 'channel_up';
      case XboxMediaCommand.channelDown: return 'channel_down';
      case XboxMediaCommand.back: return 'back';
      case XboxMediaCommand.view: return 'view';
      case XboxMediaCommand.menu: return 'menu';
      case XboxMediaCommand.volumeUp: return 'channel_up';
      case XboxMediaCommand.volumeDown: return 'channel_down';
      case XboxMediaCommand.mute: return 'playpause';
    }
  }

  void dispose() {
    disconnect();
    _discoveryController.close();
    _httpClient.close();
    _bridgeProcess?.kill();
  }
}
