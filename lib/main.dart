import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/ble_manager.dart';
import 'screens/scan_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const PixBarApp());
}

class PixBarApp extends StatelessWidget {
  const PixBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BleManager(),
      child: MaterialApp(
        title: 'PixBar',
        debugShowCheckedModeBanner: false,
        theme: PixBarTheme.theme,
        home: const _AppRoot(),
      ),
    );
  }
}

/// Decide si mostrar ScanScreen o HomeScreen según el estado inicial
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final mgr = context.read<BleManager>();
      await mgr.init(); // carga prefs + reconecta todos
      if (mounted) setState(() => _initialized = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      // Splash mientras inicializa
      return const Scaffold(
        backgroundColor: Color(0xFF080808),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
        ),
      );
    }

    final mgr = context.watch<BleManager>();
    if (mgr.anyConnected) {
      return const HomeScreen();
    } else {
      return const ScanScreen();
    }
  }
}
