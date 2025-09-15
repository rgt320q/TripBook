class Validators {
  static final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9.!#$%&\' * +/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\\.[a-zA-Z0-9-]+)*$",
  );

  static final RegExp _passwordRegExp = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}$',
  );

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Lütfen bir e-posta adresi girin.';
    }
    if (!_emailRegExp.hasMatch(value.trim())) {
      return 'Lütfen geçerli bir e-posta adresi girin.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Lütfen bir şifre girin.';
    }
    if (value.trim().length < 8) {
      return 'Şifre en az 8 karakter olmalıdır.';
    }
    if (!_passwordRegExp.hasMatch(value.trim())) {
      return 'Şifre en az bir harf ve bir rakam içermelidir.';
    }
    if (value.contains(' ')) {
      return 'Şifre boşluk içeremez.';
    }
    return null;
  }

  static String? notEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Lütfen $fieldName alanını doldurun.';
    }
    return null;
  }

  static String? noSpecialCharacters(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Lütfen $fieldName alanını doldurun.';
    }
    final RegExp specialChars = RegExp(r'[!@#<>?":_`~;[\\]|=+)(*&^%$]');
    if (specialChars.hasMatch(value.trim())) {
      return '$fieldName özel karakterler içeremez.';
    }
    return null;
  }
}
