// lib/providers/notebook_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notebook.dart';
import '../models/cell.dart';

class NotebookNotifier extends StateNotifier<Notebook> {
  NotebookNotifier() : super(Notebook(title: 'Math Notebook'));

  void addCell(Cell cell, [int? index]) {
    state = Notebook(
      id: state.id,
      title: state.title,
      cells: [...state.cells]..insert(index ?? state.cells.length, cell),
      metadata: state.metadata,
    );
  }

  void removeCell(String cellId) {
    state = Notebook(
      id: state.id,
      title: state.title,
      cells: state.cells.where((cell) => cell.id != cellId).toList(),
      metadata: state.metadata,
    );
  }

  void updateCell(String cellId, Cell newCell) {
    state = Notebook(
      id: state.id,
      title: state.title,
      cells: state.cells.map(
        (cell) => cell.id == cellId ? newCell : cell,
      ).toList(),
      metadata: state.metadata,
    );
  }


  void updateTitle(String newTitle) {
    state = Notebook(
      id: state.id,
      title: newTitle,
      cells: state.cells,
      metadata: state.metadata,
    );
  }
}

final notebookProvider =
    StateNotifierProvider<NotebookNotifier, Notebook>((ref) {
  return NotebookNotifier();
});