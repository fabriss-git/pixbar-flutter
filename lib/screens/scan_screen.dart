import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_widget.dart';
import 'home_screen.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _connecting = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BleManager>().startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mgr = context.watch<BleManager>();

    // Si ya conectó alguno, ir a Home
    if (mgr.anyConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      });
    }

return Stack(
  children: [
    Scaffold(
      backgroundColor: PixBarColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const PixBarLogo(size: 'large'),
              const SizedBox(height: 8),
              Text(
                'ARCADE · AMBIENT · MUSIC',
                style: PixBarText.mono.copyWith(
                  fontSize: 11, color: PixBarColors.grey, letterSpacing: 3),
              ),
              const Spacer(flex: 2),

              // Estado / resultados
              if (mgr.scanning)
                Column(children: [
                  const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: PixBarColors.cyan),
                  ),
                  const SizedBox(height: 12),
                  Text('Buscando PixBar...',
                    style: PixBarText.mono.copyWith(fontSize: 11, color: PixBarColors.grey2)),
                ])
              else if (mgr.scanResults.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: PixBarColors.panel,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: PixBarColors.border),
                  ),
                  child: Text(
                    'No se encontraron dispositivos.\nAsegurate de que el PixBar esté encendido.',
                    style: PixBarText.mono.copyWith(fontSize: 11, color: PixBarColors.grey2),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: PixBarColors.panel,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: PixBarColors.border),
                  ),
                  child: Column(
                    children: mgr.scanResults.map((result) {
                      return _ScanResultTile(
                        result: result,
onConnect: () async {
  await mgr.connectScanResult(result);
  if (mgr.anyConnected && mounted) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
},
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: mgr.scanning ? null : () => mgr.startScan(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mgr.scanResults.isNotEmpty
                      ? const Color(0xFF880055)
                      : const Color(0xFFFF0090),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: PixBarColors.panel2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: mgr.scanning
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: PixBarColors.grey),
                      )
                    : Text('BUSCAR',
                        style: PixBarText.display.copyWith(fontSize: 16)),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    ),  // ← cierra Scaffold

  ],  // ← cierra children del Stack
);   // ← cierra Stack


  }
}

class _ScanResultTile extends StatefulWidget {
  final ScanResult result;                          // ← era String name
  final Future<void> Function() onConnect;
  const _ScanResultTile({required this.result, required this.onConnect});

  @override
  State<_ScanResultTile> createState() => _ScanResultTileState();
}

class _ScanResultTileState extends State<_ScanResultTile> {
  bool _connecting = false;

@override
  Widget build(BuildContext context) {
final advName = widget.result.advertisementData.advName;
final platName = widget.result.device.platformName;
final mac = widget.result.device.remoteId.str;
final macClean = mac.replaceAll(':', '');
final displayName = advName.isNotEmpty
    ? advName
    : platName.isNotEmpty
        ? platName
        : 'PixBar-${macClean.substring(macClean.length - 4)}';
//debugPrint('TILE: mac=$mac macClean=$macClean displayName=$displayName');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PixBarColors.border)),
      ),
      child: Row(children: [
        _connecting
          ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: PixBarColors.cyan))
          : const Icon(Icons.bluetooth, color: PixBarColors.cyan, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName,
                style: PixBarText.mono.copyWith(fontSize: 12, color: PixBarColors.white)),
              Text(mac,
                style: PixBarText.mono.copyWith(fontSize: 9, color: PixBarColors.grey)),
              if (_connecting)
                Text('Conectando...',
                  style: PixBarText.mono.copyWith(fontSize: 9, color: PixBarColors.cyan)),
            ],
          ),
        ),
        if (!_connecting)
          TextButton(
            onPressed: () async {
              setState(() => _connecting = true);
              await Future.delayed(const Duration(milliseconds: 100)); 
              await widget.onConnect();
              if (mounted) setState(() => _connecting = false);
            },
            child: Text('CONECTAR',
              style: PixBarText.mono.copyWith(fontSize: 10, color: PixBarColors.cyan)),
          ),
      ]),
    );
  }
}
