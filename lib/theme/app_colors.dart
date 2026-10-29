import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF375BFF);
  static const primaryDeep = Color(0xFF253EB6);
  static const primarySoft = Color(0xFFEEF2FF);
  static const text = Color(0xFF111111);
  static const textSub = Color(0xFF7B8495);
  static const background = Color(0xFFF5F7FB);
  static const divider = Color(0xFFE4E8F0);
  static const positive = Color(0xFF20A67A);
  static const negative = Color(0xFFE5484D);
  static const toast = Color(0x99242628);
}

TextStyle pretendard(double size, FontWeight weight, Color color) => TextStyle(
  fontFamily: 'Pretendard',
  fontSize: size,
  fontWeight: weight,
  height: 1.45,
  color: color,
);
