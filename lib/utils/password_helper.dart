import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:secret_keeper/models/password.dart';
import 'package:secret_keeper/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordHelper {
  static String? hashedMasterPassword;
  static SharedPreferences? prefs;
  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    if (prefs!.getBool('isMasterPasswordSet') == null) {
      await prefs!.setBool('isMasterPasswordSet', false);
    }
    if (prefs!.getString('masterPassword') == null) {
      await prefs!.setString('masterPassword', '');
    }
    if (prefs!.getBool('isBiometricEnabled') == null) {
      await prefs!.setBool('isBiometricEnabled', false);
    }
    hashedMasterPassword = prefs!.getString('masterPassword') ?? '';
  }

  static void setAndSaveMasterPassword(String masterPassword) async {
    final hashedMasterPassword =
        sha256.convert(utf8.encode(masterPassword)).toString();
    await prefs!.setBool('isMasterPasswordSet', true);
    await prefs!.setString('masterPassword', hashedMasterPassword);

    await init();
  }

  static String getMasterPassword() {
    if (hashedMasterPassword == null) {
      throw Exception('Master password not set');
    } else {
      return hashedMasterPassword!;
    }
  }

  static void clearMasterPassword() async {
    await prefs!.setBool('isMasterPasswordSet', false);
    await prefs!.setString('masterPassword', '');
  }

  static Future<bool> validateMasterPassword(String inputPassword) async {
    final hashedMasterPassword = prefs!.getString('masterPassword');
    final hashedInputPassword =
        sha256.convert(utf8.encode(inputPassword)).toString();
    return hashedMasterPassword == hashedInputPassword;
  }

  static String encryptPassword(String masterPassword, String password) {
    if (masterPassword.length > 32) {
      masterPassword = masterPassword.substring(0, 32);
    } else if (masterPassword.length < 32) {
      masterPassword = masterPassword.padRight(32, '0');
    }
    final key = encrypt.Key.fromUtf8(masterPassword);
    final iv = encrypt.IV.allZerosOfLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(password, iv: iv).base64.toString();
    return encrypted;
  }

  static String decryptPassword(String masterPassword, String password) {
    if (masterPassword.length > 32) {
      masterPassword = masterPassword.substring(0, 32);
    } else if (masterPassword.length < 32) {
      masterPassword = masterPassword.padRight(32, '0');
    }
    final key = encrypt.Key.fromUtf8(masterPassword);
    final iv = encrypt.IV.allZerosOfLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final decrypted = encrypter.decrypt64(password, iv: iv);
    return decrypted;
  }

  static Future<void> savePassword(
    String masterPassword,
    String site,
    String username,
    String password,
  ) async {
    Password newPassword = Password(
      site: site,
      username: username,
      password: password,
    );

    await DatabaseHelper().insertPassword(masterPassword, newPassword);
  }

  static Future<void> updatePassword(
    String masterPassword,
    int id,
    String site,
    String username,
    String password,
    int pinned,
  ) async {
    Password updatedPassword = Password(
      id: id,
      site: site,
      username: username,
      password: password,
      pinned: pinned,
    );

    await DatabaseHelper().updatePassword(masterPassword, updatedPassword);
  }
}
