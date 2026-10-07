import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_colors.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/transport/screens/transport_home_screen.dart';

import 'features/evidence/providers/evidence_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EvidenceProvider()),
      ],
      child: const MaquiTraceApp(),
    ),
  );
}

class MaquiTraceApp extends StatelessWidget {
  const MaquiTraceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MaquiTrace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryNavy,
          primary: AppColors.primaryNavy,
          secondary: AppColors.accentBlue,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// Compuerta de autenticación que evalúa la sesión recordada
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Mientras carga SharedPreferences al arrancar
    if (auth.isInitializing) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentBlue),
        ),
      );
    }

    // Si tiene sesión guardada y recordada
    if (auth.isAuthenticated) {
      if (auth.currentUser?.isTransportador == true) {
        return const TransportHomeScreen();
      }
      return const HomeScreen();
    }

    // Si no está autenticado, va al Login
    return const LoginScreen();
  }
}
