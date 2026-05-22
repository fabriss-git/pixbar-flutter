import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../services/ble_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_widget.dart';
import 'home_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
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

    //if (mgr.anyConnected || mgr.devices.isNotEmpty) {
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

                  if (mgr.scanning)
                    Column(children: [
                      const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: PixBarColors.cyan),
                      ),
                      const SizedBox(height: 12),
                      Text('Buscando PixBar...',
                        style: PixBarText.mono.copyWith(
                          fontSize: 11, color: PixBarColors.grey2)),
                    ])
                  else if (mgr.scanResults.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: PixBarColors.panel,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: PixBarColors.border),
                      ),
                      child: Text(
                        'No se encontraron dispositivos.\nAsegurate de que el PixBar esté encendido.',
                        style: PixBarText.mono.copyWith(
                          fontSize: 11, color: PixBarColors.grey2),
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
  //final dev = await mgr.connectScanResult(result);
  await mgr.connectScanResult(result);
  // Navegar solo si conectó
  //if (dev.connected && mounted) {
  //  Navigator.of(context).pushReplacement(
  //    MaterialPageRoute(builder: (_) => const HomeScreen()),
  //  );
 // }
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
        ),
      ],
    );
  }
}

class _ScanResultTile extends StatefulWidget {
  final DiscoveredDevice result;
  final Future<void> Function() onConnect;
  const _ScanResultTile({required this.result, required this.onConnect});

  @override
  State<_ScanResultTile> createState() => _ScanResultTileState();
}

class _ScanResultTileState extends State<_ScanResultTile> {
  bool _connecting = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.result.name;
    final mac = widget.result.id;
    final macClean = mac.replaceAll(':', '');
    final displayName = name.isNotEmpty
        ? name
        : 'PixBar-${macClean.substring(macClean.length - 4)}';

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
                style: PixBarText.mono.copyWith(
                  fontSize: 12, color: PixBarColors.white)),
                  //Muestra MAC en scan:
              //Text(mac,
               // style: PixBarText.mono.copyWith(
                //  fontSize: 9, color: PixBarColors.grey)),
              if (_connecting)
                Text('Conectando...',
                  style: PixBarText.mono.copyWith(
                    fontSize: 9, color: PixBarColors.cyan)),
            ],
          ),
        ),
        if (!_connecting)
          TextButton(
            onPressed: () async {
              setState(() => _connecting = true);
              await widget.onConnect();
              if (mounted) setState(() => _connecting = false);
            },
            child: Text('CONECTAR',
              style: PixBarText.mono.copyWith(
                fontSize: 10, color: PixBarColors.cyan)),
          ),
      ]),
    );
  }
}
