import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'commands.dart';

// ============================================================
// PixBarDevice — un dispositivo BLE individual
// ============================================================
class PixBarDevice extends ChangeNotifier {
  final BluetoothDevice btDevice;

  BluetoothCharacteristic? _cmdChar;
  BluetoothCharacteristic? _stateChar;
  StreamSubscription? _stateSub;
  StreamSubscription? _connSub;

  bool _connected = false;
  bool _intentionalDisconnect = false;
  PixBarState _state = const PixBarState();
  bool Function()? isManagerConnecting;  // agregado 16052026

  // Alias editable por el usuario. Por defecto usa el nombre BT (ej: "PixBar-A3F2")
  String alias;

  PixBarDevice({
    required this.btDevice,
    String? alias,
  }) : alias = alias ?? btDevice.platformName;

  // ── Getters ──
  String get id => btDevice.remoteId.str;
  String get btName => btDevice.platformName;
  bool get connected => _connected;
  PixBarState get state => _state;

  /// Nombre que se muestra: alias si fue renombrado, si no el nombre BT
  String get displayName => alias.isNotEmpty ? alias : btName;

  // ── Conectar ──
  Future<void> connect({int retry = 0}) async {
    try {
      //await btDevice.connect(); borrado 13052026
      await btDevice.connect(timeout: const Duration(seconds: 15));

      _connSub?.cancel();
      _connSub = btDevice.connectionState.listen((s) {
        if (s == BluetoothConnectionState.disconnected) _onDisconnect();
      });

      await _discoverServices();
      _connected = true;
      notifyListeners();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('147') && retry < 2) {
        await Future.delayed(const Duration(milliseconds: 1500));
        await connect(retry: retry + 1);
      } else if (msg.contains('already connected')) {
        // GATT sigue abierto — solo redescubrir
        try {
          await _discoverServices();
          _connected = true;
          notifyListeners();
        } catch (_) {}
      }
    }
  }

  // ── Desconectar (intencional) ──
  Future<void> disconnect() async {
      debugPrint('[$displayName] disconnect() llamado');
  debugPrint(StackTrace.current.toString()); // ← ver quién lo llama
    _intentionalDisconnect = true;
    _connected = false;
    _cmdChar = null;
    _stateChar = null;
    _stateSub?.cancel();
    _connSub?.cancel();
    try { await btDevice.disconnect(); } catch (_) {}
    notifyListeners();
  }
// ── Cancelar autoreconexión temporalmente ──
void cancelAutoReconnect() {
  _intentionalDisconnect = true;
  Future.delayed(const Duration(milliseconds: 100), () {
    _intentionalDisconnect = false;
  });
}
  // ── Desconexión inesperada → autoreconectar ──
  void _onDisconnect() {
    _connected = false;
    _cmdChar = null;
    _stateChar = null;
    _stateSub?.cancel();
    notifyListeners();
    if (!_intentionalDisconnect) _autoReconnect();
    _intentionalDisconnect = false;
  }

Future<void> _autoReconnect() async {
  // Esperar un poco antes de empezar a intentar
  await Future.delayed(const Duration(seconds: 2));
  
  while (!_connected && !_intentionalDisconnect) {
    await Future.delayed(const Duration(seconds: 4));
    if (_intentionalDisconnect) break;
    
    // Si el manager está conectando otro device, esperar más
    while (isManagerConnecting?.call() == true) {
      await Future.delayed(const Duration(seconds: 2));
    }
    
    try {
      await btDevice.connect(timeout: const Duration(seconds: 8));
      await _discoverServices();
      _connected = true;
      notifyListeners();
      return;
    } catch (e) {
      if (e.toString().contains('already connected')) {
        try {
          await _discoverServices();
          _connected = true;
          notifyListeners();
          return;
        } catch (_) {}
      }
    }
  }
}

  // ── Descubrir servicios y características ──
  Future<void> _discoverServices() async {
    final services = await btDevice.discoverServices();
    for (final svc in services) {
      if (svc.uuid.toString().toLowerCase().contains('9abc')) {
        for (final char in svc.characteristics) {
          final uuid = char.uuid.toString().toLowerCase();
          if (uuid.contains('9ab1')) {
            _stateChar = char;
            await char.setNotifyValue(true);
            _stateSub?.cancel();
            _stateSub = char.onValueReceived.listen(_onStateReceived);
          }
          if (uuid.contains('9ab2')) _cmdChar = char;
        }
      }
    }
  }

  // ── Recibir estado BLE ──
  void _onStateReceived(List<int> value) {
    try {
      final raw = utf8.decode(value);
      final newState = PixBarState.fromJson(raw);
      // Notificar solo si cambió algo relevante
      if (newState != _state) {
        _state = newState;
        notifyListeners();
      } else {
        _state = newState;
      }
    } catch (_) {}
  }

  // ── Enviar comandos ──
  Future<void> cmd(int byte) async {
    if (!_connected || _cmdChar == null) return;
    try {
      await _cmdChar!.write([byte], withoutResponse: true);
    } catch (e) {
      debugPrint('[$displayName] cmd error: $e');
    }
  }

  Future<void> cmdBytes(List<int> bytes) async {
    if (!_connected || _cmdChar == null) return;
    try {
      await _cmdChar!.write(bytes, withoutResponse: false);
    } catch (e) {
      debugPrint('[$displayName] cmdBytes error: $e');
    }
  }

  Future<void> sendRGB(int r, int g, int b) async =>
      await cmdBytes(PixBarCmd.rgb(r, g, b));

  Future<void> setBrillo(double valor) async =>
      await cmd(PixBarCmd.brilloDesdeSlider(valor));

  @override
  void dispose() {
    _stateSub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }
}
