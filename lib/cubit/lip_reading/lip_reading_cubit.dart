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
  String? _currentVideoPath;

  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _controller;
  StreamSubscription? _videoProgressSubscription;

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
    _hideControlsTimer?.cancel();

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
    // Dispose current controller before recording
    await _cleanupController();
    await _pickVideo(ImageSource.camera);
  }

  Future<void> _cleanupController() async {
    _videoProgressSubscription?.cancel();
    _videoProgressSubscription = null;

    _hideControlsTimer?.cancel();
    _hideControlsTimer = null;

    if (_controller != null) {
      await _controller!.pause();
      await _controller!.dispose();
      _controller = null;
    }
  }

  // Call this method when returning to the screen
  Future<void> reInitializeLastVideo() async {
    if (_currentVideoPath != null && _currentVideoPath!.isNotEmpty) {
      final file = File(_currentVideoPath!);
      if (await file.exists()) {
        await _initializeVideoController(file);
      }
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );

      if (pickedFile != null) {
        String videoPath = pickedFile.path;
        _currentVideoPath = videoPath;
        final file = File(videoPath);

        if (await file.exists()) {
          await _cleanupController();
          await _initializeVideoController(file);
        } else {
          emit(LipReadingVideoError('Video file not found'));
        }
      } else {
        // User canceled picking video
        if (_controller == null && _currentVideoPath != null) {
          // Try to reinitialize previous video
          await reInitializeLastVideo();
        } else {
          emit(LipReadingVideoSuccess());
        }
      }
    } catch (e) {
      emit(LipReadingVideoError('Failed to load video: ${e.toString()}'));
    }
  }

  Future<void> _initializeVideoController(File videoFile) async {
    try {
      _controller = VideoPlayerController.file(videoFile);

      // Wait for controller to initialize
      await _controller!.initialize();

      totalVideoSeconds = _controller!.value.duration.inSeconds;
      totalDuration = _formatDuration(_controller!.value.duration);

      // Use a separate stream subscription instead of the listener
      _videoProgressSubscription =
          Stream.periodic(const Duration(milliseconds: 200)).listen((_) {
        if (_controller != null && _controller!.value.isInitialized) {
          final position = _controller!.value.position;
          final duration = _controller!.value.duration;

          if (duration.inSeconds > 0) {
            videoProgress = position.inSeconds / duration.inSeconds;
            currentPosition = _formatDuration(position);
            emit(LipReadingVideoSuccess());
          }
        }
      });

      await _controller!.play();
      showControls = true;
      _resetHideControlsTimer();
      emit(LipReadingVideoSuccess());
    } catch (e) {
      emit(LipReadingVideoError('Failed to initialize video: ${e.toString()}'));
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
  Future<void> close() async {
    await _cleanupController();
    return super.close();
  }
}
