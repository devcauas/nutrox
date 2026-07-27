import 'package:nutrox/models/user_model.dart';
import 'package:nutrox/database/db.dart';

class UserRepository {

  Future<int> insertUser(UserModel user) async {
    final db = await DB.instance;
    try {
      int userId = await db.insert('usuario', user.toMap());
      return userId;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> login(String email, String senha) async {
    final db = await DB.instance;
    try {
      final result = await db.query(
        'usuario',
        where: 'email = ? AND senha = ?',
        whereArgs: [email, senha],
        limit: 1,
      );
      if (result.isNotEmpty) {
        return UserModel.fromMap(result.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> getPublicUserById(int userId) async {
    final db = await DB.instance;
    try {
      final result = await db.query(
        'usuario',
        columns: ['id', 'nome', 'email', 'foto', 'data_nascimento', 'data_cadastro'],
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (result.isNotEmpty) {
        return UserModel.fromPublicMap(result.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<UserModel>> searchPublicUsers({String query = '', int? excludeUserId}) async {
    final db = await DB.instance;
    List<Map<String, dynamic>> maps;
    try {
      String whereClause = "nome LIKE ?";
      List<dynamic> whereArgs = ['%$query%'];

      if (excludeUserId != null) {
        whereClause += " AND id != ?";
        whereArgs.add(excludeUserId);
      }

      maps = await db.query(
        'usuario',
        columns: ['id', 'nome', 'email', 'foto', 'data_nascimento', 'data_cadastro'],
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'nome ASC',
      );
      
      List<UserModel> users = maps.map((userMap) => UserModel.fromPublicMap(userMap)).toList();
      return users;
    } catch (e) {
      return [];
    }
  }

  Future<int> updateUserPhoto(int userId, String newPhotoPath) async {
    final db = await DB.instance;
    try {
      final count = await db.update(
        'usuario',
        {'foto': newPhotoPath},
        where: 'id = ?',
        whereArgs: [userId],
      );
      return count;
    } catch (e) {
      rethrow;
    }
  }
}