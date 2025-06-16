// ignore_for_file: deprecated_member_use

import 'dart:math';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lip_reading/components/custom_text_from_field.dart';
import 'package:lip_reading/components/custom_video_player.dart';
import 'package:lip_reading/cubit/video_cubit/video_cubit.dart';
import 'package:lip_reading/cubit/video_cubit/video_state.dart';
import 'package:lip_reading/screens/lip_reading/history_screen.dart';
import 'package:lip_reading/utils/app_colors.dart';
import 'package:lip_reading/utils/color_scheme_extension.dart';
import 'package:lip_reading/utils/utils.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';

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
    return BlocConsumer<VideoCubit, VideoState>(
      buildWhen: (previous, current) => (current is! VideoPlaying &&
          current is! HistoryLoading &&
          current is! HistorySuccess &&
          current is! HistoryError),
      listenWhen: (previous, current) =>
          (current is VideoSuccess || current is VideoError),
      listener: (context, state) {
        // Handle state changes if needed
        if (state is VideoSuccess) {
          final videoController = context.read<VideoCubit>().controller;
          if (videoController != null && !videoController.value.isInitialized) {
            context.read<VideoCubit>().seekToCurrentPosition();
          }
        }
        if (state is VideoError) {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.warning,
            animType: AnimType.rightSlide,
            title: 'Warning',
            desc: state.errorMessage,
            btnOkOnPress: () {},
            btnOkColor: Theme.of(context).primaryColor,
          ).show();
        }
      },
      builder: (context, state) => _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, state) {
    final videoController = context.read<VideoCubit>().controller;
    print('rebuild main screen');

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Lip Reading', style: TextStyle(color: AppColors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: AppColors.white),
            onPressed: () async {
              await context.read<VideoCubit>().pauseVideo();
              if (context.mounted) {
                Navigator.pushNamed(context, HistoryScreen.routeName);
              }
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).primaryColor.withOpacity(0.6),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
              padding: EdgeInsets.all(getPadding(context)!),
              child: (state is VideoLoading)
                  ? _buildLoadingState(context)
                  :

                  // Show video and results state if controller exists and is initialized
                  ((state is VideoSuccess || state is VideoError) &&
                          videoController != null &&
                          videoController.value.isInitialized)
                      ? _buildVideoSuccessState(context, videoController)
                      :

                      // Show loading if controller exists but not initialized
                      ((state is VideoSuccess || state is VideoError) &&
                              videoController != null &&
                              !videoController.value.isInitialized)
                          ? _buildLoadingState(context)
                          :

                          // Default empty state
                          _buildEmptyState(context)),
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(context),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.videocam_outlined,
            size: 80,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 30),
        Text(
          'Ready to analyze lip movements',
          style: TextStyle(
            fontSize: getLargeFontSize(context),
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Upload a video or record now to start lip reading',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: getMediumFontSize(context),
            color: AppColors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 40),
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Processing Video',
            style: TextStyle(
              fontSize: getLargeFontSize(context),
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we process your video...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: getMediumFontSize(context),
              color: AppColors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSuccessState(
      BuildContext context, VideoPlayerController videoController) {
    // No more setState - we rely on the BLoC pattern
    var videoCubit = context.read<VideoCubit>();

    if (!videoController.value.isInitialized) {
      videoCubit.seekToCurrentPosition();

      // Show loading indicator while initializing
      return _buildLoadingState(context);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video container with enhanced styling
          GestureDetector(
            onTap: () => videoCubit.toggleControls(),
            child: Container(
              width: double.infinity,
              height: min(MediaQuery.of(context).size.height - 120,
                  videoController.value.size.height),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomVideoPlayer(),
              ),
            ),
          ),

          const SizedBox(height: 24),
          Column(
            children: [
              if (videoCubit.selectedVideo != null &&
                  videoCubit.selectedVideo!.title.isNotEmpty)
                customTextFormField(
                  context: context,
                  controller: context.read<VideoCubit>().nameVideoController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                  // suffix icon for upload new name
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.upload_file,
                    ),
                    onPressed: () {
                      context.read<VideoCubit>().updateVideoTitle(context);
                    },
                  ),
                ),
              if (videoCubit.selectedVideo != null &&
                  videoCubit.selectedVideo!.title.isNotEmpty)
                const SizedBox(height: 24),

              // Title for results section
              Text(
                'Lip Reading Results',
                style: TextStyle(
                  fontSize: getLargeFontSize(context),
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),

              const SizedBox(height: 16),

              (videoCubit.selectedVideo?.result != null)
                  ? Card(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(getPadding(context)!),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              spacing: 8,
                              children: [
                                Icon(
                                  Icons.text_fields,
                                ),
                                Expanded(
                                  child: Text(
                                    'Transcribed Text',
                                    style: TextStyle(
                                      fontSize: getMediumFontSize(context),
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .buttonColor,
                                    ),
                                  ),
                                ),
                                IconButton(
                                    onPressed: () {
                                      // copy to clipboard
                                      Clipboard.setData(ClipboardData(
                                          text: videoCubit
                                              .selectedVideo!.result));
                                    },
                                    icon: Icon(
                                      Icons.copy,
                                    ))
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              // Replace this with actual transcribed text
                              'This is where the transcribed text from lip reading will appear. The AI model has processed the video and identified the spoken words based on lip movements.',
                              style: TextStyle(
                                fontSize: getMediumFontSize(context),
                                // color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Card(
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(getPadding(context)!),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      height: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                height: 80,
                                width: double.infinity,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          context,
          icon: Icons.videocam,
          label: 'Record Video',
          onPressed: () {
            context.read<VideoCubit>().recordVideo();
          },
        ),
        const SizedBox(width: 20),
        _buildActionButton(
          context,
          icon: Icons.photo_library,
          label: 'Upload Video',
          onPressed: () {
            context.read<VideoCubit>().pickVideoFromGallery();
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Theme.of(context).primaryColor,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
            elevation: 6,
          ),
          child: Icon(icon, size: 32),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    final cubit = context.read<VideoCubit>();
    if (cubit.state is VideoInitial || cubit.selectedVideo == null) {
      return SizedBox.shrink();
    }
    return IconButton(
      onPressed: () {
        context.read<VideoCubit>().uploadVideo(context);
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(
            Theme.of(context).scaffoldBackgroundColor),
      ),
      icon: Icon(
        Icons.upload,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    // Disable buttons during loading state
    final cubit = context.read<VideoCubit>();
    final bool isLoading = cubit.state is VideoLoading;
    if (cubit.state is VideoInitial || cubit.selectedVideo == null) {
      return SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildBottomActionButton(
              context,
              icon: Icons.videocam,
              label: 'Record',
              onPressed: isLoading
                  ? null
                  : () {
                      context.read<VideoCubit>().recordVideo();
                    },
            ),
          ),
          Expanded(
            child: _buildBottomActionButton(
              context,
              icon: Icons.photo_library,
              label: 'Gallery',
              onPressed: isLoading
                  ? null
                  : () {
                      context.read<VideoCubit>().pickVideoFromGallery();
                    },
            ),
          ),
          Expanded(
            child: _buildBottomActionButton(
              context,
              icon: Icons.info_outline,
              label: 'Help',
              onPressed: () {
                // Show help or information dialog
                _showHelpDialog(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    final bool isDisabled = onPressed == null;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isDisabled
                  ? Theme.of(context).colorScheme.buttonColor.withOpacity(0.5)
                  : Theme.of(context).colorScheme.buttonColor,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isDisabled
                    ? Theme.of(context).colorScheme.buttonColor.withOpacity(0.5)
                    : Theme.of(context).colorScheme.buttonColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.rightSlide,
      btnOkOnPress: () {},
      title: 'rules',
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Record a video or select one from your gallery',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '2. Ensure good lighting and clear view of lips',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '3. Speak clearly for best results',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '4. Wait for the AI to process and show results',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '5. View the transcribed text below the video',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    ).show();
  }
}
