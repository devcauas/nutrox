import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nutrox/models/alimento_model.dart';
import 'package:nutrox/models/cardapio_model.dart';
import 'package:nutrox/models/cardapio_item_model.dart';
import 'package:nutrox/repository/alimento_repository.dart';
import 'package:nutrox/repository/cardapio_repository.dart';
import 'package:nutrox/utils/snackbar_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class ViewMenuScreen extends StatefulWidget {
  final CardapioModel cardapio;

  const ViewMenuScreen({super.key, required this.cardapio});

  @override
  State<ViewMenuScreen> createState() => _ViewMenuScreenState();
}

class _ViewMenuScreenState extends State<ViewMenuScreen> {
  final CardapioRepository _cardapioRepository = CardapioRepository();
  final AlimentoRepository _alimentoRepository = AlimentoRepository();

  late CardapioModel _cardapioAtual;
  Map<String, List<CardapioItemModel>> _itensAgrupadosVisualizacao = {};
  bool _isLoading = true;
  String? _errorMessage;

  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _editNomeController;
  late TextEditingController _editDescricaoController;
  
  final List<AlimentoModel> _editSelecionadosCafe = [];
  final List<AlimentoModel> _editSelecionadosAlmoco = [];
  final List<AlimentoModel> _editSelecionadosJantar = [];

  List<AlimentoModel> _alimentosDisponiveisParaSelecao = [];
  int? _usuarioId;

  final int _minCafe = 3;
  final int _minAlmoco = 5;
  final int _minJantar = 4;
  final List<String> _ordemCategorias = ['Café da manhã', 'Almoço', 'Jantar'];

  @override
  void initState() {
    super.initState();
    _cardapioAtual = widget.cardapio;
    _editNomeController = TextEditingController(text: _cardapioAtual.nome);
    _editDescricaoController = TextEditingController(text: _cardapioAtual.descricao ?? '');
    
    _carregarUsuarioEAlimentosDisponiveis().then((_) {
      _carregarItensCardapioVisualizacao();
    });
  }

  @override
  void dispose() {
    _editNomeController.dispose();
    _editDescricaoController.dispose();
    super.dispose();
  }

  Future<void> _carregarUsuarioEAlimentosDisponiveis() async {
    final prefs = await SharedPreferences.getInstance();
    _usuarioId = prefs.getInt('usuarioId');
    if (_usuarioId == null) {
      if(mounted) SnackBarHelper.show(context, "Usuário não encontrado para carregar alimentos.", type: SnackBarType.error);
      return;
    }
    try {
      _alimentosDisponiveisParaSelecao = await _alimentoRepository.getAllAlimentos(usuarioId: _usuarioId);
    } catch (e) {
      if(mounted) SnackBarHelper.show(context, "Erro ao carregar lista de alimentos para edição: $e", type: SnackBarType.error);
    }
  }

