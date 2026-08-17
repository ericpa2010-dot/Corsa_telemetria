import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RpmGauge extends StatelessWidget {
  final int rpm;
  final bool isConnected;
  static const int maxRpm = 7000;
  static const int redlineRpm = 6000;

  const RpmGauge({
    Key? key,
    required this.rpm,
    required this.isConnected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double ratio = (rpm / maxRpm).clamp(0.0, 1.0);
    final bool isRedline = rpm >= redlineRpm;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRedline ? const Color(0xFFFF1744) : Colors.white.withOpacity(0.1),
          width: isRedline ? 2.0 : 1.0,
        ),
        boxShadow: isRedline
            ? [
                BoxShadow(
                  color: const Color(0xFFFF1744).withOpacity(0.35),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.speed, color: Colors.amberAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "ROTAÇÃO DO MOTOR (RPM)",
                    style: GoogleFonts.orbitron(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              if (isRedline)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF1744),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "CORTE DE GIRO / REDLINE",
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Número Grande do RPM
          Text(
            rpm.toString().padLeft(4, '0'),
            style: GoogleFonts.orbitron(
              fontSize: 58,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              color: isRedline ? const Color(0xFFFF1744) : Colors.white,
            ),
          ),
          Text(
            "x 1000 RPM (MAX 7.0)",
            style: TextStyle(
              fontSize: 12,
              color: isRedline ? const Color(0xFFFF1744) : Colors.white38,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),

          // Régua de LEDs estilo Shift Light de Competição
          _buildLedShiftBar(ratio),
        ],
      ),
    );
  }

  Widget _buildLedShiftBar(double ratio) {
    const int totalSegments = 24;
    final int activeSegments = (ratio * totalSegments).round();

    return Row(
      children: List.generate(totalSegments, (index) {
        final bool isActive = index < activeSegments;
        Color segColor;

        if (index < 14) {
          segColor = const Color(0xFF00E676); // Verde (1k - 4.5k)
        } else if (index < 19) {
          segColor = const Color(0xFFFFB300); // Âmbar (4.5k - 6k)
        } else {
          segColor = const Color(0xFFFF1744); // Vermelho Redline (>6k)
        }

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            height: 16,
            decoration: BoxDecoration(
              color: isActive ? segColor : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(2),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: segColor.withOpacity(0.6),
                        blurRadius: 4,
                      )
                    ]
                  : [],
            ),
          ),
        );
      }),
    );
  }
}
