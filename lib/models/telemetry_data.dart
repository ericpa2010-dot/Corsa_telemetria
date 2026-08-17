class TelemetryData {
  final int rpm;
  final double temperature; // °C
  final double voltage;     // Volts
  final double tps;         // % (0-100)
  final int mapPressure;    // KPa (0-250)
  final int lambda;         // mV (0-1000)
  final int speed;          // Km/h
  final double ignition;    // Graus APMS (°)
  final DateTime timestamp;

  TelemetryData({
    required this.rpm,
    required this.temperature,
    required this.voltage,
    required this.tps,
    required this.mapPressure,
    required this.lambda,
    required this.speed,
    required this.ignition,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Cria objeto padrão inicial
  factory TelemetryData.initial() {
    return TelemetryData(
      rpm: 0,
      temperature: 0.0,
      voltage: 12.6,
      tps: 0.0,
      mapPressure: 100,
      lambda: 450,
      speed: 0,
      ignition: 10.0,
    );
  }

  /// Faz o parsing da linha recebida do ESP32 via Serial Bluetooth.
  /// Formato padrão esperado:
  /// "RPM:2850,TEMP:92.4,VOLT:13.8,TPS:32.0,MAP:45,LAMBDA:480,SPEED:65,IGN:22.5"
  /// Também suporta formato CSV simples: "2850,92.4,13.8,32.0,45,480,65,22.5"
  static TelemetryData? parse(String rawLine) {
    try {
      final clean = rawLine.trim();
      if (clean.isEmpty) return null;

      // Ignora mensagens de log puro que não contenham telemetria
      if (clean.startsWith('[LOG]') || clean.startsWith('[INFO]')) {
        return null;
      }

      int rpm = 0;
      double temperature = 0.0;
      double voltage = 12.6;
      double tps = 0.0;
      int mapPressure = 100;
      int lambda = 450;
      int speed = 0;
      double ignition = 10.0;

      // 1. Formato Chave-Valor (Ex: RPM:2850,TEMP:91,...)
      if (clean.contains(':')) {
        final pairs = clean.split(',');
        for (final pair in pairs) {
          final kv = pair.split(':');
          if (kv.length == 2) {
            final key = kv[0].trim().toUpperCase();
            final val = kv[1].trim();

            switch (key) {
              case 'RPM':
                rpm = int.tryParse(val) ?? rpm;
                break;
              case 'TEMP':
                temperature = double.tryParse(val) ?? temperature;
                break;
              case 'VOLT':
              case 'BAT':
                voltage = double.tryParse(val) ?? voltage;
                break;
              case 'TPS':
                tps = double.tryParse(val) ?? tps;
                break;
              case 'MAP':
                mapPressure = int.tryParse(val) ?? mapPressure;
                break;
              case 'LAMBDA':
              case 'SONDA':
                lambda = int.tryParse(val) ?? lambda;
                break;
              case 'SPEED':
              case 'VEL':
                speed = int.tryParse(val) ?? speed;
                break;
              case 'IGN':
              case 'AVANCO':
                ignition = double.tryParse(val) ?? ignition;
                break;
            }
          }
        }
      } else {
        // 2. Formato Posicional CSV
        final parts = clean.split(',');
        if (parts.length >= 8) {
          rpm = int.tryParse(parts[0].trim()) ?? 0;
          temperature = double.tryParse(parts[1].trim()) ?? 0.0;
          voltage = double.tryParse(parts[2].trim()) ?? 12.0;
          tps = double.tryParse(parts[3].trim()) ?? 0.0;
          mapPressure = int.tryParse(parts[4].trim()) ?? 100;
          lambda = int.tryParse(parts[5].trim()) ?? 450;
          speed = int.tryParse(parts[6].trim()) ?? 0;
          ignition = double.tryParse(parts[7].trim()) ?? 10.0;
        } else {
          return null;
        }
      }

      return TelemetryData(
        rpm: rpm,
        temperature: temperature,
        voltage: voltage,
        tps: tps,
        mapPressure: mapPressure,
        lambda: lambda,
        speed: speed,
        ignition: ignition,
      );
    } catch (e) {
      // Retorna null se pacote estiver corrompido
      return null;
    }
  }

  /// Verifica se a temperatura está em nível de superaquecimento
  bool get isHighTempAlert => temperature > 95.0;

  /// Verifica se a tensão da ECU está perigosamente baixa
  bool get isLowVoltageAlert => voltage < 11.5;
}
