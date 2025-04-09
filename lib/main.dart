import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:secret_keeper/screens/login_screen.dart';
import 'package:secret_keeper/services/database_helper.dart';
import 'package:secret_keeper/services/gdrive_helper.dart';

void main() async {
  await dotenv.load();
  final _ = await DatabaseHelper().database;
  final _ = await GdriveHelper.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secret Keeper',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LoginScreen(),
    );
  }
}
