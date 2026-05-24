import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'commands.dart';

// ============================================================
// PixBarDevice — un dispositivo BLE individual
// Usa flutter_reactive_ble para conexión confiable múltiple
// ============================================================
class PixBarDevice extends ChangeNotifier {
  final String id; // MAC address
  final FlutterReactiveBle _ble;

  StreamSubscription? _connSub;
  StreamSubscription? _stateSub;

  bool _connected = false;
  bool _intentionalDisconnect = false;
  PixBarState _state = const PixBarState();
  String alias;

  // Características BLE
  late QualifiedCharacteristic _cmdChar;
  late QualifiedCharacteristic _stateChar;

  static const _serviceUuid = '12345678-1234-1234-1234-123456789abc';
  static const _stateUuid   = '12345678-1234-1234-1234-123456789ab1';
  static const _cmdUuid     = '12345678-1234-1234-1234-123456789ab2';

  PixBarDevice({
    required this.id,
    required FlutterReactiveBle ble,
    String? alias,
  })  : _ble = ble,
        alias = alias ?? id {
    _cmdChar = QualifiedCharacteristic(
      serviceId: Uuid.parse(_serviceUuid),
      characteristicId: Uuid.parse(_cmdUuid),
      deviceId: id,
    );
    _stateChar = QualifiedCharacteristic(
      serviceId: Uuid.parse(_serviceUuid),
      characteristicId: Uuid.parse(_stateUuid),
      deviceId: id,
    );
  }

  // ── Getters ──
  String get btName => alias;
  bool get connected => _connected;
  PixBarState get state => _state;
  String get displayName => alias.isNotEmpty ? alias : id;

  // ── Conectar ──
  Future<void> connect() async {
  _intentionalDisconnect = false;
  _connSub?.cancel();

  _connSub = _ble.connectToDevice(
    id: id,
    servicesWithCharacteristicsToDiscover: {
      Uuid.parse(_serviceUuid): [
        Uuid.parse(_stateUuid),
        Uuid.parse(_cmdUuid),
      ],
    },
    connectionTimeout: const Duration(seconds: 8), //antes 30
  ).listen(
    (update) {
      debugPrint('[$displayName] connectionState: ${update.connectionState}');
      switch (update.connectionState) {
        case DeviceConnectionState.connected:
          _onConnected();
          break;
        case DeviceConnectionState.disconnected:
          if (!_intentionalDisconnect) {
            _onUnexpectedDisconnect();
          } else {
            _onIntentionalDisconnect();
          }
          break;
        default:
          break;
      }
    },
    onError: (e) {
      debugPrint('[$displayName] connection error: $e — reintentando en 3');
      _connected = false;
      notifyListeners();
      if (!_intentionalDisconnect) {
        Future.delayed(const Duration(seconds: 3), () {
          if (!_connected && !_intentionalDisconnect) connect();
        });
      }
    },
  );
}

  void _onConnected() async {
    //debugPrint('[$displayName] _onConnected llamado — connected=$_connected'); //debug para nombre pixbar
  
      try {
    await _ble.requestMtu(deviceId: id, mtu: 185);
    debugPrint('[$displayName] MTU negociado');
  } catch (e) {
    debugPrint('[$displayName] MTU error: $e');
  }

    _connected = true;
    notifyListeners();
    //debugPrint('[$displayName] notifyListeners llamado'); //debug par nombre pixbar
    _subscribeToState();
  }

void _onUnexpectedDisconnect() {
  _connected = false;
  _stateSub?.cancel();
  notifyListeners();
  // Delay escalonado basado en el último byte del MAC
  final lastByte = int.tryParse(id.split(':').last, radix: 16) ?? 0;
  final delay = 2 + (lastByte % 4); // entre 2 y 5 segundos
  debugPrint('[$displayName] desconexión inesperada — reintentando en ${delay}s');
  Future.delayed(Duration(seconds: delay), () {
    if (!_connected && !_intentionalDisconnect) connect();
  });
}

  void _onIntentionalDisconnect() {
    _connected = false;
    _stateSub?.cancel();
    notifyListeners();
  }

  void _subscribeToState() {
    _stateSub?.cancel();
    _stateSub = _ble.subscribeToCharacteristic(_stateChar).listen(
      _onStateReceived,
      onError: (e) => debugPrint('[$displayName] state sub error: $e'),
    );
  }

  // ── Desconectar (intencional) ──
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _stateSub?.cancel();
    _connSub?.cancel();
    _connected = false;
    notifyListeners();
  }

  // ── Recibir estado BLE ──
 final List<int> _buffer = [];

void _onStateReceived(List<int> value) {
  //debugPrint('[$displayName] bytes recibidos: ${value.length} — ${String.fromCharCodes(value)}'); //debur para medir MTU
  _buffer.addAll(value);
  final raw = utf8.decode(_buffer, allowMalformed: true);
  if (!raw.contains('{') || !raw.contains('}')) return; // esperar JSON completo
  _buffer.clear();
  try {
    //debugPrint('[$displayName] JSON completo: $raw');//debug para medir MTU
    final newState = PixBarState.fromJson(raw);
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
    if (!_connected) return;
    try {
      //await _ble.writeCharacteristicWithoutResponse(_cmdChar, value: [byte]);
    final before = DateTime.now().millisecondsSinceEpoch; //agregado para el debug

      //await _ble.writeCharacteristicWithResponse(_cmdChar, value: [byte]);
      await _ble.writeCharacteristicWithoutResponse(_cmdChar, value: [byte]);

    final after = DateTime.now().millisecondsSinceEpoch;//agregado para el debug
    debugPrint('[$displayName] cmd 0x${byte.toRadixString(16)} tardó ${after - before}ms');//agregado para el debug

    } catch (e) {
      debugPrint('[$displayName] cmd error: $e');
    }
  }

  Future<void> cmdBytes(List<int> bytes) async {
    if (!_connected) return;
    try {
      await _ble.writeCharacteristicWithResponse(_cmdChar, value: bytes);
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
