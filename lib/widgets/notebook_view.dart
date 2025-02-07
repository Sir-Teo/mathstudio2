import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cell.dart';
import '../providers/notebook_state.dart'; // Use the NotebookStateNotifier provider only
import '../services/math_engine.dart';

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
              return CellWidget(cell: cell);
            },
          ),
          if (notebookState.isExecuting)
            const Center(child: CircularProgressIndicator()),
          if (notebookState.error != null)
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.red.withOpacity(0.1),
              child: Text(
                notebookState.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      // Floating Action Button to add a new cell
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Create a new cell. You can choose the type and initial content as needed.
          // Here, we create a math cell with empty content.
          final newCell = Cell(
            content: '',
            type: CellType.math,
          );

          // Add the new cell to the notebook.
          ref.read(notebookStateProvider.notifier).addCell(newCell);
        },
        child: const Icon(Icons.add),
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
              // Execute a single cell using the NotebookStateNotifier
              ref.read(notebookStateProvider.notifier).executeCell(cell.id);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // Remove the cell via NotebookStateNotifier
              ref.read(notebookStateProvider.notifier).removeCell(cell.id);
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
          // Update the cell content via NotebookStateNotifier
          ref.read(notebookStateProvider.notifier).updateCell(
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
