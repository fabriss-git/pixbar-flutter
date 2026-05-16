import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'commands.dart';
import 'pixbar_device.dart';
import 'pixbar_group.dart';

// ============================================================
// BleManager — reemplaza BleService
// Gestiona múltiples PixBarDevices, grupos, escaneo y persistencia.
// ============================================================

/// Target activo: puede ser un PixBarDevice o un PixBarGroup.
/// La UI usa esto para saber a quién mandar comandos.
abstract class PixBarTarget {
  String get displayName;
  Future<void> cmd(int byte);
  Future<void> cmdBytes(List<int> bytes);
  Future<void> sendRGB(int r, int g, int b);
  Future<void> setBrillo(double valor);
}

/// Adapter: PixBarDevice como target
class DeviceTarget extends PixBarTarget {
  final PixBarDevice device;
  DeviceTarget(this.device);

  @override String get displayName => device.displayName;
  @override Future<void> cmd(int byte) => device.cmd(byte);
  @override Future<void> cmdBytes(List<int> bytes) => device.cmdBytes(bytes);
  @override Future<void> sendRGB(int r, int g, int b) => device.sendRGB(r, g, b);
  @override Future<void> setBrillo(double v) => device.setBrillo(v);

  /// Estado del device activo (para mostrar en HomeScreen)
  PixBarState get state => device.state;
  bool get connected => device.connected;
}

/// Adapter: PixBarGroup como target
class GroupTarget extends PixBarTarget {
  final PixBarGroup group;
  final List<PixBarDevice> allDevices;
  GroupTarget(this.group, this.allDevices);

  @override String get displayName => '${group.name} (${group.connectedCount(allDevices)}/${group.totalCount})';
  @override Future<void> cmd(int byte) => group.cmd(byte, allDevices);
  @override Future<void> cmdBytes(List<int> bytes) => group.cmdBytes(bytes, allDevices);
  @override Future<void> sendRGB(int r, int g, int b) => group.sendRGB(r, g, b, allDevices);
  @override Future<void> setBrillo(double v) => group.setBrillo(v, allDevices);

  /// Para grupos: estado del primer miembro conectado (o vacío)
  PixBarState get state {
    final first = allDevices
        .where((d) => group.memberIds.contains(d.id) && d.connected)
        .firstOrNull;
    return first?.state ?? const PixBarState();
  }
}

// ============================================================

class BleManager extends ChangeNotifier {
  // ── Dispositivos conocidos y conectados ──
  final List<PixBarDevice> devices = [];

  // ── Grupos ──
  final List<PixBarGroup> groups = [];

  // ── Escaneo ──
  bool _scanning = false;
  final List<ScanResult> _scanResults = [];
  StreamSubscription? _scanSub;

  bool _isConnecting = false; 

  // ── Target activo (device o grupo que se está controlando) ──
  PixBarTarget? _activeTarget;

  bool get scanning => _scanning;
  List<ScanResult> get scanResults => List.unmodifiable(_scanResults);
  PixBarTarget? get activeTarget => _activeTarget;

  /// Shortcut: si el target activo es un DeviceTarget, su estado
  PixBarState get activeState {
    final t = _activeTarget;
    if (t is DeviceTarget) return t.state;
    if (t is GroupTarget) return t.state;
    return const PixBarState();
  }

  /// True si hay al menos un device conectado
  bool get anyConnected => devices.any((d) => d.connected);

  // ── Init: cargar persistencia y reconectar ──
  Future<void> init() async {
    await _loadFromPrefs();
    await _reconnectAll();
    // Si ninguno conectó, el caller puede lanzar escaneo
  }

  // ── Persistencia ──
  static const _keyDevices = 'ble_devices_v2';
  static const _keyGroups  = 'ble_groups_v2';
  static const _keyActive  = 'ble_active_id';

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Cargar devices conocidos
    final devJson = prefs.getString(_keyDevices);
    if (devJson != null) {
      final list = jsonDecode(devJson) as List;
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final id    = map['id'] as String;
        final alias = map['alias'] as String? ?? '';
        final btDev = BluetoothDevice.fromId(id);
        final dev = PixBarDevice(btDevice: btDev, alias: alias);
        dev.isManagerConnecting = () => _isConnecting; 
        dev.addListener(notifyListeners); // propagar cambios al árbol
        devices.add(dev);
      }
    }

    // Cargar grupos
    final grpJson = prefs.getString(_keyGroups);
    if (grpJson != null) {
      final list = jsonDecode(grpJson) as List;
      for (final item in list) {
        groups.add(PixBarGroup.fromJson(item as Map<String, dynamic>));
      }
    }

    // Restaurar target activo
    final activeId = prefs.getString(_keyActive);
    if (activeId != null) {
      // Se intentará setear después de reconectar
      _pendingActiveId = activeId;
    }

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

  // ── Reconectar todos los devices conocidos en paralelo ──
  Future<void> _reconnectAll() async {
    //await Future.wait(devices.map((d) => d.connect()));
      for (final d in devices) {
    await d.connect();
    if (d.connected) await Future.delayed(const Duration(milliseconds: 500));
  }
    // Restaurar target activo
    if (_pendingActiveId != null) {
      _restoreActiveTarget(_pendingActiveId!);
      _pendingActiveId = null;
    }
    // Si no hay target y hay al menos uno conectado, activar el primero
    if (_activeTarget == null) {
      final first = devices.where((d) => d.connected).firstOrNull;
      if (first != null) setActiveDevice(first);
    }
    notifyListeners();
  }

  void _restoreActiveTarget(String id) {
    // Intentar como device
    final dev = devices.where((d) => d.id == id).firstOrNull;
    if (dev != null && dev.connected) {
      _activeTarget = DeviceTarget(dev);
      return;
    }
    // Intentar como grupo
    final grp = groups.where((g) => g.id == id).firstOrNull;
    if (grp != null) {
      _activeTarget = GroupTarget(grp, devices);
    }
  }

  // ── Setear target activo ──
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

  // ── Escanear — busca nuevos PixBar no conocidos ──
