import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(
    // Inizializza il Provider al livello più alto dell'app
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const IoTBankingApp(),
    ),
  );
}

class IoTBankingApp extends StatelessWidget {
  const IoTBankingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    const Color primaryBlue = Color(0xFF2563EB);

    return MaterialApp(
      title: 'Banking App',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,

      theme: ThemeData(
        // Colori principali
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          secondary: const Color(0xFF00BFA5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade50,
        // Stile globale per i bottoni
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      // Configurazione per il tema scuro
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          brightness: Brightness.dark,
          // Verde acqua più vivace anche in modalità scura
          secondary: const Color(0xFF00BFA5),
        ),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      home: const LoginScreen(),
    );
  }
}
