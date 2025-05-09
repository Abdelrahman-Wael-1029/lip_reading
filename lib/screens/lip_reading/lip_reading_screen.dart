// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lip_reading/components/custom_video_player.dart';
import 'package:lip_reading/cubit/auth/auth_cubit.dart';
import 'package:lip_reading/cubit/lip_reading/lip_reading_cubit.dart';
import 'package:lip_reading/cubit/lip_reading/lip_reading_state.dart';
import 'package:lip_reading/screens/auth/login_screen.dart';
import 'package:lip_reading/utils/app_colors.dart';
import 'package:lip_reading/utils/utils.dart';
import 'package:video_player/video_player.dart';

class LipReadingScreen extends StatefulWidget {
  const LipReadingScreen({super.key});

  static const String routeName = '/lip-reading';

  @override
  State<LipReadingScreen> createState() => _LipReadingScreenState();
}

class _LipReadingScreenState extends State<LipReadingScreen> {
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              Navigator.of(context).pushNamedAndRemoveUntil(
                  LoginScreen.routeName, (route) => false);
              context.read<AuthCubit>().logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Lip Reading', style: TextStyle(color: AppColors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.white),
            onPressed: () {
              _showLogoutDialog(context);
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
            child: BlocConsumer<LipReadingCubit, LipReadingState>(
              listener: (context, state) {
                // Handle state changes if needed
                if (state is LipReadingVideoSuccess) {
                  final videoController =
                      context.read<LipReadingCubit>().controller;
                  if (videoController != null &&
                      !videoController.value.isInitialized) {
                    videoController.initialize().then((_) {
                      setState(() {});
                    });
                  }
                }
              },
              builder: (context, state) {
                final videoController =
                    context.read<LipReadingCubit>().controller;

                // Show error state
                if (state is LipReadingVideoError) {
                  return _buildErrorState(context, state.message);
                }
                // Show loading state
                // else if (state is LipReadingVideoLoading) {
                //   return _buildLoadingState(context);
                // }
                // Show video and results state if controller exists and is initialized
                else if (state is LipReadingVideoSuccess &&
                    videoController != null &&
                    videoController.value.isInitialized) {
                  return _buildVideoSuccessState(context, videoController);
                }
                // Show loading if controller exists but not initialized
                else if (state is LipReadingVideoSuccess &&
                    videoController != null &&
                    !videoController.value.isInitialized) {
                  return _buildLoadingState(context);
                }
                // Default empty state
                return _buildEmptyState(context);
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(context),
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

  Widget _buildErrorState(BuildContext context, String errorMessage) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(getPadding(context)!),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: getLargeFontSize(context),
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: getMediumFontSize(context),
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Reset state or try again logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
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
    if (!videoController.value.isInitialized) {
      videoController.initialize().then((_) {
        // Emit state to refresh UI
        setState(() {});
      });

      // Show loading indicator while initializing
      return _buildLoadingState(context);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video container with enhanced styling
          Container(
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
              child: AspectRatio(
                aspectRatio: videoController.value.aspectRatio,
                child: CustomVideoPlayer(controller: videoController),
              ),
            ),
          ),

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

          // Results container
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            padding: EdgeInsets.all(getPadding(context)!),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    Icon(
                      Icons.text_fields,
                      color: Theme.of(context).primaryColor,
                    ),
                    Expanded(
                      child: Text(
                        'Transcribed Text',
                        style: TextStyle(
                          fontSize: getMediumFontSize(context),
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    // icon for share resutl
                    IconButton(
                        onPressed: () {
                          // Share the transcribed text
                        },
                        icon: Icon(
                          Icons.share,
                          color: Theme.of(context).primaryColor,
                        ))
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  // Replace this with actual transcribed text
                  'This is where the transcribed text from lip reading will appear. The AI model has processed the video and identified the spoken words based on lip movements.',
                  style: TextStyle(
                    fontSize: getMediumFontSize(context),
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
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
            context.read<LipReadingCubit>().recordVideo();
          },
        ),
        const SizedBox(width: 20),
        _buildActionButton(
          context,
          icon: Icons.photo_library,
          label: 'Upload Video',
          onPressed: () {
            context.read<LipReadingCubit>().pickVideoFromGallery();
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

  Widget _buildBottomActionBar(BuildContext context) {
    // Disable buttons during loading state
    final bool isLoading =
        context.watch<LipReadingCubit>().state is LipReadingVideoLoading;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomActionButton(
            context,
            icon: Icons.videocam,
            label: 'Record',
            onPressed: isLoading
                ? null
                : () {
                    context.read<LipReadingCubit>().recordVideo();
                  },
          ),
          _buildBottomActionButton(
            context,
            icon: Icons.photo_library,
            label: 'Gallery',
            onPressed: isLoading
                ? null
                : () {
                    context.read<LipReadingCubit>().pickVideoFromGallery();
                  },
          ),
          _buildBottomActionButton(
            context,
            icon: Icons.info_outline,
            label: 'Help',
            onPressed: () {
              // Show help or information dialog
              _showHelpDialog(context);
            },
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
                  ? Theme.of(context).primaryColor.withOpacity(0.5)
                  : Theme.of(context).primaryColor,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isDisabled
                    ? Theme.of(context).primaryColor.withOpacity(0.5)
                    : Theme.of(context).primaryColor,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Use'),
        content: const SingleChildScrollView(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
