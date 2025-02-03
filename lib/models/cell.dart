// lib/models/cell.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';


enum CellType {
  text,
  code,
  math,
  output
}

class Cell {
  final String id;
  String content;
  CellType type;
  DateTime createdAt;
  DateTime updatedAt;
  bool isExecuting;
  dynamic output;

  Cell({
    String? id,
    required this.content,
    required this.type,
    dynamic this.output,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = DateTime.now(),
    updatedAt = DateTime.now(),
    isExecuting = false;

  Cell copyWith({
    String? content,
    CellType? type,
    dynamic output,
    bool? isExecuting,
  }) {
    return Cell(
      id: this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      output: output ?? this.output,
    )..updatedAt = DateTime.now()
      ..isExecuting = isExecuting ?? this.isExecuting;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.toString(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'output': output,
    };
  }

  factory Cell.fromJson(Map<String, dynamic> json) {
    return Cell(
      id: json['id'],
      content: json['content'],
      type: CellType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      output: json['output'],
    )
      ..createdAt = DateTime.parse(json['createdAt'])
      ..updatedAt = DateTime.parse(json['updatedAt']);
  }
}
