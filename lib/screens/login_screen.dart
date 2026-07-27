import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrox/screens/widgets/login_cadastro_content.dart';
import 'package:nutrox/repository/user_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoginCadastroContent(
        tituloBotaoPrincipal: 'Entrar',
        onPressedPrincipal: (email, senha) async {
          final user = await UserRepository().login(email, senha);
          if (user != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('nomeUsuario', user.nome);
            if (user.id != null) {
              await prefs.setInt('usuarioId', user.id!);
            }
            if (user.foto != null && user.foto!.isNotEmpty) {
              await prefs.setString('fotoUsuarioPath', user.foto!);
            }

            if (!mounted) return;
            // ignore: use_build_context_synchronously
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          } else {
            if (!mounted) return;
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('E-mail ou senha inválidos')),
            );
          }
        },
        tituloBotaoSecundario: 'Criar conta',
        onPressedSecundario: () {
          Navigator.pushNamed(context, AppRoutes.cadastro);
        },
      ),
    );
  }
}