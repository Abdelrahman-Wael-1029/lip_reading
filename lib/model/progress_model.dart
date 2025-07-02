/// Progress status enumeration
enum ProgressStatus {
  idle,
  uploading,
  processing,
  completed,
  failed,
  cancelled,
}

/// Progress step enumeration
enum ProgressStep {
  // Flutter steps
  initializing,
  uploading,

  // Backend steps
  backendInitializing,
  videoPreprocessing,
  analyzingFrames,
  detectingLandmarks,
  extractingMouth,
  runningInference,
  aiEnhancement,
  completed,
}

extension ProgressStepExtension on ProgressStep {
  String get displayName {
    switch (this) {
      case ProgressStep.initializing:
        return 'Initializing...';
      case ProgressStep.uploading:
        return 'Uploading to server...';
      case ProgressStep.backendInitializing:
        return 'Starting processing...';
      case ProgressStep.videoPreprocessing:
        return 'Preprocessing video...';
      case ProgressStep.analyzingFrames:
        return 'Analyzing video frames...';
      case ProgressStep.detectingLandmarks:
        return 'Detecting face landmarks...';
      case ProgressStep.extractingMouth:
        return 'Extracting mouth regions...';
      case ProgressStep.runningInference:
        return 'Running lip reading...';
      case ProgressStep.aiEnhancement:
        return 'Enhancing with AI...';
      case ProgressStep.completed:
        return 'Completed successfully!';
    }
  }

  double get progressValue {
    switch (this) {
      case ProgressStep.initializing:
        return 0;
      case ProgressStep.uploading:
        return 25;
      case ProgressStep.backendInitializing:
        return 50;
      case ProgressStep.videoPreprocessing:
        return 60;
      case ProgressStep.analyzingFrames:
        return 65;
      case ProgressStep.detectingLandmarks:
        return 70;
      case ProgressStep.extractingMouth:
        return 75;
      case ProgressStep.runningInference:
        return 85;
      case ProgressStep.aiEnhancement:
        return 90;
      case ProgressStep.completed:
        return 100;
    }
  }
}

/// Progress model class
class ProgressModel {
  final String taskId;
  final ProgressStatus status;
  final ProgressStep currentStep;
  final double progress; // 0-100
  final String message;
  final String? errorMessage;
  final DateTime? startTime;
  final DateTime? endTime;
  final Map<String, dynamic>? result;
  final double? elapsedTime;

  const ProgressModel({
    required this.taskId,
    required this.status,
    required this.currentStep,
    required this.progress,
    required this.message,
    this.errorMessage,
    this.startTime,
    this.endTime,
    this.result,
    this.elapsedTime,
  });

  /// Create from backend progress data
  factory ProgressModel.fromBackendData(
      String taskId, Map<String, dynamic> data) {
    final status = _parseStatus(data['status'] as String?);
    final message = data['current_step'] as String? ?? '';
    final progress = _parseStepFromMessage(message).progressValue;

    // Extract error message more comprehensively
    String? errorMessage;
    if (data.containsKey('error') && data['error'] != null) {
      errorMessage = data['error'].toString();
    } else if (status == ProgressStatus.failed && message.isNotEmpty) {
      // If status is failed but no explicit error, use the message
      errorMessage = message;
    }

    return ProgressModel(
      taskId: taskId,
      status: status,
      currentStep: _parseStepFromMessage(message),
      progress: progress,
      message: message,
      errorMessage: errorMessage,
      elapsedTime: (data['elapsed_time'] as num?)?.toDouble(),
      result: data['result'] as Map<String, dynamic>?,
    );
  }

