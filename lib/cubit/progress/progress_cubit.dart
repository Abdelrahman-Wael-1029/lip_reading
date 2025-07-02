import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:lip_reading/cubit/progress/progress_state.dart';
import 'package:lip_reading/model/progress_model.dart';
import 'package:lip_reading/service/api_service.dart';

class ProgressCubit extends Cubit<ProgressState> {
  ProgressCubit() : super(ProgressInitial());

  String? _currentTaskId;
  String? _backendTaskId;
  StreamSubscription? _progressSubscription;
  bool _isCancelled = false;

  /// Emit local progress for frontend operations (loading, compressing)
  void emitLocalProgress({
    required String taskId,
    ProgressStep? step,
    String? message,
    ProgressStatus status = ProgressStatus.processing,
  }) {
    final progress = ProgressModel.create(
      taskId: taskId,
      status: status,
      currentStep: step,
      message: message,
    );
    emit(ProgressLoading(progress));
  }

  /// Start the complete transcription process with progress tracking
  Future<void> startTranscription({
    required File? videoFile,
    required String modelName,
    bool diacritized = false,
    String? fileHash,
    String? videoUrl, // Firebase storage URL for history videos
    bool enhance = false,
    bool includeSummary = false,
    bool includeTranslation = false,
    String targetLanguage = "English",
    String? existingTaskId, // Allow continuing from existing local processing
  }) async {
    try {
      _isCancelled = false;

      // Use existing task ID or generate new one
      final taskId = existingTaskId ?? DateTime.now().millisecondsSinceEpoch.toString();
      _currentTaskId = taskId;

      // If no existing task ID, start with initial progress
      if (existingTaskId == null) {
        emitLocalProgress(taskId: taskId);
      }

      // Step 2: Upload and start backend processing
      await _uploadAndProcess(
        file: videoFile,
        modelName: modelName,
        diacritized: diacritized,
        fileHash: fileHash,
        videoUrl: videoUrl,
        enhance: enhance,
        includeSummary: includeSummary,
        includeTranslation: includeTranslation,
        targetLanguage: targetLanguage,
        taskId: taskId,
      );
    } catch (e) {
      debugPrint('[ProgressCubit] Error in startTranscription: $e');
      if (_currentTaskId != null) {
        final errorProgress = ProgressModel.create(
          taskId: _currentTaskId!,
          status: ProgressStatus.failed,
          currentStep: ProgressStep.initializing,
          message: 'Failed to start transcription',
        );
        emit(ProgressFailed(errorProgress, e.toString()));
      }
    }
  }

  /// Upload file and start backend processing
  Future<void> _uploadAndProcess({
    required File? file,
    required String modelName,
    bool diacritized = false,
    String? fileHash,
    String? videoUrl, // Firebase storage URL for history videos
    bool enhance = false,
    bool includeSummary = false,
    bool includeTranslation = false,
    String targetLanguage = "English",
    required String taskId,
  }) async {
    try {
      // Update progress to uploading
      final uploadingProgress = ProgressModel.create(
        taskId: taskId,
        currentStep: ProgressStep.uploading,
        message: 'Uploading to server...',
      );
      emit(ProgressLoading(uploadingProgress));

      if (_isCancelled) return;

      // Start transcription and get backend task ID
      final backendTaskId = await ApiService.startTranscription(
        file: file,
        modelName: modelName,
        dia: diacritized,
        fileHash: fileHash,
        videoUrl: videoUrl,
        enhance: enhance,
        includeSummary: includeSummary,
        includeTranslation: includeTranslation,
        targetLanguage: targetLanguage
      );

      // Store backend task ID for cancellation
      _backendTaskId = backendTaskId;

      if (_isCancelled) return;

      // Start streaming backend progress
      await _streamBackendProgress(backendTaskId, taskId);
    } catch (e) {
      debugPrint('[ProgressCubit] Upload/Process error: $e');
      final errorProgress = ProgressModel.create(
        taskId: taskId,
        status: ProgressStatus.failed,
        currentStep: ProgressStep.uploading,
        message: 'Upload failed',
      );
      emit(ProgressFailed(errorProgress, e.toString()));
    }
  }

