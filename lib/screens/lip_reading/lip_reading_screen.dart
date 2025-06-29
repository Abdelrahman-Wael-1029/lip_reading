import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lip_reading/components/custom_video_player.dart';
import 'package:lip_reading/components/diacritized_toggle.dart';
import 'package:lip_reading/components/model_selector.dart';
import 'package:lip_reading/cubit/video_cubit/video_cubit.dart';
import 'package:lip_reading/cubit/video_cubit/video_state.dart';
import 'package:lip_reading/screens/splash_screen/history_screen.dart';

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
    print('previous state $state');
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
            onPressed: () {
              Navigator.pushNamed(context, HistoryScreen.routeName);
            },
            icon: const Icon(Icons.history),
            tooltip: 'View History',
          ),
        ],
      ),
      body: BlocBuilder<VideoCubit, VideoState>(
        builder: (context, state) {
          return _buildBody(context, state);
        },
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
                      Text(
                        'AI Model',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
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

          // const SizedBox(height: 24),

          // Video Name Input (if video is loaded)

          // Card(
          //   child: Padding(
          //     padding: const EdgeInsets.all(16),
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         Row(
          //           children: [
          //             Icon(
          //               Icons.edit,
          //               color: Theme.of(context).colorScheme.primary,
          //               size: 20,
          //             ),
          //             const SizedBox(width: 8),
          //             Text(
          //               'Video Name',
          //               style:
          //                   Theme.of(context).textTheme.titleMedium?.copyWith(
          //                         fontWeight: FontWeight.w600,
          //                       ),
          //             ),
          //           ],
          //         ),
          //         const SizedBox(height: 16),
          //         customTextFormField(
          //           context: context,
          //           controller:
          //               context.read<VideoCubit>().nameVideoController,
          //           hintText: 'Enter video name',
          //           prefixIcon: const Icon(Icons.videocam),
          //           textInputAction: TextInputAction.done,
          //         ),
          //       ],
          //     ),
          //   ),
          // ),

          const SizedBox(height: 16),

          // Transcription Results Card
          _buildTranscriptionCard(context),

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
    if ((videoCubit.selectedVideo?.result.isEmpty ?? true) ||
        videoCubit.state is VideoLoading) {
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
                    if (result.isNotEmpty)
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

    return Row(
      children: [
        // Pick Video Button
        Expanded(
          child: FilledButton.icon(
            onPressed: () => videoCubit.pickVideoFromGallery(),
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
            onPressed: () => videoCubit.recordVideo(),
            icon: const Icon(Icons.videocam),
            label: const Text('Record'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