  /// Copy with updated values
  factory ProgressModel.create({
    required String taskId,
    ProgressStatus? status,
    ProgressStep? currentStep,
    String? message,
    String? errorMessage,
  }) {
    if (message != null) {
      final step = currentStep ?? _parseStepFromMessage(message);
      return ProgressModel(
        taskId: taskId,
        status: status ?? ProgressStatus.uploading,
        currentStep: step,
        progress: step.progressValue,
        message: message,
        errorMessage: errorMessage,
        startTime: DateTime.now(),
      );
    }
    else {
      return ProgressModel(
        taskId: taskId,
        status: status ?? ProgressStatus.idle,
        currentStep: currentStep ?? ProgressStep.initializing,
        progress: 0.0,
        message: 'Preparing...',
        errorMessage: errorMessage,
        startTime: DateTime.now(),
      );
    }
  }

  /// Check if processing is in progress
  bool get isProcessing {
    return status == ProgressStatus.uploading ||
        status == ProgressStatus.processing;
  }

  /// Check if processing is complete
  bool get isCompleted => status == ProgressStatus.completed;

  /// Check if processing failed
  bool get isFailed => status == ProgressStatus.failed;

  /// Get estimated time remaining
  String get estimatedTimeRemaining {
    if (elapsedTime == null || progress <= 0) return 'Calculating...';

    final remainingProgress = 100 - progress;
    final rate = progress / elapsedTime!;
    final estimatedSeconds = remainingProgress / rate;

    if (estimatedSeconds < 60) {
      return '${estimatedSeconds.round()}s remaining';
    } else {
      final minutes = (estimatedSeconds / 60).round();
      return '${minutes}m remaining';
    }
  }

  /// Parse status from string
  static ProgressStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'processing':
        return ProgressStatus.processing;
      case 'completed':
        return ProgressStatus.completed;
      case 'failed':
        return ProgressStatus.failed;
      case 'cancelled':
        return ProgressStatus.cancelled;
      default:
        return ProgressStatus.processing;
    }
  }

  /// Parse step from backend message
  static ProgressStep _parseStepFromMessage(String message) {
    final lowercaseMessage = message.toLowerCase();

    // Handle explicit failure states
    if (lowercaseMessage.contains('failed') ||
        lowercaseMessage.contains('error')) {
      return ProgressStep.completed; // Use completed to show final state
    }

    if (lowercaseMessage.contains('initializing') ||
        lowercaseMessage.contains('starting')) {
      return ProgressStep.backendInitializing;
    }

    if (lowercaseMessage.contains('uploading') ||
        lowercaseMessage.contains('upload')) {
      return ProgressStep.uploading;
    }

    if (lowercaseMessage.contains('preprocess')) {
      return ProgressStep.videoPreprocessing;
    }

    if (lowercaseMessage.contains('analyzing') ||
        lowercaseMessage.contains('frames')) {
      return ProgressStep.analyzingFrames;
    }

    if (lowercaseMessage.contains('landmark') ||
        lowercaseMessage.contains('detecting')) {
      return ProgressStep.detectingLandmarks;
    }

    if (lowercaseMessage.contains('mouth') ||
        lowercaseMessage.contains('extracting')) {
      return ProgressStep.extractingMouth;
    }

    if (lowercaseMessage.contains('inference') ||
        lowercaseMessage.contains('lip reading')) {
      return ProgressStep.runningInference;
    }

    if (lowercaseMessage.contains('enhancement') ||
        lowercaseMessage.contains('ai')) {
      return ProgressStep.aiEnhancement;
    }

    if (lowercaseMessage.contains('completed') ||
        lowercaseMessage.contains('success')) {
      return ProgressStep.completed;
    }

    return ProgressStep.initializing;
  }

  @override
  String toString() {
    return 'ProgressModel(taskId: $taskId, status: $status, progress: $progress%, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProgressModel &&
        other.taskId == taskId &&
        other.status == status &&
        other.currentStep == currentStep &&
        other.progress == progress &&
        other.message == message;
  }

  @override
  int get hashCode {
    return taskId.hashCode ^
        status.hashCode ^
        currentStep.hashCode ^
        progress.hashCode ^
        message.hashCode;
  }
}
