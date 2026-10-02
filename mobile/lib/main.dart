import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'features/auth/screens/login_screen.dart';

void main() {
  runApp(const MaquiTraceApp());
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
      home: const LoginScreen(),
    );
  }
}
