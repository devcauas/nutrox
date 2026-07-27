import 'package:flutter/material.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  final List<Map<String, String>> desenvolvedores = const [
    {
      'nome': 'Cauã Souza Almeida',
      'imagem': 'assets/devs/caua.jpeg',
    },
    {
      'nome': 'Davi Vieira Peixoto',
      'imagem': 'assets/devs/davi.jpeg',
    },
    {
      'nome': 'Nicolas de Souza Santos',
      'imagem': 'assets/devs/nicolas.jpeg',
    },
    {
      'nome': 'Rafael Arati Machado de Oliveira',
      'imagem': 'assets/devs/fael.jpeg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryColor = Color.fromARGB(255, 3, 155, 109);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Créditos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Desenvolvedores',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryColor,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Este aplicativo foi construído com dedicação por:',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),

          ...desenvolvedores.map((dev) => _buildDeveloperCard(
                context,
                dev['nome']!,
                dev['imagem'],
                primaryColor,
              )),

          const SizedBox(height: 40),
          Center(
            child: Icon(
              Icons.code_rounded,
              size: 40,
              color: primaryColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Nutrox App © ${DateTime.now().year}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDeveloperCard(
      BuildContext context, String nome, String? imagem, Color highlightColor) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: highlightColor.withValues(alpha: 0.2),
              backgroundImage: imagem != null ? AssetImage(imagem) : null,
              child: imagem == null
                  ? Icon(
                      Icons.person_outline,
                      color: highlightColor,
                      size: 26,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}