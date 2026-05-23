import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart' as uuid_pkg;
import 'commands.dart';
import 'pixbar_device.dart';
import 'pixbar_group.dart';

// ============================================================
// BleManager — gestiona múltiples PixBarDevices, grupos,
// escaneo y persistencia. Usa flutter_reactive_ble.
// ============================================================

abstract class PixBarTarget {
  String get displayName;
  Future<void> cmd(int byte);
  Future<void> cmdBytes(List<int> bytes);
  Future<void> sendRGB(int r, int g, int b);
  Future<void> setBrillo(double valor);
}

class DeviceTarget extends PixBarTarget {
  final PixBarDevice device;
  DeviceTarget(this.device);

  @override String get displayName => device.displayName;
  @override Future<void> cmd(int byte) => device.cmd(byte);
  @override Future<void> cmdBytes(List<int> bytes) => device.cmdBytes(bytes);
  @override Future<void> sendRGB(int r, int g, int b) => device.sendRGB(r, g, b);
  @override Future<void> setBrillo(double v) => device.setBrillo(v);

  PixBarState get state => device.state;
  bool get connected => device.connected;
}

class GroupTarget extends PixBarTarget {
  final PixBarGroup group;
  final List<PixBarDevice> allDevices;
  GroupTarget(this.group, this.allDevices);

  @override String get displayName => '${group.name} (${group.connectedCount(allDevices)}/${group.totalCount})';
  @override Future<void> cmd(int byte) => group.cmd(byte, allDevices);
  @override Future<void> cmdBytes(List<int> bytes) => group.cmdBytes(bytes, allDevices);
  @override Future<void> sendRGB(int r, int g, int b) => group.sendRGB(r, g, b, allDevices);
  @override Future<void> setBrillo(double v) => group.setBrillo(v, allDevices);

  PixBarState get state {
    final first = allDevices
        .where((d) => group.memberIds.contains(d.id) && d.connected)
        .firstOrNull;
    return first?.state ?? const PixBarState();
  }
}

// ============================================================

class BleManager extends ChangeNotifier {
  // Una sola instancia de FlutterReactiveBle para toda la app
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  final List<PixBarDevice> devices = [];
  final List<PixBarGroup> groups = [];

  // Escaneo
  bool _scanning = false;
  final List<DiscoveredDevice> _scanResults = [];
  StreamSubscription? _scanSub;

  PixBarTarget? _activeTarget;

  bool get scanning => _scanning;
  List<DiscoveredDevice> get scanResults => List.unmodifiable(_scanResults);
  PixBarTarget? get activeTarget => _activeTarget;

  PixBarState get activeState {
    final t = _activeTarget;
    if (t is DeviceTarget) return t.state;
    if (t is GroupTarget) return t.state;
    return const PixBarState();
  }

  bool get anyConnected => devices.any((d) => d.connected);

  // ── Init ──
  Future<void> init() async {
    await _loadFromPrefs();
    _reconnectAll();
  }

