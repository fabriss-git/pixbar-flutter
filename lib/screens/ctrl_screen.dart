import 'dart:async';
import '../services/commands.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../theme/app_theme.dart';
import 'juegos_screen.dart';

class CtrlScreen extends StatelessWidget {
  final JuegoDato juego;
  final int index;
  final bool dosJ;
  const CtrlScreen({super.key, required this.juego, required this.index, required this.dosJ});

  @override
  Widget build(BuildContext context) {
    final btns = dosJ ? juego.btns2j : juego.btns1j;
    return Scaffold(
      backgroundColor: PixBarColors.background,
      appBar: AppBar(
       title: Text('JUEGOS', style: PixBarText.mono.copyWith(color: PixBarColors.cyan, fontSize: 12)),
        backgroundColor: PixBarColors.background,
        iconTheme: const IconThemeData(color: PixBarColors.grey2),
//        actions: [
//          TextButton(
//            onPressed: () {
//              context.read<BleService>().cmd(5);
//              Navigator.of(context).popUntil((r) => r.isFirst);
//            },
//            child: Text('MENÚ', style: PixBarText.mono.copyWith(color: PixBarColors.cyan, fontSize: 11)),
//          ),
//        ],

actions: [
          Selector<BleService, bool>(
            selector: (_, ble) => ble.state.mute,
            builder: (_, muted, __) => IconButton(
              onPressed: () => context.read<BleService>().cmd(PixBarCmd.mute),
              icon: Text(
                muted ? '🔇' : '🔊',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<BleService>().cmd(5);
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: Text('MENÚ', style: PixBarText.mono.copyWith(color: PixBarColors.cyan, fontSize: 11)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info
          Selector<BleService, PixBarState>(
            selector: (_, ble) => ble.state,
            builder: (_, state, __) => _InfoRow(state: state),
          ),
          // Controles
          Expanded(
            child: juego.solo
              ? _SoloBtn(btn: btns.first)
              : _CruzBtns(btns: btns),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final PixBarState state;
  const _InfoRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PixBarColors.border)),
      ),
      child: Row(children: [
        _chip('SCORE', state.esJuego ? '${state.score}' : '—', PixBarColors.green),
        const SizedBox(width: 8),
        _chip('VIDAS', state.esJuego ? state.vidasStr : '—', PixBarColors.yellow),
        const SizedBox(width: 8),
        _chip('NIVEL', '${state.nivel}', PixBarColors.cyan),
      ]),
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: PixBarColors.panel2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: PixBarColors.border),
        ),
        child: Column(children: [
          Text(value, style: PixBarText.display.copyWith(fontSize: 15, color: color)),
          Text(label, style: PixBarText.mono.copyWith(fontSize: 8)),
        ]),
      ),
    );
  }
}

// Botón único centrado (Flappy)
class _SoloBtn extends StatelessWidget {
  final BtnDato btn;
  const _SoloBtn({required this.btn});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _CtrlBtn(btn: btn, size: 120),
    );
  }
}

// Cruz de botones
class _CruzBtns extends StatelessWidget {
  final List<BtnDato> btns;
  const _CruzBtns({required this.btns});

  static const Map<String, List<int>> _pos = {
    'r': [2, 1], 'g': [1, 0], 'b': [0, 1], 'y': [1, 2],
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 280,
        height: 280,
        child: GridView.count(
          crossAxisCount: 3,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(9, (i) {
            final col = i % 3;
            final row = i ~/ 3;
            final btn = btns.where((b) {
              final p = _pos[b.color];
              return p != null && p[0] == col && p[1] == row;
            }).firstOrNull;
            if (btn == null) return const SizedBox();
            return Center(child: _CtrlBtn(btn: btn, size: 80));
          }),
        ),
      ),
    );
  }
}

class _CtrlBtn extends StatefulWidget {
  final BtnDato btn;
  final double size;
  const _CtrlBtn({required this.btn, required this.size});

  @override
  State<_CtrlBtn> createState() => _CtrlBtnState();
}

class _CtrlBtnState extends State<_CtrlBtn> {
  bool _held = false;
  Timer? _timer;

  static const Map<String, Color> _colors = {
    'r': Color(0xFFCC1A1A),
    'g': Color(0xFF1A7A1A),
    'b': Color(0xFF1A3AAA),
    'y': Color(0xFF886600),
  };

  void _start() {
    final ble = context.read<BleService>();
    ble.cmd(widget.btn.byte);
    if (widget.btn.hold) {
      _timer = Timer.periodic(const Duration(milliseconds: 90), (_) {
        ble.cmd(widget.btn.byte);
      });
    }
    setState(() => _held = true);
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    setState(() => _held = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _colors[widget.btn.color] ?? PixBarColors.grey;
    return GestureDetector(
      onTapDown: (_) => _start(),
      onTapUp: (_) => _stop(),
      onTapCancel: _stop,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _held ? color.withAlpha(255) : color.withAlpha(200),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(_held ? 180 : 80),
              blurRadius: _held ? 20 : 10,
            ),
          ],
        ),
        child: Center(
          child: Text(widget.btn.label,
            textAlign: TextAlign.center,
            style: PixBarText.display.copyWith(
              fontSize: widget.size * 0.15,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}