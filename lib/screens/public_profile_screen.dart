import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nutrox/models/user_model.dart';
import 'package:nutrox/models/cardapio_model.dart';
import 'package:nutrox/models/alimento_model.dart';
import 'package:nutrox/models/cardapio_item_model.dart';
import 'package:nutrox/repository/user_repository.dart';
import 'package:nutrox/repository/cardapio_repository.dart';
import 'package:nutrox/repository/alimento_repository.dart';

class PublicProfileScreen extends StatefulWidget {
  final int userIdToView;

  const PublicProfileScreen({super.key, required this.userIdToView});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final UserRepository _userRepository = UserRepository();
  final CardapioRepository _cardapioRepository = CardapioRepository();
  final AlimentoRepository _alimentoRepository = AlimentoRepository();

  UserModel? _viewedUser;
  List<CardapioModel> _userCardapios = [];
  List<AlimentoModel> _userAlimentos = [];

  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _ordemCategoriasModal = ['Café da manhã', 'Almoço', 'Jantar'];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _viewedUser = await _userRepository.getPublicUserById(widget.userIdToView);
      if (_viewedUser == null) {
        throw Exception("Usuário não encontrado.");
      }
      _userCardapios = await _cardapioRepository.getCardapiosByUsuario(widget.userIdToView);
      _userAlimentos = await _alimentoRepository.getAllAlimentos(
        usuarioId: widget.userIdToView,
      );

      _userAlimentos = await _alimentoRepository.getAlimentosDoUsuario(widget.userIdToView);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Erro ao carregar perfil: $e";
          _isLoading = false;
        });
      }
    }
  }
  
  void _showCardapioDetailsModal(BuildContext context, CardapioModel cardapio) async {
    if (cardapio.id == null) return;
    Map<String, List<CardapioItemModel>> itensAgrupados = {};
    bool isLoadingModal = true;
    String? errorModal;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (isLoadingModal && itensAgrupados.isEmpty && errorModal == null) {
              _cardapioRepository.getItensDoCardapioAgrupados(cardapio.id!).then((data) {
                setModalState(() {
                  itensAgrupados = data;
                  isLoadingModal = false;
                });
              }).catchError((e) {
                setModalState(() {
                  errorModal = "Erro ao carregar itens: $e";
                  isLoadingModal = false;
                });
              });
            }

            return AlertDialog(
              title: Text(cardapio.nome, style: TextStyle(color: Theme.of(context).primaryColor)),
              content: SizedBox(
                width: double.maxFinite,
                child: isLoadingModal
                    ? const Center(child: CircularProgressIndicator())
                    : errorModal != null
                        ? Text(errorModal!, style: const TextStyle(color: Colors.red))
                        : itensAgrupados.isEmpty
                            ? const Text("Nenhum item neste cardápio.")
                            : SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (cardapio.descricao != null && cardapio.descricao!.isNotEmpty) ...[
                                      const Text("Descrição:", style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(cardapio.descricao!),
                                      const SizedBox(height: 10),
                                    ],
                                    ..._ordemCategoriasModal.map((categoria) {
                                      if (itensAgrupados.containsKey(categoria) && itensAgrupados[categoria]!.isNotEmpty) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(categoria.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              ...itensAgrupados[categoria]!.map((item) => Text("- ${item.nomeAlimento ?? 'Alimento desconhecido'}")),
                                            ],
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    }).toList(),
                                  ],
                                ),
                              ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Fechar'),
                  onPressed: () => Navigator.of(modalContext).pop(),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    if (_errorMessage != null || _viewedUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Erro")),
        body: Center(child: Text(_errorMessage ?? "Usuário não encontrado.")),
      );
    }

    final user = _viewedUser!;
    ImageProvider? profileImage;
    if (user.foto != null && user.foto!.isNotEmpty) {
        profileImage = FileImage(File(user.foto!));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Perfil de ${user.nome}"),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.teal.shade700,
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: profileImage,
                  child: profileImage == null ? Icon(Icons.person, size: 50, color: Colors.teal.shade300) : null,
                ),
                const SizedBox(height: 10),
                Text(user.nome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                if (user.email.isNotEmpty)
                     Text(user.email, style: const TextStyle(fontSize: 15, color: Colors.white70)),
              ],
            ),
          ),
          _buildSectionTitle("Cardápios de ${user.nome}"),
          _userCardapios.isEmpty
            ? const Padding(padding: EdgeInsets.all(16), child: Center(child: Text("Nenhum cardápio público.")))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _userCardapios.length,
                itemBuilder: (context, index) {
                  final cardapio = _userCardapios[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.menu_book, color: Colors.green),
                      title: Text(cardapio.nome, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: cardapio.descricao != null && cardapio.descricao!.isNotEmpty ? Text(cardapio.descricao!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                      trailing: const Icon(Icons.visibility_outlined),
                      onTap: () => _showCardapioDetailsModal(context, cardapio),
                    ),
                  );
                },
              ),
          _buildSectionTitle("Alimentos Criados por ${user.nome}"),
          _userAlimentos.isEmpty
            ? const Padding(padding: EdgeInsets.all(16), child: Center(child: Text("Nenhum alimento criado.")))
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.9),
                itemCount: _userAlimentos.length,
                itemBuilder: (context, index) {
                  final alimento = _userAlimentos[index];
                   Widget imageWidget;
                    if (alimento.foto != null && alimento.foto!.isNotEmpty) {
                        if (alimento.foto!.startsWith('assets/')) {
                            imageWidget = Image.asset(alimento.foto!, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image));
                        } else {
                            imageWidget = Image.file(File(alimento.foto!), fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image));
                        }
                    } else {
                        imageWidget = const Icon(Icons.restaurant, size: 30, color: Colors.grey);
                    }
                  return Card(
                    elevation: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 2, child: Container(color: Colors.grey.shade100, child: Center(child: imageWidget))),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                                Text(alimento.nome, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                                if (alimento.tipo != null) Text(alimento.tipo!, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }
}