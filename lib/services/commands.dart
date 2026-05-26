// ============================================================
// PIXBAR BLE COMMANDS — sincronizado con firmware v80
// ============================================================

class PixBarCmd {

  static const int pcJ1Mover = 0x91;
  static const int pcJ2Mover = 0x92;

  // UUIDs
  static const String serviceUUID  = '12345678-1234-1234-1234-123456789abc';
  static const String stateUUID    = '12345678-1234-1234-1234-123456789ab1';
  static const String cmdUUID      = '12345678-1234-1234-1234-123456789ab2';

  // Botones físicos
  static const int btnRojo    = 0x01;
  static const int btnVerde   = 0x02;
  static const int btnAzul    = 0x03;
  static const int btnAmarillo= 0x04;
  static const int btnMode    = 0x05;

  // Navegación
  static const int siguienteJuego = 0x10;
  static const int brilloMas      = 0x20;
  static const int brilloMenos    = 0x21;

  // Sistema
  static const int mute    = 0x30;
  static const int apagar  = 0x31;
  static const int continuar = 0x32;

  // Juegos directos (0x40 + índice)
  static const int juegoBase = 0x40;
  static int juego(int idx) => juegoBase + idx;
  // 0=PixelAttack, 1=PixelQuest, 2=Dodge, 3=Snake, 4=Flappy
  // 5=Pong, 6=PixMan, 7=MemoPix, 8=Ritmo, 9=PixCapture

  // Modos especiales 2 jugadores
  static const int pong2J      = 0x4A;
  static const int pixCapture2J= 0x4B;

  // VU modos directos (0x4C + índice 0-9)
  static const int vuBase = 0x4C;
  static int vuModo(int idx) => vuBase + idx;

  // Brillo slider (0x70 + paso 0-15)
  static const int brilloBase = 0x70;
  static int brillo(int step) => brilloBase + step; // step 0-15

  // Colores luz directos (0x80 + índice 0-8)
  static const int colorBase = 0x80;
  static int color(int idx) => colorBase + idx;
  // 0=Cálido, 1=Blanco, 2=Azul, 3=Celeste, 4=Violeta
  // 5=Rojo, 6=Verde, 7=Amarillo, 8=Fucsia

  // Efectos directos (0x60 + índice 0-9)
  static const int efxBase = 0x60;
  static int efecto(int idx) => efxBase + idx;

  // Color RGB custom (4 bytes: 0x90, R, G, B)
  static const int rgbCmd = 0x90;
  static List<int> rgb(int r, int g, int b) => [rgbCmd, r, g, b];

  // Modo Fiesta
  static const int fiesta = 0x56;

  // Brillo en 16 pasos desde slider (0-15 → 0x70-0x7F)
  static int brilloDesdeSlider(double valor) {
    // valor 0.0 a 1.0
    int step = (valor * 15).round().clamp(0, 15);
    return brilloBase + step;
  }
}

// Modos del firmware (campo "m" en JSON de estado)
class PixBarModo {
  static const int menu       = 0;
  static const int pixAttack  = 1;
  static const int memoPix    = 2;
  static const int snake      = 3;
  static const int dodge      = 4;
  static const int ritmo      = 5;
  static const int pixMan     = 6;
  static const int pong       = 7;
  static const int flappy     = 8;
  static const int vu         = 9;
  static const int luzAmb     = 10; // no usado directamente
  static const int luzEfx     = 11;
  static const int pixQuest   = 12;
  static const int pixCapture = 13;
  static const int apagado    = 15;
  static const int fiesta     = 16;

  static const Set<int> juegos = {1,2,3,4,5,6,7,8,12,13};

  static String nombre(int m) {
    const nombres = {
    0: 'MENÚ', 1: 'P.ATK', 2: 'MEMO', 3: 'SNAKE',
    4: 'DODGE', 5: 'RITMO', 6: 'PIXMAN', 7: 'PONG',
    8: 'FLAPPY', 9: 'VU', 10: 'LUZ', 11: 'EFX',
    12: 'P.QUEST', 13: 'PCAP', 15: 'OFF', 16: 'FIESTA',
    };
    return nombres[m] ?? 'M$m';
  }

  // Modo firmware → índice en lista de juegos
  static const Map<int,int> modoAJuego = {
    1:0, 12:1, 4:2, 3:3, 8:4, 7:5, 6:6, 2:7, 5:8, 13:9
  };
}

// Estado recibido por BLE (JSON del firmware)
class PixBarState {
  final int modo;
  final int score;
  final int vidas;
  final int nivel;
  final int efxParam;
  final int vuModo;
  final int vuColor;
  final bool mute;
  final bool gameOver;

@override
bool operator ==(Object other) =>
  other is PixBarState &&
  other.modo == modo &&
  other.score == score &&
  other.vidas == vidas &&
  other.mute == mute&&
  other.gameOver == gameOver &&  // ← agregar
  other.vuColor == vuColor &&
  other.efxParam == efxParam;
  

@override
int get hashCode => Object.hash(modo, score, vidas, mute, efxParam);

  const PixBarState({
    this.modo = 0, this.score = 0, this.vidas = 3,
    this.nivel = 0, this.efxParam = 5,
    this.vuModo = 0, this.vuColor = 0, this.mute = false,
    this.gameOver = false,
  });

  factory PixBarState.fromJson(String raw) {
    int parse(String key) {
      final m = RegExp('"$key":(\\d+)').firstMatch(raw);
      return m != null ? int.parse(m.group(1)!) : 0;
      
    }
    return PixBarState(
      modo:     parse('m'),
      score:    parse('s'),
      vidas:    parse('v'),
      nivel:    parse('n'),
      efxParam: parse('ep') == 0 ? 5 : parse('ep'),
      vuModo:   parse('vm'),
      vuColor:  parse('vc'),
      mute:     parse('mu') == 1,
      gameOver: parse('go') == 1,  // ← agregar

    );
  }

  bool get esJuego => PixBarModo.juegos.contains(modo);
  String get nombreModo => PixBarModo.nombre(modo);
  String get vidasStr => vidas == 99 ? '∞' : '$vidas';
}