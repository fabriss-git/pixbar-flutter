import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../services/commands.dart';
import '../theme/app_theme.dart';
import 'ctrl_screen.dart';

class JuegosScreen extends StatelessWidget {
  const JuegosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PixBarColors.background,
      appBar: AppBar(
        title: Text('JUEGOS', style: PixBarText.mono.copyWith(color: PixBarColors.cyan, fontSize: 12)),
        backgroundColor: PixBarColors.background,
        iconTheme: const IconThemeData(color: PixBarColors.grey2),
  //se elimina boton MENU a la derecha arriba de cada pantalla
  //      actions: [
  //       TextButton(
  //          onPressed: () {
  //            context.read<BleService>().cmd(PixBarCmd.btnMode);
  //            Navigator.of(context).popUntil((r) => r.isFirst);
  //          },
  //          child: Text('MENÚ', style: PixBarText.mono.copyWith(color: PixBarColors.cyan, fontSize: 11)),
  //        ),
  //      ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.85,
        ),
        itemCount: juegosDatos.length,
        itemBuilder: (context, i) {
          final j = juegosDatos[i];
          return _JuegoCard(juego: j, index: i);
        },
      ),
    );
  }
}

class _JuegoCard extends StatelessWidget {
  final JuegoDato juego;
  final int index;
  const _JuegoCard({required this.juego, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (juego.tiene2J) {
          _mostrarSelector2J(context);
        } else {
          context.read<BleService>().cmd(PixBarCmd.juego(index));
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => CtrlScreen(juego: juego, index: index, dosJ: false),
          ));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: PixBarColors.panel2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: PixBarColors.border),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: SizedBox(
                  width: double.infinity,
                  child: CustomPaint(painter: juego.painter),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: PixBarColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(juego.nombre, style: PixBarText.display.copyWith(fontSize: 10)),
                  Text(juego.tag, style: PixBarText.mono.copyWith(fontSize: 8)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarSelector2J(BuildContext context) {
    final ble = context.read<BleService>();
    showModalBottomSheet(
      context: context,
      backgroundColor: PixBarColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(juego.nombre, style: PixBarText.display.copyWith(fontSize: 16)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: _Btn2J(
                  label: '1 JUGADOR', icon: '👤',
                  color: PixBarColors.green,
                  onTap: () {
                    ble.cmd(PixBarCmd.juego(index));
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => CtrlScreen(juego: juego, index: index, dosJ: false),
                    ));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Btn2J(
                  label: '2 JUGADORES', icon: '👥',
                  color: PixBarColors.cyan,
                  onTap: () {
                    ble.cmd(index == 5 ? PixBarCmd.pong2J : PixBarCmd.pixCapture2J);
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => CtrlScreen(juego: juego, index: index, dosJ: true),
                    ));
                  },
                ),
              ),
            ]),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Btn2J extends StatelessWidget {
  final String label, icon;
  final Color color;
  final VoidCallback onTap;
  const _Btn2J({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: PixBarColors.panel2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(100)),
        ),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 8),
          Text(label, style: PixBarText.display.copyWith(fontSize: 11, color: color)),
        ]),
      ),
    );
  }
}

// ── DATOS ──
class JuegoDato {
  final String nombre, tag;
  final bool tiene2J, solo;
  final CustomPainter painter;
  final List<BtnDato> btns1j;
  final List<BtnDato> btns2j;
  const JuegoDato({
    required this.nombre, required this.tag,
    required this.painter, required this.btns1j,
    this.btns2j = const [], this.tiene2J = false, this.solo = false,
  });
}

class BtnDato {
  final String label, color;
  final int byte;
  final bool hold;
  const BtnDato({required this.label, required this.color, required this.byte, this.hold = false});
}

