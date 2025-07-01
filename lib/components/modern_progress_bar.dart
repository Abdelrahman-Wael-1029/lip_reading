import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lip_reading/cubit/progress/progress_cubit.dart';
import 'package:lip_reading/cubit/progress/progress_state.dart';
import 'package:lip_reading/model/progress_model.dart';

class ModernProgressBar extends StatefulWidget {
  const ModernProgressBar({super.key});

  @override
  State<ModernProgressBar> createState() => _ModernProgressBarState();
}

class _ModernProgressBarState extends State<ModernProgressBar>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start pulse animation
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _updateProgress(double targetProgress) {
    if (targetProgress > _progressAnimation.value) {
      _progressController.animateTo(targetProgress / 100.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocListener<ProgressCubit, ProgressState>(
      listener: (context, state) {
        if (state is ProgressLoading) {
          _updateProgress(state.progress.progress);
        } else if (state is ProgressCompleted) {
          _updateProgress(100.0);
          _pulseController.stop();
        } else if (state is ProgressFailed) {
          _pulseController.stop();
        }
      },
      child: BlocBuilder<ProgressCubit, ProgressState>(
        builder: (context, state) {
          if (state is ProgressInitial) {
            return const SizedBox.shrink();
          }

          ProgressModel? progress;
          Color progressColor = colorScheme.primary;
          IconData statusIcon = Icons.hourglass_empty;

          if (state is ProgressLoading) {
            progress = state.progress;
            progressColor = colorScheme.primary;
            statusIcon = _getStepIcon(progress.currentStep);
          } else if (state is ProgressCompleted) {
            progress = state.progress;
            progressColor = colorScheme.tertiary;
            statusIcon = Icons.check_circle;
          } else if (state is ProgressFailed) {
            progress = state.progress;
            progressColor = colorScheme.error;
            statusIcon = Icons.error;
          } else if (state is ProgressCancelled) {
            progress = state.progress;
            progressColor = colorScheme.outline;
            statusIcon = Icons.cancel;
          }

          if (progress == null) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and status
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: state is ProgressLoading
                          ? _pulseAnimation
                          : const AlwaysStoppedAnimation(1.0),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: progressColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              statusIcon,
                              color: progressColor,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusTitle(state),
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            progress.message,
                            style: textTheme.bodyMedium?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state is ProgressLoading)
                      TextButton(
                        onPressed: () {
                          context.read<ProgressCubit>().cancelTranscription();
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Progress bar
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progressAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: progressColor,
                            borderRadius: BorderRadius.circular(3),
                            gradient: state is ProgressLoading
                                ? LinearGradient(
                                    colors: [
                                      progressColor,
                                      progressColor.withValues(alpha: 0.8),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Progress details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${progress.progress.toInt()}%',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (state is ProgressLoading &&
                        progress.elapsedTime != null)
                      Text(
                        progress.estimatedTimeRemaining,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),

                // Error message for failed state
                if (state is ProgressFailed &&
                    state.errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: colorScheme.onErrorContainer,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.errorMessage,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        context.read<ProgressCubit>().resetProgress();
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Try Again'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getStepIcon(ProgressStep step) {
    switch (step) {
      case ProgressStep.initializing:
        return Icons.play_circle_outline;
      case ProgressStep.compressing:
        return Icons.compress;
      case ProgressStep.uploading:
        return Icons.cloud_upload;
      case ProgressStep.backendInitializing:
      case ProgressStep.videoServiceInit:
        return Icons.settings;
      case ProgressStep.videoPreprocessing:
        return Icons.video_settings;
      case ProgressStep.analyzingFrames:
        return Icons.analytics;
      case ProgressStep.detectingLandmarks:
        return Icons.face;
      case ProgressStep.extractingMouth:
        return Icons.crop;
      case ProgressStep.runningInference:
        return Icons.psychology;
      case ProgressStep.aiEnhancement:
        return Icons.auto_awesome;
      case ProgressStep.finalizing:
        return Icons.check_circle_outline;
      case ProgressStep.completed:
        return Icons.check_circle;
    }
  }

  String _getStatusTitle(ProgressState state) {
    if (state is ProgressLoading) {
      switch (state.progress.status) {
        case ProgressStatus.compressing:
          return 'Compressing Video';
        case ProgressStatus.uploading:
          return 'Uploading';
        case ProgressStatus.processing:
          return 'Processing';
        default:
          return 'Working...';
      }
    } else if (state is ProgressCompleted) {
      return 'Completed Successfully';
    } else if (state is ProgressFailed) {
      return 'Processing Failed';
    } else if (state is ProgressCancelled) {
      return 'Cancelled';
    }

    return 'Processing';
  }
}
