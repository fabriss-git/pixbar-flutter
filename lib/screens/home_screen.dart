import 'scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../services/commands.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_widget.dart';
import 'juegos_screen.dart';
import 'luz_screen.dart';
import 'efectos_screen.dart';
import 'vu_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final apagado = ble.state.modo == 15;
    return Scaffold(
      backgroundColor: PixBarColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              connected: ble.connected,
              muted: ble.state.mute,
              onDisconnect: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: PixBarColors.panel,
                    title: Text('Desconectar', style: PixBarText.display.copyWith(fontSize: 16)),
                    content: Text('¿Desconectar el PixBar?',
                      style: PixBarText.mono.copyWith(fontSize: 12)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('CANCELAR', style: PixBarText.mono.copyWith(color: PixBarColors.grey)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('DESCONECTAR', style: PixBarText.mono.copyWith(color: PixBarColors.magenta)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ble.disconnect();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const ScanScreen()),
                      (route) => false,
                    );
                  }
                }
              },
              onMute: () => ble.cmd(PixBarCmd.mute),
            ),

            _InfoStrip(state: ble.state),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Grilla 2x2 — grisada cuando apagado
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
                            _ModoBtn(
                              label: 'JUEGOS', icon: '🕹️',
                              color: const Color(0xFFFF2D78),
                              bgColor: const Color(0xFF1A0A12),
                              borderColor: const Color(0x44FF2D78),
                              onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => const JuegosScreen())),
                            ),
                            _ModoBtn(
                              label: 'LUZ AMB', icon: '💡',
                              color: const Color(0xFFFFE600),
                              bgColor: const Color(0xFF12110A),
                              borderColor: const Color(0x44FFE600),
                              onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => const LuzScreen())),
                            ),
                            _ModoBtn(
                              label: 'EFECTOS', icon: '✨',
                              color: const Color(0xFF39FF14),
                              bgColor: const Color(0xFF0A120A),
                              borderColor: const Color(0x4439FF14),
                              onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => EfectosScreen())),
                            ),
                            _ModoBtn(
                              label: 'VÚMETRO', icon: '🎵',
                              color: PixBarColors.cyan,
                              bgColor: const Color(0xFF0A0F18),
                              borderColor: const Color(0x4400E5FF),
                              onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => VuScreen())),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // FIESTA — grisado cuando apagado
                    Opacity(
                      opacity: apagado ? 0.3 : 1.0,
                      child: IgnorePointer(
                        ignoring: apagado,
                        child: _FiestaBtn(onTap: () => ble.cmd(PixBarCmd.fiesta)),
                      ),
                    ),

                    const SizedBox(height: 10),

// APAGAR / ENCENDER
Center(
  child: GestureDetector(
    onTap: () => ble.cmd(apagado ? PixBarCmd.continuar : PixBarCmd.apagar),
    child: Container(
      width: 64, height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: apagado ? const Color(0xFF0A1A0A) : const Color(0xFF1A0A0A),
        border: Border.all(
          color: apagado
            ? PixBarColors.green.withAlpha(150)
            : PixBarColors.magenta.withAlpha(150),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: apagado
              ? PixBarColors.green.withAlpha(60)
              : PixBarColors.magenta.withAlpha(60),
            blurRadius: 12,
          ),
        ],
      ),
      child: Icon(
        Icons.power_settings_new,
        size: 32,
        color: apagado ? PixBarColors.green : PixBarColors.magenta,
      ),
    ),
  ),
),



                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            _BrilloBar(ble: ble),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool connected, muted;
  final VoidCallback onDisconnect, onMute;
  const _Header({
    required this.connected, required this.muted,
    required this.onDisconnect, required this.onMute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PixBarColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const PixBarLogo(size: 'small'),
          GestureDetector(
            onTap: onMute,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: muted ? const Color(0xFF1A0A0A) : PixBarColors.panel2,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: muted ? PixBarColors.magenta : PixBarColors.border),
              ),
              child: Row(children: [
                Text(muted ? '🔇' : '🔊', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(muted ? 'UNMUTE' : 'MUTE',
                  style: PixBarText.mono.copyWith(
                    fontSize: 9,
                    color: muted ? PixBarColors.magenta : PixBarColors.grey2,
                  )),
              ]),
            ),
          ),
          GestureDetector(
            onTap: onDisconnect,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: connected ? const Color(0x44FF2D78) : PixBarColors.border),
                borderRadius: BorderRadius.circular(6),
                color: PixBarColors.panel2,
              ),
              child: Row(children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: connected ? PixBarColors.green : const Color(0xFF333333),
                    boxShadow: connected ? [
                      BoxShadow(color: PixBarColors.green.withAlpha(150), blurRadius: 6)
                    ] : null,
                  ),
                ),
                const SizedBox(width: 6),
                Text(connected ? 'Conectado' : 'Desconectado',
                  style: PixBarText.mono.copyWith(fontSize: 10)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

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
  final VoidCallback onTap;
  const _FiestaBtn({required this.onTap});

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
  final BleService ble;
  const _BrilloBar({required this.ble});

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
              onChangeEnd: (v) => widget.ble.setBrillo(v),
            ),
          ),
        ),
        const Text('☀️', style: TextStyle(fontSize: 16)),
      ]),
    );
  }
}
