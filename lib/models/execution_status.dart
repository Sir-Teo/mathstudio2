// lib/models/execution_status.dart
enum ExecutionStatus {
  pending,   // Cell hasn't been executed yet
  queued,    // Cell is queued for execution
  running,   // Cell is currently executing
  completed, // Cell execution completed successfully
  error,     // Cell execution failed
  cancelled  // Cell execution was cancelled
}

// Represents the type of output produced by cell execution
enum OutputType {
  none,
  text,
  number,
  plot,
  table,
  error,
  html,
  markdown
}

// Represents a cell execution result
class ExecutionResult {
  final bool success;
  final dynamic output;
  final OutputType outputType;
  final String? error;
  final Map<String, dynamic>? scope;
  final DateTime executedAt;
  final Duration executionTime;

  ExecutionResult({
    required this.success,
    this.output,
    this.outputType = OutputType.none,
    this.error,
    this.scope,
    DateTime? executedAt,
    this.executionTime = const Duration(),
  }) : executedAt = executedAt ?? DateTime.now();

  factory ExecutionResult.error(String errorMessage) {
    return ExecutionResult(
      success: false,
      error: errorMessage,
      outputType: OutputType.error,
    );
  }

  factory ExecutionResult.success(
    dynamic output, {
    OutputType? outputType,
    Map<String, dynamic>? scope,
    Duration? executionTime,
  }) {
    return ExecutionResult(
      success: true,
      output: output,
      outputType: outputType ?? _inferOutputType(output),
      scope: scope,
      executionTime: executionTime ?? const Duration(),
    );
  }

  static OutputType _inferOutputType(dynamic output) {
    if (output == null) return OutputType.none;
    if (output is num) return OutputType.number;
    if (output is String) return OutputType.text;
    // Add more type inference logic as needed
    return OutputType.text;
  }

  @override
  String toString() {
    if (!success) return 'Error: $error';
    if (output == null) return 'null';
    return output.toString();
  }
}

// Represents the execution state of a cell
class CellExecutionState {
  final String cellId;
  final ExecutionStatus status;
  final ExecutionResult? lastResult;
  final List<ExecutionResult> history;
  final int executionCount;

  CellExecutionState({
    required this.cellId,
    this.status = ExecutionStatus.pending,
    this.lastResult,
    List<ExecutionResult>? history,
    this.executionCount = 0,
  }) : history = history ?? [];

  CellExecutionState copyWith({
    ExecutionStatus? status,
    ExecutionResult? lastResult,
    List<ExecutionResult>? history,
    int? executionCount,
  }) {
    return CellExecutionState(
      cellId: cellId,
      status: status ?? this.status,
      lastResult: lastResult ?? this.lastResult,
      history: history ?? this.history,
      executionCount: executionCount ?? this.executionCount,
    );
  }

  bool get hasError => status == ExecutionStatus.error;
  bool get isRunning => status == ExecutionStatus.running;
  bool get isPending => status == ExecutionStatus.pending;
  bool get isComplete => status == ExecutionStatus.completed;
}

// Represents the execution queue
class ExecutionQueue {
  final List<String> queue;
  final String? currentlyExecuting;
  final bool isPaused;

  ExecutionQueue({
    List<String>? queue,
    this.currentlyExecuting,
    this.isPaused = false,
  }) : queue = queue ?? [];

  ExecutionQueue copyWith({
    List<String>? queue,
    String? currentlyExecuting,
    bool? isPaused,
  }) {
    return ExecutionQueue(
      queue: queue ?? this.queue,
      currentlyExecuting: currentlyExecuting ?? this.currentlyExecuting,
      isPaused: isPaused ?? this.isPaused,
    );
  }

  bool get isEmpty => queue.isEmpty && currentlyExecuting == null;
  bool get isProcessing => currentlyExecuting != null;
}

// Represents the global notebook execution state
class NotebookExecutionState {
  final Map<String, CellExecutionState> cellStates;
  final ExecutionQueue queue;
  final Map<String, dynamic> globalScope;
  final DateTime? lastExecutionTime;

  NotebookExecutionState({
    Map<String, CellExecutionState>? cellStates,
    ExecutionQueue? queue,
    Map<String, dynamic>? globalScope,
    this.lastExecutionTime,
  })  : cellStates = cellStates ?? {},
        queue = queue ?? ExecutionQueue(),
        globalScope = globalScope ?? {};

  NotebookExecutionState copyWith({
    Map<String, CellExecutionState>? cellStates,
    ExecutionQueue? queue,
    Map<String, dynamic>? globalScope,
    DateTime? lastExecutionTime,
  }) {
    return NotebookExecutionState(
      cellStates: cellStates ?? this.cellStates,
      queue: queue ?? this.queue,
      globalScope: globalScope ?? this.globalScope,
      lastExecutionTime: lastExecutionTime ?? this.lastExecutionTime,
    );
  }

  CellExecutionState? getCellState(String cellId) => cellStates[cellId];
  
  bool get isExecuting => queue.isProcessing || 
      cellStates.values.any((state) => state.isRunning);
}