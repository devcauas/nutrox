class CardapioItemModel {
  final int? id;
  final int cardapioId;
  final int alimentoId;
  final String categoriaRefeicao;
  final int? ordem;

  final String? nomeAlimento;

  CardapioItemModel({
    this.id,
    required this.cardapioId,
    required this.alimentoId,
    required this.categoriaRefeicao,
    this.ordem,
    this.nomeAlimento,
  });

  factory CardapioItemModel.fromMap(Map<String, dynamic> map) {
    return CardapioItemModel(
      id: map['id'],
      cardapioId: map['cardapio_id'],
      alimentoId: map['alimento_id'],
      categoriaRefeicao: map['categoria_refeicao'],
      ordem: map['ordem'],
      nomeAlimento: map['nome_alimento'],
    );
  }


  Map<String, dynamic> toMap() => {
    'id': id,
    'cardapio_id': cardapioId,
    'alimento_id': alimentoId,
    'categoria_refeicao': categoriaRefeicao,
    'ordem': ordem,
  };
}