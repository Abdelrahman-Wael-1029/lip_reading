import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lip_reading/components/custom_video_player.dart';
import 'package:lip_reading/cubit/lip_reading/lip_reading_cubit.dart';
import 'package:lip_reading/cubit/lip_reading/lip_reading_state.dart';
import 'package:lip_reading/utils/app_colors.dart';
import 'package:lip_reading/utils/utils.dart';

class LipReadingScreen extends StatefulWidget {
  const LipReadingScreen({super.key});
  

  @override
  State<LipReadingScreen> createState() => _LipReadingScreenState();
}

class _LipReadingScreenState extends State<LipReadingScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  void _showVideoSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Video Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.read<LipReadingCubit>().pickVideoFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.videocam),
                  title: const Text('Record Video'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.read<LipReadingCubit>().recordVideo();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.white,
      child: SafeArea(
        child: Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(getPadding(context)!),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BlocConsumer<LipReadingCubit, LipReadingState>(
                  listener: (context, state) {},
                  builder: (context, state) {
                    if (state is LipReadingVideoLoading) {
                      return const SizedBox(
                        height: 300,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else if (state is LipReadingVideoError) {
                      return Container(
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            state.message,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    } else if (state is LipReadingVideoSuccess) {
                      final videoController =
                          context.read<LipReadingCubit>().controller;
                      if (videoController != null) {
                        return CustomVideoPlayer(controller: videoController);
                      }
                    }
                    return InkWell(
                      onTap: _showVideoSourceDialog,
                      child: Container(
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.primaryColor,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.add_circle_outline,
                                size: 48,
                                color: AppColors.buttonColor,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Tap to record or upload video',
                                style: TextStyle(
                                  color: AppColors.buttonColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
