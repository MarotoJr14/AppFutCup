import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';

void main() {
  runApp(const FutCupApp());
}

class FutCupApp extends StatelessWidget {
  const FutCupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FutCup 2026',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}