// lib/widgets/math_cell_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'dart:async';
import '../models/cell.dart';
import '../services/math_engine.dart';
import '../providers/notebook_provider.dart';
import '../providers/math_engine_provider.dart';

class MathCellWidget extends ConsumerStatefulWidget {
  final MathCell cell;

  const MathCellWidget({
    Key? key,
    required this.cell,
  }) : super(key: key);

  @override
  MathCellWidgetState createState() => MathCellWidgetState();
}

class MathCellWidgetState extends ConsumerState<MathCellWidget> {
  bool _isEditing = false;
  late TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.cell.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _debouncedEvaluate(String value) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
    final mathEngine = ref.read(mathEngineProvider);
    final result = value.contains('=') 
        ? await mathEngine.processInput(value, scope: widget.cell.scope)
        : await mathEngine.evaluate(value, scope: widget.cell.scope);
      
    if (mounted) {
      ref.read(notebookProvider.notifier).updateCell(
        widget.cell.id,
        widget.cell.copyWith(
          content: value,
          output: result,
        ),
      );
    }
  });
}


  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MathCellToolbar(
            cell: widget.cell,
            isEditing: _isEditing,
            onEditToggle: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _controller,
                maxLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter mathematical expression...',
                ),
                onChanged: _debouncedEvaluate,
              ),
            )
          else
            InkWell(
              onTap: () {
                setState(() {
                  _isEditing = true;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Math.tex(
                  widget.cell.content,
                  textStyle: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          if (widget.cell.output != null)
            MathCellOutput(
              output: widget.cell.output!,
              expression: widget.cell.content,
              mathEngine: ref.read(mathEngineProvider),
            ),
        ],
      ),
    );
  }
}

class MathCellToolbar extends ConsumerWidget {
  final MathCell cell;
  final bool isEditing;
  final VoidCallback onEditToggle;

  const MathCellToolbar({
    Key? key,
    required this.cell,
    required this.isEditing,
    required this.onEditToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          const Text('Math'),
          const Spacer(),
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: onEditToggle,
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () async {
              final mathEngine = ref.read(mathEngineProvider);
              final result = widget.cell.content.contains('=') 
                  ? await mathEngine.processInput(widget.cell.content, scope: widget.cell.scope)
                  : await mathEngine.evaluate(widget.cell.content, scope: widget.cell.scope);
                  
              ref.read(notebookProvider.notifier).updateCell(
                widget.cell.id,
                widget.cell.copyWith(output: result),
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

class MathCellOutput extends StatelessWidget {
  final EvaluationResult output;
  final String expression;
  final MathEngine mathEngine;

  const MathCellOutput({
    Key? key,
    required this.output,
    required this.expression,
    required this.mathEngine,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!output.success) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          output.error ?? 'Unknown error',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    // Check if this is a plot command
    if (expression.trim().startsWith('plot(')) {
      // Extract the function to plot from between the parentheses
      final match = RegExp(r'plot\((.*)\)').firstMatch(expression);
      if (match != null) {
        String functionToPlot = match.group(1)?.trim() ?? '';
        
        // Replace ^ with pow() for proper parsing
        functionToPlot = functionToPlot.replaceAll('^', '**');
        
        // Add multiplication operator where implied
        functionToPlot = functionToPlot.replaceAll(RegExp(r'(\d)x'), r'$1*x');
        functionToPlot = functionToPlot.replaceAll(RegExp(r'x(\d)'), r'x*$1');
        
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: mathEngine.plot(functionToPlot),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(_formatComplexOutput(output.result)),
    );
  }

  String _formatComplexOutput(dynamic result) {
    if (result is List) {
      return '[${result.join(', ')}]';
    }
    if (result is Map) {
      return '{\n${result.entries.map((e) => '  ${e.key}: ${e.value}').join(',\n')}\n}';
    }
    return result.toString();
  }
}