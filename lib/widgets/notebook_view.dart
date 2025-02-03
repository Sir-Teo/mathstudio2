// lib/widgets/notebook_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cell.dart';
import '../providers/notebook_provider.dart';
import '../providers/notebook_state.dart';



// Update NotebookView widget to use EvaluationResult
class NotebookView extends ConsumerWidget {
  const NotebookView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notebookState = ref.watch(notebookStateProvider);
    final notebook = notebookState.notebook;

    return Scaffold(
      appBar: AppBar(
        title: Text(notebook.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: notebookState.isExecuting
                ? null
                : () {
                    ref.read(notebookStateProvider.notifier).executeAllCells();
                  },
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              ref.read(notebookStateProvider.notifier).clearExecutionState();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            itemCount: notebook.cells.length,
            itemBuilder: (context, index) {
              final cell = notebook.cells[index];
              return CellWidget(
                cell: cell,
                globalScope: notebookState.globalScope,
              );
            },
          ),
          if (notebookState.isExecuting)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (notebookState.lastResult?.success == false)
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.red.withOpacity(0.1),
              child: Text(
                notebookState.lastResult!.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}

class CellWidget extends ConsumerWidget {
  final Cell cell;

  const CellWidget({
    Key? key,
    required this.cell,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CellToolbar(cell: cell),
          CellContent(cell: cell),
          if (cell.output != null) CellOutput(cell: cell),
        ],
      ),
    );
  }
}

class CellToolbar extends ConsumerWidget {
  final Cell cell;

  const CellToolbar({
    Key? key,
    required this.cell,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Text('Cell Type: ${cell.type}'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () {
              // Execute cell
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

class CellContent extends ConsumerWidget {
  final Cell cell;

  const CellContent({
    Key? key,
    required this.cell,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        initialValue: cell.content,
        maxLines: null,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Enter ${cell.type} content...',
        ),
        onChanged: (value) {
          ref.read(notebookProvider.notifier).updateCell(
                cell.id,
                cell.copyWith(content: value),
              );
        },
      ),
    );
  }
}

class CellOutput extends StatelessWidget {
  final Cell cell;

  const CellOutput({
    Key? key,
    required this.cell,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[200],
      child: Text(
        cell.output.toString(),
        style: const TextStyle(
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