Future<void> startScan() async {
  if (_scanning) return;
  _scanning = true;
  _scanResults.clear();
  notifyListeners();

  try {
    _scanSub?.cancel();

_scanSub = FlutterBluePlus.scanResults.listen((results) {
  bool changed = false;
  for (final r in results) {
    final advName = r.advertisementData.advName;
    final platName = r.device.platformName;
    final name = advName.isNotEmpty ? advName : platName;
    debugPrint('SCAN: advName="$advName" platName="$platName" mac=${r.device.remoteId.str}');
    final alreadyKnown = devices.any((d) => d.id == r.device.remoteId.str);
    final alreadyInResults = _scanResults.any((s) => s.device.remoteId == r.device.remoteId);
    if (!alreadyKnown && !alreadyInResults) {
      _scanResults.add(r);
      changed = true;
    }
  }
  if (changed) notifyListeners();
});

    // Sin filtro de nombre — filtramos nosotros por advName
    await FlutterBluePlus.startScan(
      withServices: [Guid('12345678-1234-1234-1234-123456789abc')],
      timeout: const Duration(seconds: 10),
    );

  } catch (e) {
    debugPrint('Scan error: $e');
  } finally {
    _scanning = false;
    notifyListeners();
  }
}

  void stopScan() {
    FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    _scanning = false;
    notifyListeners();
  }

  // ── Conectar un device encontrado en el scan ──
Future<PixBarDevice> connectScanResult(ScanResult result) async {
  _isConnecting = true; 
  // Detener scan antes de conectar
  stopScan();


  await Future.delayed(const Duration(seconds: 2)); //antes milliseconds: 300

  var dev = devices.where((d) => d.id == result.device.remoteId.str).firstOrNull;
  if (dev == null) {
    final advName = result.advertisementData.advName;
    final platName = result.device.platformName;
    final mac = result.device.remoteId.str;
    final macClean = mac.replaceAll(':', '');
    final alias = advName.isNotEmpty
        ? advName
        : platName.isNotEmpty
            ? platName
            : 'PixBar-${macClean.substring(macClean.length - 4)}';
    dev = PixBarDevice(btDevice: result.device, alias: alias);
    dev.isManagerConnecting = () => _isConnecting;
    dev.addListener(notifyListeners);
    devices.add(dev);
    await _saveDevicesToPrefs();
  }
  try{
  await dev.connect();
  for (int i = 0; i < 60; i++) {
    if (dev.connected) break;
    await Future.delayed(const Duration(milliseconds: 500));
  }
  if (_activeTarget == null) setActiveDevice(dev);
  notifyListeners();
  }  finally {
  _isConnecting = false;  // ← liberar al final
  }
  return dev;
}


  // ── Desconectar un device ──
  Future<void> disconnectDevice(PixBarDevice device) async {
    await device.disconnect();
    // Si era el target activo, cambiar al primer conectado disponible
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

  // ── Olvidar un device (eliminar de la lista permanente) ──
  Future<void> forgetDevice(PixBarDevice device) async {
    await device.disconnect();
    device.removeListener(notifyListeners);
    devices.remove(device);
    // Eliminar de grupos
    for (final g in groups) {
      g.memberIds.remove(device.id);
    }
    await _saveDevicesToPrefs();
    await _saveGroupsToPrefs();
    notifyListeners();
  }

  // ── Renombrar device ──
  Future<void> renameDevice(PixBarDevice device, String newAlias) async {
    device.alias = newAlias.trim().isEmpty ? device.btName : newAlias.trim();
    await _saveDevicesToPrefs();
    notifyListeners();
  }

  // ── Grupos: crear ──
  Future<PixBarGroup> createGroup(String name, List<String> memberIds) async {
    final group = PixBarGroup(
      id: const Uuid().v4(),
      name: name,
      memberIds: memberIds,
    );
    groups.add(group);
    await _saveGroupsToPrefs();
    notifyListeners();
    return group;
  }

  // ── Grupos: editar ──
  Future<void> updateGroup(PixBarGroup group, {String? name, List<String>? memberIds}) async {
    if (name != null) group.name = name;
    if (memberIds != null) group.memberIds = memberIds;
    await _saveGroupsToPrefs();
    notifyListeners();
  }

  // ── Grupos: eliminar ──
  Future<void> deleteGroup(PixBarGroup group) async {
    // Si era el target activo, limpiar
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
