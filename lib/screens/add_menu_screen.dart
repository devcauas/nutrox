import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nutrox/models/alimento_model.dart';
import 'package:nutrox/models/cardapio_model.dart';
import 'package:nutrox/models/cardapio_item_model.dart';
import 'package:nutrox/repository/alimento_repository.dart';
import 'package:nutrox/repository/cardapio_repository.dart';
import 'package:nutrox/utils/snackbar_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddMenuScreen extends StatefulWidget {
  const AddMenuScreen({super.key});

  @override
  State<AddMenuScreen> createState() => _AddMenuScreenState();
}

class _AddMenuScreenState extends State<AddMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCardapioController = TextEditingController();
  final _descricaoCardapioController = TextEditingController();

  int? _usuarioId;

  final AlimentoRepository _alimentoRepository = AlimentoRepository();
  final CardapioRepository _cardapioRepository = CardapioRepository();

  List<AlimentoModel> _alimentosDisponiveisCafe = [];
  List<AlimentoModel> _alimentosDisponiveisAlmoco = [];
  List<AlimentoModel> _alimentosDisponiveisJantar = [];

  final List<AlimentoModel> _selecionadosCafe = [];
  final List<AlimentoModel> _selecionadosAlmoco = [];
  final List<AlimentoModel> _selecionadosJantar = [];

  bool _isLoading = true;
  bool _isSaving = false;

  final int _minCafe = 3;
  final int _minAlmoco = 5;
  final int _minJantar = 4;

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _usuarioId = prefs.getInt('usuarioId');

    if (!mounted) return;
    if (_usuarioId == null) {
      SnackBarHelper.show(
        context,
        'Erro: Usuário não identificado. Faça login novamente.',
        type: SnackBarType.error,
      );
      Navigator.pop(context);
      setState(() => _isLoading = false);
      return;
    }

    try {
      _alimentosDisponiveisCafe = await _alimentoRepository.getAllAlimentos(
        usuarioId: _usuarioId,
        categoriaRefeicao: 'Café da manhã',
      );
      _alimentosDisponiveisAlmoco = await _alimentoRepository.getAllAlimentos(
        usuarioId: _usuarioId,
        categoriaRefeicao: 'Almoço',
      );
      _alimentosDisponiveisJantar = await _alimentoRepository.getAllAlimentos(
        usuarioId: _usuarioId,
        categoriaRefeicao: 'Jantar',
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.show(
        context,
        'Erro ao carregar alimentos: $e',
        type: SnackBarType.error,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nomeCardapioController.dispose();
    _descricaoCardapioController.dispose();
    super.dispose();
  }

  bool _podeSalvar() {
    if (_nomeCardapioController.text.trim().isEmpty) return false;
    return _selecionadosCafe.length >= _minCafe &&
        _selecionadosAlmoco.length >= _minAlmoco &&
        _selecionadosJantar.length >= _minJantar;
  }

  Future<void> _salvarCardapio() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_podeSalvar()) {
      SnackBarHelper.show(
        context,
        'Preencha o nome do cardápio e os requisitos mínimos de alimentos.',
        type: SnackBarType.warning,
      );
      return;
    }
    if (_usuarioId == null) return;

    setState(() => _isSaving = true);

    final novoCardapio = CardapioModel(
      nome: _nomeCardapioController.text.trim(),
      descricao: _descricaoCardapioController.text.trim().isNotEmpty
          ? _descricaoCardapioController.text.trim()
          : null,
      usuarioId: _usuarioId!,
      dataCriacao: DateTime.now().toIso8601String(),
    );

    try {
      final cardapioSalvo = await _cardapioRepository.insertCardapio(
        novoCardapio,
      );

      if (!mounted) return;

      if (cardapioSalvo != null && cardapioSalvo.id != null) {
        int ordemCafe = 0;
        for (AlimentoModel alimento in _selecionadosCafe) {
          await _cardapioRepository.insertCardapioItem(
            CardapioItemModel(
              cardapioId: cardapioSalvo.id!,
              alimentoId: alimento.id!,
              categoriaRefeicao: 'Café da manhã',
              ordem: ordemCafe++,
            ),
          );
        }
        int ordemAlmoco = 0;
        for (AlimentoModel alimento in _selecionadosAlmoco) {
          await _cardapioRepository.insertCardapioItem(
            CardapioItemModel(
              cardapioId: cardapioSalvo.id!,
              alimentoId: alimento.id!,
              categoriaRefeicao: 'Almoço',
              ordem: ordemAlmoco++,
            ),
          );
        }
        int ordemJantar = 0;
        for (AlimentoModel alimento in _selecionadosJantar) {
          await _cardapioRepository.insertCardapioItem(
            CardapioItemModel(
              cardapioId: cardapioSalvo.id!,
              alimentoId: alimento.id!,
              categoriaRefeicao: 'Jantar',
              ordem: ordemJantar++,
            ),
          );
        }
        if (!mounted) return;
        SnackBarHelper.show(
          context,
          'Cardápio salvo com sucesso!',
          type: SnackBarType.success,
        );
        Navigator.pop(context);
      } else {
        SnackBarHelper.show(
          context,
          'Erro ao salvar cardápio. Verifique se já existe um cardápio com este nome.',
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.show(
        context,
        'Falha ao salvar itens do cardápio: $e',
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildFoodSelectionSection({
    required String titulo,
    required List<AlimentoModel> alimentosDisponiveis,
    required List<AlimentoModel> alimentosSelecionados,
    required int minimo,
    required Function(AlimentoModel) onAdd,
    required Function(AlimentoModel) onRemove,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$titulo (Mínimo: $minimo, Selecionados: ${alimentosSelecionados.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(
                Icons.add_circle_outline,
                color: Colors.white,
              ),
              label: Text(
                'Adicionar ${titulo.split(" ")[0]}',
                style: const TextStyle(color: Colors.white),
              ),
              onPressed: () => _mostrarDialogoSelecaoAlimento(
                context: context,
                tituloDialogo: 'Selecionar para $titulo',
                alimentosDisponiveis: alimentosDisponiveis,
                alimentosJaSelecionados: alimentosSelecionados,
                onSelect: onAdd,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 10),
            if (alimentosSelecionados.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: alimentosSelecionados.map((alimento) {
                  return Chip(
                    label: Text(alimento.nome),
                    onDeleted: () => onRemove(alimento),
                    deleteIconColor: Colors.red.shade700,
                  );
                }).toList(),
              )
            else
              const Text(
                'Nenhum item adicionado ainda.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoSelecaoAlimento({
    required BuildContext context,
    required String tituloDialogo,
    required List<AlimentoModel> alimentosDisponiveis,
    required List<AlimentoModel> alimentosJaSelecionados,
    required Function(AlimentoModel) onSelect,
  }) {
    final List<AlimentoModel> paraSelecionar =
        alimentosDisponiveis
            .where(
              (disponivel) =>
                  !alimentosJaSelecionados.any(
                    (selecionado) => selecionado.id == disponivel.id,
                  ),
            )
            .toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        if (paraSelecionar.isEmpty) {
          return AlertDialog(
            title: Text(tituloDialogo),
            content: const Text(
              'Não há mais alimentos disponíveis para esta categoria ou todos já foram selecionados.',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
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
                    leadingWidget = Image.asset(
                      alimento.foto!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        size: 40,
                      ),
                    );
                  } else {
                    leadingWidget = Image.file(
                      File(alimento.foto!),
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        size: 40,
                      ),
                    );
                  }
                } else {
                  leadingWidget = Icon(
                    Icons.restaurant,
                    size: 40,
                    color: Colors.grey.shade400,
                  );
                }

                return ListTile(
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey.shade200,
                    child: ClipOval(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: leadingWidget,
                      ),
                    ),
                  ),
                  title: Text(alimento.nome),
                  subtitle: Text(alimento.tipo ?? 'Sem tipo'),
                  onTap: () {
                    onSelect(alimento);
                    Navigator.of(context).pop();
                    setState(() {});
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _nomeCardapioController,
                      decoration: InputDecoration(
                        labelText: 'Nome do Cardápio',
                        prefixIcon: const Icon(Icons.restaurant_menu),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira o nome do cardápio.';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descricaoCardapioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Descrição (Opcional)',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildFoodSelectionSection(
                      titulo: 'Café da manhã',
                      alimentosDisponiveis: _alimentosDisponiveisCafe,
                      alimentosSelecionados: _selecionadosCafe,
                      minimo: _minCafe,
                      onAdd: (alimento) => setState(() => _selecionadosCafe.add(alimento)),
                      onRemove: (alimento) => setState(() => _selecionadosCafe.remove(alimento)),
                    ),
                    _buildFoodSelectionSection(
                      titulo: 'Almoço',
                      alimentosDisponiveis: _alimentosDisponiveisAlmoco,
                      alimentosSelecionados: _selecionadosAlmoco,
                      minimo: _minAlmoco,
                      onAdd: (alimento) => setState(() => _selecionadosAlmoco.add(alimento)),
                      onRemove: (alimento) => setState(() => _selecionadosAlmoco.remove(alimento)),
                    ),
                    _buildFoodSelectionSection(
                      titulo: 'Jantar',
                      alimentosDisponiveis: _alimentosDisponiveisJantar,
                      alimentosSelecionados: _selecionadosJantar,
                      minimo: _minJantar,
                      onAdd: (alimento) => setState(() => _selecionadosJantar.add(alimento)),
                      onRemove: (alimento) => setState(() => _selecionadosJantar.remove(alimento)),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _isSaving || !_podeSalvar() ? null : _salvarCardapio,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.save,
                              color: Colors.white,
                            ),
                      label: Text(
                        _isSaving ? 'Salvando...' : 'Salvar Cardápio',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.green,
                        disabledBackgroundColor: Colors.grey.shade400,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Color.fromARGB(255, 50, 150, 53),
                            width: 3.0,
                          )
                        ),
                      ),
                      child: const Text(
                        'Voltar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}