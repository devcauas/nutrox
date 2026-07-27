// lib/routes/app_routes.dart

import 'package:flutter/material.dart';
import '../screens/credits_screen.dart';
import '../screens/home_screen.dart';
import '../screens/add_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/login_screen.dart';
import '../screens/cadastro_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String add = '/add';
  static const String profile = '/profile';
  static const String credits = '/credits';
  static const String cadastro = '/cadastro';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    home: (context) => const HomeScreen(),
    add: (context) => const AddScreen(),
    profile: (context) => const ProfileScreen(),
    credits: (context) => const CreditsScreen(),
    cadastro: (context) => const CadastroScreen(),
  };
}
