import 'package:nutrox/database/db.dart';
import 'package:nutrox/models/cardapio_model.dart';
import 'package:nutrox/models/cardapio_item_model.dart';
import 'package:nutrox/models/alimento_model.dart';
import 'package:sqflite/sqflite.dart';

class CardapioRepository {
  Future<CardapioModel?> insertCardapio(CardapioModel cardapio) async {
    final db = await DB.instance;
    try {
      int id = await db.insert(
        'cardapio',
        cardapio.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      if (id == 0) {
        return null;
      }
      final maps = await db.query('cardapio', where: 'id = ?', whereArgs: [id], limit: 1);
      if (maps.isNotEmpty) {
        return CardapioModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<CardapioItemModel?> insertCardapioItem(CardapioItemModel item) async {
    final db = await DB.instance;
    try {
      final alimentoCategorias = await db.query(
        'alimento_categoria',
        where: 'alimento_id = ? AND categoria = ?',
        whereArgs: [item.alimentoId, item.categoriaRefeicao],
        limit: 1,
      );

      if (alimentoCategorias.isEmpty) {
        throw Exception("Alimento não é adequado para esta categoria de refeição.");
      }

      int id = await db.insert('cardapio_item', item.toMap());
      final maps = await db.query('cardapio_item', where: 'id = ?', whereArgs: [id], limit: 1);
      if (maps.isNotEmpty) {
        return CardapioItemModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CardapioModel>> getCardapiosByUsuario(int usuarioId) async {
    final db = await DB.instance;
    final List<Map<String, dynamic>> maps = await db.query('cardapio', where: 'usuario_id = ?', whereArgs: [usuarioId], orderBy: 'data_criacao DESC');
    List<CardapioModel> cardapios = List.generate(maps.length, (i) => CardapioModel.fromMap(maps[i]));
    return cardapios;
  }

  Future<Map<String, List<CardapioItemModel>>> getItensDoCardapioAgrupados(int cardapioId) async {
    final db = await DB.instance;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''SELECT ci.*, a.nome as nome_alimento, a.foto as foto_alimento, a.tipo as tipo_alimento 
         FROM cardapio_item ci
         JOIN alimento a ON ci.alimento_id = a.id
         WHERE ci.cardapio_id = ?
         ORDER BY ci.categoria_refeicao ASC, ci.ordem ASC
      ''', [cardapioId]);

    Map<String, List<CardapioItemModel>> agrupados = {};
    for (var map in maps) {
      CardapioItemModel item = CardapioItemModel.fromMap(map);
      (agrupados[item.categoriaRefeicao] ??= []).add(item);
    }
    return agrupados;
  }
  
  Future<void> deleteCardapio(int cardapioId) async {
    final db = await DB.instance;
    try {
      await db.delete('cardapio', where: 'id = ?', whereArgs: [cardapioId]);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCardapio(
    CardapioModel cardapio,
    List<AlimentoModel> selecionadosCafe,
    List<AlimentoModel> selecionadosAlmoco,
    List<AlimentoModel> selecionadosJantar,
  ) async {
    final db = await DB.instance;
    if (cardapio.id == null) {
      throw Exception("ID do cardápio não pode ser nulo para atualização.");
    }

    try {
      await db.transaction((txn) async {
        if (cardapio.nome != (await txn.query('cardapio', columns: ['nome'], where: 'id = ?', whereArgs: [cardapio.id])).first['nome']) {
            final conflictingCardapios = await txn.query('cardapio', where: 'nome = ? AND usuario_id = ? AND id != ?', whereArgs: [cardapio.nome, cardapio.usuarioId, cardapio.id], limit: 1);
            if (conflictingCardapios.isNotEmpty) {
                throw Exception("O nome de cardápio '${cardapio.nome}' já está em uso.");
            }
        }

        await txn.update(
          'cardapio',
          cardapio.toMap(),
          where: 'id = ?',
          whereArgs: [cardapio.id],
        );

        await txn.delete('cardapio_item', where: 'cardapio_id = ?', whereArgs: [cardapio.id]);

        int ordem = 0;
        for (AlimentoModel alimento in selecionadosCafe) {
          await txn.insert('cardapio_item', CardapioItemModel(cardapioId: cardapio.id!, alimentoId: alimento.id!, categoriaRefeicao: 'Café da manhã', ordem: ordem++).toMap());
        }
        ordem = 0;
        for (AlimentoModel alimento in selecionadosAlmoco) {
          await txn.insert('cardapio_item', CardapioItemModel(cardapioId: cardapio.id!, alimentoId: alimento.id!, categoriaRefeicao: 'Almoço', ordem: ordem++).toMap());
        }
        ordem = 0;
        for (AlimentoModel alimento in selecionadosJantar) {
          await txn.insert('cardapio_item', CardapioItemModel(cardapioId: cardapio.id!, alimentoId: alimento.id!, categoriaRefeicao: 'Jantar', ordem: ordem++).toMap());
        }
      });
    } catch (e) {
      rethrow;
    }
  }
}