class _SpacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0A0A12));
    final p = Paint()..color = const Color(0xFF00E5FF);
    canvas.drawRect(Rect.fromLTWH(size.width*.45, size.height*.75, size.width*.1, size.height*.06), p);
    canvas.drawRect(Rect.fromLTWH(size.width*.42, size.height*.69, size.width*.16, size.height*.06), p);
    p.color = const Color(0xFFFF2D78);
    for (final x in [0.22, 0.42, 0.62]) {
      canvas.drawRect(Rect.fromLTWH(size.width*x, size.height*.15, size.width*.08, size.height*.16), p);
    }
    p.color = const Color(0xFFFF6B00);
    for (final x in [0.32, 0.52]) {
      canvas.drawRect(Rect.fromLTWH(size.width*x, size.height*.35, size.width*.08, size.height*.16), p);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _DodgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0A120A));
    final p = Paint();
    for (final d in [
      [0.05, 0.2, 0.1, 0.6, 0.7],
      [0.22, 0.1, 0.1, 0.7, 0.5],
      [0.55, 0.15, 0.1, 0.58, 0.6],
      [0.78, 0.25, 0.1, 0.42, 0.4],
    ]) {
      p.color = const Color(0xFFFF2D78).withAlpha((d[4]*255).toInt());
      canvas.drawRect(Rect.fromLTWH(size.width*d[0], size.height*d[1], size.width*d[2], size.height*d[3]), p);
    }
    p.color = const Color(0xFF39FF14);
    canvas.drawCircle(Offset(size.width*.42, size.height*.48), size.width*.08, p);
  }
  @override bool shouldRepaint(_) => false;
}

class _SnakePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0A120A));
    final p = Paint()..color = const Color(0xFF39FF14);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width*.1, size.height*.42, size.width*.55, size.height*.12),
      const Radius.circular(4)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width*.58, size.height*.2, size.width*.12, size.height*.34),
      const Radius.circular(4)), p);
    p.color = const Color(0xFFFF2D78);
    canvas.drawCircle(Offset(size.width*.78, size.height*.48), size.width*.07, p);
  }
  @override bool shouldRepaint(_) => false;
}

class _FlappyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0A0F1A));
    final p = Paint()..color = const Color(0xFF1A3AAA).withAlpha(180);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width*.18, size.height*.32), p);
    canvas.drawRect(Rect.fromLTWH(0, size.height*.52, size.width*.18, size.height*.48), p);
    p.color = const Color(0xFF1A3AAA).withAlpha(130);
    canvas.drawRect(Rect.fromLTWH(size.width*.42, 0, size.width*.18, size.height*.24), p);
    canvas.drawRect(Rect.fromLTWH(size.width*.42, size.height*.48, size.width*.18, size.height*.52), p);
    p.color = const Color(0xFFFFE600);
    canvas.drawCircle(Offset(size.width*.28, size.height*.4), size.width*.09, p);
  }
  @override bool shouldRepaint(_) => false;
}

class _MemoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF080808));
    final colors = [0xFFCC1A1A, 0xFF1A7A1A, 0xFF1A3AAA, 0xFF886600];
    for (int i = 0; i < 4; i++) {
      final p = Paint()..color = Color(colors[i]);
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width*(0.08+i*0.22), size.height*.25, size.width*.18, size.height*.45),
        const Radius.circular(4)), p);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _PongPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF080808));
    final p = Paint()..color = const Color(0xFFFFE600);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width*.06, size.height*.25, size.width*.08, size.height*.35),
      const Radius.circular(2)), p);
    p.color = const Color(0xFF39FF14);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width*.86, size.height*.42, size.width*.08, size.height*.35),
      const Radius.circular(2)), p);
    p.color = Colors.white;
    canvas.drawCircle(Offset(size.width*.62, size.height*.48), size.width*.06, p);
    p.color = const Color(0xFF252A33);
    for (double y = 0; y < size.height; y += size.height*.12) {
      canvas.drawRect(Rect.fromLTWH(size.width*.48, y, size.width*.02, size.height*.08), p);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _PixManPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0A0A12));
    final p = Paint()..color = const Color(0xFFFFE600);
    canvas.drawCircle(Offset(size.width*.18, size.height*.48), size.width*.1, p);
    p.color = const Color(0xFFFFE600).withAlpha(80);
    canvas.drawRect(Rect.fromLTWH(size.width*.28, size.height*.44, size.width*.35, size.height*.08), p);
    p.color = const Color(0xFFFF2D78).withAlpha(200);
    canvas.drawCircle(Offset(size.width*.75, size.height*.48), size.width*.09, p);
    p.color = const Color(0xFF9933FF).withAlpha(200);
    canvas.drawCircle(Offset(size.width*.56, size.height*.48), size.width*.09, p);
  }
  @override bool shouldRepaint(_) => false;
}

