// lib/services/math_engine.dart
import 'package:js/js.dart';
import 'dart:js_util';
import 'dart:async';

@JS('math')
external dynamic get mathJS;
external dynamic get windowJS;

class MathEngine {
  // Singleton instance
  static final MathEngine _instance = MathEngine._internal();
  factory MathEngine() => _instance;
  MathEngine._internal();

  // Store variables and their values
  final Map<String, dynamic> _variables = {};
  
  // Store user-defined functions
  final Map<String, String> _functions = {};

  // Initialize MathJS
  Future<void> initialize() async {
    // Load MathJS from CDN if needed
    await _loadMathJS();
  }

  Future<void> _loadMathJS() async {
    final script = '''
      if (typeof math === 'undefined') {
        const script = document.createElement('script');
        script.src = 'https://cdnjs.cloudflare.com/ajax/libs/mathjs/9.4.4/math.js';
        document.head.appendChild(script);
        await new Promise(resolve => script.onload = resolve);
      }
    ''';
    await promiseToFuture(callMethod(windowJS, 'eval', [script]));
  }

  // Evaluate mathematical expression
  Future<EvaluationResult> evaluate(String expression, {Map<String, dynamic>? scope}) async {
    try {
      final evaluationScope = {..._variables};
      if (scope != null) {
        evaluationScope.addAll(scope);
      }

      // Replace any user-defined functions in the expression
      String processedExpression = _replaceFunctions(expression);

      // Evaluate using MathJS
      final result = await promiseToFuture(callMethod(mathJS, 'evaluate', [
        processedExpression,
        jsify(evaluationScope),
      ]));

      return EvaluationResult(
        success: true,
        result: _convertJSResult(result),
        type: _getResultType(result),
      );
    } catch (e) {
      return EvaluationResult(
        success: false,
        error: e.toString(),
        type: ResultType.error,
      );
    }
  }

  // Define a variable
  void setVariable(String name, dynamic value) {
    _variables[name] = value;
  }

  // Get a variable value
  dynamic getVariable(String name) {
    return _variables[name];
  }

  // Define a function
  void defineFunction(String name, String expression) {
    _functions[name] = expression;
  }

  // Replace function calls with their definitions
  String _replaceFunctions(String expression) {
    String result = expression;
    _functions.forEach((name, def) {
      final regex = RegExp(r'\b' + name + r'\((.*?)\)');
      result = result.replaceAllMapped(regex, (match) {
        String args = match.group(1) ?? '';
        return '(' + def.replaceAll(RegExp(r'x'), args) + ')';
      });
    });
    return result;
  }

  // Convert JS result to Dart
  dynamic _convertJSResult(dynamic jsResult) {
    if (jsResult == null) return null;
    
    // Handle arrays
    if (jsResult is List) {
      return jsResult.map(_convertJSResult).toList();
    }
    
    // Handle objects
    if (jsResult is Map) {
      return jsResult.map((k, v) => MapEntry(k, _convertJSResult(v)));
    }
    
    // Handle numbers
    if (jsResult is num) {
      return jsResult;
    }
    
    // Handle strings
    return jsResult.toString();
  }

  ResultType _getResultType(dynamic result) {
    if (result == null) return ResultType.null_;
    if (result is num) return ResultType.number;
    if (result is bool) return ResultType.boolean;
    if (result is List) return ResultType.array;
    if (result is Map) return ResultType.object;
    return ResultType.string;
  }

  // Clear all variables and functions
  void clear() {
    _variables.clear();
    _functions.clear();
  }
}

enum ResultType {
  number,
  string,
  boolean,
  array,
  object,
  null_,
  error,
}

class EvaluationResult {
  final bool success;
  final dynamic result;
  final String? error;
  final ResultType type;

  EvaluationResult({
    required this.success,
    this.result,
    this.error,
    required this.type,
  });

  @override
  String toString() {
    if (!success) return 'Error: $error';
    return result?.toString() ?? 'null';
  }
}
