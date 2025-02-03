// lib/providers/math_engine_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/math_engine.dart';

final mathEngineProvider = Provider<MathEngine>((ref) {
  return MathEngine();
});
