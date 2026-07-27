import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutrox/utils/validators.dart';
import 'package:nutrox/utils/snackbar_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/app_routes.dart';
import 'package:nutrox/models/user_model.dart';
import 'package:nutrox/repository/user_repository.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  DateTime? _dataNascimento;
  File? _imagemSelecionada;
  bool _isCreatingAccount = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _selecionarImagem() async {
    final XFile? imagem = await _picker.pickImage(source: ImageSource.gallery);
    if (imagem != null) {
      setState(() {
        _imagemSelecionada = File(imagem.path);
      });
    }
  }

  Future<void> _selecionarDataNascimento() async {
    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: DateTime(2005, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (dataSelecionada != null) {
      setState(() {
        _dataNascimento = dataSelecionada;
      });
    }
  }

  Future<void> _criarConta() async {
    if (_isCreatingAccount) {
      return;
    }

    final bool isFormValid = _formKey.currentState?.validate() ?? false;

    if (!isFormValid || _dataNascimento == null) {
      if (_dataNascimento == null && isFormValid) {
        SnackBarHelper.show(
          context,
          'Por favor, selecione a data de nascimento.',
          type: SnackBarType.info,
        );
      }
      return;
    }

    setState(() {
      _isCreatingAccount = true;
    });

    final novoUsuario = UserModel(
      nome: _nomeController.text.trim(),
      email: _emailController.text.trim(),
      senha: _senhaController.text.trim(),
      dataNascimento: _dataNascimento!.toIso8601String(),
      dataCadastro: DateTime.now().toIso8601String(),
      foto: _imagemSelecionada?.path,
    );

    try {
      final int userId = await UserRepository().insertUser(novoUsuario);

      if (userId > 0) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('nomeUsuario', novoUsuario.nome);
        await prefs.setInt('usuarioId', userId);
        if (novoUsuario.foto != null && novoUsuario.foto!.isNotEmpty) {
          await prefs.setString('fotoUsuarioPath', novoUsuario.foto!);
        }

        if (!mounted) {
          return;
        }
        SnackBarHelper.show(
          context,
          'Conta criada com sucesso!',
          type: SnackBarType.success,
        );
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
      } else {
        if (!mounted) return;
        SnackBarHelper.show(
          context,
          'Erro desconhecido ao criar conta.',
          type: SnackBarType.error,
        );
      }
    } on DatabaseException catch (e) {
      if (!mounted) return;
      String errorMessage = 'Erro ao criar conta. Tente novamente.';
      if (e.isUniqueConstraintError()) {
        errorMessage = 'Este e-mail já está em uso. Por favor, utilize outro.';
      }
      SnackBarHelper.show(
        context,
        errorMessage,
        type: SnackBarType.error,
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.show(
        context,
        'Ocorreu um erro inesperado: $e',
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingAccount = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/fundologin.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _selecionarImagem,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(77),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.green.shade900,
                          backgroundImage:
                              _imagemSelecionada != null ? FileImage(_imagemSelecionada!) : null,
                          child: _imagemSelecionada == null
                              ? const Icon(Icons.person_outline, size: 50, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 315,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF73AE54),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(77),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildTextFormField(
                            controller: _nomeController,
                            hint: 'Nome',
                            icon: Icons.person,
                            validator: AppValidators.validateNome,
                          ),
                          const SizedBox(height: 15),
                          _buildTextFormField(
                            controller: _emailController,
                            hint: 'E-mail',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: AppValidators.validateEmail,
                          ),
                          const SizedBox(height: 15),
                          _buildTextFormField(
                            controller: _senhaController,
                            hint: 'Senha',
                            icon: Icons.lock,
                            obscureText: true,
                            validator: AppValidators.validatePassword,
                          ),
                          const SizedBox(height: 15),
                          _buildTextFormField(
                            controller: _confirmarSenhaController,
                            hint: 'Confirmar Senha',
                            icon: Icons.lock_outline,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, confirme sua senha.';
                              }
                              if (value != _senhaController.text) {
                                return 'As senhas não coincidem.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _dataNascimento != null
                                      ? DateFormat('dd/MM/yyyy').format(_dataNascimento!)
                                      : 'Selecione a data de nascimento',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              IconButton(
                                onPressed: _selecionarDataNascimento,
                                icon: const Icon(Icons.calendar_today, color: Colors.white),
                              )
                            ],
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _isCreatingAccount ? null : _criarConta,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade900,
                              minimumSize: const Size(double.infinity, 40),
                              disabledBackgroundColor: Colors.grey.shade600,
                            ),
                            child: _isCreatingAccount
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Criar conta', style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _isCreatingAccount ? null : () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade800,
                              minimumSize: const Size(double.infinity, 40),
                              disabledBackgroundColor: Colors.grey.shade500,
                            ),
                            child: const Text('Voltar', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey.shade700),
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.green.shade700, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red.shade700, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red.shade700, width: 2),
        ),
        hintStyle: TextStyle(color: Colors.grey.shade500),
      ),
      validator: validator,
      style: const TextStyle(color: Colors.black87),
    );
  }
}