// lib/services/execution_engine.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cell.dart';
import '../services/math_engine.dart';
import '../providers/math_engine_provider.dart';

class ExecutionEngine {
  final MathEngine mathEngine;
  Map<String, dynamic> globalScope = {};

  ExecutionEngine(this.mathEngine);

  Future<EvaluationResult> executeCell(Cell cell) async {
    if (cell.type != CellType.math) {
      return EvaluationResult(
        success: false,
        error: 'Not a math cell',
        type: ResultType.error,
      );
    }

    cell.isExecuting = true;

    try {
      final result = await mathEngine.evaluate(
        cell.content,
        scope: {...globalScope},
      );

      // Update global scope with any new variables
      if (result.success && result.type == ResultType.object) {
        globalScope.addAll(result.result as Map<String, dynamic>);
      }

      return result;
    } catch (e) {
      return EvaluationResult(
        success: false,
        error: e.toString(),
        type: ResultType.error,
      );
    } finally {
      cell.isExecuting = false;
    }
  }

  Future<List<EvaluationResult>> executeAllCells(List<Cell> cells) async {
    final results = <EvaluationResult>[];
    globalScope.clear();

    for (final cell in cells) {
      if (cell.type == CellType.math) {
        final result = await executeCell(cell);
        results.add(result);
      }
    }

    return results;
  }

  void clearScope() {
    globalScope.clear();
  }
}

final executionEngineProvider = Provider<ExecutionEngine>((ref) {
  final mathEngine = ref.watch(mathEngineProvider);
  return ExecutionEngine(mathEngine);
});
