import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_manager.dart';
import '../services/pixbar_device.dart';
import '../services/pixbar_group.dart';
import '../theme/app_theme.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mgr = context.watch<BleManager>();

    return Scaffold(
      backgroundColor: PixBarColors.background,
      appBar: AppBar(
        title: Text('DISPOSITIVOS', style: PixBarText.mono.copyWith(
          color: PixBarColors.cyan, fontSize: 12)),
        backgroundColor: PixBarColors.background,
        iconTheme: const IconThemeData(color: PixBarColors.grey2),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── DISPOSITIVOS ──
          _SectionHeader(
            title: 'DISPOSITIVOS',
            action: mgr.scanning
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: PixBarColors.cyan))
              : _AddButton(label: '+ AGREGAR', onTap: () => _showScanSheet(context, mgr)),
          ),
          const SizedBox(height: 8),

          if (mgr.devices.isEmpty)
            _EmptyCard(text: 'No hay dispositivos.\nTocá + AGREGAR para buscar.')
          else
            ...mgr.devices.map((dev) => _DeviceTile(device: dev, mgr: mgr)),

          const SizedBox(height: 24),

          // ── GRUPOS ──
          _SectionHeader(
            title: 'GRUPOS',
            action: _AddButton(
              label: '+ NUEVO',
              onTap: () => _showCreateGroupSheet(context, mgr),
            ),
          ),
          const SizedBox(height: 8),

          if (mgr.groups.isEmpty)
            _EmptyCard(text: 'No hay grupos.\nTocá + NUEVO para crear uno.')
          else
            ...mgr.groups.map((grp) => _GroupTile(group: grp, mgr: mgr)),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Sheet: agregar dispositivo (scan inline) ──
  void _showScanSheet(BuildContext context, BleManager mgr) {
    mgr.startScan();
    showModalBottomSheet(
      context: context,
      backgroundColor: PixBarColors.panel,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _ScanSheet(mgr: mgr),
    );
  }

  // ── Sheet: crear grupo ──
  void _showCreateGroupSheet(BuildContext context, BleManager mgr) {
    showModalBottomSheet(
      context: context,
      backgroundColor: PixBarColors.panel,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _GroupEditSheet(mgr: mgr, group: null),
    );
  }
}

// ── Tile de dispositivo ──
class _DeviceTile extends StatefulWidget {
  final PixBarDevice device;
  final BleManager mgr;
  const _DeviceTile({required this.device, required this.mgr});

  @override
  State<_DeviceTile> createState() => _DeviceTileState();
}

class _DeviceTileState extends State<_DeviceTile> {
  bool _connecting = false;

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final mgr = widget.mgr;
    final isActive = mgr.activeTarget is DeviceTarget &&
        (mgr.activeTarget as DeviceTarget).device.id == device.id;

