// math_engine.dart
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:expressions/expressions.dart';

import 'plot_engine.dart';

/// Encapsulates the result of evaluating an expression.
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

/// The type of evaluation result.
enum ResultType {
  number,
  error,
  object,
}

class MathEngine {
  // Singleton instance.
  static final MathEngine _instance = MathEngine._internal();
  factory MathEngine() => _instance;
  MathEngine._internal();

  /// A map for storing variables (e.g. x -> 5.0).
  final Map<String, double> _variables = {};

  /// A map for storing user-defined function definitions: (fnName -> expressionString).
  /// For example: `f` -> `"x^2"`.
  final Map<String, String> _functionStrings = {};

  /// (Optional) asynchronous initialization if needed.
  Future<void> initialize() async {
    // No async initialization for this example.
  }

  /// Clears all stored variables and user-defined functions.
  void clear() {
    _variables.clear();
    _functionStrings.clear();
  }

  /// Define or update a variable directly.
  void setVariable(String name, double value) {
    _variables[name] = value;
  }

  /// Retrieve the value of a variable, or null if not found.
  double? getVariable(String name) => _variables[name];

  /// Define a simple single-parameter function f(x).
  /// The [expression] should be in terms of `x`, for example: "x^2 + 1".
  void defineFunction(String name, String expression) {
    _functionStrings[name] = expression;
  }

  /// Processes user input that might be an assignment (e.g. "x = 5 + 2")
  /// or just an expression (e.g. "3 + x").
  /// For assignment, store the result in [_variables].
  /// Otherwise, evaluate the expression directly.
  Future<EvaluationResult> processInput(
    String input, {
    Map<String, double>? scope,
  }) async {
    try {
      // Check if it contains '=' → potential assignment
      if (input.contains('=')) {
        final parts = input.split('=');
        if (parts.length != 2) {
          return EvaluationResult(
            success: false,
            error: "Invalid assignment format",
            type: ResultType.error,
          );
        }
        final variableName = parts[0].trim();
        final expressionString = parts[1].trim();

        // Evaluate the right-hand side
        final result = await evaluate(expressionString, scope: scope);

        if (!result.success) {
          return result; // forward any evaluation error
        }
        if (result.result is num) {
          setVariable(variableName, (result.result as num).toDouble());
          return EvaluationResult(
            success: true,
            result: result.result,
            type: ResultType.number,
          );
        } else {
          return EvaluationResult(
            success: false,
            error: "Right-hand side did not evaluate to a number.",
            type: ResultType.error,
          );
        }
      } else {
        // No assignment → just evaluate
        return await evaluate(input, scope: scope);
      }
    } catch (e) {
      return EvaluationResult(
        success: false,
        error: e.toString(),
        type: ResultType.error,
      );
    }
  }

  /// Evaluate a math expression string and return the result.
  /// This method expects an expression only, no assignment operator '='.
  /// Scope variables can optionally override or supplement stored variables.
  ///
  /// NOTE: If you truly want '^' to mean exponent, you'll likely need to
  /// transform it to `pow(...)` or handle it some other way. For now, we
  /// just keep '^' as-is and let `expressions` treat it as XOR.
  Future<EvaluationResult> evaluate(
    String expressionString, {
    Map<String, double>? scope,
  }) async {
    // Quick check: do not allow '=' in this expression-eval method.
    if (expressionString.contains('=')) {
      return EvaluationResult(
        success: false,
        error: "Invalid usage: '=' found. Use processInput() for assignments.",
        type: ResultType.error,
      );
    }

    try {
      // Create the expression
      // (Optional) For exponent: transform '^' → 'pow(...)' or do something else.
      final cleanString = expressionString;
      final expr = Expression.parse(cleanString);

      // Build the context
      final context = _buildContext(scope);

      // Evaluate with the new ExpressionEvaluator
      final evaluator = const ExpressionEvaluator();
      final result = evaluator.eval(expr, context);

      if (result is num) {
        return EvaluationResult(
          success: true,
          result: result.toDouble(),
          type: ResultType.number,
        );
      } else {
        return EvaluationResult(
          success: true,
          result: result,
          type: ResultType.object,
        );
      }
    } catch (err, stack) {
      debugPrint("Evaluation error: $err\n$stack");
      return EvaluationResult(
        success: false,
        error: err.toString(),
        type: ResultType.error,
      );
    }
  }

  /// Builds a context map that includes:
  /// - math constants (pi, e)
  /// - built-in math functions (sin, cos, etc.)
  /// - stored variables
  /// - optionally scope overrides
  /// - user-defined functions
  Map<String, dynamic> _buildContext(Map<String, double>? scope) {
    // Start with some standard values
    final context = <String, dynamic>{
      'pi': math.pi,
      'e': math.e,

      // You can add built-in math functions as needed:
      'sin': (num x) => math.sin(x),
      'cos': (num x) => math.cos(x),
      'tan': (num x) => math.tan(x),
      'sqrt': (num x) => math.sqrt(x),
      'log': (num x) => math.log(x),
      'exp': (num x) => math.exp(x),
      // etc...

      // If you want exponent as pow:
      'pow': (num base, num exp) => math.pow(base, exp),
    };

    // Add stored variables
    for (final entry in _variables.entries) {
      context[entry.key] = entry.value;
    }

    // Add scope variables if provided
    if (scope != null) {
      for (final entry in scope.entries) {
        context[entry.key] = entry.value;
      }
    }

    // Add user-defined single-argument functions
    // For each functionName -> expressionString
    final evaluator = const ExpressionEvaluator();
    for (final entry in _functionStrings.entries) {
      final fname = entry.key;
      final fexprString = entry.value;
      final parsedExpr = Expression.parse(fexprString);

      // Store a closure that, when called with one argument x,
      // re-evaluates the user-defined expression using that x.
      context[fname] = (dynamic x) {
        // Merge x into the main context, so 'x' is accessible
        final localContext = Map<String, dynamic>.from(context)
          ..['x'] = x; // override or set x
        return evaluator.eval(parsedExpr, localContext);
      };
    }

    return context;
  }

  /// Example: Return a widget that plots a function of x.
  Widget plot(
    String function, {
    double width = 300,
    double height = 200,
    double start = -10,
    double end = 10,
    int points = 200,
  }) {
    final plotEngine = PlotEngine(this);
    return plotEngine.createPlot(
      function,
      width: width,
      height: height,
      start: start,
      end: end,
      points: points,
    );
  }
}
