import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notebook.dart';
import '../models/cell.dart';
import '../services/execution_engine.dart';
import '../services/math_engine.dart';

// lib/providers/notebook_state.dart
class NotebookState {
  final Notebook notebook;
  final bool isExecuting;
  final Map<String, dynamic> globalScope;
  final String? error;

  NotebookState({
    required this.notebook,
    this.isExecuting = false,
    Map<String, dynamic>? globalScope,
    this.error,
  }) : globalScope = globalScope ?? {};

  NotebookState copyWith({
    Notebook? notebook,
    bool? isExecuting,
    Map<String, dynamic>? globalScope,
    String? error,
  }) {
    return NotebookState(
      notebook: notebook ?? this.notebook,
      isExecuting: isExecuting ?? this.isExecuting,
      globalScope: globalScope ?? this.globalScope,
      error: error,
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
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        error: e.toString(),
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
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        error: e.toString(),
      );
    }
  }

  void clearExecutionState() {
    executionEngine.clearScope();
    state = state.copyWith(
      globalScope: {},
      error: null,
    );
  }
}

final notebookStateProvider =
    StateNotifierProvider<NotebookStateNotifier, NotebookState>((ref) {
  final executionEngine = ref.watch(executionEngineProvider);
  return NotebookStateNotifier(executionEngine);
});
