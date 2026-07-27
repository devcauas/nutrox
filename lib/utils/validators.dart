class AppValidators {
  static String? validateNome(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'O nome é obrigatório.';
    }
    if (value.trim().length < 3) {
      return 'O nome deve ter pelo menos 3 caracteres.';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'O e-mail é obrigatório.';
    }
    final emailRegex = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9\-\_]+\.[a-zA-Z]+");
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Digite um e-mail válido.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'A senha é obrigatória.';
    }
    if (value.length < 8) {
      return 'A senha deve ter pelo menos 8 caracteres.';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'A senha deve conter pelo menos um número.';
    }
    return null;
  }

  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório(a).';
    }
    return null;
  }
}