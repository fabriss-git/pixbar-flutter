import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_manager.dart';
import '../services/commands.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_widget.dart';
import 'devices_screen.dart';
import 'juegos_screen.dart';
import 'luz_screen.dart';
import 'efectos_screen.dart';
import 'vu_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mgr = context.watch<BleManager>();
    final target = mgr.activeTarget;
    final state = mgr.activeState;
    final apagado = state.modo == 15;
    final esGrupo = mgr.activeTarget is GroupTarget;

    return Scaffold(
      backgroundColor: PixBarColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(mgr: mgr),
            _InfoStrip(state: state),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Opacity(
                      opacity: apagado ? 0.3 : 1.0,
                      child: IgnorePointer(
                        ignoring: apagado,
                        child: GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          children: [


                            //_ModoBtn(
                            //  label: 'JUEGOS', icon: '🕹️',
                            //  color: const Color(0xFFFF2D78),
                            //  bgColor: const Color(0xFF1A0A12),
                            //  borderColor: const Color(0x44FF2D78),
                            //  onTap: () => Navigator.push(context,
                            //    MaterialPageRoute(builder: (_) => const JuegosScreen()))),
                            
                            Opacity(
      opacity: (apagado || esGrupo) ? 0.3 : 1.0,
      child: IgnorePointer(
        ignoring: apagado || esGrupo,
        child: _ModoBtn(
          label: 'JUEGOS', icon: '🕹️',
          color: const Color(0xFFFF2D78),
          bgColor: const Color(0xFF1A0A12),
          borderColor: const Color(0x44FF2D78),
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const JuegosScreen()))),
                ),
    ),
                            
                            _ModoBtn(
                              label: 'LUZ AMB', icon: '💡',
                              color: const Color(0xFFFFE600),
                              bgColor: const Color(0xFF12110A),
                              borderColor: const Color(0x44FFE600),
                              onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const LuzScreen()))),
                            _ModoBtn(
                              label: 'EFECTOS', icon: '✨',
                              color: const Color(0xFF39FF14),
                              bgColor: const Color(0xFF0A120A),
                              borderColor: const Color(0x4439FF14),
                              onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const EfectosScreen()))),
                            _ModoBtn(
                              label: 'VÚMETRO', icon: '🎵',
                              color: PixBarColors.cyan,
                              bgColor: const Color(0xFF0A0F18),
                              borderColor: const Color(0x4400E5FF),
                              onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const VuScreen()))),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Opacity(
                      opacity: apagado ? 0.3 : 1.0,
                      child: IgnorePointer(
                        ignoring: apagado,
                        child: _FiestaBtn(
                          onTap: () => target?.cmd(PixBarCmd.fiesta)),
                      ),
                    ),

                    const SizedBox(height: 10),


              //aca estaba el boton power abajo de todo

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            _BrilloBar(mgr: mgr),
          ],
        ),
      ),
    );
  }
}

// ── Header ──
class _Header extends StatelessWidget {
  final BleManager mgr;
  const _Header({required this.mgr});

  @override
  Widget build(BuildContext context) {
    final target = mgr.activeTarget;
    final state = mgr.activeState;
    final muted = state.mute;
    final apagado = state.modo == 15;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PixBarColors.border)),
      ),
      child: Column(
        children: [
          // ── Fila 1: Logo, Mute, Power ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const PixBarLogo(size: 'small'),

              // Mute
              SizedBox(
              height: 30,
              child: GestureDetector(
                onTap: () => target?.cmd(PixBarCmd.mute),
                child: Container(
                  //padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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


              // Power
              SizedBox(
              height: 30,
              child: GestureDetector(
                onTap: () => target?.cmd(
                  apagado ? PixBarCmd.continuar : PixBarCmd.apagar),
                child: Container(
                  //padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  decoration: BoxDecoration(
                    color: apagado ? const Color(0xFF0A1A0A) : const Color(0xFF1A0A0A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: apagado
                        ? PixBarColors.green.withAlpha(150)
                        : PixBarColors.magenta.withAlpha(150)),
                  ),
                  child: Icon(
                    Icons.power_settings_new, size: 16,
                    color: apagado ? PixBarColors.green : PixBarColors.magenta,
                  ),
                ),
              ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Fila 2: Botón dispositivos ancho completo ──
          GestureDetector(
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const DevicesScreen())),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: PixBarColors.panel2,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: mgr.anyConnected
                    ? const Color(0x4400E5FF)
                    : PixBarColors.border),
              ),
              child: Row(children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: mgr.anyConnected
                      ? PixBarColors.green
                      : const Color(0xFF333333),
                    boxShadow: mgr.anyConnected ? [
                      BoxShadow(
                        color: PixBarColors.green.withAlpha(150),
                        blurRadius: 6)
                    ] : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    target?.displayName ?? 'Sin conexión',
                    style: PixBarText.mono.copyWith(
                      fontSize: 10, color: PixBarColors.white),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const Icon(Icons.expand_more, size: 14, color: PixBarColors.grey),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}


// ── InfoStrip ──
class _InfoStrip extends StatelessWidget {
  final PixBarState state;
  const _InfoStrip({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PixBarColors.border)),
      ),
      child: Row(children: [
        _InfoCard(label: 'MODO',  value: state.nombreModo, color: PixBarColors.cyan),
        const SizedBox(width: 8),
        _InfoCard(label: 'SCORE', value: state.esJuego ? '${state.score}' : '—', color: PixBarColors.green),
        const SizedBox(width: 8),
        _InfoCard(label: 'VIDAS', value: state.esJuego ? state.vidasStr : '—', color: PixBarColors.yellow),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _InfoCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: PixBarColors.panel2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: PixBarColors.border),
        ),
        child: Column(children: [
          Text(value, style: PixBarText.display.copyWith(fontSize: 16, color: color)),
          const SizedBox(height: 2),
          Text(label, style: PixBarText.mono.copyWith(fontSize: 8, letterSpacing: 1)),
        ]),
      ),
    );
  }
}

class _ModoBtn extends StatelessWidget {
  final String label, icon;
  final Color color, bgColor, borderColor;
  final VoidCallback onTap;
  const _ModoBtn({
    required this.label, required this.icon,
    required this.color, required this.bgColor,
    required this.borderColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(label, style: PixBarText.display.copyWith(
              fontSize: 13, color: color, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

class _FiestaBtn extends StatelessWidget {
  final VoidCallback? onTap;
  const _FiestaBtn({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF12102A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x66AA88FF)),
        ),
        child: Text('🎉  FIESTA',
          textAlign: TextAlign.center,
          style: PixBarText.display.copyWith(
            fontSize: 16, color: const Color(0xFFCC99FF), letterSpacing: 2)),
      ),
    );
  }
}

class _BrilloBar extends StatefulWidget {
  final BleManager mgr;
  const _BrilloBar({required this.mgr});

  @override
  State<_BrilloBar> createState() => _BrilloBarState();
}

class _BrilloBarState extends State<_BrilloBar> {
  double _valor = 0.7;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              value: _valor, min: 0, max: 1,
              onChanged: (v) => setState(() => _valor = v),
              onChangeEnd: (v) => widget.mgr.activeTarget?.setBrillo(v),
            ),
          ),
        ),
        const Text('☀️', style: TextStyle(fontSize: 16)),
      ]),
    );
  }
}
