import 'package:flutter/material.dart';

// Widget semplice per visualizzare un'intestazione di sezione in maiuscolo.
// Utilizzato solitamente tra gruppi di impostazioni per migliorare l'organizzazione visiva.
class SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;

  const SectionHeader({super.key, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}
