import 'package:flutter/material.dart';

// DEV IMPORTS (Remove or revert when done testing)
import 'models/app_models.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/my_reports_screen.dart';
import 'screens/report_problem_screen.dart';
import 'screens/splash_screen.dart';
//==============================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SyswatchMobileApp());
}

// DEV TEST USER (for HomeScreen preview)
// const _testUser = StudentUser(
//   id: 1,
//   displayName: 'Test Student',
//   email: 'test@example.com',
// );
//==============================================

class SyswatchMobileApp extends StatelessWidget {
  const SyswatchMobileApp({super.key});

  static const navyBlue = Color(0xFF003366);
  static const gold = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Syswatch Mobile',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: navyBlue,
          primary: navyBlue,
          secondary: gold,
          brightness: Brightness.light,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: navyBlue,
          selectionHandleColor: navyBlue,
          selectionColor: Color(0x4D003366),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: navyBlue,
          primary: gold,
          secondary: navyBlue,
          brightness: Brightness.dark,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: gold,
          selectionHandleColor: gold,
          selectionColor: Color(0x4DFFD700),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),

      // -------------------------------------------------------------
      // DEV SCREEN SELECTOR - Simply uncomment the screen you want:
      // -------------------------------------------------------------
      home: const SplashScreen(),
      // home: const LoginScreen(),
      // home: const HomeScreen(user: _testUser),
      // home: const MyReportsScreen(),
      // home: ReportProblemScreen(onSubmitted: () {}),
      // -------------------------------------------------------------
    );
  }
}

