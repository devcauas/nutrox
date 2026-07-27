import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nutrox/models/alimento_model.dart';
import 'package:nutrox/repository/alimento_repository.dart';
import 'package:nutrox/utils/snackbar_helper.dart';
import 'package:nutrox/screens/add_food_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class ViewFoodScreen extends StatefulWidget {
  final AlimentoModel alimento;

  const ViewFoodScreen({super.key, required this.alimento});

  @override
  State<ViewFoodScreen> createState() => _ViewFoodScreenState();
}

class _ViewFoodScreenState extends State<ViewFoodScreen> {
  late AlimentoModel _alimentoAtual;
  int? _loggedUserId;
  bool _isOwner = false;

  final AlimentoRepository _alimentoRepository = AlimentoRepository();

  @override
  void initState() {
    super.initState();
    _alimentoAtual = widget.alimento;
    _checkOwnership();
  }

  Future<void> _checkOwnership() async {
    final prefs = await SharedPreferences.getInstance();
    _loggedUserId = prefs.getInt('usuarioId');
    if (mounted) {
      setState(() {
        _isOwner =
            (_alimentoAtual.usuarioId != null &&
                _alimentoAtual.usuarioId == _loggedUserId);
      });
    }
  }

  Future<void> _editarAlimento() async {
    if (!_isOwner) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFoodScreen(
          alimentoParaEditar: _alimentoAtual,
        ),
      ),
    );

    if (result == true && mounted) {
      try {
        final alimentoAtualizado = await _alimentoRepository.getAlimentoById(
          _alimentoAtual.id!,
        );
        if (alimentoAtualizado != null && mounted) {
          setState(() {
            _alimentoAtual = alimentoAtualizado;
          });
          SnackBarHelper.show(
            context,
            "Alimento atualizado.",
            type: SnackBarType.success,
          );
        }
      } catch (e) {
        if (!mounted) return;
        SnackBarHelper.show(
          context,
          "Erro ao recarregar alimento: $e",
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _confirmarDeletarAlimento() async {
    if (!_isOwner && _alimentoAtual.usuarioId != null) {
      SnackBarHelper.show(
        context,
        "Você só pode deletar seus próprios alimentos.",
        type: SnackBarType.warning,
      );
      return;
    }
    if (_alimentoAtual.usuarioId == null) {
      SnackBarHelper.show(
        context,
        "Alimentos base do sistema não podem ser excluídos.",
        type: SnackBarType.info,
      );
      return;
    }

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
            'Tem certeza de que deseja excluir o alimento "${_alimentoAtual.nome}"? Esta ação pode afetar cardápios que o utilizam.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Excluir'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmar == true && _alimentoAtual.id != null) {
      try {
        await _alimentoRepository.deleteAlimento(
          _alimentoAtual.id!,
        );
        if (mounted) {
          SnackBarHelper.show(
            context,
            'Alimento excluído com sucesso.',
            type: SnackBarType.success,
          );
          Navigator.of(
            context,
          ).pop(true);
        }
      } catch (e) {
        if (mounted) {
          SnackBarHelper.show(
            context,
            'Erro ao excluir alimento: $e',
            type: SnackBarType.error,
          );
        }
      }
    }
  }

  Future<void> _compartilharAlimento() async {
    final StringBuffer sb = StringBuffer();
    sb.writeln("Alimento: ${_alimentoAtual.nome}");
    if (_alimentoAtual.tipo != null) {
      sb.writeln("Tipo: ${_alimentoAtual.tipo}");
    }
    if (_alimentoAtual.categoriasRefeicao != null &&
        _alimentoAtual.categoriasRefeicao!.isNotEmpty) {
      sb.writeln(
        "Pode ser usado em: ${_alimentoAtual.categoriasRefeicao!.join(', ')}",
      );
    }
    sb.writeln("\nInformação do Nutrox App!");
    await Share.share(
      sb.toString(),
      subject: 'Confira este alimento: ${_alimentoAtual.nome}',
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (_alimentoAtual.foto != null && _alimentoAtual.foto!.isNotEmpty) {
      if (_alimentoAtual.foto!.startsWith('assets/')) {
        imageWidget = Image.asset(
          _alimentoAtual.foto!,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) => Icon(
                Icons.broken_image,
                size: 100,
                color: Colors.grey.shade400,
              ),
        );
      } else {
        imageWidget = Image.file(
          File(_alimentoAtual.foto!),
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) => Icon(
                Icons.broken_image,
                size: 100,
                color: Colors.grey.shade400,
              ),
        );
      }
    } else {
      imageWidget = Icon(
        Icons.restaurant_menu,
        size: 100,
        color: Colors.grey.shade400,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _alimentoAtual.nome,
           style: const TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        actions: [
          if (_isOwner)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _editarAlimento,
              tooltip: 'Editar Alimento',
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _compartilharAlimento,
            tooltip: 'Compartilhar Alimento',
          ),
          if (_isOwner && _alimentoAtual.usuarioId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmarDeletarAlimento,
              tooltip: 'Deletar Alimento',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(
                        255,
                        49,
                        49,
                        49,
                      ).withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, -2),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imageWidget,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoRow(Icons.label_outline, 'Nome', _alimentoAtual.nome),
            if (_alimentoAtual.tipo != null)
              _buildInfoRow(
                Icons.category_outlined,
                'Tipo',
                _alimentoAtual.tipo!,
              ),
            if (_alimentoAtual.categoriasRefeicao != null &&
                _alimentoAtual.categoriasRefeicao!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Pode ser usado em:',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children:
                    _alimentoAtual.categoriasRefeicao!
                        .map(
                          (cat) => Chip(
                            label: Text(cat),
                            backgroundColor: Colors.green.shade100,
                          ),
                        )
                        .toList(),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Cadastrado em: ${DateTime.parse(_alimentoAtual.dataCadastro).day}/${DateTime.parse(_alimentoAtual.dataCadastro).month}/${DateTime.parse(_alimentoAtual.dataCadastro).year}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green.shade700, size: 24),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 17))),
        ],
      ),
    );
  }
}