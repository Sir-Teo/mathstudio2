// lib/widgets/markdown_cell_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:google_fonts/google_fonts.dart';
import 'package:highlight/highlight.dart' show highlight;
import '../models/text_cell.dart';
import '../providers/notebook_provider.dart';

class MarkdownCellWidget extends ConsumerStatefulWidget {
  final TextCell cell;

  const MarkdownCellWidget({
    Key? key,
    required this.cell,
  }) : super(key: key);

  @override
  MarkdownCellWidgetState createState() => MarkdownCellWidgetState();
}

class MarkdownCellWidgetState extends ConsumerState<MarkdownCellWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.cell.content);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    final isEditing = _focusNode.hasFocus;
    ref.read(notebookProvider.notifier).updateCell(
          widget.cell.id,
          widget.cell.copyWith(isEditing: isEditing),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MarkdownCellToolbar(cell: widget.cell),
          if (widget.cell.isEditing)
            _buildEditor()
          else
            _buildMarkdownPreview(),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: null,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Enter markdown text...',
        ),
        style: GoogleFonts.firaCode(),
        onChanged: (value) {
          ref.read(notebookProvider.notifier).updateCell(
                widget.cell.id,
                widget.cell.copyWith(content: value),
              );
        },
      ),
    );
  }

  Widget _buildMarkdownPreview() {
    return InkWell(
      onTap: () {
        setState(() {
          _focusNode.requestFocus();
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: MarkdownBody(
          data: widget.cell.content,
          selectable: true,
          builders: {
            'code': CustomCodeBuilder(),
            'math': MathBuilder(),
          },
          extensionSet: md.ExtensionSet(
            // Block syntaxes:
            [
              const md.FencedCodeBlockSyntax(),
              const md.TableSyntax(),
              const BlockMathSyntax(),
            ],
            // Inline syntaxes:
            [
              ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
              InlineMathSyntax(),
            ],
          ),
        ),
      ),
    );
  }
}

class MarkdownCellToolbar extends ConsumerWidget {
  final TextCell cell;

  const MarkdownCellToolbar({
    Key? key,
    required this.cell,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          const Text('Markdown'),
          const Spacer(),
          IconButton(
            icon: Icon(cell.isEditing ? Icons.visibility : Icons.edit),
            onPressed: () {
              ref.read(notebookProvider.notifier).updateCell(
                    cell.id,
                    cell.copyWith(isEditing: !cell.isEditing),
                  );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              ref.read(notebookProvider.notifier).removeCell(cell.id);
            },
          ),
        ],
      ),
    );
  }
}

class CustomCodeBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final String language = element.attributes['class']?.split('-').last ?? '';
    final String code = element.textContent;

    // Apply syntax highlighting
    final highlighted = highlight.parse(code, language: language);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(8),
      child: SelectableText.rich(
        TextSpan(
          style: GoogleFonts.firaCode(fontSize: 14),
          children: _parseHighlightedCode(highlighted),
        ),
      ),
    );
  }

  List<TextSpan> _parseHighlightedCode(highlighted) {
    // Convert highlight.js spans to TextSpans
    return highlighted.nodes?.map<TextSpan>((node) {
          if (node.value == null) return const TextSpan();

          return TextSpan(
            text: node.value,
            style: TextStyle(
              color: _getColorForType(node.className ?? ''),
              fontWeight: node.className?.contains('bold') ?? false
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontStyle: node.className?.contains('italic') ?? false
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          );
        })?.toList() ??
        [TextSpan(text: highlighted.value ?? '')];
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'keyword':
        return Colors.blue[700]!;
      case 'string':
        return Colors.green[700]!;
      case 'number':
        return Colors.orange[700]!;
      case 'comment':
        return Colors.grey[600]!;
      default:
        return Colors.black87;
    }
  }
}

class InlineMathSyntax extends md.InlineSyntax {
  InlineMathSyntax() : super(r'\$([^$]+)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('math', match[1]!));
    return true;
  }
}

class BlockMathSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^(\$\$)(.*?)(\$\$)$', multiLine: true);

  const BlockMathSyntax();

  @override
  md.Node parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content)!;
    final math = match[2]!.trim();
    parser.advance();
    return md.Element('math', [md.Text(math)]);
  }
}

class MathBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Math.tex(
      element.textContent,
      textStyle: preferredStyle,
      mathStyle: MathStyle.text,
    );
  }
}
