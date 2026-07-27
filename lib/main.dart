import 'package:flutter/material.dart';
import 'package:nutrox/screens/credits_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/cadastro_screen.dart';
import 'routes/app_routes.dart';
import 'database/db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DB.instance;
  runApp(const NutroxApp());
}

class NutroxApp extends StatelessWidget {
  const NutroxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutrox',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.credits: (context) => const CreditsScreen(),
        AppRoutes.cadastro: (context) => const CadastroScreen(),
      },
    );
  }
}
