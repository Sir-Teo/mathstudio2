// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/notebook_view.dart';
import 'services/math_engine.dart';
import 'models/cell.dart';
import 'providers/notebook_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize MathEngine
  final mathEngine = MathEngine();
  await mathEngine.initialize();

  runApp(
    ProviderScope(
      overrides: [
        // Initialize notebook with an empty cell
        notebookProvider.overrideWith((ref) => NotebookNotifier()
          ..addCell(Cell(
            content: '',
            type: CellType.math,
          )))
      ],
      child: const MathematicalNotebookApp(),
    ),
  );
}

class MathematicalNotebookApp extends StatelessWidget {
  const MathematicalNotebookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mathematical Notebook',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const NotebookView(),
    );
  }
}