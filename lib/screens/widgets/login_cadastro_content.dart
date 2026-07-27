import 'package:flutter/material.dart';

class LoginCadastroContent extends StatefulWidget {
  final String tituloBotaoPrincipal;
  final void Function(String email, String senha) onPressedPrincipal;
  final String tituloBotaoSecundario;
  final VoidCallback onPressedSecundario;
  final bool mostrarCampoEmail;
  final bool mostrarCampoSenha;

  const LoginCadastroContent({
    super.key,
    required this.tituloBotaoPrincipal,
    required this.onPressedPrincipal,
    required this.tituloBotaoSecundario,
    required this.onPressedSecundario,
    this.mostrarCampoEmail = true,
    this.mostrarCampoSenha = true, 
  });

  @override
  State<LoginCadastroContent> createState() => _LoginCadastroContentState();
}

class _LoginCadastroContentState extends State<LoginCadastroContent> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
          child: Image.asset(
            'assets/fundologin.jpg',
            fit: BoxFit.cover,
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.green.shade900,
                  child: const Icon(
                    Icons.person_outline,
                    size: 50,
                    color: Colors.white,
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
                      color: Colors.black.withValues(),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (widget.mostrarCampoEmail)
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email),
                          hintText: 'E-mail',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    if (widget.mostrarCampoEmail) const SizedBox(height: 15),
                    if (widget.mostrarCampoSenha)
                      TextField(
                        controller: _senhaController,
                        obscureText: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock),
                          hintText: 'Senha',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    if (widget.mostrarCampoSenha) const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => widget.onPressedPrincipal(
                        _emailController.text,
                        _senhaController.text,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade900,
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      child: Text(widget.tituloBotaoPrincipal,
                          style: const TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: widget.onPressedSecundario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade800,
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      child: Text(widget.tituloBotaoSecundario,
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
