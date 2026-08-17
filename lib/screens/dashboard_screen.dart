import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/telemetry_data.dart';
import '../services/bluetooth_service.dart';
import '../widgets/rpm_gauge.dart';
import '../widgets/sensor_card.dart';
import '../widgets/critical_alert_dialog.dart';

class DashboardScreen extends StatefulWidget {
  final BluetoothService bluetoothService;

  const DashboardScreen({Key? key, required this.bluetoothService}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late TelemetryData _currentTelemetry;
  late ConnectionStateEnum _connectionState;
  
  StreamSubscription? _telemetrySub;
  StreamSubscription? _connSub;
  StreamSubscription? _alertSub;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isCriticalAlertOpen = false;

  @override
  void initState() {
    super.initState();
    _currentTelemetry = TelemetryData.initial();
    _connectionState = widget.bluetoothService.currentState;

    // Escuta atualizações de estado de conexão
    _connSub = widget.bluetoothService.connectionStateStream.listen((state) {
      setState(() {
        _connectionState = state;
      });
    });

    // Escuta atualizações de telemetria
    _telemetrySub = widget.bluetoothService.telemetryStream.listen((data) {
      setState(() {
        _currentTelemetry = data;
      });
    });

    // Escuta Alerta Crítico (Corte de Alimentação na Central)
    _alertSub = widget.bluetoothService.criticalAlertStream.listen((message) {
      _triggerCriticalAlert(message);
    });
  }

  void _triggerCriticalAlert(String message) async {
    if (_isCriticalAlertOpen) return;
    _isCriticalAlertOpen = true;

    // Toca som de alarme se configurado
    try {
      // Exemplo com som sintetizado ou arquivo local
      // await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
    } catch (_) {}

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CriticalAlertDialog(
        title: "ALERTA CRÍTICO DE ECU",
        message: "Corte de Alimentação na Central!",
        detail: "A comunicação com a ECU foi interrompida abruptamente pelo ESP32.",
        onDismiss: () {
          _isCriticalAlertOpen = false;
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  void dispose() {
    _telemetrySub?.cancel();
    _connSub?.cancel();
    _alertSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _connectionState == ConnectionStateEnum.connected;
    final isConnecting = _connectionState == ConnectionStateEnum.connecting;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Fundo automotivo dark tech
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 4,
        title: Row(
          children: [
            const Icon(Icons.speed, color: Colors.amberAccent, size: 26),
            const SizedBox(width: 10),
            Text(
              "TELEMETRIA CORSA",
              style: GoogleFonts.orbitron(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          // Botão de Reconectar / Desconectar rápido
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: isConnecting
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.amberAccent,
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () {
                      if (isConnected) {
                        widget.bluetoothService.disconnect();
                      } else {
                        widget.bluetoothService.connectToTargetDevice();
                      }
                    },
                    icon: Icon(
                      isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                      size: 18,
                      color: isConnected ? Colors.black : Colors.white,
                    ),
                    label: Text(
                      isConnected ? "Desconectar" : "Conectar Bluetooth",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isConnected ? Colors.black : Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isConnected ? const Color(0xFF00E676) : const Color(0xFF238636),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // REQUISITO 2: Status de Conexão no Topo (Verde = Conectado / Vermelho = Desconectado)
            _buildConnectionStatusBar(isConnected, isConnecting),

            // Conteúdo dos Sensores com Scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // REQUISITO 3: Card de RPM com mostrador grande
                    RpmGauge(
                      rpm: _currentTelemetry.rpm,
                      isConnected: isConnected,
                    ),
                    const SizedBox(height: 14),

                    // Cards Primários em Grid (Temperatura >95°C alerta + Tensão ECU <11.5V alerta)
                    Row(
                      children: [
                        // Card Temperatura (°C)
                        Expanded(
                          child: SensorCard(
                            title: "TEMP. MOTOR",
                            value: "${_currentTelemetry.temperature.toStringAsFixed(1)}",
                            unit: "°C",
                            icon: Icons.thermostat,
                            isAlert: _currentTelemetry.isHighTempAlert,
                            alertMessage: "ALERTA: > 95°C SUPER-AQUECIMENTO!",
                            normalColor: const Color(0xFF00E5FF),
                            alertColor: const Color(0xFFFF1744),
                            progressValue: (_currentTelemetry.temperature / 130).clamp(0.0, 1.0),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Card Tensão ECU (Volts)
                        Expanded(
                          child: SensorCard(
                            title: "TENSÃO ECU",
                            value: "${_currentTelemetry.voltage.toStringAsFixed(2)}",
                            unit: "V",
                            icon: Icons.electric_bolt,
                            isAlert: _currentTelemetry.isLowVoltageAlert,
                            alertMessage: "ALERTA: < 11.5V BATERIA BAIXA!",
                            normalColor: const Color(0xFF00E676),
                            alertColor: const Color(0xFFFF9100),
                            progressValue: (_currentTelemetry.voltage / 16.0).clamp(0.0, 1.0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // REQUISITO 3.4: Cards menores para TPS, MAP, Sonda Lambda, Velocidade e Ponto
                    Text(
                      "PARÂMETROS DA INJEÇÃO ELETRÔNICA",
                      style: GoogleFonts.orbitron(
                        fontSize: 12,
                        letterSpacing: 1.2,
                        color: Colors.white54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.45,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // 1. TPS (Borboleta %)
                        _buildMiniSensorTile(
                          title: "TPS (Borboleta)",
                          value: "${_currentTelemetry.tps.toStringAsFixed(1)}",
                          unit: "%",
                          icon: Icons.speed_rounded,
                          accentColor: Colors.purpleAccent,
                          progress: _currentTelemetry.tps / 100.0,
                        ),
                        // 2. Pressão MAP (KPa)
                        _buildMiniSensorTile(
                          title: "Pressão MAP",
                          value: "${_currentTelemetry.mapPressure}",
                          unit: "KPa",
                          icon: Icons.compress,
                          accentColor: Colors.blueAccent,
                          progress: (_currentTelemetry.mapPressure / 200.0).clamp(0.0, 1.0),
                        ),
                        // 3. Sonda Lambda (mV)
                        _buildMiniSensorTile(
                          title: "Sonda Lambda",
                          value: "${_currentTelemetry.lambda}",
                          unit: "mV",
                          icon: Icons.grain,
                          accentColor: _getLambdaColor(_currentTelemetry.lambda),
                          subtitle: _getLambdaLabel(_currentTelemetry.lambda),
                          progress: (_currentTelemetry.lambda / 1000.0).clamp(0.0, 1.0),
                        ),
                        // 4. Velocidade (Km/h)
                        _buildMiniSensorTile(
                          title: "Velocidade",
                          value: "${_currentTelemetry.speed}",
                          unit: "Km/h",
                          icon: Icons.directions_car,
                          accentColor: Colors.amberAccent,
                          progress: (_currentTelemetry.speed / 220.0).clamp(0.0, 1.0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 5. Ponto de Ignição (° APMS) - Card Largo
                    _buildIgnitionAdvanceCard(_currentTelemetry.ignition),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// REQUISITO 2: Barra de Status no Topo
  Widget _buildConnectionStatusBar(bool isConnected, bool isConnecting) {
    Color barColor;
    String statusText;
    IconData statusIcon;

    if (isConnected) {
      barColor = const Color(0xFF00E676); // Verde
      statusText = "CONECTADO: Telemetria_Completa_Corsa";
      statusIcon = Icons.check_circle;
    } else if (isConnecting) {
      barColor = const Color(0xFFFFB300); // Laranja
      statusText = "CONECTANDO AO ESP32...";
      statusIcon = Icons.sync;
    } else {
      barColor = const Color(0xFFFF1744); // Vermelho
      statusText = "DESCONECTADO (ESP32 OFFLINE)";
      statusIcon = Icons.cancel;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: barColor.withOpacity(0.15),
        border: Border(
          bottom: BorderSide(color: barColor.withOpacity(0.6), width: 1.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: barColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: barColor.withOpacity(0.8),
                  blurRadius: 6,
                  spreadRadius: 2,
                )
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(statusIcon, color: barColor, size: 18),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: GoogleFonts.orbitron(
              color: barColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSensorTile({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color accentColor,
    String? subtitle,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Icon(icon, color: accentColor, size: 18),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.orbitron(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.w600),
              ),
              if (subtitle != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    subtitle,
                    style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIgnitionAdvanceCard(double ignition) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on, color: Colors.orangeAccent, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Ponto de Ignição", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text("Graus de Avanço APMS", style: TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "${ignition.toStringAsFixed(1)}",
                style: GoogleFonts.orbitron(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
              ),
              const SizedBox(width: 4),
              const Text("°", style: TextStyle(fontSize: 18, color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getLambdaColor(int mv) {
    if (mv < 300) return Colors.redAccent;    // Mistura Pobre
    if (mv > 700) return Colors.amberAccent;  // Mistura Rica
    return const Color(0xFF00E676);           // Mistura Estequiométrica Ideal
  }

  String _getLambdaLabel(int mv) {
    if (mv < 300) return "POBRE";
    if (mv > 700) return "RICA";
    return "IDEAL";
  }
}
