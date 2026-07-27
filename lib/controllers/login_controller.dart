import 'package:nutrox/repository/user_repository.dart';

class LoginController {
  final UserRepository _repo = UserRepository();

  Future<bool> login(String email, String senha) async {
    final user = await _repo.login(email, senha);
    return user != null;
  }
}
