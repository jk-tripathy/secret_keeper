import 'package:flutter/material.dart';

class AppColors {
  static const lavender = Color(0xFFD1C4E9);
  static const white = Colors.white;
  static const accent = Color(0xFF164F55);
}

extension AppColorsExtension on BuildContext {
  Color get lavender => AppColors.lavender;
  Color get white => AppColors.white;
  Color get accent => AppColors.accent;
}
