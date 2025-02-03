// lib/models/notebook.dart
import 'cell.dart';
import 'package:uuid/uuid.dart';

class Notebook {
  final String id;
  String title;
  List<Cell> cells;
  DateTime createdAt;
  DateTime updatedAt;
  Map<String, dynamic> metadata;

  Notebook({
    String? id,
    required this.title,
    List<Cell>? cells,
    Map<String, dynamic>? metadata,
  }) :
    id = id ?? const Uuid().v4(),
    cells = cells ?? [],
    metadata = metadata ?? {},
    createdAt = DateTime.now(),
    updatedAt = DateTime.now();

  void addCell(Cell cell, [int? index]) {
    if (index != null) {
      cells.insert(index, cell);
    } else {
      cells.add(cell);
    }
    updatedAt = DateTime.now();
  }

  void removeCell(String cellId) {
    cells.removeWhere((cell) => cell.id == cellId);
    updatedAt = DateTime.now();
  }

  void updateCell(String cellId, Cell newCell) {
    final index = cells.indexWhere((cell) => cell.id == cellId);
    if (index != -1) {
      cells[index] = newCell;
      updatedAt = DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'cells': cells.map((cell) => cell.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory Notebook.fromJson(Map<String, dynamic> json) {
    return Notebook(
      id: json['id'],
      title: json['title'],
      cells: (json['cells'] as List)
          .map((cellJson) => Cell.fromJson(cellJson))
          .toList(),
      metadata: json['metadata'],
    )
      ..createdAt = DateTime.parse(json['createdAt'])
      ..updatedAt = DateTime.parse(json['updatedAt']);
  }
}