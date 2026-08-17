import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CriticalAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final String detail;
  final VoidCallback onDismiss;

  const CriticalAlertDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.detail,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1014),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFFF1744), width: 3.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone Pulsante de Perigo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF1744).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFFF1744),
                size: 54,
              ),
            ),
            const SizedBox(height: 16),

            // Título
            Text(
              title,
              style: GoogleFonts.orbitron(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: const Color(0xFFFF1744),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Mensagem Principal Obrigatória: "Corte de Alimentação na Central!"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF1744),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                style: GoogleFonts.orbitron(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 14),

            // Detalhe Explicativo
            Text(
              detail,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Botão de Reconhecimento
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onDismiss,
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: const Text(
                  "RECONHECER ALERTA",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
