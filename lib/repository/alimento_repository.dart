import 'package:nutrox/database/db.dart';
import 'package:nutrox/models/alimento_model.dart';
import 'package:nutrox/models/alimento_categoria_model.dart';
import 'package:sqflite/sqflite.dart';

class AlimentoRepository {
  Future<AlimentoModel?> insertAlimento(AlimentoModel alimento, List<String> categoriasRefeicao) async {
    final db = await DB.instance;
    try {
      return await db.transaction((txn) async {
        int alimentoId = await txn.insert(
          'alimento',
          alimento.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        if (alimentoId == 0) {
          List<Map<String, dynamic>> existingAlimentos;
          if (alimento.usuarioId == null) {
            existingAlimentos = await txn.query(
              'alimento', where: 'nome = ? AND usuario_id IS NULL', whereArgs: [alimento.nome], limit: 1,
            );
          } else {
            existingAlimentos = await txn.query(
              'alimento', where: 'nome = ? AND usuario_id = ?', whereArgs: [alimento.nome, alimento.usuarioId], limit: 1,
            );
          }
          if (existingAlimentos.isNotEmpty) {
            alimentoId = existingAlimentos.first['id'] as int;
            return null;
          } else {
            return null;
          }
        }

        await txn.delete('alimento_categoria', where: 'alimento_id = ?', whereArgs: [alimentoId]);

        for (String categoriaNome in categoriasRefeicao) {
          await txn.insert(
            'alimento_categoria',
            AlimentoCategoriaModel(alimentoId: alimentoId, categoria: categoriaNome).toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }

        final maps = await txn.query('alimento', where: 'id = ?', whereArgs: [alimentoId], limit: 1);
        if (maps.isNotEmpty) {
          return AlimentoModel.fromMap(maps.first, categorias: categoriasRefeicao);
        }
        return null;
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<AlimentoModel>> getAllAlimentos({int? usuarioId, String? categoriaRefeicao}) async {
    final db = await DB.instance;
    List<Map<String, dynamic>> maps;
    String query = 'SELECT a.* FROM alimento a';
    List<dynamic> queryArgs = [];
    List<String> conditions = [];

    if (usuarioId != null) {
      conditions.add('(a.usuario_id = ? OR a.usuario_id IS NULL)');
      queryArgs.add(usuarioId);
    } else {
      conditions.add('a.usuario_id IS NULL');
    }

    if (categoriaRefeicao != null && categoriaRefeicao.isNotEmpty) {
      query += ' INNER JOIN alimento_categoria ac ON a.id = ac.alimento_id';
      conditions.add('ac.categoria = ?');
      queryArgs.add(categoriaRefeicao);
    }

    if (conditions.isNotEmpty) {
      query += ' WHERE ${conditions.join(' AND ')}';
    }
    query += ' ORDER BY a.nome ASC';

    maps = await db.rawQuery(query, queryArgs);

    List<AlimentoModel> alimentos = [];
    for (var map in maps) {
      final alimentoId = map['id'] as int;
      final categoriasMap = await db.query(
        'alimento_categoria', columns: ['categoria'], where: 'alimento_id = ?', whereArgs: [alimentoId],
      );
      final List<String> cats = categoriasMap.map((catMap) => catMap['categoria'] as String).toList();
      alimentos.add(AlimentoModel.fromMap(map, categorias: cats));
    }
    return alimentos;
  }

  Future<AlimentoModel?> getAlimentoById(int id) async {
    final db = await DB.instance;
    final List<Map<String, dynamic>> maps = await db.query('alimento', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isNotEmpty) {
      final categoriasMap = await db.query('alimento_categoria', columns: ['categoria'], where: 'alimento_id = ?', whereArgs: [id]);
      final List<String> cats = categoriasMap.map((catMap) => catMap['categoria'] as String).toList();
      return AlimentoModel.fromMap(maps.first, categorias: cats);
    }
    return null;
  }

  Future<AlimentoModel?> updateAlimento(AlimentoModel alimento, List<String> novasCategoriasRefeicao) async {
    final db = await DB.instance;

    if (alimento.id == null) {
      return null;
    }

    try {
      return await db.transaction((txn) async {
        if (alimento.nome != (await txn.query('alimento', columns: ['nome'], where: 'id = ?', whereArgs: [alimento.id])).first['nome']) {
          List<Map<String, dynamic>> conflictingAlimentos;
          if (alimento.usuarioId == null) {
            conflictingAlimentos = await txn.query('alimento', where: 'nome = ? AND usuario_id IS NULL AND id != ?', whereArgs: [alimento.nome, alimento.id], limit: 1);
          } else {
            conflictingAlimentos = await txn.query('alimento', where: 'nome = ? AND usuario_id = ? AND id != ?', whereArgs: [alimento.nome, alimento.usuarioId, alimento.id], limit: 1);
          }
          if (conflictingAlimentos.isNotEmpty) {
            throw Exception("O nome '${alimento.nome}' já está em uso.");
          }
        }

        int count = await txn.update(
          'alimento',
          alimento.toMap(),
          where: 'id = ?',
          whereArgs: [alimento.id],
        );

        if (count == 0) {
          return null;
        }

        await txn.delete(
          'alimento_categoria',
          where: 'alimento_id = ?',
          whereArgs: [alimento.id],
        );

        for (String categoriaNome in novasCategoriasRefeicao) {
          await txn.insert(
            'alimento_categoria',
            AlimentoCategoriaModel(alimentoId: alimento.id!, categoria: categoriaNome).toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }

        final maps = await txn.query('alimento', where: 'id = ?', whereArgs: [alimento.id], limit: 1);
        if (maps.isNotEmpty) {
          final categoriasMap = await txn.query('alimento_categoria', columns: ['categoria'], where: 'alimento_id = ?', whereArgs: [alimento.id]);
          final List<String> cats = categoriasMap.map((catMap) => catMap['categoria'] as String).toList();
          return AlimentoModel.fromMap(maps.first, categorias: cats);
        }
        return null;
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAlimento(int alimentoId) async {
    final db = await DB.instance;
    try {
      await db.transaction((txn) async {
        await txn.delete(
          'alimento',
          where: 'id = ?',
          whereArgs: [alimentoId],
        );
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<AlimentoModel>> getAlimentosDoUsuario(int usuarioId) async {
    final db = await DB.instance;
    String query = 'SELECT a.* FROM alimento a WHERE a.usuario_id = ? ORDER BY a.nome ASC';
    List<Map<String, dynamic>> maps = await db.rawQuery(query, [usuarioId]);

    List<AlimentoModel> alimentos = [];
    for (var map in maps) {
      final alimentoId = map['id'] as int;
      final categoriasMap = await db.query('alimento_categoria', columns: ['categoria'], where: 'alimento_id = ?', whereArgs: [alimentoId]);
      final List<String> cats = categoriasMap.map((catMap) => catMap['categoria'] as String).toList();
      alimentos.add(AlimentoModel.fromMap(map, categorias: cats));
    }
    return alimentos;
  }
}