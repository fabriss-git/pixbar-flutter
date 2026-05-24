import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_manager.dart';
import '../services/commands.dart';
import '../theme/app_theme.dart';

class EfectosScreen extends StatefulWidget {
  const EfectosScreen({super.key});

  @override
  State<EfectosScreen> createState() => _EfectosScreenState();
}

class _EfectosScreenState extends State<EfectosScreen> {
  int _selEfx = 0;
  double _brillo = 0.7;

  @override
  Widget build(BuildContext context) {
    final target = context.read<BleManager>().activeTarget;
    return Scaffold(
      backgroundColor: PixBarColors.background,
      appBar: AppBar(
        title: Text('EFECTOS', style: PixBarText.mono.copyWith(color: PixBarColors.cyan, fontSize: 12)),
        backgroundColor: PixBarColors.background,
        iconTheme: const IconThemeData(color: PixBarColors.grey2),
//se elimina boton MENU arriba a la derecha en cada pantalla
//        actions: [
//          TextButton(
//            onPressed: () {
//              ble.cmd(PixBarCmd.btnMode);
//              Navigator.of(context).popUntil((r) => r.isFirst);
//            },
//            child: Text('MENÚ', style: PixBarText.mono.copyWith(color: PixBarColors.cyan, fontSize: 11)),
//          ),
//        ],
      ),

          body: SafeArea(
          child: Column(
          children: [

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 8,
                mainAxisSpacing: 8, childAspectRatio: 1.1,
              ),
              itemCount: _efectosModos.length,
              itemBuilder: (_, i) {
                final e = _efectosModos[i];
                final sel = _selEfx == i;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selEfx = i);
                    target?.cmd(PixBarCmd.efecto(i));
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: PixBarColors.panel2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel ? PixBarColors.cyan : PixBarColors.border,
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                            child: SizedBox(
                              width: double.infinity,
                              child: CustomPaint(painter: e.painter),
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: PixBarColors.border)),
                          ),
                          child: Text(
                            '${(i+1).toString().padLeft(2,'0')} ${e.nombre}',
                            style: PixBarText.display.copyWith(
                              fontSize: 10,
                              color: sel ? PixBarColors.cyan : PixBarColors.white,
                            )),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Param + brillo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: PixBarColors.panel,
              border: Border(top: BorderSide(color: PixBarColors.border)),
            ),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('PARAM', style: PixBarText.mono.copyWith(fontSize: 9, letterSpacing: 2)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => target?.cmd(PixBarCmd.btnVerde),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A120A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x8839FF14)),
                      ),
                      child: Text('▲', style: PixBarText.display.copyWith(
                        fontSize: 14, color: PixBarColors.green)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Selector<BleManager, int>(
                    selector: (_, m) => m.activeState.efxParam,
                    builder: (_, param, __) => Text(
                      '$param/10',
                      style: PixBarText.mono.copyWith(fontSize: 11, color: PixBarColors.green),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => target?.cmd(PixBarCmd.btnAmarillo),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1200),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x88886600)),
                      ),
                      child: Text('▼', style: PixBarText.display.copyWith(
                        fontSize: 14, color: const Color(0xFFFFE600))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(children: [
                const Text('🔅', style: TextStyle(fontSize: 13)),
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
                      value: _brillo, min: 0, max: 1,
                      onChanged: (v) => setState(() => _brillo = v),
                      onChangeEnd: (v) => target?.setBrillo(v),
                    ),
                  ),
                ),
                const Text('☀️', style: TextStyle(fontSize: 14)),
              ]),
            ]),
          ),
        ],
      ),
      ),
    );
  }
}

// ── PAINTERS ──

class _FuegoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF080808));
    // Llama de fuego
    final path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.05);
    path.quadraticBezierTo(size.width * 0.85, size.height * 0.35, size.width * 0.7, size.height * 0.65);
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.5, size.width * 0.8, size.height * 0.85);
    path.quadraticBezierTo(size.width * 0.5, size.height * 1.0, size.width * 0.2, size.height * 0.85);
    path.quadraticBezierTo(size.width * 0.1, size.height * 0.5, size.width * 0.3, size.height * 0.65);
    path.quadraticBezierTo(size.width * 0.15, size.height * 0.35, size.width * 0.5, size.height * 0.05);
    canvas.drawPath(path, Paint()..color = const Color(0xFFFF6B00));
    // Llama interior
    final path2 = Path();
    path2.moveTo(size.width * 0.5, size.height * 0.2);
    path2.quadraticBezierTo(size.width * 0.7, size.height * 0.45, size.width * 0.6, size.height * 0.7);
    path2.quadraticBezierTo(size.width * 0.5, size.height * 0.85, size.width * 0.4, size.height * 0.7);
    path2.quadraticBezierTo(size.width * 0.3, size.height * 0.45, size.width * 0.5, size.height * 0.2);
    canvas.drawPath(path2, Paint()..color = const Color(0xFFFFE600));
    // Centro
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.6), size.width * 0.08,
      Paint()..color = Colors.white.withAlpha(200));
  }
  @override bool shouldRepaint(_) => false;
}

