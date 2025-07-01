import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:lip_reading/cubit/progress/progress_state.dart';
import 'package:lip_reading/model/progress_model.dart';
import 'package:lip_reading/service/progress_service.dart';
import 'package:video_compress/video_compress.dart';

class ProgressCubit extends Cubit<ProgressState> {
  ProgressCubit() : super(ProgressInitial());

  String? _currentTaskId;
  StreamSubscription? _progressSubscription;
  bool _isCancelled = false;

  /// Start the complete transcription process with progress tracking
  Future<void> startTranscription({
    required File videoFile,
    required String modelName,
    bool diacritized = false,
    String? fileHash,
    bool enhance = false,
    bool includeSummary = false,
    bool includeTranslation = false,
    String targetLanguage = "English",
  }) async {
    try {
      _isCancelled = false;

      // Generate task ID
      final taskId = DateTime.now().millisecondsSinceEpoch.toString();
      _currentTaskId = taskId;

      // Start with initial progress
      final initialProgress = ProgressModel.initial(taskId);
      emit(ProgressLoading(initialProgress));

      File? processedFile = videoFile;

      // Step 1: Video Compression (if needed)
      if (fileHash == null) {
        await _compressVideo(videoFile, taskId);
        if (_isCancelled) return;

        // Use compressed file if compression was successful
        // Note: video_compress plugin handles compression internally
        processedFile = videoFile;
      }

      // Step 2: Upload and start backend processing
      await _uploadAndProcess(
        file: processedFile,
        modelName: modelName,
        diacritized: diacritized,
        fileHash: fileHash,
        enhance: enhance,
        includeSummary: includeSummary,
        includeTranslation: includeTranslation,
        targetLanguage: targetLanguage,
        taskId: taskId,
      );
    } catch (e) {
      debugPrint('[ProgressCubit] Error in startTranscription: $e');
      if (_currentTaskId != null) {
        final errorProgress = ProgressModel.initial(_currentTaskId!).copyWith(
          status: ProgressStatus.failed,
          currentStep: ProgressStep.initializing,
          message: 'Failed to start transcription',
        );
        emit(ProgressFailed(errorProgress, e.toString()));
      }
    }
  }

  /// Compress video with progress tracking
  Future<void> _compressVideo(File videoFile, String taskId) async {
    try {
      // Update progress to compressing
      final compressingProgress = ProgressModel.initial(taskId).copyWith(
        status: ProgressStatus.compressing,
        currentStep: ProgressStep.compressing,
        progress: 5.0,
        message: 'Compressing video...',
      );
      emit(ProgressLoading(compressingProgress));

      // Perform compression
      final info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: false,
      );

      if (_isCancelled) return;

      // Update progress after compression
      final compressedProgress = compressingProgress.copyWith(
        progress: 15.0,
        message: info != null
            ? 'Video compressed successfully'
            : 'Video compression completed',
      );
      emit(ProgressLoading(compressedProgress));
    } catch (e) {
      debugPrint('[ProgressCubit] Compression error: $e');
      // Continue without compression if it fails
      final progress = ProgressModel.initial(taskId).copyWith(
        status: ProgressStatus.uploading,
        currentStep: ProgressStep.uploading,
        progress: 15.0,
        message: 'Proceeding without compression...',
      );
      emit(ProgressLoading(progress));
    }
  }

  /// Upload file and start backend processing
  Future<void> _uploadAndProcess({
    required File file,
    required String modelName,
    bool diacritized = false,
    String? fileHash,
    bool enhance = false,
    bool includeSummary = false,
    bool includeTranslation = false,
    String targetLanguage = "English",
    required String taskId,
  }) async {
    try {
      // Update progress to uploading
      final uploadingProgress = ProgressModel.initial(taskId).copyWith(
        status: ProgressStatus.uploading,
        currentStep: ProgressStep.uploading,
        progress: 20.0,
        message: 'Uploading to server...',
      );
      emit(ProgressLoading(uploadingProgress));

      if (_isCancelled) return;

      // Start transcription and get backend task ID
      final backendTaskId = await ProgressService.startTranscription(
        file: fileHash == null ? file : null,
        modelName: modelName,
        dia: diacritized,
        fileHash: fileHash,
        enhance: enhance,
        includeSummary: includeSummary,
        includeTranslation: includeTranslation,
        targetLanguage: targetLanguage,
        onUploadProgress: (progress) {
          if (_isCancelled) return;

          // Map upload progress to our scale (20-30%)
          final mappedProgress = 20.0 + (progress * 10.0);
          final progressModel = uploadingProgress.copyWith(
            progress: mappedProgress,
            message: 'Uploading... ${(progress * 100).toInt()}%',
          );
          emit(ProgressLoading(progressModel));
        },
      );

      if (_isCancelled) return;

      // Start streaming backend progress
      await _streamBackendProgress(backendTaskId, taskId);
    } catch (e) {
      debugPrint('[ProgressCubit] Upload/Process error: $e');
      final errorProgress = ProgressModel.initial(taskId).copyWith(
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
      final processingProgress = ProgressModel.initial(frontendTaskId).copyWith(
        status: ProgressStatus.processing,
        currentStep: ProgressStep.backendInitializing,
        progress: 30.0,
        message: 'Starting backend processing...',
      );
      emit(ProgressLoading(processingProgress));

      if (_isCancelled) return;

      // Start streaming progress
      _progressSubscription =
          ProgressService.streamProgress(backendTaskId).listen(
        (backendProgress) {
          if (_isCancelled) return;

          // Map backend progress to our frontend task
          final frontendProgress = backendProgress.copyWith(
            taskId: frontendTaskId,
            // Map backend progress (30-100%)
            progress: 30.0 + ((backendProgress.progress / 100.0) * 70.0),
          );

          if (backendProgress.status == ProgressStatus.completed) {
            emit(ProgressCompleted(
                frontendProgress, backendProgress.result ?? {}));
            _cleanup(backendTaskId);
          } else if (backendProgress.status == ProgressStatus.failed) {
            emit(ProgressFailed(frontendProgress,
                backendProgress.errorMessage ?? 'Unknown error'));
            _cleanup(backendTaskId);
          } else {
            emit(ProgressLoading(frontendProgress));
          }
        },
        onError: (error) {
          debugPrint('[ProgressCubit] Stream error: $error');
          if (!_isCancelled) {
            final errorProgress =
                ProgressModel.initial(frontendTaskId).copyWith(
              status: ProgressStatus.failed,
              message: 'Connection lost',
            );
            emit(ProgressFailed(errorProgress, error.toString()));
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
      final errorProgress = ProgressModel.initial(frontendTaskId).copyWith(
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
      // Note: We can't cancel compression easily, so we just mark as cancelled

      final cancelledProgress = ProgressModel.initial(_currentTaskId!).copyWith(
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
  }

  @override
  Future<void> close() {
    _cleanup(null);
    return super.close();
  }
}
