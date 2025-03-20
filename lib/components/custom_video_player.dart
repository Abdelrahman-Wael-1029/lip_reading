import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lip_reading/cubit/lip_reading/lip_reading_cubit.dart';
import 'package:lip_reading/utils/app_colors.dart';
import 'package:video_player/video_player.dart';

class CustomVideoPlayer extends StatelessWidget {
  final VideoPlayerController controller;

  const CustomVideoPlayer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    var cubit = context.read<LipReadingCubit>();
    return GestureDetector(
      onTap: () => cubit.toggleControls(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
          (!cubit.showControls)
              ? SizedBox.shrink()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildControlButton(
                        icon: Icons.replay_10,
                        onPressed: () {
                          final currentPosition = controller.value.position;
                          controller.seekTo(
                              currentPosition - const Duration(seconds: 10));
                        }),
                    _buildControlButton(
                      icon: controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      onPressed: () {
                        if (controller.value.isPlaying) {
                          controller.pause();
                        } else {
                          controller.play();
                        }
                        context
                            .read<LipReadingCubit>()
                            .updatePlayPauseIcon(controller.value.isPlaying);
                      },
                    ),
                    _buildControlButton(
                      icon: Icons.forward_10,
                      onPressed: () async {
                        final currentPosition = await controller.position;
                        if (currentPosition != null) {
                          await controller.seekTo(
                              currentPosition + const Duration(seconds: 10));
                        }
                      },
                    ),
                  ],
                ),
          if (cubit.showControls)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Column(
                crossAxisAlignment:  CrossAxisAlignment.end,
                children: [
                  Slider(
                    value: cubit.videoProgress,
                    min: 0.0,
                    max: 1.0,
                    activeColor: Colors.red,
                    inactiveColor: Colors.grey.shade300,
                    onChanged: (value) {
                      cubit.updateVideoPosition(value);
                    },
                    onChangeEnd: (value) async {
                      final position = Duration(
                          seconds: (value * cubit.totalVideoSeconds).toInt());
                      await cubit.controller!.seekTo(position);
                    },
                  ),
                  // Text(
                  //   "${cubit.currentPosition} / ${cubit.totalDuration}",
                  //   style: const TextStyle(color: Colors.black),
                  // ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.buttonColor,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}
