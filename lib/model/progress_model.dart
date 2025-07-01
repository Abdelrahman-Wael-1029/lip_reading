/// Progress status enumeration
enum ProgressStatus {
  idle,
  compressing,
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
  compressing,
  uploading,

  // Backend steps
  backendInitializing,
  videoServiceInit,
  videoPreprocessing,
  analyzingFrames,
  detectingLandmarks,
  extractingMouth,
  runningInference,
  aiEnhancement,
  finalizing,
  completed,
}

extension ProgressStepExtension on ProgressStep {
  String get displayName {
    switch (this) {
      case ProgressStep.initializing:
        return 'Initializing...';
      case ProgressStep.compressing:
        return 'Compressing video...';
      case ProgressStep.uploading:
        return 'Uploading to server...';
      case ProgressStep.backendInitializing:
        return 'Starting processing...';
      case ProgressStep.videoServiceInit:
        return 'Initializing AI model...';
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
      case ProgressStep.finalizing:
        return 'Finalizing results...';
      case ProgressStep.completed:
        return 'Completed successfully!';
    }
  }

  int get progressValue {
    switch (this) {
      case ProgressStep.initializing:
        return 0;
      case ProgressStep.compressing:
        return 10;
      case ProgressStep.uploading:
        return 20;
      case ProgressStep.backendInitializing:
        return 30;
      case ProgressStep.videoServiceInit:
        return 35;
      case ProgressStep.videoPreprocessing:
        return 40;
      case ProgressStep.analyzingFrames:
        return 50;
      case ProgressStep.detectingLandmarks:
        return 60;
      case ProgressStep.extractingMouth:
        return 70;
      case ProgressStep.runningInference:
        return 80;
      case ProgressStep.aiEnhancement:
        return 90;
      case ProgressStep.finalizing:
        return 95;
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

  /// Create initial progress model
  factory ProgressModel.initial(String taskId) {
    return ProgressModel(
      taskId: taskId,
      status: ProgressStatus.idle,
      currentStep: ProgressStep.initializing,
      progress: 0.0,
      message: 'Preparing...',
      startTime: DateTime.now(),
    );
  }

  /// Create from backend progress data
  factory ProgressModel.fromBackendData(
      String taskId, Map<String, dynamic> data) {
    final status = _parseStatus(data['status'] as String?);
    final progress = (data['percentage'] as num?)?.toDouble() ?? 0.0;
    final message = data['current_step'] as String? ?? '';

    return ProgressModel(
      taskId: taskId,
      status: status,
      currentStep: _parseStepFromMessage(message),
      progress: progress,
      message: message,
      errorMessage: data['error'] as String?,
      elapsedTime: (data['elapsed_time'] as num?)?.toDouble(),
      result: data['result'] as Map<String, dynamic>?,
    );
  }

  /// Copy with updated values
  ProgressModel copyWith({
    String? taskId,
    ProgressStatus? status,
    ProgressStep? currentStep,
    double? progress,
    String? message,
    String? errorMessage,
    DateTime? startTime,
    DateTime? endTime,
    Map<String, dynamic>? result,
    double? elapsedTime,
  }) {
    return ProgressModel(
      taskId: taskId ?? this.taskId,
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      errorMessage: errorMessage ?? this.errorMessage,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      result: result ?? this.result,
      elapsedTime: elapsedTime ?? this.elapsedTime,
    );
  }

  /// Check if processing is in progress
  bool get isProcessing {
    return status == ProgressStatus.compressing ||
        status == ProgressStatus.uploading ||
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
      default:
        return ProgressStatus.processing;
    }
  }

  /// Parse step from backend message
  static ProgressStep _parseStepFromMessage(String message) {
    final lowercaseMessage = message.toLowerCase();

    if (lowercaseMessage.contains('initializing') ||
        lowercaseMessage.contains('starting')) {
      if (lowercaseMessage.contains('video service')) {
        return ProgressStep.videoServiceInit;
      }
      return ProgressStep.backendInitializing;
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

    if (lowercaseMessage.contains('finalizing') ||
        lowercaseMessage.contains('completing')) {
      return ProgressStep.finalizing;
    }

    if (lowercaseMessage.contains('completed') ||
        lowercaseMessage.contains('success')) {
      return ProgressStep.completed;
    }

    return ProgressStep.backendInitializing;
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
