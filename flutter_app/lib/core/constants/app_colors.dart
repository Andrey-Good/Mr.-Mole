import 'package:flutter/material.dart';

class AppColors {
  static const Color gradientStart = Color(0xFF0D111E);
  static const Color gradientEnd = Color(0xFF1B264A);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientStart, gradientEnd],
  );

  static const LinearGradient reverseGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientEnd, gradientStart],
  );

  static const Color cardBackground = Color(0x4A364884);

  static const Color overlay = Color(0x66000000);
  static const Color overlayDark = Color(0x80000000);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFF2DDCC);
  static const Color textForDetail = Colors.white70;
  static const Color textOnLight = Color(0xFF0D111E);

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);

  static const Color riskLow = success; // Зеленый
  static const Color riskMedium = warning; // Оранжевый
  static const Color riskHigh = error; // Красный

  static const Color buttonPrimary = Color(0xFF273458);
  static const Color buttonText = textSecondary;

  static const Color iconPrimary = textPrimary;
  static const Color iconSecondary = textSecondary;

  static const Color cameraBackground = Colors.black;
  static const Color cameraOverlay = Colors.black;
  static const Color cameraFrame = Colors.white;
  static const Color captureButton = Colors.white;

  static const Color instructionBackground = Color(0x81F2DDCC);
  static const Color instructionText = Color(0xFF0D111E);

  static const Color transparent = Colors.transparent;
}
