import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutrox/models/alimento_model.dart';
import 'package:nutrox/repository/alimento_repository.dart';
import 'package:nutrox/utils/snackbar_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddFoodScreen extends StatefulWidget {
  final AlimentoModel? alimentoParaEditar;

  const AddFoodScreen({super.key, this.alimentoParaEditar});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  File? _imagemSelecionada;
  String? _caminhoFotoExistente;
  String? _tipoSelecionado;
  final List<String> _categoriasRefeicaoSelecionadas = [];

  final ImagePicker _picker = ImagePicker();
  final AlimentoRepository _alimentoRepository = AlimentoRepository();

  bool _isSaving = false;
  bool get _isEditing => widget.alimentoParaEditar != null;
  int? _loggedUserId;

  final List<String> _tiposDeAlimento = [
    'Bebida', 'Carboidrato', 'Proteína', 'Fruta', 'Grãos',
  ];
  final List<String> _categoriasDeRefeicaoDisponiveis = [
    'Café da manhã', 'Almoço', 'Jantar',
  ];

  @override
  void initState() {
    super.initState();
    _carregarUsuarioId();
    if (_isEditing && widget.alimentoParaEditar != null) {
      final alimento = widget.alimentoParaEditar!;
      _nomeController.text = alimento.nome;
      _tipoSelecionado = alimento.tipo;
      _caminhoFotoExistente = alimento.foto;
      if (alimento.categoriasRefeicao != null) {
        _categoriasRefeicaoSelecionadas.addAll(alimento.categoriasRefeicao!);
      }
    }
  }
  
  Future<void> _carregarUsuarioId() async {
    final prefs = await SharedPreferences.getInstance();
    _loggedUserId = prefs.getInt('usuarioId');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _selecionarImagem() async {
    final XFile? imagem = await _picker.pickImage(source: ImageSource.gallery);
    if (imagem != null) {
      setState(() {
        _imagemSelecionada = File(imagem.path);
        _caminhoFotoExistente = null;
      });
    }
  }

  Future<void> _salvarAlimento() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_tipoSelecionado == null) {
      SnackBarHelper.show(context, 'Por favor, selecione o tipo do alimento.', type: SnackBarType.warning);
      return;
    }
    if (_categoriasRefeicaoSelecionadas.isEmpty) {
      SnackBarHelper.show(context, 'Selecione pelo menos uma categoria de refeição.', type: SnackBarType.warning);
      return;
    }
    if (_loggedUserId == null && !_isEditing) {
      SnackBarHelper.show(context, "Erro: Usuário não identificado.", type: SnackBarType.error);
      return;
    }
    setState(() => _isSaving = true);

    String? finalFotoPath = _imagemSelecionada?.path ?? _caminhoFotoExistente;

    AlimentoModel alimentoParaSalvar = AlimentoModel(
      id: _isEditing ? widget.alimentoParaEditar!.id : null,
      nome: _nomeController.text.trim(),
      foto: finalFotoPath,
      tipo: _tipoSelecionado,
      usuarioId: _isEditing ? widget.alimentoParaEditar!.usuarioId : _loggedUserId,
      dataCadastro: _isEditing ? widget.alimentoParaEditar!.dataCadastro : DateTime.now().toIso8601String(),
    );

    AlimentoModel? alimentoSalvo;
    try {
      if (_isEditing) {
        alimentoSalvo = await _alimentoRepository.updateAlimento(alimentoParaSalvar, _categoriasRefeicaoSelecionadas);
      } else {
        alimentoSalvo = await _alimentoRepository.insertAlimento(alimentoParaSalvar, _categoriasRefeicaoSelecionadas);
      }

      if (!mounted) return;

      if (alimentoSalvo != null) {
        SnackBarHelper.show(
          context,
          _isEditing ? 'Alimento atualizado com sucesso!' : 'Alimento salvo com sucesso!',
          type: SnackBarType.success,
        );
        Navigator.pop(context, true);
      } else {
        SnackBarHelper.show(
          context,
          _isEditing ? 'Erro ao atualizar alimento.' : 'Erro ao salvar alimento. Verifique se o nome já existe.',
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      if(mounted) SnackBarHelper.show(context, "Erro: $e", type: SnackBarType.error);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? currentImageProvider;
    if (_imagemSelecionada != null) {
      currentImageProvider = FileImage(_imagemSelecionada!);
    } else if (_caminhoFotoExistente != null && _caminhoFotoExistente!.isNotEmpty) {
      if (_caminhoFotoExistente!.startsWith('assets/')) {
        currentImageProvider = AssetImage(_caminhoFotoExistente!);
      } else {
        currentImageProvider = FileImage(File(_caminhoFotoExistente!));
      }
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Center(
                child: GestureDetector(
                  onTap: _selecionarImagem,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: currentImageProvider,
                    child: currentImageProvider == null
                        ? Icon(Icons.camera_alt, size: 50, color: Colors.grey.shade700)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                  child: Text(
                currentImageProvider == null ? 'Toque para adicionar foto' : 'Toque para alterar foto',
                style: TextStyle(color: Colors.grey.shade600),
              )),
              const SizedBox(height: 25),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome do Alimento'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome do alimento';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Tipo do Alimento'),
                value: _tipoSelecionado,
                items: _tiposDeAlimento.map((String tipo) => DropdownMenuItem<String>(value: tipo, child: Text(tipo))).toList(),
                onChanged: (String? newValue) => setState(() => _tipoSelecionado = newValue),
                validator: (value) => value == null ? 'Selecione um tipo' : null,
              ),
              const SizedBox(height: 20),
              const Text('Pode ser usado em:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0, runSpacing: 4.0,
                children: _categoriasDeRefeicaoDisponiveis.map((categoria) {
                  final isSelected = _categoriasRefeicaoSelecionadas.contains(categoria);
                  return FilterChip(
                    label: Text(categoria),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _categoriasRefeicaoSelecionadas.add(categoria);
                        } else {
                          _categoriasRefeicaoSelecionadas.remove(categoria);
                        }
                      });
                    },
                    selectedColor: Colors.green.shade200,
                    checkmarkColor: Colors.black,
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _salvarAlimento,
                icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save, color: Colors.white,),
                label: Text(
                  _isSaving ? 'Salvando...' : (_isEditing ? 'Atualizar Alimento' : 'Salvar Alimento'),
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Cantos arredondados
                    side: const BorderSide(
                      color: Color.fromARGB(255, 50, 150, 53), // Cor da borda
                      width: 2,            // Largura da borda
                    ),
                  ),
                ),
                child: const Text(
                  'Voltar',
                  style: TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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