import 'package:flutter/material.dart';

class ActionsTab extends StatelessWidget {
  const ActionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Operazioni',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildActionCard(
            context,
            'Bonifico Bancario',
            'Trasferisci fondi verso un altro IBAN',
            Icons.account_balance,
            isDark,
          ),
          const SizedBox(height: 10), // Spazio tra card ridotto
          _buildActionCard(
            context,
            'Giroconto',
            'Sposta denaro tra i tuoi conti',
            Icons.sync_alt,
            isDark,
          ),
          const SizedBox(height: 10), // Spazio tra card ridotto
          _buildActionCard(
            context,
            'Ricarica Telefonica',
            'Aggiungi credito al tuo smartphone',
            Icons.phone_android,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool isDark,
  ) {
    return Card(
      elevation: 0,
      color: isDark ? Colors.grey.shade900 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Uniformato ai 12px delle transazioni
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title in fase di sviluppo...')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
