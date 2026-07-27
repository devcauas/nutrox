import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DB {
  static Database? _database;

  static Future<Database> get instance async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'nutrox.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createTablesFinal(db);
        await _seedDataFinal(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
      },
    );
  }

  static Future<void> _createTablesFinal(Database db) async {
    await db.execute('''
      CREATE TABLE usuario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        senha TEXT NOT NULL,
        foto TEXT,
        data_nascimento TEXT,
        data_cadastro TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cardapio (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        descricao TEXT,
        usuario_id INTEGER NOT NULL,
        data_criacao TEXT NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE,
        UNIQUE(usuario_id, nome COLLATE NOCASE)
      )
    ''');

    await db.execute('''
      CREATE TABLE alimento (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL COLLATE NOCASE,
        foto TEXT,
        tipo TEXT,
        usuario_id INTEGER,
        data_cadastro TEXT NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE SET NULL,
        UNIQUE(nome, usuario_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE alimento_categoria (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        alimento_id INTEGER NOT NULL,
        categoria TEXT NOT NULL,
        FOREIGN KEY (alimento_id) REFERENCES alimento(id) ON DELETE CASCADE,
        UNIQUE(alimento_id, categoria COLLATE NOCASE)
      )
    ''');

    await db.execute('''
      CREATE TABLE cardapio_item (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cardapio_id INTEGER NOT NULL,
        alimento_id INTEGER NOT NULL,
        categoria_refeicao TEXT NOT NULL,
        ordem INTEGER,
        FOREIGN KEY (cardapio_id) REFERENCES cardapio(id) ON DELETE CASCADE,
        FOREIGN KEY (alimento_id) REFERENCES alimento(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _seedDataFinal(Database db) async {
    String now = DateTime.now().toIso8601String();

    var alimentosSeed = [
      {'nome': 'Banana', 'foto': 'assets/food_images/banana.png', 'tipo': 'Fruta', 'categorias_refeicao': ['Café da manhã']},
      {'nome': 'Maçã', 'foto': 'assets/food_images/maca.png', 'tipo': 'Fruta', 'categorias_refeicao': ['Café da manhã']},
      {'nome': 'Pão Integral', 'foto': 'assets/food_images/pao_integral.png', 'tipo': 'Carboidrato', 'categorias_refeicao': ['Café da manhã', 'Jantar']},
      {'nome': 'Arroz Branco Cozido', 'foto': 'assets/food_images/arroz.png', 'tipo': 'Grãos', 'categorias_refeicao': ['Almoço', 'Jantar']},
      {'nome': 'Feijão Carioca Cozido', 'foto': 'assets/food_images/feijao.png', 'tipo': 'Grãos', 'categorias_refeicao': ['Almoço', 'Jantar']},
      {'nome': 'Peito de Frango Grelhado', 'foto': 'assets/food_images/frango_grelhado.png', 'tipo': 'Proteína', 'categorias_refeicao': ['Almoço', 'Jantar']},
      {'nome': 'Salada de Alface e Tomate', 'foto': 'assets/food_images/salada.png', 'tipo': 'Verdura/Legume', 'categorias_refeicao': ['Almoço', 'Jantar']},
      {'nome': 'Ovo Cozido', 'foto': 'assets/food_images/ovo_cozido.png', 'tipo': 'Proteína', 'categorias_refeicao': ['Café da manhã', 'Almoço']},
      {'nome': 'Leite Integral', 'foto': 'assets/food_images/leite.png', 'tipo': 'Bebida', 'categorias_refeicao': ['Café da manhã']},
      {'nome': 'Suco de Laranja Natural', 'foto': 'assets/food_images/suco_laranja.png', 'tipo': 'Bebida', 'categorias_refeicao': ['Café da manhã', 'Almoço']},
      {'nome': 'Iogurte Natural', 'foto': 'assets/food_images/iogurte.png', 'tipo': 'Laticínio', 'categorias_refeicao': ['Café da manhã']},
    ];

    for (var alimentoData in alimentosSeed) {
      int alimentoId = 0;
      try {
        alimentoId = await db.insert(
          'alimento',
          {
            'nome': alimentoData['nome'],
            'foto': alimentoData['foto'],
            'tipo': alimentoData['tipo'],
            'usuario_id': null,
            'data_cadastro': now,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        if (alimentoId == 0) {
          final existing = await db.query('alimento', columns: ['id'], where: 'nome = ? AND usuario_id IS NULL', whereArgs: [alimentoData['nome']]);
          if (existing.isNotEmpty) {
            alimentoId = existing.first['id'] as int;
          } else {
            continue;
          }
        }
      } catch (e) {
        final existing = await db.query('alimento', columns: ['id'], where: 'nome = ? AND usuario_id IS NULL', whereArgs: [alimentoData['nome']]);
        if (existing.isNotEmpty) {
          alimentoId = existing.first['id'] as int;
        } else {
          continue;
        }
      }

      if (alimentoId > 0 && alimentoData['categorias_refeicao'] != null) {
        for (String categoriaRefeicao in alimentoData['categorias_refeicao'] as List<String>) {
          try {
            await db.insert(
              'alimento_categoria',
              {
                'alimento_id': alimentoId,
                'categoria': categoriaRefeicao,
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          } catch (e) {
            debugPrint('Erro ao inserir alimento_categoria: $e');
          }
        }
      }
    }
  }
}

