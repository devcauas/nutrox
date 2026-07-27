import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutrox/repository/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/profile_content.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? nomeUsuario;
  String? fotoUsuarioPath;
  int? _loggedUserId;

  final ImagePicker _picker = ImagePicker();
  final UserRepository _userRepository = UserRepository();

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  Future<void> _carregarDadosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    _loggedUserId = prefs.getInt('usuarioId');
    final nome = prefs.getString('nomeUsuario');
    final fotoPath = prefs.getString('fotoUsuarioPath');

    if (mounted) {
      setState(() {
        nomeUsuario = nome ?? '';
        fotoUsuarioPath = fotoPath;
      });
    }
  }

  Future<void> _editarFotoPerfil() async {
    final XFile? novaImagemXFile = await _picker.pickImage(source: ImageSource.gallery);

    if (novaImagemXFile != null) {
      if (_loggedUserId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: Usuário não identificado.')),
        );
        return;
      }

      final novaFotoPath = novaImagemXFile.path;

      try {
        await _userRepository.updateUserPhoto(_loggedUserId!, novaFotoPath);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fotoUsuarioPath', novaFotoPath);

        if (mounted) {
          setState(() {
            fotoUsuarioPath = novaFotoPath;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto de perfil atualizada com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao atualizar foto: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? profileImage;
    if (fotoUsuarioPath != null && fotoUsuarioPath!.isNotEmpty) {
      profileImage = FileImage(File(fotoUsuarioPath!));
    }

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 3, 155, 109),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      backgroundImage: profileImage,
                      child: profileImage == null
                          ? const Icon(Icons.person, size: 60, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: InkWell(
                          onTap: _editarFotoPerfil,
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Icon(
                              Icons.edit,
                              size: 20,
                              color: Color.fromARGB(255, 3, 155, 109),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  nomeUsuario ?? 'Usuário',
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const ProfileContent(icon: Icons.settings_outlined, label: 'Configurações'),
                const ProfileContent(icon: Icons.accessibility_new_outlined, label: 'Acessibilidade'),
                ProfileContent(
                  icon: Icons.info_outline,
                  label: 'Créditos',
                  onTap: () {
                    Navigator.pushNamed(context, '/credits');
                  },
                ),
                const ProfileContent(icon: Icons.help_outline, label: 'Ajuda'),
                ProfileContent(
                  icon: Icons.logout_outlined,
                  label: 'Sair',
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('nomeUsuario');
                    await prefs.remove('usuarioId');
                    await prefs.remove('fotoUsuarioPath');
                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}