import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nutrox/models/cardapio_model.dart';
import 'package:nutrox/models/alimento_model.dart';
import 'package:nutrox/models/user_model.dart';
import 'package:nutrox/repository/cardapio_repository.dart';
import 'package:nutrox/repository/alimento_repository.dart';
import 'package:nutrox/repository/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrox/screens/view_menu_screen.dart';
import 'package:nutrox/screens/view_food_screen.dart';
import 'package:nutrox/screens/public_profile_screen.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final CardapioRepository _cardapioRepository = CardapioRepository();
  final AlimentoRepository _alimentoRepository = AlimentoRepository();
  final UserRepository _userRepository = UserRepository();

  List<CardapioModel> _listaCardapios = [];
  List<AlimentoModel> _listaAlimentos = [];
  List<UserModel> _listaUsuarios = [];

  bool _isLoading = true;
  String? _errorMessage;
  int? _loggedUserId;

  final TextEditingController _searchController = TextEditingController();
  List<CardapioModel> _cardapiosFiltrados = [];
  List<AlimentoModel> _alimentosFiltrados = [];
  List<UserModel> _usuariosFiltrados = [];

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
    _searchController.addListener(_filtrarConteudo);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filtrarConteudo);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosIniciais() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      _loggedUserId = prefs.getInt('usuarioId');

      if (_loggedUserId != null) {
        final cardapios = await _cardapioRepository.getCardapiosByUsuario(_loggedUserId!);
        final alimentos = await _alimentoRepository.getAllAlimentos(usuarioId: _loggedUserId);
        final outrosUsuarios = await _userRepository.searchPublicUsers(excludeUserId: _loggedUserId);

        if (mounted) {
          setState(() {
            _listaCardapios = cardapios;
            _cardapiosFiltrados = List.from(cardapios);
            _listaAlimentos = alimentos;
            _alimentosFiltrados = List.from(alimentos);
            _listaUsuarios = outrosUsuarios;
            _usuariosFiltrados = List.from(outrosUsuarios);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Usuário não identificado. Faça login novamente.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar dados: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _filtrarConteudo() {
    final query = _searchController.text.toLowerCase();
    if (!mounted) return;
    setState(() {
      if (query.isEmpty) {
        _cardapiosFiltrados = List.from(_listaCardapios);
        _alimentosFiltrados = List.from(_listaAlimentos);
        _usuariosFiltrados = List.from(_listaUsuarios);
      } else {
        _cardapiosFiltrados = _listaCardapios.where((cardapio) =>
          cardapio.nome.toLowerCase().contains(query) ||
          (cardapio.descricao?.toLowerCase().contains(query) ?? false)
        ).toList();
        _alimentosFiltrados = _listaAlimentos.where((alimento) =>
          alimento.nome.toLowerCase().contains(query) ||
          (alimento.tipo?.toLowerCase().contains(query) ?? false)
        ).toList();
        _usuariosFiltrados = _listaUsuarios.where((user) =>
          user.nome.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query)
        ).toList();
      }
    });
  }

  void _navigateToViewMenuScreen(CardapioModel cardapio) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ViewMenuScreen(cardapio: cardapio)),
    ).then((result) {
      if (result == true && mounted) _carregarDadosIniciais();
    });
  }

  void _navigateToViewFoodScreen(AlimentoModel alimento) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ViewFoodScreen(alimento: alimento)),
    ).then((result) {
      if (result == true && mounted) _carregarDadosIniciais();
    });
  }

  void _navigateToPublicProfileScreen(UserModel user) {
    if (user.id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PublicProfileScreen(userIdToView: user.id!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Explorar Conteúdo',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), letterSpacing: 1.2),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar cardápios, alimentos, usuários...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF0F0F0),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () => _searchController.clear())
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? _buildErrorView()
                      : RefreshIndicator(
                          onRefresh: _carregarDadosIniciais,
                          child: ListView(
                            children: [
                              _buildSecaoCardapios(),
                              const SizedBox(height: 24),
                              _buildSecaoAlimentos(),
                              const SizedBox(height: 24),
                              _buildSecaoUsuarios(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _carregarDadosIniciais,
              child: const Text('Tentar Novamente'),
            )
          ],
        ),
      )
    );
  }

  Widget _buildSecaoCardapios() {
    bool mostrarMensagemVazia = _cardapiosFiltrados.isEmpty &&
                               (_searchController.text.isEmpty ? _listaCardapios.isEmpty : true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Meus Cardápios', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
          ],
        ),
        const SizedBox(height: 10),
        if (mostrarMensagemVazia)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.menu_book, size: 50, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                     _searchController.text.isEmpty
                        ? 'Nenhum cardápio criado ainda.'
                        : 'Nenhum cardápio encontrado para "${_searchController.text}".',
                    style: const TextStyle(fontSize: 16, color: Colors.grey)
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cardapiosFiltrados.length,
            itemBuilder: (context, index) {
              final cardapio = _cardapiosFiltrados[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () => _navigateToViewMenuScreen(cardapio),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cardapio.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                        if (cardapio.descricao != null && cardapio.descricao!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(cardapio.descricao!, style: TextStyle(fontSize: 14, color: Colors.grey.shade700), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text('Clique para ver mais...', style: TextStyle(fontSize: 13, color: Colors.blue.shade700, fontStyle: FontStyle.italic)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSecaoAlimentos() {
    bool mostrarMensagemVazia = _alimentosFiltrados.isEmpty &&
                               (_searchController.text.isEmpty ? _listaAlimentos.isEmpty : true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Alimentos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepOrangeAccent)),
          ],
        ),
        const SizedBox(height: 10),
        if (mostrarMensagemVazia)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.no_food_outlined, size: 50, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                   Text(
                     _searchController.text.isEmpty
                        ? 'Nenhum alimento cadastrado ainda.'
                        : 'Nenhum alimento encontrado para "${_searchController.text}".',
                    style: const TextStyle(fontSize: 16, color: Colors.grey)
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: _alimentosFiltrados.length,
            itemBuilder: (context, index) {
              final alimento = _alimentosFiltrados[index];
              Widget imageWidget;
              if (alimento.foto != null && alimento.foto!.isNotEmpty) {
                if (alimento.foto!.startsWith('assets/')) {
                  imageWidget = Image.asset(alimento.foto!, fit: BoxFit.cover,
                    errorBuilder: (c,e,s) => Icon(Icons.broken_image, size: 40, color: Colors.grey.shade400));
                } else {
                  imageWidget = Image.file(File(alimento.foto!), fit: BoxFit.cover,
                    errorBuilder: (c,e,s) => Icon(Icons.broken_image, size: 40, color: Colors.grey.shade400));
                }
              } else {
                imageWidget = Icon(Icons.restaurant, size: 40, color: Colors.grey.shade400);
              }

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _navigateToViewFoodScreen(alimento),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          color: Colors.grey.shade100,
                          child: Center(child: imageWidget),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                alimento.nome,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                              ),
                              if(alimento.tipo != null)
                                Text(
                                  alimento.tipo!,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSecaoUsuarios() {
    bool mostrarMensagemVazia = _usuariosFiltrados.isEmpty &&
                               (_searchController.text.isEmpty ? _listaUsuarios.isEmpty : true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Outros Usuários', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)),
          ],
        ),
        const SizedBox(height: 10),
        if (mostrarMensagemVazia)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: Text(
                _searchController.text.isEmpty
                  ? 'Nenhum outro usuário para mostrar.'
                  : 'Nenhum usuário encontrado para "${_searchController.text}".',
                style: const TextStyle(fontSize: 16, color: Colors.grey)
              )
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _usuariosFiltrados.length,
            itemBuilder: (context, index) {
              final user = _usuariosFiltrados[index];
              ImageProvider? userImage;
              if (user.foto != null && user.foto!.isNotEmpty) {
                try {
                  userImage = FileImage(File(user.foto!));
                } catch (e) {
                  debugPrint('Erro ao carregar imagem do usuário: $e');
                }
              }
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: userImage,
                    backgroundColor: Colors.grey.shade300,
                    child: userImage == null
                        ? Icon(Icons.person_outline, color: Colors.grey.shade700)
                        : null,
                  ),
                  title: Text(user.nome, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(user.email, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () => _navigateToPublicProfileScreen(user),
                ),
              );
            },
          ),
      ],
    );
  }
}