class _RitmoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0A080A));
    final data = [
      [0.08, 0.12, 0.12, 0.72, 0xFFCC1A1A],
      [0.28, 0.22, 0.12, 0.62, 0xFF1A7A1A],
      [0.48, 0.18, 0.12, 0.65, 0xFF1A3AAA],
      [0.68, 0.28, 0.12, 0.55, 0xFF886600],
    ];
    for (final d in data) {
      final p = Paint()..color = Color(d[4].toInt()).withAlpha(160);
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width*d[0], size.height*d[1], size.width*d[2], size.height*d[3]),
        const Radius.circular(3)), p);
    }
    final p = Paint()..color = const Color(0xFF252A33);
    canvas.drawRect(Rect.fromLTWH(0, size.height*.82, size.width, size.height*.1), p);
  }
  @override bool shouldRepaint(_) => false;
}

class _PCaptPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF080808));
    final p = Paint()..color = const Color(0xFFFFE600);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width*.03, size.height*.32, size.width*.12, size.height*.32),
      const Radius.circular(2)), p);
    p.color = const Color(0xFF39FF14);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width*.85, size.height*.32, size.width*.12, size.height*.32),
      const Radius.circular(2)), p);
    p.color = const Color(0xFFFF2D78);
    canvas.drawCircle(Offset(size.width*.35, size.height*.48), size.width*.09, p);
    canvas.drawCircle(Offset(size.width*.62, size.height*.48), size.width*.09, p);
  }
  @override bool shouldRepaint(_) => false;
}

class _PQPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0A0A12));
    final p = Paint()..color = const Color(0xFF9933FF).withAlpha(200);
    canvas.drawRect(Rect.fromLTWH(size.width*.1, size.height*.1, size.width*.14, size.height*.3), p);
    canvas.drawRect(Rect.fromLTWH(size.width*.76, size.height*.1, size.width*.14, size.height*.3), p);
    p.color = const Color(0xFF00E5FF);
    canvas.drawRect(Rect.fromLTWH(size.width*.42, size.height*.72, size.width*.1, size.height*.08), p);
    canvas.drawRect(Rect.fromLTWH(size.width*.38, size.height*.64, size.width*.18, size.height*.08), p);
    final strokeP = Paint()
      ..color = const Color(0xFFFF2D78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(size.width*.5, size.height*.45), size.width*.18, strokeP);
    canvas.drawRect(Rect.fromLTWH(size.width*.48, size.height*.55, size.width*.04, size.height*.1),
      Paint()..color = Colors.white);
  }
  @override bool shouldRepaint(_) => false;
}

