import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'actions_tab.dart';
import 'settings_screen.dart';

// Definisce la struttura principale dell'app con la barra di navigazione inferiore.
// Utilizza uno StatefulWidget per mantenere lo stato della pagina attualmente selezionata.
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Indice della pagina corrente nella navigazione.
  int _currentIndex = 0;

  // Lista delle pagine principali accessibili dalla barra di navigazione.
  static const _pages = [HomeTab(), ActionsTab(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    // Determina se il tema corrente è scuro per adattare i colori.
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // IndexedStack mantiene lo stato di tutte le pagine, evitando di ricostruirle
      // ogni volta che si cambia tab, ma mostrandone solo una alla volta.
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark
                  ? const Color(0xFF1F2937)
                  : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
        ),
        // Barra di navigazione moderna introdotta con Material 3.
        child: NavigationBar(
          selectedIndex: _currentIndex,
          // Aggiorna l'indice e scatena il ridisegno del widget quando viene cliccata una voce.
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.swap_horiz_outlined),
              selectedIcon: Icon(Icons.swap_horiz_rounded),
              label: 'Operazioni',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Impostazioni',
            ),
          ],
        ),
      ),
    );
  }
}
