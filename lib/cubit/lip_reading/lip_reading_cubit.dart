// lip_reading_cubit.dart
import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lip_reading/cubit/lip_reading/lip_reading_state.dart';
import 'package:video_player/video_player.dart';

class LipReadingCubit extends Cubit<LipReadingState> {
  LipReadingCubit() : super(LipReadingInitial());
  double videoProgress = 0.0;
  int totalVideoSeconds = 0;
  String currentPosition = "0:00";
  String totalDuration = "0:00";
  Timer? _hideControlsTimer;

  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _controller;

  bool showControls = true;

  void toggleControls() {
    showControls = !showControls;
    emit(LipReadingVideoSuccess());
    if (showControls) {
      _resetHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void updateVideoPosition(double progress) {
    videoProgress = progress;
    showControls = true;
    emit(LipReadingVideoSuccess());

    _resetHideControlsTimer();
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel(); // إلغاء المؤقت القديم

    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      showControls = false;
      emit(LipReadingVideoSuccess());
    });
  }

  void updatePlayPauseIcon(bool isPlaying) {
    emit(LipReadingVideoSuccess());
  }

  void pickVideoFromGallery() async {
    await _pickVideo(ImageSource.gallery);
  }

  void recordVideo() async {
    await _pickVideo(ImageSource.camera);
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      emit(LipReadingVideoLoading());

      final XFile? pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );

      if (pickedFile != null) {
        String videoPath = pickedFile.path;
        final file = File(videoPath);

        if (await file.exists()) {
          await _controller?.dispose();

          _controller = VideoPlayerController.file(file);
          await _controller!.initialize();
          totalVideoSeconds = _controller!.value.duration.inSeconds;
          totalDuration = _formatDuration(_controller!.value.duration);

// Listener to update video progress
          _controller!.addListener(() {
            final position = _controller!.value.position;
            final duration = _controller!.value.duration;

            if (duration.inSeconds > 0) {
              videoProgress = position.inSeconds / duration.inSeconds;
              currentPosition = _formatDuration(position);
              emit(LipReadingVideoSuccess());
            }
          });

          await _controller!.play();
          emit(LipReadingVideoSuccess());
        } else {
          emit(LipReadingVideoError('Video file not found'));
        }
      } else {
        emit(LipReadingInitial());
      }
    } catch (e) {
      emit(LipReadingVideoError('Failed to load video: ${e.toString()}'));
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  VideoPlayerController? get controller => _controller;

  @override
  Future<void> close() {
    _controller?.dispose();
    return super.close();
  }
}
