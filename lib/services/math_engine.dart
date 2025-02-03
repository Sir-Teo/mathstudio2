// lib/services/math_engine.dart
import 'package:math_expressions/math_expressions.dart';
import 'dart:async';

class MathEngine {
  // Singleton instance
  static final MathEngine _instance = MathEngine._internal();
  factory MathEngine() => _instance;
  MathEngine._internal();

  // Parser for expressions
  final Parser _parser = Parser();

  // Store variables and their numeric values
  final Map<String, double> _variables = {};

  // Store user-defined functions (simple single-parameter functions)
  final Map<String, String> _functions = {};

  /// Initialize the math engine.
  /// For math_expressions, no async initialization is needed.
  Future<void> initialize() async {
    // No initialization required for math_expressions.
  }

  /// Evaluate a mathematical [expression] with an optional [scope] of variables.
  Future<EvaluationResult> evaluate(String expression,
      {Map<String, double>? scope}) async {
    try {
      // Create a context model and bind variables from the engine.
      final contextModel = ContextModel();

      // Bind engine-wide variables.
      _variables.forEach((key, value) {
        contextModel.bindVariable(Variable(key), Number(value));
      });

      // Bind any additional variables provided in the scope.
      if (scope != null) {
        scope.forEach((key, value) {
          contextModel.bindVariable(Variable(key), Number(value));
        });
      }

      // Replace any user-defined functions in the expression.
      String processedExpression = _replaceFunctions(expression);

      // Parse the processed expression.
      Expression exp = _parser.parse(processedExpression);

      // Evaluate the expression.
      double evalResult = exp.evaluate(EvaluationType.REAL, contextModel);

      return EvaluationResult(
        success: true,
        result: evalResult,
        type: ResultType.number,
      );
    } catch (e) {
      return EvaluationResult(
        success: false,
        error: e.toString(),
        type: ResultType.error,
      );
    }
  }

  /// Define or update a variable with a given [name] and numeric [value].
  void setVariable(String name, double value) {
    _variables[name] = value;
  }

  /// Retrieve the value of a variable by its [name].
  double? getVariable(String name) {
    return _variables[name];
  }

  /// Define a simple function by [name] with an [expression].
  /// The expression should be written in terms of a single parameter "x".
  /// For example: defineFunction('f', 'x^2 + 2*x + 1');
  void defineFunction(String name, String expression) {
    _functions[name] = expression;
  }

  /// Replace user-defined function calls in [expression] with their definitions.
  ///
  /// For example, if you have defined:
  /// ```dart
  /// defineFunction('f', 'x^2 + 2*x + 1');
  /// ```
  /// then a call like `f(3)` will be replaced by `(3^2 + 2*3 + 1)`.
  String _replaceFunctions(String expression) {
    String result = expression;
    _functions.forEach((name, def) {
      final regex = RegExp(r'\b' + name + r'\((.*?)\)');
      result = result.replaceAllMapped(regex, (match) {
        String args = match.group(1) ?? '';
        // Replace the parameter "x" in the function definition with the argument.
        return '(' + def.replaceAll(RegExp(r'\bx\b'), args) + ')';
      });
    });
    return result;
  }

  /// Clear all stored variables and user-defined functions.
  void clear() {
    _variables.clear();
    _functions.clear();
  }
}

/// Represents the type of evaluation result.
enum ResultType {
  number,
  string,
  boolean,
  array,
  object,
  null_,
  error,
}

/// Encapsulates the result of an evaluation.
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
