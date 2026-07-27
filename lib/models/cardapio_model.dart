class CardapioModel {
  final int? id;
  final String nome;
  final String? descricao;
  final int usuarioId;
  final String dataCriacao;

  CardapioModel({
    this.id,
    required this.nome,
    this.descricao,
    required this.usuarioId,
    required this.dataCriacao,
  });

  factory CardapioModel.fromMap(Map<String, dynamic> map) => CardapioModel(
    id: map['id'],
    nome: map['nome'],
    descricao: map['descricao'],
    usuarioId: map['usuario_id'],
    dataCriacao: map['data_criacao'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'nome': nome,
    'descricao': descricao,
    'usuario_id': usuarioId,
    'data_criacao': dataCriacao,
  };
}