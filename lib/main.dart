// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/notebook_view.dart';

void main() {
  runApp(
    const ProviderScope(
      child: NotebookApp(),
    ),
  );
}

class NotebookApp extends StatelessWidget {
  const NotebookApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mathematical Notebook',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const NotebookView(),
    );
  }
}