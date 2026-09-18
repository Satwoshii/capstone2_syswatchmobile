import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SyswatchMobileApp());
}

class SyswatchMobileApp extends StatelessWidget {
  const SyswatchMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0B2D4D);

    return MaterialApp(
      title: 'Syswatch Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: navy),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
