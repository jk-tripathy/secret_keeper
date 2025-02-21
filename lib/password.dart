import 'package:encrypt/encrypt.dart' as encrypt;

class Password {
  final String site;
  final String username;
  final String password;

  Password({
    required this.site,
    required this.username,
    required this.password,
  });

  String encryptPassword(String masterPassword, String password) {
    final key = encrypt.Key.fromUtf8(masterPassword.padRight(32, '0'));
    final iv = encrypt.IV.allZerosOfLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(password, iv: iv).base64.toString();
    return encrypted;
  }

  String decryptPassword(String masterPassword, String password) {
    final key = encrypt.Key.fromUtf8(masterPassword.padRight(32, '0'));
    final iv = encrypt.IV.allZerosOfLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final decrypted = encrypter.decrypt64(password, iv: iv);
    return decrypted;
  }

  factory Password.fromMap(Map<String, dynamic> json) => Password(
    site: json['site'],
    username: json['username'],
    password: json['password'],
  );

  Map<String, dynamic> toMap(String userPin) {
    String encPwd = encryptPassword(userPin, password);
    return {'site': site, 'username': username, 'password': encPwd};
  }
}
