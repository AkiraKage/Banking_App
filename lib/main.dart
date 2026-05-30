import 'package:banking_app/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';

void main() async {
  // Garantisce che i widget di Flutter siano pronti prima di eseguire codice asincrono.
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Avvia l'app avvolgendola in un MultiProvider per gestire gli stati globali.
  runApp(
    MultiProvider(
      providers: [
        // Gestisce il tema dell'app (chiaro/scuro).
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Gestisce lo stato dell'autenticazione utente.
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const IoTBankingApp(),
    ),
  );
}

// Widget radice dell'applicazione, senza stato interno.
class IoTBankingApp extends StatelessWidget {
  const IoTBankingApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ascolta i cambiamenti nel provider del tema per aggiornare l'interfaccia.
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Configura l'applicazione MaterialApp con i temi definiti.
    return MaterialApp(
      title: 'Banking App',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // Schermata iniziale visualizzata all'avvio.
      home: const LoginScreen(),
    );
  }
}
