import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'commands.dart';

class BleService extends ChangeNotifier {
  BluetoothDevice? _device;
  BluetoothDevice? _foundDevice;  // dispositivo encontrado, esperando que el usuario conecte
  BluetoothCharacteristic? _cmdChar;
  BluetoothCharacteristic? _stateChar;
  StreamSubscription? _stateSub;
  StreamSubscription? _connSub;
  StreamSubscription? _scanSub;

  bool _connected = false;
  bool _scanning = false;
  PixBarState _state = const PixBarState();
  String _log = 'Buscando PixBar...';

  bool get connected => _connected;
  bool get scanning  => _scanning;
  bool get found => _foundDevice != null;
  PixBarState get state => _state;
  String get log => _log;

  // ── Reconectar al último dispositivo conocido ──
  Future<bool> reconnectLast() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastId = prefs.getString('last_device_id');
      if (lastId == null) return false;
      _log = 'Conectando a PixBar...'; notifyListeners();
      final device = BluetoothDevice.fromId(lastId);
      await connect(device);
      return _connected;
    } catch (_) {
      return false;
    }
  }

  // ── Escanear — solo busca, NO conecta ──
  Future<void> startScan() async {
    if (_scanning) return;
    _foundDevice = null;
    _scanning = true; _log = 'Buscando PixBar...'; notifyListeners();
    try {
      _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        if (results.isNotEmpty && _foundDevice == null) {
          _foundDevice = results.first.device;
          _scanning = false;
          _log = 'Encontrado: ${_foundDevice!.platformName} — tocá CONECTAR';
          notifyListeners();
          FlutterBluePlus.stopScan();
        }
      });
      await FlutterBluePlus.startScan(
        withNames: ['PixBar'],
        timeout: const Duration(seconds: 10),
      );
      if (_scanning) {
        _scanning = false;
        _log = 'No encontrado. Tocá CONECTAR para reintentar.';
        notifyListeners();
      }
    } catch (e) {
      _scanning = false;
      _log = 'Error: $e';
      notifyListeners();
    }
  }

  // ── Conectar — el usuario tocó CONECTAR ──
  Future<void> connectFound() async {
    if (_foundDevice != null) {
      await connect(_foundDevice!);
    } else {
      await startScan();
    }
  }

  Future<void> connect(BluetoothDevice device, {int retry = 0}) async {
    try {
      _log = retry > 0 ? 'Reintentando ($retry/2)...' : 'Conectando...';
      notifyListeners();
      await device.connect();
      _device = device;

      _connSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _onDisconnect();
        }
      });

      final services = await device.discoverServices();
      for (final svc in services) {
        if (svc.uuid.toString().toLowerCase().contains('9abc')) {
          for (final char in svc.characteristics) {
            final uuid = char.uuid.toString().toLowerCase();
            if (uuid.contains('9ab1')) {
              _stateChar = char;
              await char.setNotifyValue(true);
              _stateSub = char.onValueReceived.listen(_onStateReceived);
            }
            if (uuid.contains('9ab2')) _cmdChar = char;
          }
        }
      }
      _connected = true;
      _log = 'Conectado ✓';
      // Guardar ID del dispositivo para reconexión futura
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_device_id', device.remoteId.str);
      notifyListeners();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('147') && retry < 2) {
        _log = 'Error BT, reintentando...'; notifyListeners();
        await Future.delayed(const Duration(milliseconds: 1500));
        await connect(device, retry: retry + 1);
      } else {
        _log = 'Error: $msg'; notifyListeners();
      }
    }
  }

  // ── Desconectar ──
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _connected = false;
    _foundDevice = null;
    _cmdChar = null; _stateChar = null;
    _stateSub?.cancel(); _connSub?.cancel();
    try { await _device?.disconnect(); } catch (_) {}
    _device = null;
    _log = 'Desconectado';
    notifyListeners();
  }

  bool _intentionalDisconnect = false;

  void _onDisconnect() {
    _connected = false;
    _cmdChar = null; _stateChar = null;
    _stateSub?.cancel();
    // NO cancelar _connSub — seguimos escuchando connectionState
    _log = 'Desconectado — reconectando...';
    notifyListeners();
    if (!_intentionalDisconnect && _device != null) {
      _autoReconnect();
    }
    _intentionalDisconnect = false;
  }

  Future<void> _autoReconnect() async {
    // Escuchar connectionState — cuando Android reconecta solo, redescubrir servicios
    // También intentar connect() periódicamente para ayudar a Android
    while (!_connected && _device != null && !_intentionalDisconnect) {
      await Future.delayed(const Duration(seconds: 4));
      if (_device == null || _intentionalDisconnect || _connected) break;
      try {
        // Intentar conectar — si ya está conectado a nivel GATT, solo redescubre servicios
        await _device!.connect();
        // Si llegamos acá sin excepción, redescubrir servicios
        final services = await _device!.discoverServices();
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
        _connected = true;
        _log = 'Reconectado ✓';
        notifyListeners();
        return;
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('already connected')) {
          // GATT sigue abierto — solo redescubrir servicios
          try {
            final services = await _device!.discoverServices();
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
            _connected = true;
            _log = 'Reconectado ✓';
            notifyListeners();
            return;
          } catch (_) {}
        }
        // Cualquier otro error — seguir intentando
      }
    }
  }

  // ── Recibir estado ──
  void _onStateReceived(List<int> value) {
    try {
      final raw = utf8.decode(value);
      final newState = PixBarState.fromJson(raw);
      if (newState.modo != _state.modo ||
          newState.score != _state.score ||
          newState.vidas != _state.vidas ||
          newState.mute != _state.mute ||
          newState.vuColor != _state.vuColor ||
          newState.efxParam != _state.efxParam) {
        _state = newState;
        notifyListeners();
      } else {
        _state = newState;
      }
    } catch (_) {}
  }

  Future<void> cmd(int byte) async {
    if (!_connected || _cmdChar == null) return;
    try { await _cmdChar!.write([byte], withoutResponse: true); }
    catch (e) { debugPrint('cmd error: $e'); }
  }

  Future<void> cmdBytes(List<int> bytes) async {
    if (!_connected || _cmdChar == null) return;
    try { await _cmdChar!.write(bytes, withoutResponse: false); }
    catch (e) { debugPrint('cmdBytes error: $e'); }
  }

  Future<void> sendRGB(int r, int g, int b) async => await cmdBytes(PixBarCmd.rgb(r, g, b));

  Future<void> setBrillo(double valor) async => await cmd(PixBarCmd.brilloDesdeSlider(valor));

  @override
  void dispose() {
    _scanSub?.cancel(); _stateSub?.cancel(); _connSub?.cancel();
    super.dispose();
  }
}
