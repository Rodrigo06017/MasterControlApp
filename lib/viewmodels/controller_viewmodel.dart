import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/xbox_commands.dart';
import '../models/xbox_device.dart';
import '../services/xbox_smartglass_service.dart';

enum ConnectionStateEnum {
  disconnected,
  scanning,
  connecting,
  connected,
}

enum ControllerMode {
  gamepad,
  media,
}

class ControllerViewModel extends ChangeNotifier {
  final XboxSmartGlassService _smartGlassService = XboxSmartGlassService();
  StreamSubscription<List<XboxDevice>>? _discoverySubscription;

  ConnectionStateEnum _connectionState = ConnectionStateEnum.disconnected;
  ControllerMode _currentMode = ControllerMode.gamepad;
  XboxDevice? _activeDevice;
  List<XboxDevice> _discoveredDevices = [];
  String? _statusMessage;

  // Track active pressed button for UI feedback
  final Set<dynamic> _pressedButtons = {};

  ConnectionStateEnum get connectionState => _connectionState;
  ControllerMode get currentMode => _currentMode;
  XboxDevice? get activeDevice => _activeDevice;
  List<XboxDevice> get discoveredDevices => _discoveredDevices;
  String? get statusMessage => _statusMessage;
  bool isPressed(dynamic button) => _pressedButtons.contains(button);

  ControllerViewModel() {
    _discoverySubscription = _smartGlassService.discoveryStream.listen((devices) {
      _discoveredDevices = devices;
      notifyListeners();
    });
  }

  void setMode(ControllerMode mode) {
    _currentMode = mode;
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  Future<void> startScan() async {
    _connectionState = ConnectionStateEnum.scanning;
    _statusMessage = 'Buscando consolas Xbox en tu red Wi-Fi...';
    notifyListeners();

    await _smartGlassService.startDiscovery(timeout: const Duration(seconds: 4));

    if (_connectionState == ConnectionStateEnum.scanning) {
      _connectionState = _activeDevice != null ? ConnectionStateEnum.connected : ConnectionStateEnum.disconnected;
      _statusMessage = _discoveredDevices.isEmpty
          ? 'No se encontraron consolas automáticamente. Prueba ingresando la IP.'
          : 'Se encontraron ${_discoveredDevices.length} dispositivo(s).';
      notifyListeners();
    }
  }

  Future<bool> connectTo(XboxDevice device) async {
    _connectionState = ConnectionStateEnum.connecting;
    _statusMessage = 'Conectando a ${device.name} (${device.ip})...';
    HapticFeedback.lightImpact();
    notifyListeners();

    final success = await _smartGlassService.connectToDevice(device);
    if (success) {
      _connectionState = ConnectionStateEnum.connected;
      _activeDevice = device.copyWith(isConnected: true);
      _statusMessage = 'Conectado a ${device.name}';
      HapticFeedback.mediumImpact();
    } else {
      _connectionState = ConnectionStateEnum.disconnected;
      _activeDevice = null;
      _statusMessage = 'No se pudo conectar a ${device.ip}. Revisa las opciones de conexión en tu Xbox.';
      HapticFeedback.heavyImpact();
    }

    notifyListeners();
    return success;
  }

  Future<bool> connectByIp(String ip, {String name = 'Xbox Console'}) async {
    final cleanIp = ip.trim();
    if (cleanIp.isEmpty) return false;

    final device = XboxDevice(
      ip: cleanIp,
      name: name,
      lastSeen: DateTime.now(),
    );

    return connectTo(device);
  }

  Future<void> disconnect() async {
    await _smartGlassService.disconnect();
    _connectionState = ConnectionStateEnum.disconnected;
    _activeDevice = null;
    _statusMessage = 'Desconectado';
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void pressButton(XboxButton button) {
    HapticFeedback.lightImpact();
    _pressedButtons.add(button);
    notifyListeners();

    _smartGlassService.sendButton(button);

    // Auto-release after brief delay for visual tap animation
    Future.delayed(const Duration(milliseconds: 140), () {
      _pressedButtons.remove(button);
      notifyListeners();
    });
  }

  void pressMediaCommand(XboxMediaCommand command) {
    HapticFeedback.lightImpact();
    _pressedButtons.add(command);
    notifyListeners();

    _smartGlassService.sendMediaCommand(command);

    Future.delayed(const Duration(milliseconds: 140), () {
      _pressedButtons.remove(command);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _discoverySubscription?.cancel();
    _smartGlassService.dispose();
    super.dispose();
  }
}