  Future<void> _carregarItensCardapioVisualizacao() async {
    if (_cardapioAtual.id == null) {
      if(mounted) setState(() { _errorMessage = "ID do cardápio inválido."; _isLoading = false; });
      return;
    }
    if(mounted) setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final itens = await _cardapioRepository.getItensDoCardapioAgrupados(_cardapioAtual.id!);
      if (mounted) {
        setState(() {
          _itensAgrupadosVisualizacao = itens;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar itens do cardápio: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _entrarModoEdicao() {
    _editNomeController.text = _cardapioAtual.nome;
    _editDescricaoController.text = _cardapioAtual.descricao ?? '';

    _editSelecionadosCafe.clear();
    _editSelecionadosAlmoco.clear();
    _editSelecionadosJantar.clear();

    AlimentoModel? encontrarAlimento(int alimentoId) {
        try {
            return _alimentosDisponiveisParaSelecao.firstWhere((a) => a.id == alimentoId);
        } catch (e) {
            final itemOriginal = _itensAgrupadosVisualizacao.values.expand((list) => list).firstWhere((item) => item.alimentoId == alimentoId, orElse: () => CardapioItemModel(cardapioId: 0, alimentoId: alimentoId, categoriaRefeicao: '', nomeAlimento: 'Desconhecido'));
            return AlimentoModel(id: alimentoId, nome: itemOriginal.nomeAlimento ?? 'Desconhecido', usuarioId: _usuarioId, dataCadastro: DateTime.now().toIso8601String());
        }
    }

    _itensAgrupadosVisualizacao['Café da manhã']?.forEach((item) {
        final alimento = encontrarAlimento(item.alimentoId);
        if (alimento != null && !_editSelecionadosCafe.any((a) => a.id == alimento.id)) _editSelecionadosCafe.add(alimento);
    });
    _itensAgrupadosVisualizacao['Almoço']?.forEach((item) {
        final alimento = encontrarAlimento(item.alimentoId);
        if (alimento != null && !_editSelecionadosAlmoco.any((a) => a.id == alimento.id)) _editSelecionadosAlmoco.add(alimento);
    });
    _itensAgrupadosVisualizacao['Jantar']?.forEach((item) {
        final alimento = encontrarAlimento(item.alimentoId);
        if (alimento != null && !_editSelecionadosJantar.any((a) => a.id == alimento.id)) _editSelecionadosJantar.add(alimento);
    });

    if(mounted) setState(() { _isEditing = true; });
  }

  void _cancelarEdicao() {
    _editNomeController.text = _cardapioAtual.nome;
    _editDescricaoController.text = _cardapioAtual.descricao ?? '';
    if(mounted) setState(() { _isEditing = false; });
  }

  bool _podeSalvarEdicao() {
    if (_editNomeController.text.trim().isEmpty) return false;
    return _editSelecionadosCafe.length >= _minCafe &&
           _editSelecionadosAlmoco.length >= _minAlmoco &&
           _editSelecionadosJantar.length >= _minJantar;
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_podeSalvarEdicao()) {
      if(mounted) SnackBarHelper.show(context, 'Preencha o nome do cardápio e os requisitos mínimos de alimentos.', type: SnackBarType.warning);
      return;
    }

    if(mounted) setState(() { _isLoading = true; });

    CardapioModel cardapioAtualizado = CardapioModel(
      id: _cardapioAtual.id,
      nome: _editNomeController.text.trim(),
      descricao: _editDescricaoController.text.trim().isNotEmpty ? _editDescricaoController.text.trim() : null,
      usuarioId: _cardapioAtual.usuarioId,
      dataCriacao: _cardapioAtual.dataCriacao,
    );

    try {
      await _cardapioRepository.updateCardapio(
        cardapioAtualizado,
        _editSelecionadosCafe,
        _editSelecionadosAlmoco,
        _editSelecionadosJantar,
      );
      if (mounted) {
        setState(() {
          _cardapioAtual = cardapioAtualizado;
          _isEditing = false;
        });
        await _carregarItensCardapioVisualizacao();
        if (!mounted) return;
        SnackBarHelper.show(context, 'Cardápio atualizado com sucesso!', type: SnackBarType.success);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.show(context, 'Erro ao atualizar cardápio: $e', type: SnackBarType.error);
        setState(() { _isLoading = false; });
      }
    } finally {
       if (mounted && _isLoading) {
         setState(() { _isLoading = false; });
       }
    }
  }

  Future<void> _compartilharCardapio() async {
    final StringBuffer sb = StringBuffer();
    sb.writeln("Meu Cardápio: ${_cardapioAtual.nome}");
    if (_cardapioAtual.descricao != null && _cardapioAtual.descricao!.isNotEmpty) {
      sb.writeln("Descrição: ${_cardapioAtual.descricao}");
    }
    sb.writeln("\n--- Itens ---");

    for (String categoria in _ordemCategorias) {
      if (_itensAgrupadosVisualizacao.containsKey(categoria) && _itensAgrupadosVisualizacao[categoria]!.isNotEmpty) {
        sb.writeln("\n${categoria.toUpperCase()}:");
        for (var item in _itensAgrupadosVisualizacao[categoria]!) {
          sb.writeln("- ${item.nomeAlimento ?? 'Alimento não encontrado'}");
        }
      }
    }
    sb.writeln("\nCriado com Nutrox App!");
    await Share.share(sb.toString(), subject: 'Confira meu cardápio: ${_cardapioAtual.nome}');
  }

  Future<void> _confirmarDeletarCardapio() async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text('Tem certeza de que deseja excluir o cardápio "${_cardapioAtual.nome}"? Esta ação não pode ser desfeita.'),
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

    if (confirmar == true && _cardapioAtual.id != null) {
      try {
        await _cardapioRepository.deleteCardapio(_cardapioAtual.id!);
        if (mounted) {
          SnackBarHelper.show(context, 'Cardápio excluído com sucesso.', type: SnackBarType.success);
          Navigator.of(context).pop(true); 
        }
      } catch (e) {
        if (mounted) {
          SnackBarHelper.show(context, 'Erro ao excluir cardápio: $e', type: SnackBarType.error);
        }
      }
    }
  }

  void _mostrarDialogoSelecaoAlimentoParaEdicao({
    required BuildContext context,
    required String tituloDialogo,
    required List<AlimentoModel> alimentosJaSelecionadosNaCategoria,
    required Function(AlimentoModel) onSelect,
  }) {
    String categoriaRefeicaoDialogo;
    if (tituloDialogo.toLowerCase().contains("café da manhã")) {
        categoriaRefeicaoDialogo = "Café da manhã";
    } else if (tituloDialogo.toLowerCase().contains("almoço")) {
        categoriaRefeicaoDialogo = "Almoço";
    } else if (tituloDialogo.toLowerCase().contains("jantar")) {
        categoriaRefeicaoDialogo = "Jantar";
    } else {
        SnackBarHelper.show(context, "Categoria de refeição inválida no diálogo.", type: SnackBarType.error);
        return;
    }

    final List<AlimentoModel> paraSelecionar = _alimentosDisponiveisParaSelecao.where((disponivel) {
      final naoSelecionadoNestaCategoria = !alimentosJaSelecionadosNaCategoria.any((jaSel) => jaSel.id == disponivel.id);
      final podeSerDestaCategoria = disponivel.categoriasRefeicao?.contains(categoriaRefeicaoDialogo) ?? false;
      return naoSelecionadoNestaCategoria && podeSerDestaCategoria;
    }).toList();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        if (paraSelecionar.isEmpty) {
          return AlertDialog(
            title: Text(tituloDialogo),
            content: const Text('Não há alimentos adequados disponíveis ou todos já foram selecionados para esta refeição.'),
            actions: <Widget>[TextButton(child: const Text('OK'), onPressed: () => Navigator.of(dialogContext).pop())],
          );
        }
        return AlertDialog(
          title: Text(tituloDialogo),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: paraSelecionar.length,
              itemBuilder: (BuildContext context, int index) {
                final alimento = paraSelecionar[index];
                Widget leadingWidget;
                if (alimento.foto != null && alimento.foto!.isNotEmpty) {
                  if (alimento.foto!.startsWith('assets/')) {
                    leadingWidget = Image.asset(alimento.foto!, width: 40, height: 40, fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image, size: 40));
                  } else {
                    leadingWidget = Image.file(File(alimento.foto!), width: 40, height: 40, fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image, size: 40));
                  }
                } else {
                  leadingWidget = Icon(Icons.restaurant, size: 40, color: Colors.grey.shade400);
                }
                return ListTile(
                  leading: CircleAvatar(radius: 22, backgroundColor: Colors.grey.shade200,
                      child: ClipOval(child: SizedBox(width: 40, height: 40, child: leadingWidget))),
                  title: Text(alimento.nome),
                  subtitle: Text(alimento.tipo ?? 'Sem tipo'),
                  onTap: () {
                    onSelect(alimento);
                    Navigator.of(dialogContext).pop();
                  },
                );
              },
            ),
          ),
          actions: <Widget>[TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(dialogContext).pop())],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isEditing ? const Text("Editar Cardápio") : Text(_cardapioAtual.nome),
        backgroundColor: Colors.green,
        leading: _isEditing 
            ? IconButton(icon: const Icon(Icons.close), onPressed: _cancelarEdicao, tooltip: 'Cancelar Edição')
            : null,
        actions: _isEditing
          ? [
              IconButton(icon: const Icon(Icons.save_alt_outlined), onPressed: (_isLoading || _isEditing == false) ? null : _salvarAlteracoes, tooltip: 'Salvar Alterações')
            ]
          : [
              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: (_isLoading || _isEditing == true) ? null : _entrarModoEdicao, tooltip: 'Editar Cardápio'),
              IconButton(icon: const Icon(Icons.share), onPressed: (_isLoading || _isEditing == true) ? null : _compartilharCardapio, tooltip: 'Compartilhar'),
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: (_isLoading || _isEditing == true) ? null : _confirmarDeletarCardapio, tooltip: 'Deletar'),
            ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center)))
              : _isEditing ? _buildEditingView() : _buildReadOnlyView(),
    );
  }

  Widget _buildReadOnlyView() {
    if (_itensAgrupadosVisualizacao.isEmpty && !_isLoading) {
      return const Center(child: Text('Nenhum item encontrado neste cardápio.', style: TextStyle(fontSize: 16, color: Colors.grey)));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isEditing)
            Text(
              _cardapioAtual.nome,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade800),
            ),
          if (!_isEditing) const SizedBox(height: 8),
          if (_cardapioAtual.descricao != null && _cardapioAtual.descricao!.isNotEmpty) ...[
            Text('Descrição:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_cardapioAtual.descricao!, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
          ],
          ..._ordemCategorias.map((categoria) {
            if (_itensAgrupadosVisualizacao.containsKey(categoria) && _itensAgrupadosVisualizacao[categoria]!.isNotEmpty) {
              return _buildCategoriaSectionVisualizacao(categoria, _itensAgrupadosVisualizacao[categoria]!);
            }
            return const SizedBox.shrink();
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoriaSectionVisualizacao(String nomeCategoria, List<CardapioItemModel> itens) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(nomeCategoria, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
          const Divider(thickness: 1),
          if (itens.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text('Nenhum item para esta refeição.', style: TextStyle(fontStyle: FontStyle.italic)))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itens.length,
              itemBuilder: (context, index) {
                final item = itens[index];
                final nomeAlimento = item.nomeAlimento ?? 'Alimento ID: ${item.alimentoId}';
                return Card(
                  elevation: 1, margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(Icons.restaurant, color: Colors.green.shade600),
                    title: Text(nomeAlimento, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEditingView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _editNomeController,
              decoration: const InputDecoration(labelText: 'Nome do Cardápio', border: OutlineInputBorder()),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'O nome é obrigatório.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _editDescricaoController,
              decoration: const InputDecoration(labelText: 'Descrição (Opcional)', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            _buildFoodEditingSection(
              titulo: 'Café da manhã',
              alimentosSelecionadosNaCategoria: _editSelecionadosCafe,
              minimo: _minCafe,
              onAdd: (alimento) {
                setState(() {
                  if (!_editSelecionadosCafe.any((a) => a.id == alimento.id)) {
                    _editSelecionadosCafe.add(alimento);
                  }
                });
              },
              onRemove: (alimento) {
                setState(() {
                  _editSelecionadosCafe.removeWhere((a) => a.id == alimento.id);
                });
              },
            ),
            _buildFoodEditingSection(
              titulo: 'Almoço',
              alimentosSelecionadosNaCategoria: _editSelecionadosAlmoco,
              minimo: _minAlmoco,
              onAdd: (alimento) {
                setState(() {
                  if (!_editSelecionadosAlmoco.any((a) => a.id == alimento.id)) {
                    _editSelecionadosAlmoco.add(alimento);
                  }
                });
              },
              onRemove: (alimento) {
                setState(() {
                  _editSelecionadosAlmoco.removeWhere((a) => a.id == alimento.id);
                });
              },
            ),
            _buildFoodEditingSection(
              titulo: 'Jantar',
              alimentosSelecionadosNaCategoria: _editSelecionadosJantar,
              minimo: _minJantar,
              onAdd: (alimento) {
                setState(() {
                  if (!_editSelecionadosJantar.any((a) => a.id == alimento.id)) {
                    _editSelecionadosJantar.add(alimento);
                  }
                });
              },
              onRemove: (alimento) {
                setState(() {
                  _editSelecionadosJantar.removeWhere((a) => a.id == alimento.id);
                });
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodEditingSection({
    required String titulo,
    required List<AlimentoModel> alimentosSelecionadosNaCategoria,
    required int minimo,
    required Function(AlimentoModel) onAdd,
    required Function(AlimentoModel) onRemove,
  }) {
    return Card(
      elevation: 2, margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$titulo (Mínimo: $minimo, Selecionados: ${alimentosSelecionadosNaCategoria.length})',
                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: Text('Adicionar ${titulo.split(" ")[0]}'),
              onPressed: () => _mostrarDialogoSelecaoAlimentoParaEdicao(
                context: context,
                tituloDialogo: 'Selecionar para $titulo',
                alimentosJaSelecionadosNaCategoria: alimentosSelecionadosNaCategoria,
                onSelect: onAdd,
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
            ),
            const SizedBox(height: 10),
            if (alimentosSelecionadosNaCategoria.isNotEmpty)
              Wrap(
                spacing: 8.0, runSpacing: 4.0,
                children: alimentosSelecionadosNaCategoria.map((alimento) {
                  Widget avatarWidget;
                  if (alimento.foto != null && alimento.foto!.isNotEmpty) {
                    if (alimento.foto!.startsWith('assets/')) {
                      avatarWidget = Image.asset(alimento.foto!, width: 24, height: 24, fit: BoxFit.cover);
                    } else {
                      avatarWidget = Image.file(File(alimento.foto!), width: 24, height: 24, fit: BoxFit.cover);
                    }
                  } else {
                    avatarWidget = const Icon(Icons.restaurant, size: 20);
                  }
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      radius: 15,
                      child: ClipOval(child: SizedBox(width: 24, height: 24, child: avatarWidget)),
                    ),
                    label: Text(alimento.nome),
                    onDeleted: () => onRemove(alimento),
                    deleteIconColor: Colors.red.shade700,
                  );
                }).toList(),
              )
            else
              const Text('Nenhum item adicionado ainda.', style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}