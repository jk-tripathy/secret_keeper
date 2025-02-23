import 'package:secret_keeper/utils/password_helper.dart';

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

  Password copyWith(
    String masterPassword, {
    String? site,
    String? username,
    String? password,
    int? id,
    int? pinned,
  }) {
    String decPwd = PasswordHelper.decryptPassword(
      masterPassword,
      this.password,
    );
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
    String encPwd = PasswordHelper.encryptPassword(userPin, password);
    return {
      'id': id,
      'site': site,
      'username': username,
      'password': encPwd,
      'pinned': pinned,
    };
  }
}