    return ListenableBuilder(
      //listenable: device,
        listenable: Listenable.merge([device, mgr]),
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0A1A12) : PixBarColors.panel2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? PixBarColors.green : PixBarColors.border,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Fila principal
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
              child: Row(children: [
                // Indicador de conexión o spinner
                _connecting
                  ? const SizedBox(width: 8, height: 8,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: PixBarColors.cyan))
                  : Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: device.connected ? PixBarColors.green : const Color(0xFF444444),
                        boxShadow: device.connected ? [
                          BoxShadow(color: PixBarColors.green.withAlpha(150), blurRadius: 6)
                        ] : null,
                      ),
                    ),
                const SizedBox(width: 10),
                // Nombre
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(device.displayName,
                        style: PixBarText.display.copyWith(
                          fontSize: 13,
                          color: device.connected ? PixBarColors.white : PixBarColors.grey)),
                      Text(device.id,
                        style: PixBarText.mono.copyWith(fontSize: 9, color: PixBarColors.grey)),
                      if (_connecting)
                        Text('Conectando...',
                          style: PixBarText.mono.copyWith(fontSize: 9, color: PixBarColors.cyan)),
                      if (device.alias != device.btName)
                        Text(device.btName,
                          style: PixBarText.mono.copyWith(fontSize: 9, color: PixBarColors.grey)),
                    ],
                  ),
                ),
                // Renombrar
                IconButton(
                  icon: const Icon(Icons.edit, size: 16, color: PixBarColors.grey),
                  onPressed: () => _showRenameDialog(context),
                ),
              ]),
            ),

            // Botones
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(children: [
                // CONTROLAR
                Expanded(
                  child: _ActionBtn(
                    label: isActive ? '✓ ACTIVO' : 'CONTROLAR',
                    color: isActive ? PixBarColors.green : PixBarColors.cyan,
                    enabled: device.connected && !isActive,
                    onTap: () {
                      mgr.setActiveDevice(device);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // CONECTAR / DESCONECTAR
                Expanded(
                  child: _ActionBtn(
                    label: _connecting
                      ? 'CONECTANDO...'
                      : device.connected ? 'DESCONECTAR' : 'CONECTAR',
                    color: device.connected ? PixBarColors.magenta : PixBarColors.grey2,
                    enabled: !_connecting,
                    onTap: () async {
                      if (device.connected) {
                        await mgr.disconnectDevice(device);
                      } else {
                        setState(() => _connecting = true);
                        await device.connect();
                        if (mounted) setState(() => _connecting = false);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // OLVIDAR
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: PixBarColors.grey),
                  tooltip: 'Olvidar dispositivo',
                  onPressed: () => _confirmForget(context),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final ctrl = TextEditingController(text: widget.device.alias);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: PixBarColors.panel,
        title: Text('Renombrar', style: PixBarText.display.copyWith(fontSize: 14)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: PixBarText.mono.copyWith(color: PixBarColors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: widget.device.btName,
            hintStyle: PixBarText.mono.copyWith(color: PixBarColors.grey),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: PixBarColors.border)),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: PixBarColors.cyan)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCELAR', style: PixBarText.mono.copyWith(color: PixBarColors.grey))),
          TextButton(
            onPressed: () {
              widget.mgr.renameDevice(widget.device, ctrl.text);
              Navigator.pop(context);
            },
            child: Text('GUARDAR', style: PixBarText.mono.copyWith(color: PixBarColors.cyan))),
        ],
      ),
    );
  }

  void _confirmForget(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: PixBarColors.panel,
        title: Text('Olvidar dispositivo', style: PixBarText.display.copyWith(fontSize: 14)),
        content: Text('Se eliminará ${widget.device.displayName} de la lista.\n¿Continuás?',
          style: PixBarText.mono.copyWith(fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCELAR', style: PixBarText.mono.copyWith(color: PixBarColors.grey))),
          TextButton(
            onPressed: () {
              widget.mgr.forgetDevice(widget.device);
              Navigator.pop(context);
            },
            child: Text('OLVIDAR', style: PixBarText.mono.copyWith(color: PixBarColors.magenta))),
        ],
      ),
    );
  }
}

// ── Tile de grupo ──
class _GroupTile extends StatelessWidget {
  final PixBarGroup group;
  final BleManager mgr;
  const _GroupTile({required this.group, required this.mgr});

  @override
  Widget build(BuildContext context) {
    final connected = group.connectedCount(mgr.devices);
    final total = group.totalCount;
    final isActive = mgr.activeTarget is GroupTarget &&
        (mgr.activeTarget as GroupTarget).group.id == group.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0A0F1A) : PixBarColors.panel2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? PixBarColors.cyan : PixBarColors.border,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            const Text('◈', style: TextStyle(color: PixBarColors.cyan, fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(group.name,
                  style: PixBarText.display.copyWith(fontSize: 13, color: PixBarColors.white)),
                Text('$connected/$total conectados',
                  style: PixBarText.mono.copyWith(fontSize: 9, color: PixBarColors.grey)),
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Row(children: [
            Expanded(
              child: _ActionBtn(
                label: isActive ? '✓ ACTIVO' : 'CONTROLAR',
                color: isActive ? PixBarColors.cyan : PixBarColors.cyan,
                enabled: connected > 0 && !isActive,
                onTap: () {
                  mgr.setActiveGroup(group);
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionBtn(
                label: 'EDITAR',
                color: PixBarColors.grey2,
                onTap: () => _showEditSheet(context),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: PixBarColors.grey),
              onPressed: () => _confirmDelete(context),
            ),
          ]),
        ),
      ]),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: PixBarColors.panel,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _GroupEditSheet(mgr: mgr, group: group),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: PixBarColors.panel,
        title: Text('Eliminar grupo', style: PixBarText.display.copyWith(fontSize: 14)),
        content: Text('¿Eliminás el grupo "${group.name}"?',
          style: PixBarText.mono.copyWith(fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCELAR', style: PixBarText.mono.copyWith(color: PixBarColors.grey))),
          TextButton(
            onPressed: () {
              mgr.deleteGroup(group);
              Navigator.pop(context);
            },
            child: Text('ELIMINAR', style: PixBarText.mono.copyWith(color: PixBarColors.magenta))),
        ],
      ),
    );
  }
}

