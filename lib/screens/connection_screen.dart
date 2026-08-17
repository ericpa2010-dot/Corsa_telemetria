import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/bluetooth_service.dart';
import 'dashboard_screen.dart';

class ConnectionScreen extends StatefulWidget {
  final BluetoothService bluetoothService;

  const ConnectionScreen({Key? key, required this.bluetoothService}) : super(key: key);

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  List<BluetoothDevice> _devicesList = [];
  bool _isScanning = false;
  String _statusMsg = "Clique para buscar 'Telemetria_Completa_Corsa'";

  @override
  void initState() {
    super.initState();
    _loadBondedDevices();
  }

  Future<void> _loadBondedDevices() async {
    setState(() => _isScanning = true);
    await widget.bluetoothService.requestPermissions();
    try {
      final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() {
        _devicesList = bonded;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _statusMsg = "Erro ao carregar dispositivos: $e";
        _isScanning = false;
      });
    }
  }

  Future<void> _connectToCorsa() async {
    setState(() {
      _statusMsg = "Conectando ao ESP32 'Telemetria_Completa_Corsa'...";
    });

    bool success = await widget.bluetoothService.connectToTargetDevice();
    if (success) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (ctx) => DashboardScreen(bluetoothService: widget.bluetoothService),
        ),
      );
    } else {
      setState(() {
        _statusMsg = "Falha ao conectar. Verifique se o ESP32 está ligado e pareado!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: Text(
          "CONEXÃO BLUETOOTH",
          style: GoogleFonts.orbitron(letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Botão Principal de Conexão Rápida ao Alvo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00E676).withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.bluetooth_searching, size: 50, color: Color(0xFF00E676)),
                  const SizedBox(height: 12),
                  Text(
                    "Telemetria_Completa_Corsa",
                    style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Dispositivo ESP32 SPP (Serial Port Profile)",
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _connectToCorsa,
                      icon: const Icon(Icons.bluetooth, color: Colors.black),
                      label: const Text(
                        "CONECTAR BLUETOOTH",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(_statusMsg, style: const TextStyle(color: Colors.amberAccent, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 20),

            // Lista de Dispositivos Pareados
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("DISPOSITIVOS PAREADOS NO ANDROID", style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white60),
                  onPressed: _loadBondedDevices,
                ),
              ],
            ),
            Expanded(
              child: _isScanning
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
                  : ListView.builder(
                      itemCount: _devicesList.length,
                      itemBuilder: (ctx, index) {
                        final dev = _devicesList[index];
                        final isTarget = dev.name == BluetoothService.targetDeviceName;
                        return Card(
                          color: isTarget ? const Color(0xFF1C2C20) : const Color(0xFF161B22),
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isTarget ? const Color(0xFF00E676) : Colors.white10,
                            ),
                          ),
                          child: ListTile(
                            leading: Icon(Icons.bluetooth, color: isTarget ? const Color(0xFF00E676) : Colors.white54),
                            title: Text(dev.name ?? "Desconhecido", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text(dev.address, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                            trailing: isTarget
                                ? const Chip(label: Text("ALVO", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)), backgroundColor: Color(0xFF00E676))
                                : null,
                            onTap: () => _connectToCorsa(),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