  /// Stream progress from backend
  Future<void> _streamBackendProgress(
      String backendTaskId, String frontendTaskId) async {
    try {
      // Update to processing status
      final processingProgress = ProgressModel.create(
        taskId: frontendTaskId,
        status: ProgressStatus.processing,
        message: 'Starting backend processing...',
      );
      emit(ProgressLoading(processingProgress));

      if (_isCancelled) return;

      // Start streaming progress
      _progressSubscription = ApiService.streamProgress(backendTaskId).listen(
        (backendProgress) {
          if (_isCancelled) return;

          if (backendProgress.status == ProgressStatus.completed) {
            emit(ProgressCompleted(
                backendProgress, backendProgress.result ?? {}));
            _cleanup(backendTaskId);
          } else if (backendProgress.status == ProgressStatus.failed) {
            final errorMessage =
                backendProgress.errorMessage ?? 'Unknown error occurred';
            debugPrint(
                '[ProgressCubit] Backend processing failed: $errorMessage');
            debugPrint(
                '[ProgressCubit] Progress details: ${backendProgress.toString()}');

            emit(ProgressFailed(backendProgress, errorMessage));
            _cleanup(backendTaskId);
          } else {
            emit(ProgressLoading(backendProgress));
          }
        },
        onError: (error) {
          debugPrint('[ProgressCubit] Stream error: $error');
          debugPrint('[ProgressCubit] Stream error type: ${error.runtimeType}');

          if (!_isCancelled) {
            final errorMessage = error.toString();
            final errorProgress = ProgressModel.create(
              taskId: frontendTaskId,
              status: ProgressStatus.failed,
              message: 'Connection lost',
              errorMessage: errorMessage,
            );
            emit(ProgressFailed(errorProgress, errorMessage));
            _cleanup(backendTaskId);
          }
        },
        onDone: () {
          debugPrint('[ProgressCubit] Stream completed');
          _cleanup(backendTaskId);
        },
      );
    } catch (e) {
      debugPrint('[ProgressCubit] Backend streaming error: $e');
      final errorProgress = ProgressModel.create(
        taskId: frontendTaskId,
        status: ProgressStatus.failed,
        message: 'Backend connection failed',
      );
      emit(ProgressFailed(errorProgress, e.toString()));
    }
  }

  /// Cancel current transcription
  Future<void> cancelTranscription() async {
    _isCancelled = true;

    if (_currentTaskId != null) {
      // Cancel backend task if it exists
      if (_backendTaskId != null) {
        try {
          debugPrint(
              '[ProgressCubit] Cancelling backend task: $_backendTaskId');
          await ApiService.cancelTask(_backendTaskId!);
        } catch (e) {
          debugPrint('[ProgressCubit] Error cancelling backend task: $e');
          // Continue with local cancellation even if backend cancellation fails
        }
      }

      final cancelledProgress = ProgressModel.create(
        taskId: _currentTaskId!,
        status: ProgressStatus.cancelled,
        message: 'Transcription cancelled',
      );
      emit(ProgressCancelled(cancelledProgress));

      _cleanup(null);
    }
  }

  /// Reset progress state
  void resetProgress() {
    _cleanup(null);
    emit(ProgressInitial());
  }

  /// Cleanup resources
  void _cleanup(String? backendTaskId) {
    _progressSubscription?.cancel();
    _progressSubscription = null;

    // Note: Backend handles its own cleanup automatically
    // No manual cleanup endpoint available

    _currentTaskId = null;
    _backendTaskId = null;
  }

  @override
  Future<void> close() {
    _cleanup(null);
    return super.close();
  }
}
