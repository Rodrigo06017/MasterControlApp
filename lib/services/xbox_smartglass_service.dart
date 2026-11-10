import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../core/constants/xbox_commands.dart';
import '../models/xbox_device.dart';

/// Service implementing Xbox SmartGlass UDP Discovery and Remote Protocol
class XboxSmartGlassService {
  RawDatagramSocket? _udpSocket;
  Timer? _heartbeatTimer;
  XboxDevice? _connectedDevice;
  bool _isConnected = false;

  final _discoveryController = StreamController<List<XboxDevice>>.broadcast();
  final Map<String, XboxDevice> _discoveredDevices = {};

  Stream<List<XboxDevice>> get discoveryStream => _discoveryController.stream;
  bool get isConnected => _isConnected;
  XboxDevice? get connectedDevice => _connectedDevice;

  /// Starts discovery on the local network via UDP Broadcast on port 5050
  Future<void> startDiscovery({Duration timeout = const Duration(seconds: 4)}) async {
    _discoveredDevices.clear();
    _discoveryController.add([]);

    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      // SmartGlass Discovery Packet Structure
      // [Header: 0xDD, 0x00] [Length: 0x00, 0x10] [Client Type: 0x00, 0x01] ...
      final discoveryPacket = _buildDiscoveryPacket();

      // Broadcast to standard port 5050
      final broadcastAddresses = [
        InternetAddress('255.255.255.255'),
      ];

      // Try to find local subnet broadcast address
      try {
        final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            if (!addr.isLoopback) {
              final parts = addr.address.split('.');
              if (parts.length == 4) {
                final subnetBroadcast = InternetAddress('${parts[0]}.${parts[1]}.${parts[2]}.255');
                broadcastAddresses.add(subnetBroadcast);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Could not list network interfaces: $e');
      }

      for (final address in broadcastAddresses) {
        try {
          socket.send(discoveryPacket, address, 5050);
        } catch (_) {}
      }

      // Listen for Xbox responses
      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            _handleDiscoveryResponse(datagram);
          }
        }
      });

      // Close socket after timeout
      Future.delayed(timeout, () {
        socket.close();
      });
    } catch (e) {
      debugPrint('Error during Xbox discovery: $e');
    }
  }

  /// Parses datagram responses received from Xbox consoles on UDP 5050
  void _handleDiscoveryResponse(Datagram datagram) {
    try {
      final data = datagram.data;
      if (data.length < 8) return;

      final ip = datagram.address.address;
      final port = datagram.port;

      String name = 'Xbox Console';
      String liveId = '';

      // Check for SmartGlass signature (0xDD00 / 0xDD01 / 0xDD02)
      if (data[0] == 0xDD) {
        // Attempt to extract UTF-8 or ASCII console name if present in payload
        try {
          final rawText = utf8.decode(data, allowMalformed: true);
          final match = RegExp(r'[a-zA-Z0-9_\- ]{3,25}').allMatches(rawText);
          for (final m in match) {
            final word = m.group(0)!;
            if (word.toLowerCase().contains('xbox') || word.length >= 4) {
              name = word;
              break;
            }
          }
        } catch (_) {}
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

  /// Connects directly to an Xbox by IP (manual or discovered)
  Future<bool> connectToDevice(XboxDevice device) async {
    try {
      await disconnect();

      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

      // Send initial connect / handshake datagram
      final connectPacket = _buildConnectPacket();
      final targetAddress = InternetAddress(device.ip);
      _udpSocket!.send(connectPacket, targetAddress, device.port);

      _connectedDevice = device.copyWith(isConnected: true);
      _isConnected = true;

      // Start periodic heartbeat / keep-alive (every 1 second)
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isConnected && _udpSocket != null) {
          final pingPacket = _buildPingPacket();
          _udpSocket!.send(pingPacket, targetAddress, device.port);
        }
      });

      return true;
    } catch (e) {
      debugPrint('Error connecting to Xbox at ${device.ip}: $e');
      _isConnected = false;
      _connectedDevice = null;
      return false;
    }
  }

  /// Sends a Gamepad Button Press (A, B, X, Y, D-Pad, Nexus, Menu, etc.)
  Future<void> sendButton(XboxButton button) async {
    if (!_isConnected || _udpSocket == null || _connectedDevice == null) {
      // In offline/simulation mode, still acknowledge for UI testing
      debugPrint('Simulated button press: $button');
      return;
    }

    try {
      final opCode = _mapButtonToOpCode(button);
      final packet = _buildInputPacket(opCode);
      final target = InternetAddress(_connectedDevice!.ip);
      _udpSocket!.send(packet, target, _connectedDevice!.port);
      debugPrint('Sent button $button (OpCode: 0x${opCode.toRadixString(16)}) to ${_connectedDevice!.ip}');
    } catch (e) {
      debugPrint('Error sending button: $e');
    }
  }

  /// Sends a Media Command (Play, Pause, FastForward, Vol+, Vol-, etc.)
  Future<void> sendMediaCommand(XboxMediaCommand command) async {
    if (!_isConnected || _udpSocket == null || _connectedDevice == null) {
      debugPrint('Simulated media command: $command');
      return;
    }

    try {
      final opCode = _mapMediaToOpCode(command);
      final packet = _buildMediaPacket(opCode);
      final target = InternetAddress(_connectedDevice!.ip);
      _udpSocket!.send(packet, target, _connectedDevice!.port);
      debugPrint('Sent media command $command to ${_connectedDevice!.ip}');
    } catch (e) {
      debugPrint('Error sending media command: $e');
    }
  }

  /// Disconnects from current console and frees sockets
  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _udpSocket?.close();
    _udpSocket = null;
    _isConnected = false;
    _connectedDevice = null;
  }

  // --- Packet Builders ---

  Uint8List _buildDiscoveryPacket() {
    // 0xDD00 SmartGlass discovery request
    final bytes = BytesBuilder();
    bytes.add([0xDD, 0x00]); // Header: Discovery Request
    bytes.add([0x00, 0x10]); // Payload length
    bytes.add([0x00, 0x02]); // Protocol version 2
    bytes.add([0x00, 0x01]); // Client type: Mobile App
    bytes.add(List.filled(8, 0x00)); // Padding / Client flags
    return bytes.toBytes();
  }

  Uint8List _buildConnectPacket() {
    // 0xCC00 SmartGlass Connect request
    final bytes = BytesBuilder();
    bytes.add([0xCC, 0x00]); // Header: Connect
    bytes.add([0x00, 0x08]); // Length
    bytes.add([0x00, 0x02]); // Version
    bytes.add([0x00, 0x00, 0x00, 0x01]); // Anonymous session flag
    return bytes.toBytes();
  }

  Uint8List _buildPingPacket() {
    final bytes = BytesBuilder();
    bytes.add([0xDD, 0x02]); // Header: Heartbeat / Ping
    bytes.add([0x00, 0x04]);
    bytes.add([0x00, 0x01, 0x00, 0x00]);
    return bytes.toBytes();
  }

  Uint8List _buildInputPacket(int opCode) {
    final bytes = BytesBuilder();
    bytes.add([0xD0, 0x01]); // Input Header
    bytes.add([0x00, 0x08]); // Length
    // 16-bit OpCode
    bytes.add([(opCode >> 8) & 0xFF, opCode & 0xFF]);
    bytes.add([0x00, 0x00, 0x00, 0x00]); // Timestamp / Reserved
    return bytes.toBytes();
  }

  Uint8List _buildMediaPacket(int opCode) {
    final bytes = BytesBuilder();
    bytes.add([0xD0, 0x02]); // Media Header
    bytes.add([0x00, 0x06]); // Length
    bytes.add([(opCode >> 8) & 0xFF, opCode & 0xFF]);
    bytes.add([0x00, 0x00]);
    return bytes.toBytes();
  }

  int _mapButtonToOpCode(XboxButton btn) {
    switch (btn) {
      case XboxButton.dpadUp:
        return XboxCommandCodes.opDpadUp;
      case XboxButton.dpadDown:
        return XboxCommandCodes.opDpadDown;
      case XboxButton.dpadLeft:
        return XboxCommandCodes.opDpadLeft;
      case XboxButton.dpadRight:
        return XboxCommandCodes.opDpadRight;
      case XboxButton.a:
        return XboxCommandCodes.opA;
      case XboxButton.b:
        return XboxCommandCodes.opB;
      case XboxButton.x:
        return XboxCommandCodes.opX;
      case XboxButton.y:
        return XboxCommandCodes.opY;
      case XboxButton.nexus:
        return XboxCommandCodes.opNexus;
      case XboxButton.view:
        return XboxCommandCodes.opBack;
      case XboxButton.menu:
        return XboxCommandCodes.opStart;
      case XboxButton.leftShoulder:
        return XboxCommandCodes.opLeftShoulder;
      case XboxButton.rightShoulder:
        return XboxCommandCodes.opRightShoulder;
      case XboxButton.leftThumbstick:
        return XboxCommandCodes.opLeftThumb;
      case XboxButton.rightThumbstick:
        return XboxCommandCodes.opRightThumb;
    }
  }

  int _mapMediaToOpCode(XboxMediaCommand cmd) {
    switch (cmd) {
      case XboxMediaCommand.play:
        return XboxCommandCodes.mediaPlay;
      case XboxMediaCommand.pause:
        return XboxCommandCodes.mediaPause;
      case XboxMediaCommand.playPauseToggle:
        return XboxCommandCodes.mediaPlayPause;
      case XboxMediaCommand.stop:
        return XboxCommandCodes.mediaStop;
      case XboxMediaCommand.record:
        return XboxCommandCodes.mediaRecord;
      case XboxMediaCommand.previous:
        return XboxCommandCodes.mediaPrevious;
      case XboxMediaCommand.next:
        return XboxCommandCodes.mediaNext;
      case XboxMediaCommand.rewind:
        return XboxCommandCodes.mediaRewind;
      case XboxMediaCommand.fastForward:
        return XboxCommandCodes.mediaFastForward;
      case XboxMediaCommand.volumeUp:
        return XboxCommandCodes.mediaVolumeUp;
      case XboxMediaCommand.volumeDown:
        return XboxCommandCodes.mediaVolumeDown;
      case XboxMediaCommand.mute:
        return XboxCommandCodes.mediaMute;
      case XboxMediaCommand.channelUp:
      case XboxMediaCommand.channelDown:
      case XboxMediaCommand.back:
      case XboxMediaCommand.view:
      case XboxMediaCommand.menu:
        return XboxCommandCodes.mediaPlayPause;
    }
  }

  void dispose() {
    disconnect();
    _discoveryController.close();
  }
}
