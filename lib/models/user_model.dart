class UserModel {
  final int? id;
  final String nome;
  final String email;
  final String senha;
  final String? foto;
  final String? dataNascimento;
  final String dataCadastro;

  UserModel({
    this.id,
    required this.nome,
    required this.email,
    required this.senha,
    this.foto,
    this.dataNascimento,
    required this.dataCadastro,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id'],
    nome: map['nome'],
    email: map['email'],
    senha: map['senha'],
    foto: map['foto'],
    dataNascimento: map['data_nascimento'],
    dataCadastro: map['data_cadastro'],
  );
  
  factory UserModel.fromPublicMap(Map<String, dynamic> map) => UserModel(
    id: map['id'],
    nome: map['nome'],
    email: map['email'],
    senha: '',
    foto: map['foto'],
    dataNascimento: map['data_nascimento'],
    dataCadastro: map['data_cadastro'],
  );


  Map<String, dynamic> toMap() => {
    'id': id,
    'nome': nome,
    'email': email,
    'senha': senha,
    'foto': foto,
    'data_nascimento': dataNascimento,
    'data_cadastro': dataCadastro,
  };
}