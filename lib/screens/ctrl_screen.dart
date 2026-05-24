import 'dart:async';
import '../services/commands.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_manager.dart';
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
  title: Text(juego.nombre, style: PixBarText.mono.copyWith(
    color: PixBarColors.cyan, fontSize: 12)),
  backgroundColor: PixBarColors.background,
  iconTheme: const IconThemeData(color: PixBarColors.grey2),
  

actions: [
  SizedBox(
    height: 30,
    child: Selector<BleManager, bool>(
      selector: (_, m) => m.activeState.mute,
      builder: (_, muted, __) => GestureDetector(
        onTap: () => context.read<BleManager>().activeTarget?.cmd(PixBarCmd.mute),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          decoration: BoxDecoration(
            color: muted ? const Color(0xFF1A0A0A) : PixBarColors.panel2,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: muted ? PixBarColors.magenta : PixBarColors.border),
          ),
          child: Row(children: [
            Text(muted ? '🔇' : '🔊', style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(muted ? 'UNMUTE' : 'MUTE',
              style: PixBarText.mono.copyWith(
                fontSize: 9,
                color: muted ? PixBarColors.magenta : PixBarColors.grey2)),
          ]),
        ),
      ),
    ),
  ),
  const SizedBox(width: 8),
  SizedBox(
    height: 30,
    child: GestureDetector(
      onTap: () {
        context.read<BleManager>().activeTarget?.cmd(5);
        Navigator.of(context).popUntil((r) => r.isFirst);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        decoration: BoxDecoration(
          color: PixBarColors.panel2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: PixBarColors.border),
        ),
        child: Center(
          child: Text('MENÚ',
            style: PixBarText.mono.copyWith(
              fontSize: 9, color: PixBarColors.cyan)),
        ),
      ),
    ),
  ),
  const SizedBox(width: 8),
],

),

      body: Column(
        children: [
          // Info
          Selector<BleManager, PixBarState>(
            selector: (_, m) => m.activeState,
            builder: (_, state, __) => _InfoRow(state: state),
          ),
          // Controles
          Expanded(
            child: juego.solo
              ? _SoloBtn(btn: btns.first)
              //: _CruzBtns(btns: btns),
              : _CruzBtns(btns: btns, juegoNombre: juego.nombre),
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
class _CruzBtns extends StatefulWidget {
  final List<BtnDato> btns;
  //const _CruzBtns({required this.btns});
  final String juegoNombre;  // ← agregar
  const _CruzBtns({required this.btns, required this.juegoNombre});

  @override
  State<_CruzBtns> createState() => _CruzBtnsState();
}

class _CruzBtnsState extends State<_CruzBtns> {
  final Set<int> _held = {};
  Timer? _timer;

  static const Map<String, List<int>> _pos = {
    'r': [2, 1], 'g': [1, 0], 'b': [0, 1], 'y': [1, 2],
  };


void _disparo(int byte) {
  // Pausar timer brevemente para dar paso al tiro
  _timer?.cancel();
  _timer = null;
  context.read<BleManager>().activeTarget?.cmd(byte);
  // Reiniciar timer después de 50ms
  Future.delayed(const Duration(milliseconds: 50), () {
    if (mounted && _held.isNotEmpty) _startTimer();
  });
}

  void _press(int byte) {
    _held.add(byte);
    _startTimer();
  }

  void _release(int byte) {
    _held.remove(byte);
    if (_held.isEmpty) _stopTimer();
  }

void _startTimer() {
  final interval = widget.juegoNombre == 'PIXCAPTURE' 
    ? const Duration(milliseconds: 20)
    : const Duration(milliseconds: 90);
  _timer ??= Timer.periodic(interval, (_) {
    final mgr = context.read<BleManager>();
    for (final byte in _held) {
      int cmdByte = byte;
      if (widget.juegoNombre == 'PIXCAPTURE') {
        if (byte == PixBarCmd.btnAmarillo) cmdByte = PixBarCmd.pcJ1Mover;
        if (byte == PixBarCmd.btnVerde) cmdByte = PixBarCmd.pcJ2Mover;
      }
      mgr.activeTarget?.cmd(cmdByte);
    }
  });
}

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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
            final btn = widget.btns.where((b) {
              final p = _pos[b.color];
              return p != null && p[0] == col && p[1] == row;
            }).firstOrNull;
            if (btn == null) return const SizedBox();
            return Center(
              child: _CtrlBtn(
                btn: btn,
                size: 80,
                //onPress: btn.hold ? () => _press(btn.byte) : null,
                onPress: btn.hold 
  ? () => _press(btn.byte) 
  : widget.juegoNombre == 'PIXCAPTURE' 
    ? () => _disparo(btn.byte)
    : null,
                onRelease: btn.hold ? () => _release(btn.byte) : null,
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _CtrlBtn extends StatefulWidget {
  final BtnDato btn;
  final double size;
  final VoidCallback? onPress;
  final VoidCallback? onRelease;
  const _CtrlBtn({
    required this.btn,
    required this.size,
    this.onPress,
    this.onRelease,
  });

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
    if (widget.onPress != null) {
      // Timer manejado por el padre
      widget.onPress!();
      //context.read<BleManager>().activeTarget?.cmd(widget.btn.byte);
    } else {
      context.read<BleManager>().activeTarget?.cmd(widget.btn.byte);
      if (widget.btn.hold) {
        _timer = Timer.periodic(const Duration(milliseconds: 90), (_) {
          context.read<BleManager>().activeTarget?.cmd(widget.btn.byte);
        });
      }
    }
    setState(() => _held = true);
  }

  void _stop() {
    widget.onRelease?.call();
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
      //onLongPressEnd: (_) => _stop(),  // ← agregar
      //onPanEnd: (_) => _stop(),        // ← agregar
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