//lib/models/text_cell.dart
import 'package:flutter/material.dart';
import 'cell.dart';

class TextCell extends Cell {
  bool isEditing;
  Map<String, String>? metadata;

  TextCell({
    required String content,
    this.isEditing = false,
    this.metadata,
  }) : super(
          content: content,
          type: CellType.text,
        );

  @override
  TextCell copyWith({
    String? content,
    // Include the base class parameters.
    bool? isExecuting, // not used by TextCell, but must be present.
    dynamic output,    // not used here either.
    CellType? type,    // again, not used.
    // Additional parameters for TextCell.
    bool? isEditing,
    Map<String, String>? metadata,
  }) {
    return TextCell(
      content: content ?? this.content,
      isEditing: isEditing ?? this.isEditing,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['metadata'] = metadata;
    return json;
  }

  factory TextCell.fromJson(Map<String, dynamic> json) {
    return TextCell(
      content: json['content'],
      metadata: Map<String, String>.from(json['metadata'] ?? {}),
    );
  }
}