class _PlasmaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF08001A));
    final circles = [
      [0.3, 0.4, 0.35, 0xFF6600CC, 80],
      [0.6, 0.35, 0.32, 0xFF004488, 80],
      [0.45, 0.6, 0.28, 0xFF008866, 80],
    ];
    for (final c in circles) {
      canvas.drawCircle(
        Offset(size.width * c[0], size.height * c[1]),
        size.width * c[2],
        Paint()..color = Color(c[3].toInt()).withAlpha(c[4].toInt()));
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _RainbowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF080808));
    final colors = [
      Color(0xFFFF0000), Color(0xFFFF6600), Color(0xFFFFFF00),
      Color(0xFF00FF00), Color(0xFF0088FF), Color(0xFF6600FF),
    ];
    final h = size.height / colors.length;
    for (int i = 0; i < colors.length; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * h, size.width * 0.75, h),
        Paint()..color = colors[i]);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _EstrellasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF020208));
    final stars = [
      [0.2, 0.2, 5.0, 0xFFFFFFFF],
      [0.6, 0.15, 4.0, 0xFFFFFFFF],
      [0.8, 0.35, 3.0, 0xFFFFFFFF],
      [0.35, 0.45, 4.0, 0xFF00E5FF],
      [0.7, 0.55, 5.0, 0xFFFFFFFF],
      [0.15, 0.65, 3.0, 0xFFFF2D78],
      [0.5, 0.75, 4.0, 0xFFFFFFFF],
      [0.85, 0.7, 3.0, 0xFFFFE600],
    ];
    for (final s in stars) {
      canvas.drawCircle(
        Offset(size.width * s[0], size.height * s[1]),
        s[2].toDouble(),
        Paint()..color = Color(s[3].toInt()));
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _EscanerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF080808));
    // Línea escáner cyan
    final cx = size.width / 2;
    canvas.drawRect(
      Rect.fromLTWH(cx - 2, 0, 4, size.height),
      Paint()..color = const Color(0xFF00E5FF));
    // Halo
    canvas.drawRect(
      Rect.fromLTWH(cx - 12, 0, 24, size.height),
      Paint()..color = const Color(0xFF00E5FF).withAlpha(30));
  }
  @override bool shouldRepaint(_) => false;
}

class _OceanoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF000A14));
    // Olas
    for (int w = 0; w < 3; w++) {
      final path = Path();
      final yBase = size.height * (0.4 + w * 0.15);
      path.moveTo(0, yBase);
      for (double x = 0; x <= size.width; x += 10) {
        path.lineTo(x, yBase + 12 * (0.5 - (x / size.width - 0.5).abs()) * 2);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      final colors = [Color(0xFF006699), Color(0xFF004477), Color(0xFF003366)];
      canvas.drawPath(path, Paint()..color = colors[w]);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _ZenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF080808));
    final cx = size.width / 2;
    final cy = size.height / 2;
    for (int i = 3; i >= 0; i--) {
      canvas.drawCircle(
        Offset(cx, cy),
        size.width * (0.15 + i * 0.12),
        Paint()..color = const Color(0xFF6600CC).withAlpha(60 + i * 20));
    }
    canvas.drawCircle(Offset(cx, cy), size.width * 0.06,
      Paint()..color = Colors.white.withAlpha(200));
  }
  @override bool shouldRepaint(_) => false;
}

class _FlashBPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF0F4FF));
    // Rayo
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    path.moveTo(cx - 12, cy - 28);
    path.lineTo(cx + 6, cy - 4);
    path.lineTo(cx - 4, cy - 4);
    path.lineTo(cx + 12, cy + 28);
    path.lineTo(cx - 6, cy + 4);
    path.lineTo(cx + 4, cy + 4);
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFE600));
  }
  @override bool shouldRepaint(_) => false;
}

class _FlashCPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFAA0066));
    // Rayo
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    path.moveTo(cx - 12, cy - 28);
    path.lineTo(cx + 6, cy - 4);
    path.lineTo(cx - 4, cy - 4);
    path.lineTo(cx + 12, cy + 28);
    path.lineTo(cx - 6, cy + 4);
    path.lineTo(cx + 4, cy + 4);
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFE600));
  }
  @override bool shouldRepaint(_) => false;
}

class _BarridoEfxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF080808));
    final colors = [Color(0xFFFF2D78), Color(0xFF886600), Color(0xFF39FF14)];
    final w = size.width / 3;
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * w, 0, w, size.height),
        Paint()..color = colors[i]);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _EfxDato {
  final String nombre;
  final CustomPainter painter;
  const _EfxDato(this.nombre, this.painter);
}

final _efectosModos = [
  _EfxDato('FUEGO',    _FuegoPainter()),
  _EfxDato('PLASMA',   _PlasmaPainter()),
  _EfxDato('RAINBOW',  _RainbowPainter()),
  _EfxDato('ESTRELLAS',_EstrellasPainter()),
  _EfxDato('ESCÁNER',  _EscanerPainter()),
  _EfxDato('OCÉANO',   _OceanoPainter()),
  _EfxDato('ZEN',      _ZenPainter()),
  _EfxDato('FLASH B',  _FlashBPainter()),
  _EfxDato('FLASH C',  _FlashCPainter()),
  _EfxDato('BARRIDO',  _BarridoEfxPainter()),
];
