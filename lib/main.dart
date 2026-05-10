import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/ble_service.dart';
import 'screens/scan_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Pantalla siempre vertical
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Barra de estado oscura
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
      create: (_) => BleService(),
      child: MaterialApp(
        title: 'PixBar',
        debugShowCheckedModeBanner: false,
        theme: PixBarTheme.theme,
        home: const ScanScreen(),
      ),
    );
  }
}