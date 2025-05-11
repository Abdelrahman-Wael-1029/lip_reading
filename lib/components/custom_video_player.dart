import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lip_reading/cubit/video_cubit/video_cubit.dart';
import 'package:video_player/video_player.dart';

class CustomVideoPlayer extends StatelessWidget {
  final VideoPlayerController controller;

  const CustomVideoPlayer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    var cubit = context.watch<VideoCubit>();
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
                        cubit.updatePlayPauseIcon(controller.value.isPlaying);
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
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4.0,
                        thumbShape:
                            RoundSliderThumbShape(enabledThumbRadius: 6.0),
                        overlayShape:
                            RoundSliderOverlayShape(overlayRadius: 12.0),
                        thumbColor: Colors.red,
                        activeTrackColor: Colors.red,
                        inactiveTrackColor: Colors.black.withOpacity(0.3),
                      ),
                      child: Slider(
                        value: cubit.videoProgress,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (value) {
                          cubit.updateVideoPosition(value);
                        },
                        onChangeEnd: (value) async {
                          final position = Duration(
                              seconds:
                                  (value * cubit.totalVideoSeconds).toInt());
                          await cubit.controller!.seekTo(position);
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Text(
                      "${cubit.currentPosition} / ${cubit.totalDuration}",
                      style: TextStyle(
                        color: Colors.black,
                        backgroundColor: Colors.white.withOpacity(0.7),
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
        color: Colors.black.withOpacity(0.6),
      ),
      child: IconButton(
        iconSize: 30.0,
        padding: EdgeInsets.all(8.0),
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}