// ── Sheet de scan para agregar dispositivo ──
class _ScanSheet extends StatefulWidget {
  final BleManager mgr;
  const _ScanSheet({required this.mgr});

  @override
  State<_ScanSheet> createState() => _ScanSheetState();
}

class _ScanSheetState extends State<_ScanSheet> {
  String? _connectingId; // MAC del device que está conectando

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.mgr,
      child: Consumer<BleManager>(
        builder: (_, m, __) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Text('AGREGAR DISPOSITIVO',
                  style: PixBarText.mono.copyWith(
                    fontSize: 11, letterSpacing: 2, color: PixBarColors.cyan)),
                const Spacer(),
                if (m.scanning)
                  const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: PixBarColors.cyan))
                else
                  TextButton(
                    onPressed: () => m.startScan(),
                    child: Text('BUSCAR', style: PixBarText.mono.copyWith(
                      fontSize: 10, color: PixBarColors.cyan))),
              ]),
              const SizedBox(height: 12),
              if (m.scanResults.isEmpty && !m.scanning)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('No se encontraron nuevos dispositivos.',
                    style: PixBarText.mono.copyWith(
                      fontSize: 11, color: PixBarColors.grey),
                    textAlign: TextAlign.center),
                )
              else
                ...m.scanResults.map((r) {
                  final advName = r.advertisementData.advName;
                  final platName = r.device.platformName;
                  final mac = r.device.remoteId.str;
                  final macClean = mac.replaceAll(':', '');
                  final nombre = advName.isNotEmpty
                      ? advName
                      : platName.isNotEmpty
                          ? platName
                          : 'PixBar-${macClean.substring(macClean.length - 4)}';
                  final isConnecting = _connectingId == mac;
                  return ListTile(
                    leading: isConnecting
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: PixBarColors.cyan))
                      : const Icon(Icons.bluetooth,
                          color: PixBarColors.cyan, size: 18),
                    title: Text(nombre,
                      style: PixBarText.mono.copyWith(
                        fontSize: 12, color: PixBarColors.white)),
                    subtitle: Text(mac,
                      style: PixBarText.mono.copyWith(
                        fontSize: 9, color: PixBarColors.grey)),
                    trailing: isConnecting
                      ? Text('Conectando...',
                          style: PixBarText.mono.copyWith(
                            fontSize: 9, color: PixBarColors.cyan))
                      : TextButton(
                          onPressed: () async {
                            setState(() => _connectingId = mac);
                            await m.connectScanResult(r);
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: Text('CONECTAR',
                            style: PixBarText.mono.copyWith(
                              fontSize: 10, color: PixBarColors.cyan)),
                        ),
                  );
                }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
// ── Sheet crear/editar grupo ──
class _GroupEditSheet extends StatefulWidget {
  final BleManager mgr;
  final PixBarGroup? group; // null = crear nuevo
  const _GroupEditSheet({required this.mgr, required this.group});

  @override
  State<_GroupEditSheet> createState() => _GroupEditSheetState();
}

