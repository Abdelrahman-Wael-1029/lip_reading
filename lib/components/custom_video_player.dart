import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lip_reading/cubit/video_cubit/video_cubit.dart';
import 'package:lip_reading/cubit/video_cubit/video_state.dart';
import 'package:lip_reading/utils/app_colors.dart';
import 'package:video_player/video_player.dart';

class CustomVideoPlayer extends StatelessWidget {
  const CustomVideoPlayer({
    super.key,
  });

  Widget _emtpyState(context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: isDarkMode
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No video found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Video not Found Please try again',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoCubit, VideoState>(
      builder: (context, state) {
        final cubit = context.read<VideoCubit>();
        if (cubit.controller == null) return _emtpyState(context);
        return Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: cubit.controller!.value.aspectRatio,
              child: VideoPlayer(cubit.controller!),
            ),
            (!cubit.showControls)
                ? SizedBox.shrink()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildControlButton(
                          icon: Icons.replay_10,
                          onPressed: () {
                            cubit.replay_10();
                          }),
                      _buildControlButton(
                        icon: cubit.controller!.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        onPressed: () {
                          if (cubit.controller!.value.isPlaying) {
                            cubit.controller!.pause();
                          } else {
                            cubit.controller!.play();
                          }
                          cubit.updatePlayPauseIcon(
                              cubit.controller!.value.isPlaying);
                        },
                      ),
                      _buildControlButton(
                        icon: Icons.forward_10,
                        onPressed: () async {
                          await cubit.forward_10();
                        },
                      ),
                    ],
                  ),
            if (cubit.showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4.0,
                          thumbShape:
                              RoundSliderThumbShape(enabledThumbRadius: 6.0),
                          overlayShape:
                              RoundSliderOverlayShape(overlayRadius: 12.0),
                          thumbColor: Colors.red,
                          activeTrackColor: Colors.red,
                          inactiveTrackColor:
                              Colors.black.withValues(alpha: 0.3),
                        ),
                        child: Slider(
                          value: cubit.videoProgress,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (value) {
                            cubit.updateVideoPosition(value);
                          },
                          onChangeEnd: (value) async {
                            cubit.onEnd(value);
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
                          backgroundColor: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildControlButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.6),
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
