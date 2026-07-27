class AlimentoModel {
  final int? id;
  final String nome;
  final String? foto;
  final String? tipo;
  final int? usuarioId;
  final String dataCadastro;
  final List<String>? categoriasRefeicao;


  AlimentoModel({
    this.id,
    required this.nome,
    this.foto,
    this.tipo,
    this.usuarioId,
    required this.dataCadastro,
    this.categoriasRefeicao,
  });

  factory AlimentoModel.fromMap(Map<String, dynamic> map, {List<String>? categorias}) => AlimentoModel(
    id: map['id'],
    nome: map['nome'],
    foto: map['foto'],
    tipo: map['tipo'],
    usuarioId: map['usuario_id'],
    dataCadastro: map['data_cadastro'],
    categoriasRefeicao: categorias,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'nome': nome,
    'foto': foto,
    'tipo': tipo,
    'usuario_id': usuarioId,
    'data_cadastro': dataCadastro,
  };
}