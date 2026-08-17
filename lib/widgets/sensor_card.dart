import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final bool isAlert;
  final String alertMessage;
  final Color normalColor;
  final Color alertColor;
  final double progressValue;

  const SensorCard({
    Key? key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.isAlert,
    required this.alertMessage,
    required this.normalColor,
    required this.alertColor,
    required this.progressValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentColor = isAlert ? alertColor : normalColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAlert ? alertColor.withOpacity(0.12) : const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlert ? alertColor : Colors.white.withOpacity(0.1),
          width: isAlert ? 2.0 : 1.0,
        ),
        boxShadow: isAlert
            ? [
                BoxShadow(
                  color: alertColor.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isAlert ? alertColor : Colors.white70,
                ),
              ),
              Icon(icon, color: currentColor, size: 22),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.orbitron(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: currentColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: currentColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(currentColor),
              minHeight: 6,
            ),
          ),
          if (isAlert) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: alertColor.withOpacity(0.25),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                alertMessage,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: alertColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
