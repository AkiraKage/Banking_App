import 'package:flutter/material.dart';

// Componente riutilizzabile per le voci della schermata impostazioni.
// Estende le funzionalità del ListTile standard con uno stile personalizzato e icone racchiuse in box.
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback? onTap;
  final Widget? trailing;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // Icona a sinistra con sfondo arrotondato per differenziarla dal testo.
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
        ),
      ),
      // Visualizza un componente personalizzato a destra (es. Switch) o una freccia se è cliccabile.
      trailing:
          trailing ??
          (onTap != null
              ? Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? const Color(0xFF4B5563)
                      : const Color(0xFFD1D5DB),
                )
              : null),
      onTap: onTap,
    );
  }
}
