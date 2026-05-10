import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PixBarLogo extends StatefulWidget {
  final String size; // 'large' o 'small'
  const PixBarLogo({super.key, this.size = 'small'});

  @override
  State<PixBarLogo> createState() => _PixBarLogoState();
}

class _PixBarLogoState extends State<PixBarLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  double _level = 0;
  double _levelObj = 0;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _ctrl.addListener(_tick);
  }

  void _tick() {
    _t += 0.07;
    final beat = pow(max(0.0, sin(_t * 1.2)), 2).toDouble();
    _levelObj = min(1.0, beat * 0.8 + max(0.0, sin(_t * 0.7 + 1)) * 0.4);
    if (_levelObj > _level) {
      _level += (_levelObj - _level) * 0.7;
    } else {
      _level += (_levelObj - _level) * 0.08;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = widget.size == 'large';
    final fontSize = isLarge ? 40.0 : 20.0;
    final barW = isLarge ? 17.0 : 9.0;
    final barH = isLarge ? 48.0 : 24.0;
    final n = isLarge ? 12 : 6;
    final padBot = isLarge ? 8.0 : 4.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // P
        Text('P', style: TextStyle(
          fontFamily: 'BlackOpsOne',
          fontSize: fontSize,
          color: PixBarColors.white,
          height: 1,
        )),
        // Barra LED
        SizedBox(
          width: barW,
          height: barH,
          child: CustomPaint(
            painter: _BarPainter(
              level: _level,
              nLeds: n,
              padBot: padBot,
            ),
          ),
        ),
        // X
        Text('X', style: TextStyle(
          fontFamily: 'BlackOpsOne',
          fontSize: fontSize,
          color: PixBarColors.white,
          height: 1,
        )),
        // BAR
        Text('BAR', style: TextStyle(
          fontFamily: 'BlackOpsOne',
          fontSize: fontSize,
          color: PixBarColors.cyan,
          letterSpacing: isLarge ? 2 : 1,
          height: 1,
        )),
      ],
    );
  }
}

class _BarPainter extends CustomPainter {
  final double level;
  final int nLeds;
  final double padBot;

  static const colors = [
    Color(0xFF39FF14), Color(0xFF39FF14), Color(0xFFAAFF00),
    Color(0xFFFFE600), Color(0xFFFF9900), Color(0xFFFF2D78),
    Color(0xFF00FF99), Color(0xFF00E5FF), Color(0xFF0099FF),
    Color(0xFF0033FF), Color(0xFF6600FF), Color(0xFFCC00FF),
  ];
  static const off = Color(0xFF111111);

  const _BarPainter({
    required this.level,
    required this.nLeds,
    required this.padBot,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fondo
    final bgPaint = Paint()..color = const Color(0xFF1A1C20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(2)),
      bgPaint,
    );

    final ledH = 2.0;
    final gap = (nLeds <= 6) ? 1.0 : 1.0;
    final nOn = (level * nLeds).round();
    final paint = Paint();

    for (int i = 0; i < nLeds; i++) {
      final yBot = size.height - 1 - padBot - i * (ledH + gap);
      final yTop = yBot - ledH + 1;
      final rect = Rect.fromLTWH(1, yTop, size.width - 2, ledH);
      paint.color = i < nOn
          ? colors[i.clamp(0, colors.length - 1)]
          : off.withOpacity(0.15);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.level != level;
}