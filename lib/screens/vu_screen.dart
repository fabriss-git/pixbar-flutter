import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../services/commands.dart';
import '../theme/app_theme.dart';

class VuScreen extends StatefulWidget {
  const VuScreen({super.key});

  @override
  State<VuScreen> createState() => _VuScreenState();
}

class _VuScreenState extends State<VuScreen> {
  int _selVu = 0;
  double _brillo = 0.7;

  @override
  Widget build(BuildContext context) {
    final ble = context.read<BleService>();
    return Scaffold(
      backgroundColor: PixBarColors.background,
      appBar: AppBar(
        title: Text('VÚMETRO', style: PixBarText.mono.copyWith(color: PixBarColors.cyan, fontSize: 12)),
        backgroundColor: PixBarColors.background,
        iconTheme: const IconThemeData(color: PixBarColors.grey2),
        actions: [
          TextButton(
            onPressed: () {
              ble.cmd(PixBarCmd.btnMode);
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: Text('MENÚ', style: PixBarText.mono.copyWith(color: PixBarColors.cyan, fontSize: 11)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 8,
                mainAxisSpacing: 8, childAspectRatio: 1.1,
              ),
              itemCount: _vuModos.length,
              itemBuilder: (_, i) {
                final m = _vuModos[i];
                final sel = _selVu == i;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selVu = i);
                    //ble.cmd(PixBarCmd.vuModo(i));
                    ble.cmd(PixBarCmd.vuModo(m.fwIndex));
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
                              child: CustomPaint(painter: m.painter),
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: PixBarColors.border)),
                          ),
                          child: Text(m.nombre,
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

          // Color + brillo
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
                  Text('COLOR', style: PixBarText.mono.copyWith(fontSize: 9, letterSpacing: 2)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => ble.cmd(PixBarCmd.btnVerde),
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
                  Selector<BleService, int>(
                    selector: (_, b) => b.state.vuColor,
                    builder: (_, color, __) => Text(
                      '${color+1}/10',
                      style: PixBarText.mono.copyWith(fontSize: 11, color: PixBarColors.cyan),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => ble.cmd(PixBarCmd.btnAmarillo),
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
                      onChangeEnd: (v) => ble.setBrillo(v),
                    ),
                  ),
                ),
                const Text('☀️', style: TextStyle(fontSize: 14)),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── PAINTERS ──
class _BarrasAbajoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF080808));
    final heights = [0.55, 0.75, 0.9, 0.65, 0.4, 0.5];
    final colors = [Color(0xFF39FF14), Color(0xFF39FF14), Color(0xFFFFE600),
                    Color(0xFFFFE600), Color(0xFFFF2D78), Color(0xFFFF2D78)];
    final w = size.width / 8;
    for (int i = 0; i < 6; i++) {
      final h = size.height * heights[i] * 0.8;
      final x = size.width * 0.08 + i * (w + 2);
      canvas.drawRect(
        Rect.fromLTWH(x, size.height * 0.85 - h, w, h),
        Paint()..color = colors[i]);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _AbajoPicoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF080808));
    final heights = [0.55, 0.75, 0.9, 0.65, 0.4];
    final colors = [Color(0xFF39FF14), Color(0xFFFFE600), Color(0xFFFFE600),
                    Color(0xFFFF8C00), Color(0xFFFF2D78)];
    final w = size.width / 7;
    for (int i = 0; i < 5; i++) {
      final h = size.height * heights[i] * 0.75;
      final x = size.width * 0.08 + i * (w + 3);
      canvas.drawRect(
        Rect.fromLTWH(x, size.height * 0.85 - h, w, h),
        Paint()..color = colors[i]);
      // Pico
      canvas.drawRect(
        Rect.fromLTWH(x, size.height * 0.85 - h - 6, w, 3),
        Paint()..color = Colors.white);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _BarrasCentroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF080808));
    final heights = [0.3, 0.6, 0.85, 0.5];
    final colors = [Color(0xFF39FF14), Color(0xFFFFE600), Color(0xFFFFE600), Color(0xFFFF2D78)];
    final cy = size.height / 2;
    final w = size.width / 6;
    for (int i = 0; i < 4; i++) {
      final h = size.height * heights[i] * 0.4;
      final x = size.width * 0.1 + i * (w + 4);
      canvas.drawRect(
        Rect.fromLTWH(x, cy - h, w, h * 2),
        Paint()..color = colors[i]);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _CentroPicoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF080808));
    final heights = [0.35, 0.7, 0.5];
    final colors = [Color(0xFF39FF14), Color(0xFFFFE600), Color(0xFFFF2D78)];
    final cy = size.height / 2;
    final w = size.width / 5;
    for (int i = 0; i < 3; i++) {
      final h = size.height * heights[i] * 0.38;
      final x = size.width * 0.12 + i * (w + 6);
      canvas.drawRect(
        Rect.fromLTWH(x, cy - h, w, h * 2),
        Paint()..color = colors[i]);
      // Picos arriba y abajo
      canvas.drawRect(Rect.fromLTWH(x, cy - h - 5, w, 3), Paint()..color = Colors.white);
      canvas.drawRect(Rect.fromLTWH(x, cy + h + 2, w, 3), Paint()..color = Colors.white);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _BarrasArribaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF080808));
    final heights = [0.55, 0.75, 0.9, 0.65, 0.4, 0.5];
    final colors = [Color(0xFF39FF14), Color(0xFF39FF14), Color(0xFFFFE600),
                    Color(0xFFFFE600), Color(0xFFFF2D78), Color(0xFFFF2D78)];
    final w = size.width / 8;
    for (int i = 0; i < 6; i++) {
      final h = size.height * heights[i] * 0.8;
      final x = size.width * 0.08 + i * (w + 2);
      canvas.drawRect(
        Rect.fromLTWH(x, size.height * 0.1, w, h),
        Paint()..color = colors[i]);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _ArribaPicoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF080808));
    final heights = [0.55, 0.75, 0.9, 0.65, 0.4];
    final colors = [Color(0xFF39FF14), Color(0xFFFFE600), Color(0xFFFFE600),
                    Color(0xFFFF8C00), Color(0xFFFF2D78)];
    final w = size.width / 7;
    for (int i = 0; i < 5; i++) {
      final h = size.height * heights[i] * 0.75;
      final x = size.width * 0.08 + i * (w + 3);
      canvas.drawRect(
        Rect.fromLTWH(x, size.height * 0.1, w, h),
        Paint()..color = colors[i]);
      // Pico abajo
      canvas.drawRect(
        Rect.fromLTWH(x, size.height * 0.1 + h + 2, w, 3),
        Paint()..color = Colors.white);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _SextuplePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF080808));
    final colors = [Color(0xFF39FF14), Color(0xFFFF6B00), Color(0xFF00E5FF),
                    Color(0xFFFF2D78), Color(0xFF9933FF), Color(0xFFAAAAAA)];
    final heights = [0.7, 0.85, 0.6, 0.5, 0.75, 0.4];
    final w = size.width / 8;
    for (int i = 0; i < 6; i++) {
      final h = size.height * heights[i] * 0.8;
      final x = size.width * 0.06 + i * (w + 2);
      canvas.drawRect(
        Rect.fromLTWH(x, size.height * 0.85 - h, w, h),
        Paint()..color = colors[i]);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _FlashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF1A0A2E));
    // Rayo
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    path.moveTo(cx - 10, cy - 30);
    path.lineTo(cx + 5, cy - 5);
    path.lineTo(cx - 3, cy - 5);
    path.lineTo(cx + 10, cy + 30);
    path.lineTo(cx - 5, cy + 5);
    path.lineTo(cx + 3, cy + 5);
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFE600));
  }
  @override bool shouldRepaint(_) => false;
}

