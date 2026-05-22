import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/storage_service.dart';
import '../services/biometric_service.dart';
import '../widgets/settings_tile.dart';
import '../widgets/section_header.dart';
import 'login_screen.dart';
import 'shared_pin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _useBiometrics = false;
  bool _canCheckBiometrics = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final useBio = await StorageService.getBiometrics();
    final canCheck = await BiometricService.canCheckBiometrics();
    if (!mounted) return;
    setState(() {
      _useBiometrics = useBio;
      _canCheckBiometrics = canCheck;
      _isLoading = false;
    });
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      final ok = await BiometricService.authenticate(
        'Conferma la biometria per abilitarla',
      );
      if (ok) {
        await StorageService.setBiometrics(true);
        if (mounted) setState(() => _useBiometrics = true);
      }
    } else {
      await StorageService.setBiometrics(false);
      if (mounted) setState(() => _useBiometrics = false);
    }
  }

  Future<void> _changePinFlow() async {
    final currentPin = await StorageService.getPin();
    if (!mounted) return;

    final newPin = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SharedPinScreen(action: PinAction.change, currentPin: currentPin),
      ),
    );

    if (newPin != null && mounted) {
      await StorageService.savePin(newPin);
      _showSnack('PIN modificato con successo!');
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF059669),
      ),
    );
  }

  Future<void> _handleLogout() async {
    await context.read<AuthProvider>().logout();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SectionHeader(label: 'Aspetto', isDark: isDark),
                SettingsTile(
                  icon: isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  title: isDark ? 'Tema scuro' : 'Tema chiaro',
                  subtitle: 'Cambia aspetto dell\'app',
                  isDark: isDark,
                  trailing: Switch.adaptive(
                    value: isDark,
                    onChanged: (_) => themeProvider.toggleTheme(),
                  ),
                ),
                SectionHeader(label: 'Sicurezza', isDark: isDark),
                SettingsTile(
                  icon: Icons.pin_outlined,
                  title: 'Cambia PIN',
                  subtitle: 'Modifica il codice a 6 cifre',
                  isDark: isDark,
                  onTap: _changePinFlow,
                ),
                if (_canCheckBiometrics)
                  SettingsTile(
                    icon: Icons.fingerprint_rounded,
                    title: 'Accesso Biometrico',
                    subtitle: 'Usa impronta o volto per accedere',
                    isDark: isDark,
                    trailing: Switch.adaptive(
                      value: _useBiometrics,
                      onChanged: _toggleBiometrics,
                    ),
                  ),
                SectionHeader(label: 'Profilo', isDark: isDark),
                SettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Intestatario',
                  subtitle: '${context.watch<AuthProvider>().userName} Banking',
                  isDark: isDark,
                ),
                SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Versione app',
                  subtitle: '1.0.0',
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFDC2626),
                    ),
                    label: const Text(
                      'Esci dall\'account',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
