// lib/models/code_cell.dart
import 'cell.dart';

class CodeCell extends Cell {
  Map<String, dynamic>? scope;
  String? language;

  CodeCell({
    required String content,
    this.scope,
    this.language = 'javascript',
    dynamic output,
  }) : super(
          content: content,
          type: CellType.code,
          output: output,
        );

  @override
  CodeCell copyWith({
    String? content,
    bool? isExecuting,
    dynamic output,
    CellType? type,
  }) {
    return CodeCell(
      content: content ?? this.content,
      scope:
          this.scope, // No way to change scope here unless the parent passes it
      language: this.language, // Same with language
      output: output ?? this.output,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['language'] = language;
    json['scope'] = scope;
    return json;
  }

  factory CodeCell.fromJson(Map<String, dynamic> json) {
    return CodeCell(
      content: json['content'],
      language: json['language'],
      scope: json['scope'] != null
          ? Map<String, dynamic>.from(json['scope'])
          : null,
      output: json['output'],
    );
  }
}
