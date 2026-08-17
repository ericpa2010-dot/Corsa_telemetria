import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/bluetooth_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/connection_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Bloqueia orientação em modo paisagem ou retrato (ideal retrato para cockpit ou paisagem para tablet)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Estilização da barra de status do Android
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D1117),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const CorsaTelemetriaApp());
}

class CorsaTelemetriaApp extends StatefulWidget {
  const CorsaTelemetriaApp({Key? key}) : super(key: key);

  @override
  State<CorsaTelemetriaApp> createState() => _CorsaTelemetriaAppState();
}

class _CorsaTelemetriaAppState extends State<CorsaTelemetriaApp> {
  final BluetoothService _bluetoothService = BluetoothService();

  @override
  void dispose() {
    _bluetoothService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telemetria Corsa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        primaryColor: const Color(0xFF00E676),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF161B22),
          error: Color(0xFFFF1744),
        ),
      ),
      home: DashboardScreen(bluetoothService: _bluetoothService),
    );
  }
}