final juegosDatos = [
  JuegoDato(nombre: 'PIXEL ATTACK', tag: '1 jugador', painter: _SpacePainter(),
    btns1j: [
      BtnDato(label: 'ROJO',  color: 'r', byte: PixBarCmd.btnRojo),
      BtnDato(label: 'VERDE', color: 'g', byte: PixBarCmd.btnVerde),
      BtnDato(label: 'AZUL',  color: 'b', byte: PixBarCmd.btnAzul),
      BtnDato(label: 'AMAR',  color: 'y', byte: PixBarCmd.btnAmarillo),
    ]),
  JuegoDato(nombre: 'PIXEL QUEST', tag: '1 jugador', painter: _PQPainter(),
    btns1j: [
      BtnDato(label: 'FUEGO', color: 'r', byte: PixBarCmd.btnRojo),
      BtnDato(label: '▲',     color: 'g', byte: PixBarCmd.btnVerde, hold: true),
      BtnDato(label: 'BOMBA', color: 'b', byte: PixBarCmd.btnAzul),
      BtnDato(label: '▼',     color: 'y', byte: PixBarCmd.btnAmarillo, hold: true),
    ]),
  JuegoDato(nombre: 'DODGE', tag: '1 jugador', painter: _DodgePainter(),
    btns1j: [
      BtnDato(label: '▲', color: 'g', byte: PixBarCmd.btnVerde, hold: true),
      BtnDato(label: '▼', color: 'y', byte: PixBarCmd.btnAmarillo, hold: true),
    ]),
  JuegoDato(nombre: 'SNAKE', tag: '1 jugador', painter: _SnakePainter(),
    btns1j: [
      BtnDato(label: '▲', color: 'g', byte: PixBarCmd.btnVerde, hold: true),
      BtnDato(label: '▼', color: 'y', byte: PixBarCmd.btnAmarillo, hold: true),
    ]),
  JuegoDato(nombre: 'FLAPPY PIX', tag: '1 jugador', painter: _FlappyPainter(), solo: true,
    btns1j: [
      BtnDato(label: '▲ SALTAR', color: 'g', byte: PixBarCmd.btnVerde),
    ]),
  JuegoDato(nombre: 'PIXPONG', tag: '1J o 2J', painter: _PongPainter(), tiene2J: true,
    btns1j: [
      BtnDato(label: '▼ J1', color: 'y', byte: PixBarCmd.btnAmarillo, hold: true),
    ],
    btns2j: [
      BtnDato(label: 'J2 ▲', color: 'g', byte: PixBarCmd.btnVerde, hold: true),
      BtnDato(label: '▼ J1', color: 'y', byte: PixBarCmd.btnAmarillo, hold: true),
    ]),
  JuegoDato(nombre: 'PIXMAN', tag: '1 jugador', painter: _PixManPainter(),
    btns1j: [
      BtnDato(label: '►', color: 'r', byte: PixBarCmd.btnRojo, hold: true),
      BtnDato(label: '▲', color: 'g', byte: PixBarCmd.btnVerde, hold: true),
      BtnDato(label: '◄', color: 'b', byte: PixBarCmd.btnAzul, hold: true),
      BtnDato(label: '▼', color: 'y', byte: PixBarCmd.btnAmarillo, hold: true),
    ]),
  JuegoDato(nombre: 'MEMOPIX', tag: '1 jugador', painter: _MemoPainter(),
    btns1j: [
      BtnDato(label: 'ROJO',  color: 'r', byte: PixBarCmd.btnRojo),
      BtnDato(label: 'VERDE', color: 'g', byte: PixBarCmd.btnVerde),
      BtnDato(label: 'AZUL',  color: 'b', byte: PixBarCmd.btnAzul),
      BtnDato(label: 'AMAR',  color: 'y', byte: PixBarCmd.btnAmarillo),
    ]),
  JuegoDato(nombre: 'RITMO', tag: '1 jugador', painter: _RitmoPainter(),
    btns1j: [
      BtnDato(label: 'ROJO',  color: 'r', byte: PixBarCmd.btnRojo),
      BtnDato(label: 'VERDE', color: 'g', byte: PixBarCmd.btnVerde),
      BtnDato(label: 'AZUL',  color: 'b', byte: PixBarCmd.btnAzul),
      BtnDato(label: 'AMAR',  color: 'y', byte: PixBarCmd.btnAmarillo),
    ]),
  JuegoDato(nombre: 'PIXCAPTURE', tag: '1J o 2J', painter: _PCaptPainter(), tiene2J: true,
    btns1j: [
      BtnDato(label: 'TIRO J1', color: 'r', byte: PixBarCmd.btnRojo),
      BtnDato(label: 'J1 ▼',   color: 'y', byte: PixBarCmd.btnAmarillo, hold: true),
    ],
    btns2j: [
      BtnDato(label: 'TIRO J1', color: 'r', byte: PixBarCmd.btnRojo),
      BtnDato(label: 'J2 ▲',   color: 'g', byte: PixBarCmd.btnVerde, hold: true),
      BtnDato(label: 'TIRO J2', color: 'b', byte: PixBarCmd.btnAzul),
      BtnDato(label: 'J1 ▼',   color: 'y', byte: PixBarCmd.btnAmarillo, hold: true),
    ]),
];