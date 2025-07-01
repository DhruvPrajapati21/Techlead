import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Title provider
final appBarTitleProvider = StateProvider<String>((ref) => "Default Title");

// Gradient colors provider
final appBarGradientColorsProvider = StateProvider<List<Color>>((ref) => [
  Color(0xFF2F68AA), // Default gradient colors for Leave Info
  Color(0xFF025BB6),
]);
final customTitleWidgetProvider = StateProvider<Widget?>((ref) => null);