  // ── Persistencia ──
  static const _keyDevices = 'ble_devices_v2';
  static const _keyGroups  = 'ble_groups_v2';
  static const _keyActive  = 'ble_active_id';

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final devJson = prefs.getString(_keyDevices);
    if (devJson != null) {
      final list = jsonDecode(devJson) as List;
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final id    = map['id'] as String;
        final alias = map['alias'] as String? ?? '';
        final dev = PixBarDevice(id: id, ble: _ble, alias: alias);
        dev.addListener(notifyListeners);
        devices.add(dev);
      }
    }

    final grpJson = prefs.getString(_keyGroups);
    if (grpJson != null) {
      final list = jsonDecode(grpJson) as List;
      for (final item in list) {
        groups.add(PixBarGroup.fromJson(item as Map<String, dynamic>));
      }
    }

    final activeId = prefs.getString(_keyActive);
    if (activeId != null) _pendingActiveId = activeId;

    notifyListeners();
  }

  String? _pendingActiveId;

  Future<void> _saveDevicesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final list = devices.map((d) => {'id': d.id, 'alias': d.alias}).toList();
    await prefs.setString(_keyDevices, jsonEncode(list));
  }

  Future<void> _saveGroupsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final list = groups.map((g) => g.toJson()).toList();
    await prefs.setString(_keyGroups, jsonEncode(list));
  }

  Future<void> _saveActiveToPrefs(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActive, id);
  }

  // ── Reconectar todos — flutter_reactive_ble reconecta solo ──
  void _reconnectAll() {
    for (final d in devices) {
      d.connect(); // no await — el stream maneja reconexión automática
    }
    // Restaurar target activo después de un momento
    Future.delayed(const Duration(seconds: 3), () {
      if (_pendingActiveId != null) {
        _restoreActiveTarget(_pendingActiveId!);
        _pendingActiveId = null;
      }
      if (_activeTarget == null) {
        final first = devices.where((d) => d.connected).firstOrNull;
        if (first != null) setActiveDevice(first);
      }
      notifyListeners();
    });
  }

  void _restoreActiveTarget(String id) {
    final dev = devices.where((d) => d.id == id).firstOrNull;
    if (dev != null && dev.connected) {
      _activeTarget = DeviceTarget(dev);
      return;
    }
    final grp = groups.where((g) => g.id == id).firstOrNull;
    if (grp != null) _activeTarget = GroupTarget(grp, devices);
  }

  // ── Target activo ──
  void setActiveDevice(PixBarDevice device) {
    _activeTarget = DeviceTarget(device);
    _saveActiveToPrefs(device.id);
    notifyListeners();
  }

  void setActiveGroup(PixBarGroup group) {
    _activeTarget = GroupTarget(group, devices);
    _saveActiveToPrefs(group.id);
    notifyListeners();
  }

  // ── Escanear ──
  Future<void> startScan() async {
    if (_scanning) return;
    _scanning = true;
    _scanResults.clear();
    notifyListeners();

    try {
      _scanSub?.cancel();
      _scanSub = _ble.scanForDevices(
        withServices: [Uuid.parse('12345678-1234-1234-1234-123456789abc')],
        scanMode: ScanMode.lowLatency,
      ).listen(
        (device) {
          debugPrint('SCAN: id=${device.id} name=${device.name}');
          final alreadyKnown = devices.any((d) => d.id == device.id);
          final alreadyInResults = _scanResults.any((r) => r.id == device.id);
          if (!alreadyKnown && !alreadyInResults) {
            _scanResults.add(device);
            notifyListeners();
          }
        },
        onError: (e) => debugPrint('Scan error: $e'),
      );

      // Detener después de 10 segundos
      await Future.delayed(const Duration(seconds: 10));
      stopScan();

    } catch (e) {
      debugPrint('Scan error: $e');
      _scanning = false;
      notifyListeners();
    }
  }

  void stopScan() {
    _scanSub?.cancel();
    _scanning = false;
    notifyListeners();
  }

  // ── Conectar device encontrado en scan ──
 Future<PixBarDevice> connectScanResult(DiscoveredDevice result) async {
  stopScan();

  var dev = devices.where((d) => d.id == result.id).firstOrNull;
  if (dev == null) {
    final name = result.name.isNotEmpty
        ? result.name
        : 'PixBar-${result.id.replaceAll(':', '').substring(result.id.replaceAll(':', '').length - 4)}';
    dev = PixBarDevice(id: result.id, ble: _ble, alias: name);
    dev.addListener(notifyListeners);
    devices.add(dev);
    await _saveDevicesToPrefs();
  }
//debugPrint('connectScanResult: llamando connect() para ${dev.id}'); //debug para nombre pixbar
 //await dev.connect(); // sin await — el stream notifica cuando conecta
 dev.connect();
//debugPrint('connectScanResult: connect() retornó, connected=${dev.connected}');
//debugPrint('connectScanResult: device agregado, esperando conexión...'); //debug para conexion bluetooth
  // Esperar conexión real
  //for (int i = 0; i < 30; i++) {
  //  if (dev.connected) break;
  //  await Future.delayed(const Duration(milliseconds: 500));
 // }


//Funcion para hacer debug de nombre y conexion bluetooth
//  void dbgListener() {
//    debugPrint('connectScanResult listener: connected=${dev!.connected}');
//  }
//  dev.addListener(dbgListener);
//  Future.delayed(const Duration(seconds: 10), () {
//    dev!.removeListener(dbgListener);
//  });


  if (_activeTarget == null) setActiveDevice(dev);
  notifyListeners();
  return dev;
}

  // ── Desconectar device ──
  Future<void> disconnectDevice(PixBarDevice device) async {
    await device.disconnect();
    if (_activeTarget is DeviceTarget &&
        (_activeTarget as DeviceTarget).device.id == device.id) {
      final next = devices.where((d) => d.connected && d.id != device.id).firstOrNull;
      if (next != null) {
        setActiveDevice(next);
      } else {
        _activeTarget = null;
        notifyListeners();
      }
    }
  }

  // ── Olvidar device ──
  Future<void> forgetDevice(PixBarDevice device) async {
    await device.disconnect();
    device.removeListener(notifyListeners);
    devices.remove(device);
    for (final g in groups) {
      g.memberIds.remove(device.id);
    }
    await _saveDevicesToPrefs();
    await _saveGroupsToPrefs();
    notifyListeners();
  }

  // ── Renombrar device ──
  Future<void> renameDevice(PixBarDevice device, String newAlias) async {
    device.alias = newAlias.trim().isEmpty ? device.id : newAlias.trim();
    await _saveDevicesToPrefs();
    notifyListeners();
  }

  // ── Grupos ──
  Future<PixBarGroup> createGroup(String name, List<String> memberIds) async {
    final group = PixBarGroup(
      id: const uuid_pkg.Uuid().v4(),
      name: name,
      memberIds: memberIds,
    );
    groups.add(group);
    await _saveGroupsToPrefs();
    notifyListeners();
    return group;
  }

  Future<void> updateGroup(PixBarGroup group, {String? name, List<String>? memberIds}) async {
    if (name != null) group.name = name;
    if (memberIds != null) group.memberIds = memberIds;
    await _saveGroupsToPrefs();
    notifyListeners();
  }

  Future<void> deleteGroup(PixBarGroup group) async {
    if (_activeTarget is GroupTarget &&
        (_activeTarget as GroupTarget).group.id == group.id) {
      final first = devices.where((d) => d.connected).firstOrNull;
      if (first != null) setActiveDevice(first);
      else _activeTarget = null;
    }
    groups.remove(group);
    await _saveGroupsToPrefs();
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    for (final d in devices) {
      d.removeListener(notifyListeners);
      d.dispose();
    }
    super.dispose();
  }
}
