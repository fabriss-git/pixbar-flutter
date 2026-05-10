import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
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
    //WidgetsBinding.instance.addPostFrameCallback((_) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ble = context.read<BleService>();
      ble.addListener(_onBleChange);
      // Intentar reconectar al último dispositivo conocido
      final reconectado = await ble.reconnectLast();
      // Si no reconectó, escanear automáticamente
      if (!reconectado) ble.startScan();
    });
  }

  void _onBleChange() {
    if (!mounted) return;
    if (context.read<BleService>().connected) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    context.read<BleService>().removeListener(_onBleChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    return Scaffold(
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

              // Log
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: PixBarColors.panel,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PixBarColors.border),
                ),
                child: Text(
                  ble.log,
                  style: PixBarText.mono.copyWith(fontSize: 11, color: PixBarColors.grey2),
                ),
              ),

              const SizedBox(height: 16),

              // Botón — CONECTAR conecta al dispositivo encontrado (o escanea si no hay)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: ble.scanning ? null : () => ble.connectFound(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ble.found
                      ? const Color(0xFFFF0090)
                      : const Color(0xFF880055),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: PixBarColors.panel2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: ble.scanning
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: PixBarColors.grey),
                      )
                    : Text(
                        ble.found ? 'CONECTAR' : 'BUSCAR',
                        style: PixBarText.display.copyWith(fontSize: 16)),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
