import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:shared_preferences/shared_preferences.dart';

class Password {
  String site;
  String username;
  String password;
  final int? id;
  int pinned;

  Password({
    required this.site,
    required this.username,
    required this.password,
    this.id,
    this.pinned = 0,
  });

  static Future<void> setAndSaveMasterPassword(String masterPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final hashedMasterPassword =
        sha256.convert(utf8.encode(masterPassword)).toString();
    await prefs.setBool('isMasterPasswordSet', true);
    await prefs.setString('masterPassword', hashedMasterPassword);
  }

  static Future<void> clearMasterPassword() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMasterPasswordSet', false);
    await prefs.remove('masterPassword');
  }

  static Future<bool> validateMasterPassword(String inputPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final hashedMasterPassword = prefs.getString('masterPassword');
    final hashedInputPassword =
        sha256.convert(utf8.encode(inputPassword)).toString();
    return hashedMasterPassword == hashedInputPassword;
  }

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

  Password copyWith(
    String masterPassword, {
    String? site,
    String? username,
    String? password,
    int? id,
    int? pinned,
  }) {
    String decPwd = decryptPassword(masterPassword, this.password);
    return Password(
      site: site ?? this.site,
      username: username ?? this.username,
      password: password ?? decPwd,
      id: id ?? this.id,
      pinned: pinned ?? this.pinned,
    );
  }

  factory Password.fromMap(Map<String, dynamic> json) => Password(
    id: json['id'],
    site: json['site'],
    username: json['username'],
    password: json['password'],
    pinned: json['pinned'],
  );

  Map<String, dynamic> toMap(String userPin) {
    String encPwd = encryptPassword(userPin, password);
    return {
      'id': id,
      'site': site,
      'username': username,
      'password': encPwd,
      'pinned': pinned,
    };
  }
}
