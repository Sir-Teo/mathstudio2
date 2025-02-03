// lib/services/execution_engine.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cell.dart';
import '../services/math_engine.dart';

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

// lib/providers/notebook_state.dart
class NotebookState {
  final Notebook notebook;
  final bool isExecuting;
  final Map<String, dynamic> globalScope;
  final EvaluationResult? lastResult;

  NotebookState({
    required this.notebook,
    this.isExecuting = false,
    Map<String, dynamic>? globalScope,
    this.lastResult,
  }) : globalScope = globalScope ?? {};

  NotebookState copyWith({
    Notebook? notebook,
    bool? isExecuting,
    Map<String, dynamic>? globalScope,
    EvaluationResult? lastResult,
  }) {
    return NotebookState(
      notebook: notebook ?? this.notebook,
      isExecuting: isExecuting ?? this.isExecuting,
      globalScope: globalScope ?? this.globalScope,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}

class NotebookStateNotifier extends StateNotifier<NotebookState> {
  final ExecutionEngine executionEngine;

  NotebookStateNotifier(this.executionEngine)
      : super(NotebookState(notebook: Notebook(title: 'Untitled Notebook')));

  Future<void> executeCell(String cellId) async {
    final cellIndex = state.notebook.cells.indexWhere((c) => c.id == cellId);
    if (cellIndex == -1) return;

    final cell = state.notebook.cells[cellIndex];
    
    state = state.copyWith(isExecuting: true);
    
    try {
      final result = await executionEngine.executeCell(cell);
      
      final updatedCell = cell.copyWith(
        output: result,
        isExecuting: false,
      );

      final updatedCells = List<Cell>.from(state.notebook.cells);
      updatedCells[cellIndex] = updatedCell;

      state = state.copyWith(
        notebook: state.notebook.copyWith(cells: updatedCells),
        globalScope: executionEngine.globalScope,
        isExecuting: false,
        lastResult: result,
      );
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        lastResult: EvaluationResult(
          success: false,
          error: e.toString(),
          type: ResultType.error,
        ),
      );
    }
  }

  Future<void> executeAllCells() async {
    state = state.copyWith(isExecuting: true);
    
    try {
      final results = await executionEngine.executeAllCells(state.notebook.cells);
      
      final updatedCells = state.notebook.cells.map((cell) {
        if (cell.type != CellType.math) return cell;
        
        final index = state.notebook.cells.indexOf(cell);
        return cell.copyWith(
          output: results[index],
          isExecuting: false,
        );
      }).toList();

      state = state.copyWith(
        notebook: state.notebook.copyWith(cells: updatedCells),
        globalScope: executionEngine.globalScope,
        isExecuting: false,
        lastResult: results.lastOrNull,
      );
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        lastResult: EvaluationResult(
          success: false,
          error: e.toString(),
          type: ResultType.error,
        ),
      );
    }
  }

  void clearExecutionState() {
    executionEngine.clearScope();
    state = state.copyWith(
      globalScope: {},
      lastResult: null,
    );
  }
}

final notebookStateProvider =
    StateNotifierProvider<NotebookStateNotifier, NotebookState>((ref) {
  final executionEngine = ref.watch(executionEngineProvider);
  return NotebookStateNotifier(executionEngine);
});
