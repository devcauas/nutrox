import 'package:flutter/material.dart';
import 'dart:async';
import '../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double _scale = 0.0;

  @override
  void initState() {
    super.initState();

    Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _scale = 1.0;
      });
    });

    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff73AE54),
      body: Center(
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutBack,
          child: Image.asset(
            'assets/logo.png',
            width: 250,
            height: 250,
          ),
        ),
      ),
    );
  }
}
