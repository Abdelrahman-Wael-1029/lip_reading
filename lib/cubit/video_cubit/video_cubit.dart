import 'dart:async';
import 'dart:io';
import 'package:video_compress/video_compress.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lip_reading/cubit/progress/progress_cubit.dart';
import 'package:lip_reading/cubit/progress/progress_state.dart';
import 'package:lip_reading/cubit/video_cubit/video_state.dart';
import 'package:lip_reading/model/video_model.dart';
import 'package:lip_reading/repository/video_repository.dart';
import 'package:lip_reading/service/api_service.dart';
import 'package:lip_reading/service/connectivity_service.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

class VideoCubit extends Cubit<VideoState> {
  // Repository
  final VideoRepository _videoRepository;
  String selectedModel = '';
  List<String>? models;
  bool isDiacritized =
      false; // Add diacritized state (UI name, but API uses 'dia')
  bool loading = false;

  // Image picker
  final ImagePicker _picker = ImagePicker();

  // Controllers
  VideoPlayerController? controller;
  final nameVideoController = TextEditingController();
  File? videoFile;

  // Video state
  double videoProgress = 0.0;
  int totalVideoSeconds = 0;
  String currentPosition = "0:00";
  String totalDuration = "0:00";
  bool showControls = true;
  String? _currentVideoPath;

  // Data
  List<VideoModel> videos = [];
  VideoModel? selectedVideo;
  List<VideoModel> videoModelsCache = [];

  // Timers and subscriptions
  Timer? _hideControlsTimer;
  StreamSubscription? _videoProgressSubscription;

  VideoCubit({VideoRepository? videoRepository})
      : _videoRepository = videoRepository ?? VideoRepository(),
        super(VideoInitial()) {
    models = null;
    emit(VideoLoading());
    ApiService.getModels().then((v) {
      models = v;
      if (models!.isNotEmpty) selectedModel = models![2];
      emit(VideoInitial());
    }).catchError((e) {
      models = [];
      emit(VideoError('Please try again'));
    });
  }

