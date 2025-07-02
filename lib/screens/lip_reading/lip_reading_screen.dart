import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lip_reading/components/custom_video_player.dart';
import 'package:lip_reading/components/diacritized_toggle.dart';
import 'package:lip_reading/components/model_selector.dart';
import 'package:lip_reading/components/modern_progress_bar.dart';
import 'package:lip_reading/components/progress_notification.dart';
import 'package:lip_reading/cubit/auth/auth_cubit.dart';
import 'package:lip_reading/cubit/progress/progress_cubit.dart';
import 'package:lip_reading/cubit/progress/progress_state.dart';
import 'package:lip_reading/cubit/video_cubit/video_cubit.dart';
import 'package:lip_reading/cubit/video_cubit/video_state.dart';

/// Modern redesigned lip reading screen with improved UI/UX
/// Features semi-transparent cards, improved typography, and diacritized toggle
class LipReadingScreen extends StatefulWidget {
  const LipReadingScreen({super.key});

  static const String routeName = '/lip-reading';

  @override
  State<LipReadingScreen> createState() => _LipReadingScreenState();
}

class _LipReadingScreenState extends State<LipReadingScreen>
    with WidgetsBindingObserver {
  bool isHidden = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _showLogoutDialog(BuildContext context) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.rightSlide,
      title: 'Are you sure',
      desc: 'Do you want to logout?',
      btnOkOnPress: () => context.read<AuthCubit>().logout(context),
      btnOkColor: Theme.of(context).colorScheme.error,
      btnCancelOnPress: () {},
      btnCancelColor: Theme.of(context).colorScheme.primary,
    ).show();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden) {
      context.read<VideoCubit>().pauseVideo();
    } else if (state == AppLifecycleState.resumed && isHidden) {
      isHidden = false;
      if (context.read<VideoCubit>().controller != null) {
        context.read<VideoCubit>().seekToCurrentPosition();
      }
    }
    if (!isHidden) isHidden = state == AppLifecycleState.hidden;
    debugPrint('[LipReadingScreen] App lifecycle state changed to: $state');
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Lip Reading',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          // Video cubit listener for errors
          BlocListener<VideoCubit, VideoState>(
            listener: (context, state) {
              if (state is VideoError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.errorMessage)),
                );
              }
            },
          ),
          // Progress cubit listener for notifications
          BlocListener<ProgressCubit, ProgressState>(
            listener: (context, state) {
              if (state is ProgressCompleted) {
                // Extract result and update video cubit
                final result = state.result;

                // Process transcript with fallback handling
                final videoCubit = context.read<VideoCubit>();
                final finalTranscript =
                    videoCubit.processTranscriptResult(result: result);

                final videoHash = result['video_hash'] as String?;
                final metadata = result['metadata'] as Map<String, dynamic>?;

                // Update video cubit with results
                context.read<VideoCubit>().updateVideoResultFromProgress(
                      enhancedTranscript: finalTranscript,
                      videoHash: videoHash,
                      metadata: metadata,
                    );

                // Show appropriate notification based on result
                if (videoCubit.isNoLipMovementsDetected(finalTranscript)) {
                  ProgressNotification.showInfo(
                    context,
                    'Processing completed, but no clear lip movements were detected in the video.',
                  );
                } else {
                  ProgressNotification.showSuccess(
                    context,
                    'Lip reading completed successfully!',
                  );
                }

                // Reset progress after short delay
                Future.delayed(const Duration(seconds: 2), () {
                  if (context.mounted) {
                    context.read<ProgressCubit>().resetProgress();
                  }
                });
              } else if (state is ProgressFailed) {
                // Get user-friendly error message
                final userFriendlyError =
                    _getUserFriendlyErrorMessage(state.errorMessage);

                // Show error notification with retry option
                ProgressNotification.showError(
                  context,
                  userFriendlyError,
                  onRetry: () {
                    // Reset progress and let user try again
                    context.read<ProgressCubit>().resetProgress();
                  },
                );
              }
            },
          ),
        ],
        child: BlocBuilder<VideoCubit, VideoState>(
          buildWhen: (previous, current) => (current is! VideoPlaying &&
              current is! HistoryLoading &&
              current is! HistoryFetchedSuccess &&
              current is! HistoryError),
          builder: (context, state) {
            return _buildBody(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, VideoState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Video Player Card
          GestureDetector(
            onTap: () => context.read<VideoCubit>().toggleControls(),
            child: Card(
              elevation: 4,
              shadowColor:
                  Theme.of(context).colorScheme.shadow.withValues(alpha: 0.2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context)
                            .colorScheme
                            .surfaceVariant
                            .withValues(alpha: 0.3),
                        Theme.of(context).colorScheme.surface,
                      ],
                    ),
                  ),
                  child: const CustomVideoPlayer(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Model Selection Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AI Model',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const ModelSelector(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Diacritized Toggle Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.text_format,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Text Format',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const DiacritizedToggle(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Progress Bar or Transcription Results Card
          BlocBuilder<ProgressCubit, ProgressState>(
            builder: (context, progressState) {
              if (progressState is ProgressLoading) {
                return const ModernProgressBar();
              }
              // If not processing, show transcription card
              return _buildTranscriptionCard(context);
            },
          ),

          const SizedBox(height: 24),

          // Action Buttons
          _buildActionButtons(context, state),

          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildTranscriptionCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final videoCubit = context.read<VideoCubit>();
    final result = videoCubit.selectedVideo?.result ?? '';
    // check if loading state
    if (videoCubit.loading) {
      return _buildLoadingState(context);
    }

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.1),
              colorScheme.surface,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with gradient accent
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.transcribe,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transcription Result',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            videoCubit.isDiacritized
                                ? 'With diacritical marks'
                                : 'Plain text',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (result.isNotEmpty &&
                        !videoCubit.isNoLipMovementsDetected(result))
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: result));
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Text copied to clipboard'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        tooltip: 'Copy to clipboard',
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Transcription text
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 120),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: result.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.text_snippet_outlined,
                              size: 48,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Transcription will appear here',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : videoCubit.isNoLipMovementsDetected(result)
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.visibility_off,
                                  size: 48,
                                  color: colorScheme.secondary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No Lip Movements Detected',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: colorScheme.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text(
                                    'The AI could not detect clear lip movements in this video. Please try with a video that contains visible lip movements and clear pronunciation.',
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondaryContainer
                                        .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.lightbulb_outline,
                                        size: 16,
                                        color: colorScheme.secondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Try a different video or model',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.secondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            child: SelectableText(
                              result,
                              style: textTheme.bodyLarge?.copyWith(
                                height: 1.6,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Processing video...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few moments',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, VideoState state) {
    final videoCubit = context.read<VideoCubit>();

    return BlocBuilder<ProgressCubit, ProgressState>(
      builder: (context, progressState) {
        final isProcessing = progressState is ProgressLoading;

        return Row(
          children: [
            // Pick Video Button
            Expanded(
              child: FilledButton.icon(
                onPressed: isProcessing
                    ? null
                    : () => videoCubit.pickVideoFromGallery(context),
                icon: const Icon(Icons.video_library),
                label: const Text('Pick Video'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Record Video Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    isProcessing ? null : () => videoCubit.recordVideo(context),
                icon: const Icon(Icons.videocam),
                label: const Text('Record'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Helper method to convert technical error messages to user-friendly ones
  String _getUserFriendlyErrorMessage(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();

    // Handle specific error cases
    if (lowerError.contains('no landmarks detected')) {
      return 'No face detected in the video. Please ensure the person\'s face is clearly visible throughout the video.';
    }

    if (lowerError.contains('failed to preprocess video')) {
      return 'Unable to process the video. Please try uploading a different video with better quality.';
    }

    if (lowerError.contains('connection') || lowerError.contains('network')) {
      return 'Network connection issue. Please check your internet connection and try again.';
    }

    if (lowerError.contains('upload') || lowerError.contains('file')) {
      return 'Failed to upload the video. Please try again with a smaller video file.';
    }

    if (lowerError.contains('timeout') || lowerError.contains('timed out')) {
      return 'Processing took too long. Please try again with a shorter video.';
    }

    if (lowerError.contains('format') || lowerError.contains('codec')) {
      return 'Video format not supported. Please use MP4, MOV, or AVI format.';
    }

    if (lowerError.contains('size') || lowerError.contains('large')) {
      return 'Video file is too large. Please compress the video or use a shorter clip.';
    }

    // Default fallback for unknown errors
    return 'Processing failed. Please try again or contact support if the issue persists.';
  }
}
