class AlimentoCategoriaModel {
  final int? id;
  final int alimentoId;
  final String categoria;

  AlimentoCategoriaModel({
    this.id,
    required this.alimentoId,
    required this.categoria,
  });

  factory AlimentoCategoriaModel.fromMap(Map<String, dynamic> map) => AlimentoCategoriaModel(
    id: map['id'],
    alimentoId: map['alimento_id'],
    categoria: map['categoria'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'alimento_id': alimentoId,
    'categoria': categoria,
  };
}