  // UI Control Methods
  void toggleControls() {
    showControls = !showControls;
    emit(VideoPlaying());

    if (showControls) {
      _resetHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 6), () {
      showControls = false;
      emit(VideoPlaying());
    });
  }

  void updateVideoPosition(double progress) {
    videoProgress = progress;
    showControls = true;
    emit(VideoPlaying());
    _resetHideControlsTimer();
  }

  void updatePlayPauseIcon(bool isPlaying) {
    emit(VideoPlaying());
  }

  // Video Controller Methods
  Future<bool> initializeNetworkVideo(VideoModel video) async {
    if (state is VideoLoading) return false;
    emit(VideoLoading());
    try {
      if (video.url.isEmpty) throw Exception('Video URL is empty');
      if (!await ConnectivityService().isConnected()) {
        emit(VideoError('No internet connection'));
        return false;
      }
      videoFile = null;
      _currentVideoPath = null;
      await cleanupController();
      videoModelsCache.clear();

      // Store selected video before initializing controller
      selectedVideo = video;
      selectedModel = video.model;
      nameVideoController.text = video.title;
      isDiacritized = video.diacritized ?? true;

      // Create controller with safeguards
      final VideoPlayerController newController =
          VideoPlayerController.networkUrl(Uri.parse(video.url));

      // Initialize first before assigning to class variable
      await newController.initialize();

      // Only assign after successful initialization
      controller = newController;

      totalVideoSeconds = controller!.value.duration.inSeconds;
      totalDuration = _formatDuration(controller!.value.duration);

      _setupVideoProgressTracking();

      showControls = true;
      _resetHideControlsTimer();

      // play video
      await controller!.play();

      emit(VideoSuccess());
      return true; // Success indicator
    } catch (e) {
      emit(VideoError('Video not exist please try again'));
      return false; // Failure indicator
    }
  }

  Future<void> pauseVideo() async {
    if (controller != null && controller!.value.isInitialized) {
      await controller!.pause();
    }
  }

  Future<void> seekToCurrentPosition() async {
    try {
      if (controller != null && controller!.value.isInitialized) {
        final currentPosition = controller!.value.position;
        await controller!.initialize();
        await controller!.seekTo(currentPosition);
        emit(VideoSuccess());
      }
    } catch (e) {
      // Do Nothing, just ensure we don't throw an error
    }
  }

  Future<void> cleanupController() async {
    // Cancel subscriptions and timers
    _videoProgressSubscription?.cancel();
    _videoProgressSubscription = null;
    _hideControlsTimer?.cancel();
    _hideControlsTimer = null;

    // Dispose controller safely
    if (controller != null) {
      final tempController = controller;
      controller =
          null; // Set to null before disposal to prevent access after disposal

      if (tempController!.value.isInitialized) {
        await tempController.pause();
      }
      await tempController.dispose();
    }

    // Reset state
    selectedVideo = null;
    nameVideoController.clear();
  }

  void _setupVideoProgressTracking() {
    _videoProgressSubscription?.cancel();

    _videoProgressSubscription =
        Stream.periodic(const Duration(milliseconds: 200)).listen((_) {
      if (controller != null && controller!.value.isInitialized) {
        final position = controller!.value.position;
        final duration = controller!.value.duration;
        if (position >= duration) {
          controller!.seekTo(Duration.zero);
          emit(VideoPlaying());
        }
        if (!controller!.value.isPlaying) return;

        if (duration.inSeconds > 0) {
          videoProgress = position.inSeconds / duration.inSeconds;
          currentPosition = _formatDuration(position);
          emit(VideoPlaying());
        }
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  // show popup to tell user wait for process video
  void showLoadingPopup(context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: const [
          CircularProgressIndicator(),
          SizedBox(width: 10),
          Text('Processing video please wait...')
        ],
      ),
    ));
  }

  // Video Pick Methods
  Future<void> pickVideoFromGallery(BuildContext context) async {
    if (loading) return;
    await pauseVideo();
    if (context.mounted) await _pickVideo(ImageSource.gallery, context);
  }

  Future<void> recordVideo(BuildContext context) async {
    if (loading) return;
    await pauseVideo();
    if (context.mounted) await _pickVideo(ImageSource.camera, context);
  }

  Future<void> reInitializeLastVideo(BuildContext context) async {
    try {
      if (_currentVideoPath != null && _currentVideoPath!.isNotEmpty) {
        final file = File(_currentVideoPath!);
        if (await file.exists()) {
          videoFile = file;
          if (context.mounted) await _initializeVideoController(context);
        }
      }
    } catch (e) {
      // Do Nothing, just ensure we don't throw an error
    }
  }

  Future<void> fetchModels() async {
    try {
      models = null;
      emit(VideoLoading());
      models = await ApiService.getModels();
      if (models!.isNotEmpty) {
        selectedModel = models![2];
        emit(VideoInitial());
      } else {
        emit(VideoError('Please try again'));
        models = [];
      }
    } catch (e) {
      emit(VideoError('Network error occurred'));
      models = [];
    }
  }

  Future<File?> compressAndUploadVideo(String videoPath) async {
    try {
      // Start compression
      final info = await VideoCompress.compressVideo(
        videoPath,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
      );

      if (info != null && info.file != null) {
        return info.file!;
      }
    } catch (e) {
      debugPrint('[VideoCompress] Error compressing video: $e');
    }
    return null;
  }

  Future<void> _pickVideo(ImageSource source, BuildContext context) async {
    try {
      if (selectedModel.isEmpty) {
        return;
      }

      final XFile? pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 1),
      );

      debugPrint('[VideoPicker] Selected file: $pickedFile');

      if (pickedFile != null) {
        await cleanupController();
        _currentVideoPath = pickedFile.path;

        final file = File(_currentVideoPath!);

        if (await file.exists()) {
          videoFile = file;
          videoModelsCache.clear();
          if (context.mounted) await _initializeVideoController(context);
          videoModelsCache.add(selectedVideo!.copyWith());
          for (final item in videoModelsCache) {
            debugPrint('[VideoCache] Cache item: $item');
          }
        } else {
          emit(VideoError('Video file not found'));
        }
      } else {
        debugPrint(
            '[VideoPicker] Current video path status: ${_currentVideoPath != null ? "available" : "null"}');
        // User canceled picking video
        if (controller == null && _currentVideoPath != null) {
          if (context.mounted) await reInitializeLastVideo(context);
        } else {
          emit(VideoPlaying());
        }
      }
    } catch (e) {
      emit(VideoError('Failed to setup video'));
    }
  }

  Future<void> _initializeVideoController(BuildContext context) async {
    if (state is VideoLoading || loading) return;
    loading = true;
    if (state is VideoLoading) return;
    emit(VideoLoading());
    try {
      await cleanupController();

      var temp = VideoPlayerController.file(videoFile!);
      await temp.initialize();
      // check on time duration of video max is 1 minute
      if (temp.value.duration.inSeconds > 60) {
        _currentVideoPath = null;

        await cleanupController();
        emit(VideoError('Video duration exceeds 1 minute'));
        return;
      }

      controller = temp;
      _setupVideoProgressTracking();

      totalVideoSeconds = controller!.value.duration.inSeconds;
      totalDuration = _formatDuration(controller!.value.duration);

      selectedVideo = VideoModel(
        id: const Uuid().v4(),
        title: '',
        url: '',
        result: '',
        model: selectedModel,
      );
      emit(VideoLoading());
      nameVideoController.text = await _videoRepository.getNextTitle();
      selectedVideo?.title = nameVideoController.text;

      // Only compress video if we don't have a cached hash
      if (selectedVideo?.fileHash == null) {
        File? file = await compressAndUploadVideo(videoFile!.path);
        if (file != null) {
          videoFile = file;
        }
      }

      // Start transcription using the new progress system
      if (context.mounted) {
        debugPrint(
            '[VideoCubit] Starting transcription with progress tracking');
        await startTranscriptionWithProgress(context);
      }

      await controller!.play();
      showControls = true;
      _resetHideControlsTimer();

      // Don't emit VideoSuccess immediately - wait for transcription to complete
      // The success will be emitted when progress completes in startTranscriptionWithProgress
      return;
    } catch (e) {
      loading = false;
      emit(VideoError('Failed to process video try again'));
      return;
    }
  }

  Future<bool> canUpload() async {
    if (controller == null ||
        !await ConnectivityService().isConnected() ||
        selectedVideo == null) {
      return false;
    }
    return true;
  }

  // Repository Methods
  Future<void> uploadVideo(BuildContext context) async {
    try {
      if (!await canUpload()) {
        if (!await ConnectivityService().isConnected()) {
          emit(VideoError('No internet connection'));
        } else {
          emit(VideoError('No video selected'));
        }
        return;
      }
      if (nameVideoController.text.isEmpty) throw Exception('');
      await pauseVideo();
      await _videoRepository.addVideo(selectedVideo!);

      String videoUrl = await _videoRepository.uploadVideoFile(
        File(_currentVideoPath!),
        selectedVideo!.id,
      );

      selectedVideo!.url = videoUrl;
      selectedVideo?.model = selectedModel;
      await _videoRepository.updateVideo(selectedVideo!);
    } catch (e) {
      emit(VideoError(
          'you arrive into limit please delete to upload another video'));
    }
  }

  Future<void> updateVideoResult() async {
    try {
      if (!await ConnectivityService().isConnected()) {
        emit(VideoError('No internet connection'));
        return;
      }

      // Check if video has been uploaded to Firestore (has URL)
      if (selectedVideo == null || selectedVideo!.url.isEmpty) {
        debugPrint(
            '[VideoCubit] Skipping Firestore update - video not uploaded yet');
        return;
      }

      await _videoRepository.updateVideoResult(selectedVideo!);
    } catch (e) {
      debugPrint('[VideoCubit] Repository update error: $e');
      emit(VideoError('Network error occurred while saving video'));
    }
  }

  Future<void> fetchVideos() async {
    if (state is HistoryLoading) return;
    emit(HistoryLoading());
    try {
      if (!await ConnectivityService().isConnected()) {
        throw Exception('No internet connection');
      }
      videos = await _videoRepository.getVideoHistory();
      emit(HistoryFetchedSuccess());
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }

  Future<void> updateVideoTitle(BuildContext context) async {
    try {
      if (selectedVideo == null) {
        if (context.mounted) {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.warning,
            animType: AnimType.rightSlide,
            title: 'No video selected',
            btnOkOnPress: () {},
            btnOkColor: Theme.of(context).primaryColor,
          ).show();
        }
        return;
      }
      // check on network
      if (!await ConnectivityService().isConnected()) {
        if (context.mounted) {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.warning,
            animType: AnimType.rightSlide,
            title: 'No internet connection',
            btnOkOnPress: () {},
            btnOkColor: Theme.of(context).primaryColor,
          ).show();
        }
        return;
      }
      if (nameVideoController.text.isEmpty) throw Exception('');

      await _videoRepository.updateVideoTitle(
          selectedVideo!.id, nameVideoController.text);

      // Update local state
      selectedVideo = selectedVideo!.copyWith(title: nameVideoController.text);
      if (context.mounted) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          animType: AnimType.rightSlide,
          title: 'Video title updated successfully',
          btnOkOnPress: () {},
          btnOkColor: Theme.of(context).primaryColor,
        ).show();
      }
    } catch (e) {
      if (context.mounted) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          title: 'Failed to update title, Video not exist',
          btnOkOnPress: () {},
          btnOkColor: Theme.of(context).primaryColor,
        ).show();
      }
    }
  }

  Future<void> deleteVideo(context, String videoId) async {
    if (state is HistoryLoading) return;
    emit(HistoryLoading());
    try {
      if (!await ConnectivityService().isConnected()) {
        if (context.mounted) {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.error,
            animType: AnimType.rightSlide,
            title: 'No internet connection',
            btnOkOnPress: () {},
            btnOkColor: Theme.of(context).primaryColor,
          ).show();
        }
        emit(HistoryError('No internet connection'));
        return;
      }
      if (videoId == selectedVideo?.id) {
        debugPrint('[VideoDelete] Selected video has same ID as deleted video');
        await cleanupController();
        videoFile = null;
        _currentVideoPath = null;
      } else {
        debugPrint('[VideoDelete] Selected video has different ID');
      }
      await _videoRepository.deleteVideo(videoId);

      // Update local state
      videos.removeWhere((video) => video.id == videoId);
      if (selectedVideo?.id == videoId) {
        selectedVideo = null;
      }

      emit(DeleteHistoryItemSuccess());
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }

  Future<void> replay_10() async {
    final currentPosition = controller!.value.position;
    await controller!.seekTo(currentPosition - const Duration(seconds: 10));
    updateVideoPosition(
        controller!.value.position.inSeconds.toDouble() / totalVideoSeconds);

    emit(VideoPlaying());
  }

  Future<void> forward_10() async {
    final currentPosition = controller!.value.position;
    await controller!.seekTo(currentPosition + const Duration(seconds: 10));
    updateVideoPosition(
        controller!.value.position.inSeconds.toDouble() / totalVideoSeconds);
    emit(VideoPlaying());
  }

  @override
  Future<void> close() async {
    await cleanupController();
    nameVideoController.dispose();
    return super.close();
  }

  Future<void> changeModel(String model, BuildContext context) async {
    if (state is VideoLoading || loading) return;
    loading = true;
    selectedModel = model;

    // if not select video
    if (selectedVideo == null) {
      loading = false;
      emit(VideoSuccess());
      return;
    }
    try {
      emit(VideoLoading());
      for (final item in videoModelsCache) {
        if (item.model == model && item.diacritized == isDiacritized) {
          selectedVideo = item.copyWith();
          loading = false;
          emit(VideoSuccess());
          return;
        }
      }

      var response = await ApiService.uploadFile(
          fileHash: selectedVideo?.fileHash,
          file: videoFile,
          modelName: selectedModel,
          dia: isDiacritized);
      if (response['error'] != null) {
        loading = false;
        emit(VideoError(response['error']));
      }
      selectedVideo?.result = response['raw_transcript'] ?? '';
      selectedVideo?.fileHash = response['video_hash'];

      selectedVideo?.model = selectedModel;
      videoModelsCache.add(selectedVideo!.copyWith());
      updateVideoResult();

      loading = false;
      emit(VideoSuccess());
    } catch (e) {
      loading = false;
      debugPrint('[VideoCubit] Error in changeModel: $e');
      emit(VideoError('Network error occurred'));
    }
  }

  Future<void> onEnd(double value) async {
    debugPrint('[VideoSlider] Position changed to: $value');
    final position = Duration(seconds: (value * totalVideoSeconds).toInt());
    await controller!.seekTo(position);
    emit(VideoPlaying());
  }

  // Toggle diacritized setting
  void toggleDiacritized(bool value) {
    if (isDiacritized == value) return; // No change needed
    isDiacritized = !isDiacritized;
    emit(VideoSuccess()); // Emit to update UI
  }

  // Re-process video with current diacritized setting
  Future<void> reprocessWithDiacritized() async {
    if (selectedVideo == null || loading) return;
    loading = true;
    try {
      emit(VideoLoading());
      for (int i = 0; i < videoModelsCache.length; i++) {
        debugPrint('[VideoDiacritized] Cache item $i: ${videoModelsCache[i]}');
      }
      for (final item in videoModelsCache) {
        if (item.model == selectedModel && item.diacritized == isDiacritized) {
          debugPrint('[VideoDiacritized] Found matching cached item: $item');
          selectedVideo = item.copyWith();
          loading = false;
          emit(VideoSuccess());
          return;
        }
      }
      var response = await ApiService.uploadFile(
          fileHash: selectedVideo?.fileHash,
          file: videoFile,
          modelName: selectedModel,
          dia: isDiacritized);
      if (response['error'] != null) {
        loading = false;
        emit(VideoError(response['error']));
      }
      selectedVideo?.result = response['raw_transcript'] ?? '';
      selectedVideo?.fileHash = response['video_hash'];
      debugPrint(
          '[VideoDiacritized] API response diacritized status: ${response['diacritized']}');
      selectedVideo?.diacritized = isDiacritized;
      videoModelsCache.add(selectedVideo!.copyWith());
      for (final item in videoModelsCache) {
        debugPrint('[VideoDiacritized] Updated cache item: $item');
      }
      await updateVideoResult();

      loading = false;
      emit(VideoSuccess());
    } catch (e) {
      loading = false;
      debugPrint('[VideoDiacritized] Error: ${e.toString()}');
      emit(VideoError('Network error occurred'));
    }
  }

  /// Update video results from progress system
  void updateVideoResultFromProgress({
    required String rawTranscript,
    String? videoHash,
    Map<String, dynamic>? metadata,
  }) {
    if (selectedVideo != null) {
      debugPrint('[VideoCubit] Updating video results from progress');
      debugPrint('[VideoCubit] Raw transcript: $rawTranscript');
      debugPrint('[VideoCubit] Video hash: $videoHash');
      debugPrint('[VideoCubit] Metadata: $metadata');

      selectedVideo!.result = rawTranscript;
      selectedVideo!.fileHash = videoHash;
      if (metadata != null) {
        selectedVideo!.diacritized = metadata['diacritized'] ?? isDiacritized;
      } else {
        selectedVideo!.diacritized = isDiacritized;
      }

      loading = false;
      emit(VideoSuccess());
    }
  }

  /// Start transcription using the new progress system
  Future<void> startTranscriptionWithProgress(BuildContext context) async {
    if (videoFile == null || selectedModel.isEmpty) {
      emit(VideoError('Please select a video and model'));
      return;
    }

    try {
      // Get progress cubit
      final progressCubit = context.read<ProgressCubit>();

      // Listen to progress state changes
      late StreamSubscription progressSubscription;
      progressSubscription = progressCubit.stream.listen((progressState) async {
        if (progressState is ProgressCompleted) {
          debugPrint('[VideoCubit] Progress completed, updating video results');
          debugPrint('[VideoCubit] Results: ${progressState.result}');

          // Extract results from progress completion
          final result = progressState.result;
          if (result.containsKey('raw_transcript')) {
            final rawTranscript = result['raw_transcript'] as String? ?? '';
            final videoHash = result['video_hash'] as String?;
            final metadata = result['metadata'] as Map<String, dynamic>? ?? {};

            // Update video results
            updateVideoResultFromProgress(
              rawTranscript: rawTranscript,
              videoHash: videoHash,
              metadata: metadata,
            );

            // Cache the result
            if (selectedVideo != null) {
              selectedVideo!.diacritized = isDiacritized;
              videoModelsCache.add(selectedVideo!.copyWith());
              debugPrint('[VideoCubit] Added to cache: ${selectedVideo!}');
            }

            // Try to save to repository
            try {
              await updateVideoResult();
            } catch (e) {
              debugPrint('[VideoCubit] Repository update failed: $e');
              // This is expected for videos that haven't been uploaded to Firestore yet
            }
          }

          // Cancel subscription
          progressSubscription.cancel();
        } else if (progressState is ProgressFailed) {
          debugPrint(
              '[VideoCubit] Progress failed: ${progressState.errorMessage}');
          loading = false;
          emit(VideoError(
              'Transcription failed: ${progressState.errorMessage}'));
          progressSubscription.cancel();
        }
      });

      // Start transcription with progress tracking
      await progressCubit.startTranscription(
        videoFile: videoFile!,
        modelName: selectedModel,
        diacritized: isDiacritized,
        fileHash: selectedVideo?.fileHash,
      );
    } catch (e) {
      emit(VideoError('Failed to start transcription: ${e.toString()}'));
    }
  }
}
