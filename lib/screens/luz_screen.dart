import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_manager.dart';
import '../services/commands.dart';
import '../theme/app_theme.dart';

class LuzScreen extends StatefulWidget {
  const LuzScreen({super.key});

  @override
  State<LuzScreen> createState() => _LuzScreenState();
}

class _LuzScreenState extends State<LuzScreen> {
  int _selColor = 0;
  double _brillo = 0.7;

  static const colores = [
    Color(0xFFFFB452), Color(0xFFDDE8FF), Color(0xFF0033FF),
    Color(0xFF00BFFF), Color(0xFF8B00CC), Color(0xFFFF0000),
    Color(0xFF00CC00), Color(0xFFFFEE00), Color(0xFFFF1493),
  ];
  static const nombres = [
    'CÁLIDO','BLANCO','AZUL','CELESTE',
    'VIOLETA','ROJO','VERDE','AMARILLO','FUCSIA',
  ];

  @override
  Widget build(BuildContext context) {
    final target = context.read<BleManager>().activeTarget;
    return Scaffold(
      backgroundColor: PixBarColors.background,
      appBar: AppBar(
        title: Text('LUZ AMBIENTE',
          style: PixBarText.mono.copyWith(color: PixBarColors.cyan, fontSize: 12)),
        backgroundColor: PixBarColors.background,
        iconTheme: const IconThemeData(color: PixBarColors.grey2),
//se elimina boton MENU arriba a la derecha en las pantallas
//        actions: [
//          TextButton(
//            onPressed: () {
//              ble.cmd(PixBarCmd.btnMode);
//              Navigator.of(context).popUntil((r) => r.isFirst);
//            },
//            child: Text('MENÚ',
//              style: PixBarText.mono.copyWith(color: PixBarColors.cyan, fontSize: 11)),
//          ),
//        ],
      ),
      body: Column(
        children: [
          // Colores rápidos
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(children: [
              Text('COLORES RÁPIDOS',
                style: PixBarText.mono.copyWith(fontSize: 9, letterSpacing: 2)),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 6,
                  mainAxisSpacing: 6, childAspectRatio: 2.2,
                ),
                itemCount: colores.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () {
                    setState(() => _selColor = i + 1);
                    target?.cmd(PixBarCmd.color(i));
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: colores[i].withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _selColor == i + 1
                          ? Colors.white : colores[i].withAlpha(80),
                        width: _selColor == i + 1 ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 10, height: 10,
                          decoration: BoxDecoration(
                            color: colores[i], shape: BoxShape.circle,
                            boxShadow: [BoxShadow(
                              color: colores[i].withAlpha(150), blurRadius: 6)],
                          )),
                        const SizedBox(width: 4),
                        Text(nombres[i],
                          style: PixBarText.mono.copyWith(fontSize: 7)),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ),

          Container(height: 1, color: PixBarColors.border),

          // Rueda — ocupa el espacio restante
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(children: [
                Text('RUEDA DE COLORES',
                  style: PixBarText.mono.copyWith(fontSize: 9, letterSpacing: 2)),
                const SizedBox(height: 8),
                Expanded(
                  child: _ColorWheel(
                    onColor: (r, g, b) {
                      setState(() => _selColor = 0);
                      target?.sendRGB(r, g, b);
                    },
                  ),
                ),
              ]),
            ),
          ),

          // Slider brillo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: PixBarColors.panel,
              border: Border(top: BorderSide(color: PixBarColors.border)),
            ),
            child: Row(children: [
              const Text('🔅', style: TextStyle(fontSize: 14)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: PixBarColors.cyan,
                    inactiveTrackColor: PixBarColors.border,
                    thumbColor: PixBarColors.cyan,
                    overlayColor: PixBarColors.cyan.withAlpha(30),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _brillo,
                    min: 0, max: 1,
                    onChanged: (v) => setState(() => _brillo = v),
                    onChangeEnd: (v) => target?.setBrillo(v),
                  ),
                ),
              ),
              const Text('☀️', style: TextStyle(fontSize: 16)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ColorWheel extends StatefulWidget {
  final void Function(int r, int g, int b) onColor;
  const _ColorWheel({required this.onColor});

  @override
  State<_ColorWheel> createState() => _ColorWheelState();
}

class _ColorWheelState extends State<_ColorWheel> {
  Offset? _cursor;
  Color _selected = const Color(0xFFFF0090);
  Timer? _debounce;

  List<int> _hsvToRgb(double h, double s, double v) {
    s /= 100; v /= 100;
    double f(double n) {
      final k = (n + h / 60) % 6;
      return v - v * s * max(0, min(k, min(4 - k, 1.0)));
    }
    return [(f(5) * 255).round(), (f(3) * 255).round(), (f(1) * 255).round()];
  }

  void _onTouch(Offset local, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = min(cx, cy) - 4;
    final dx = local.dx - cx;
    final dy = local.dy - cy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist > r) return;

    final angle = (atan2(dy, dx) * 180 / pi + 360) % 360;
    final sat = min(100.0, (dist / r) * 100);
    final rgb = _hsvToRgb(angle, sat, 80);
    final color = Color.fromARGB(255, rgb[0], rgb[1], rgb[2]);

    setState(() { _cursor = local; _selected = color; });

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      widget.onColor(rgb[0], rgb[1], rgb[2]);
    });
  }

  @override
  void dispose() { _debounce?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: LayoutBuilder(builder: (_, constraints) {
          final side = min(constraints.maxWidth, constraints.maxHeight);
          final size = Size(side, side);
          return Center(
            child: GestureDetector(
              onPanStart: (d) => _onTouch(d.localPosition, size),
              onPanUpdate: (d) => _onTouch(d.localPosition, size),
              onTapDown: (d) => _onTouch(d.localPosition, size),
              child: SizedBox(
                width: side, height: side,
                child: CustomPaint(
                  painter: _WheelPainter(cursor: _cursor),
                ),
              ),
            ),
          );
        }),
      ),
      const SizedBox(height: 8),
      Container(
        height: 28,
        decoration: BoxDecoration(
          color: _selected,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [BoxShadow(color: _selected.withAlpha(150), blurRadius: 10)],
        ),
      ),
    ]);
  }
}

class _WheelPainter extends CustomPainter {
  final Offset? cursor;
  const _WheelPainter({this.cursor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = min(cx, cy) - 4;

    for (int a = 0; a < 360; a++) {
      final a1 = (a - 0.5) * pi / 180;
      final paint = Paint()
        ..shader = RadialGradient(colors: [
          Colors.white,  // centro blanco
          HSVColor.fromAHSV(1, a.toDouble(), 1, 0.9).toColor(),
        ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      final path = Path()
        ..moveTo(cx, cy)
        ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r),
          a1, pi / 180 * 1.5, false)
        ..close();
      canvas.drawPath(path, paint);
    }

    if (cursor != null) {
      canvas.drawCircle(cursor!, 10, Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke);
      canvas.drawCircle(cursor!, 10, Paint()
        ..color = Colors.black.withAlpha(60));
    }
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.cursor != cursor;
}