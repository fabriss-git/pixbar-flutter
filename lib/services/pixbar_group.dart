import 'pixbar_device.dart';

// ============================================================
// PixBarGroup — grupo de PixBarDevices
// Los comandos se envían a todos los miembros en paralelo.
// ============================================================
class PixBarGroup {
  final String id;         // UUID generado al crear el grupo
  String name;             // Nombre editable: "Pista", "Barra", etc.
  List<String> memberIds;  // IDs (MAC) de los devices miembro

  PixBarGroup({
    required this.id,
    required this.name,
    required this.memberIds,
  });

  // ── Serialización para shared_preferences ──
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'memberIds': memberIds,
  };

  factory PixBarGroup.fromJson(Map<String, dynamic> json) => PixBarGroup(
    id: json['id'] as String,
    name: json['name'] as String,
    memberIds: List<String>.from(json['memberIds'] as List),
  );

  // ── Enviar comando a todos los miembros conectados ──
  Future<void> cmd(int byte, List<PixBarDevice> allDevices) async {
    final targets = _members(allDevices);
    await Future.wait(targets.map((d) => d.cmd(byte)));
  }

  Future<void> cmdBytes(List<int> bytes, List<PixBarDevice> allDevices) async {
    final targets = _members(allDevices);
    await Future.wait(targets.map((d) => d.cmdBytes(bytes)));
  }

  Future<void> sendRGB(int r, int g, int b, List<PixBarDevice> allDevices) async {
    final targets = _members(allDevices);
    await Future.wait(targets.map((d) => d.sendRGB(r, g, b)));
  }

  Future<void> setBrillo(double valor, List<PixBarDevice> allDevices) async {
    final targets = _members(allDevices);
    await Future.wait(targets.map((d) => d.setBrillo(valor)));
  }

  // Filtra solo los miembros que existen y están conectados
  List<PixBarDevice> _members(List<PixBarDevice> allDevices) =>
      allDevices.where((d) => memberIds.contains(d.id) && d.connected).toList();

  // Estado: cantidad de miembros conectados
  int connectedCount(List<PixBarDevice> allDevices) =>
      _members(allDevices).length;

  int get totalCount => memberIds.length;
}