class _GroupEditSheetState extends State<_GroupEditSheet> {
  late TextEditingController _nameCtrl;
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.group?.name ?? '');
    _selectedIds = Set.from(widget.group?.memberIds ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devices = widget.mgr.devices;
    final isEdit = widget.group != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20,
        20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isEdit ? 'EDITAR GRUPO' : 'NUEVO GRUPO',
            style: PixBarText.mono.copyWith(
              fontSize: 11, letterSpacing: 2, color: PixBarColors.cyan)),
          const SizedBox(height: 16),

          // Nombre
          TextField(
            controller: _nameCtrl,
            autofocus: !isEdit,
            style: PixBarText.mono.copyWith(color: PixBarColors.white, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Nombre del grupo',
              labelStyle: PixBarText.mono.copyWith(color: PixBarColors.grey, fontSize: 10),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: PixBarColors.border)),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: PixBarColors.cyan)),
            ),
          ),
          const SizedBox(height: 16),

          Text('DISPOSITIVOS',
            style: PixBarText.mono.copyWith(fontSize: 9, letterSpacing: 2, color: PixBarColors.grey)),
          const SizedBox(height: 8),

          if (devices.isEmpty)
            Text('No hay dispositivos conectados.',
              style: PixBarText.mono.copyWith(fontSize: 11, color: PixBarColors.grey))
          else
            ...devices.map((dev) => CheckboxListTile(
              value: _selectedIds.contains(dev.id),
              onChanged: (v) {
                setState(() {
                  if (v == true) _selectedIds.add(dev.id);
                  else _selectedIds.remove(dev.id);
                });
              },
              title: Text(dev.displayName,
                style: PixBarText.mono.copyWith(
                  fontSize: 12,
                  color: dev.connected ? PixBarColors.white : PixBarColors.grey)),
              subtitle: dev.connected
                ? null
                : Text('desconectado',
                    style: PixBarText.mono.copyWith(fontSize: 9, color: PixBarColors.grey)),
              activeColor: PixBarColors.cyan,
              checkColor: PixBarColors.background,
              contentPadding: EdgeInsets.zero,
            )),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _selectedIds.isEmpty || _nameCtrl.text.trim().isEmpty
                ? null
                : () async {
                    if (isEdit) {
                      await widget.mgr.updateGroup(widget.group!,
                        name: _nameCtrl.text.trim(),
                        memberIds: _selectedIds.toList());
                    } else {
                      await widget.mgr.createGroup(
                        _nameCtrl.text.trim(),
                        _selectedIds.toList());
                    }
                    if (mounted) Navigator.pop(context);
                  },
              style: ElevatedButton.styleFrom(
                backgroundColor: PixBarColors.cyan,
                foregroundColor: PixBarColors.background,
                disabledBackgroundColor: PixBarColors.border,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(isEdit ? 'GUARDAR' : 'CREAR GRUPO',
                style: PixBarText.display.copyWith(fontSize: 13)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ──

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget action;
  const _SectionHeader({required this.title, required this.action});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(title, style: PixBarText.mono.copyWith(
        fontSize: 10, letterSpacing: 2, color: PixBarColors.grey)),
      const Spacer(),
      action,
    ]);
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: PixBarColors.cyan.withAlpha(100)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
          style: PixBarText.mono.copyWith(fontSize: 10, color: PixBarColors.cyan)),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool enabled;
  const _ActionBtn({
    required this.label, required this.color,
    this.onTap, this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && onTap != null;
    return GestureDetector(
      onTap: active ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withAlpha(20) : PixBarColors.panel,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? color.withAlpha(120) : PixBarColors.border),
        ),
        child: Text(label,
          textAlign: TextAlign.center,
          style: PixBarText.mono.copyWith(
            fontSize: 9,
            color: active ? color : PixBarColors.grey)),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: PixBarColors.panel2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PixBarColors.border),
      ),
      child: Text(text,
        style: PixBarText.mono.copyWith(fontSize: 11, color: PixBarColors.grey),
        textAlign: TextAlign.center),
    );
  }
}
