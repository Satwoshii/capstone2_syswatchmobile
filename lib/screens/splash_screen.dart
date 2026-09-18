import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await ApiService.instance.init();
    final user = await ApiService.instance.restoreSession();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            user == null ? const LoginScreen() : HomeScreen(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.monitor_heart_outlined, size: 76),
              SizedBox(height: 16),
              Text(
                'SYSWATCH',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 6),
              Text('Mobile Laboratory Reporter'),
              SizedBox(height: 22),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
}