class _BarridoPainter extends CustomPainter {
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

class _BloquesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF080808));
    final blocks = [
      [0.05, 0.1, 0.35, 0.28, 0xFFCCCCCC],
      [0.05, 0.42, 0.35, 0.18, 0xFF666666],
      [0.45, 0.3, 0.28, 0.28, 0xFF00E5FF],
      [0.75, 0.1, 0.22, 0.28, 0xFFFF2D78],
      [0.75, 0.42, 0.22, 0.18, 0xFF880033],
    ];
    for (final b in blocks) {
      canvas.drawRect(
        Rect.fromLTWH(size.width*b[0], size.height*b[1], size.width*b[2], size.height*b[3]),
        Paint()..color = Color(b[4].toInt()));
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _VuDato {
  final String nombre;
  final CustomPainter painter;
  //const _VuDato(this.nombre, this.painter);
  final int fwIndex;  // ← índice real del firmware
  const _VuDato(this.nombre, this.painter, this.fwIndex);
}

final _vuModos = [
  _VuDato('BARRAS ABAJO',  _BarrasAbajoPainter(),  0),
  _VuDato('ABAJO+PICO',    _AbajoPicoPainter(),    2),  // ← fw índice 2
  _VuDato('BARRAS CENTRO', _BarrasCentroPainter(), 1),  // ← fw índice 1
  _VuDato('CENTRO+PICO',   _CentroPicoPainter(),   3),
  _VuDato('BARRAS ARRIBA', _BarrasArribaPainter(),  4),
  _VuDato('ARRIBA+PICO',   _ArribaPicoPainter(),   5),
  _VuDato('SÉXTUPLE',      _SextuplePainter(),     6),
  _VuDato('FLASH',         _FlashPainter(),        7),
  _VuDato('BARRIDO',       _BarridoPainter(),      8),
  _VuDato('BLOQUES',       _BloquesPainter(),      9),
];
