import 'dart:async';
import 'dart:io';
import 'package:video_compress/video_compress.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  List<String> models = [];
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

  // Timers and subscriptions
  Timer? _hideControlsTimer;
  StreamSubscription? _videoProgressSubscription;

  VideoCubit({VideoRepository? videoRepository})
      : _videoRepository = videoRepository ?? VideoRepository(),
        super(VideoInitial()) {
    emit(VideoLoading());
    ApiService.getModels().then((v) {
      models = v;
      if (models.isNotEmpty) selectedModel = models[2];
      emit(VideoInitial());
    }).catchError((e) {
      emit(VideoError('حاول مرة اخرى'));
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
      await cleanupController();

      // Store selected video before initializing controller
      selectedVideo = video;
      selectedModel = video.model;
      nameVideoController.text = video.title;

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
    if(context.mounted) await _pickVideo(ImageSource.gallery, context);
  }

  Future<void> recordVideo(BuildContext context) async {
    if (loading) return;
    await pauseVideo();
    if(context.mounted) await _pickVideo(ImageSource.camera, context);
  }

  Future<void> reInitializeLastVideo(BuildContext context) async {
    try {
      if (_currentVideoPath != null && _currentVideoPath!.isNotEmpty) {
        final file = File(_currentVideoPath!);
        if (await file.exists()) {
          videoFile = file;
          if(context.mounted) await _initializeVideoController(context);
        }
      }
    } catch (e) {
      // Do Nothing, just ensure we don't throw an error
    }
  }

  Future<void> fetchModels() async {
    emit(VideoLoading());
    models = await ApiService.getModels();
    if (models.isNotEmpty) {
      selectedModel = models[2];
      emit(VideoInitial());
    } else {
      emit(VideoError('حاول مرة اخرى'));
      throw Exception('حدث خطاء في الانترنت');
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
      debugPrint('Error compressing video: $e');
    }
    return null;
  }

  Future<void> _pickVideo(ImageSource source, BuildContext context) async {
    try {
      if (selectedModel.isEmpty) {
        await fetchModels();
      }

      final XFile? pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 1),
      );

      debugPrint('pickedFile: $pickedFile');

      if (pickedFile != null) {
        await cleanupController();
        _currentVideoPath = pickedFile.path;

        final file = File(_currentVideoPath!);

        if (await file.exists()) {
          videoFile = file;
          if(context.mounted) await _initializeVideoController(context);
        } else {
          emit(VideoError('Video file not found'));
        }
      } else {
        debugPrint(
            '_currentVideoPath is ${_currentVideoPath != null ? "not null" : "null"}');
        // User canceled picking video
        if (controller == null && _currentVideoPath != null) {
          if(context.mounted) await reInitializeLastVideo(context);
        } else {
          emit(VideoPlaying());
        }
      }
    } catch (e) {
      emit(VideoError('حدث خطا في اعداد الفيديو'));
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
      File? file = await compressAndUploadVideo(videoFile!.path);
      if (file != null) {
        videoFile = file;
      }

      var response = await ApiService.uploadFile(
          fileHash: selectedVideo?.fileHash,
          file: videoFile!,
          modelName: selectedModel,
          dia: isDiacritized);
      debugPrint('myresponse $response');

      selectedVideo?.result = response['raw_transcript'] ?? '';
      selectedVideo?.fileHash = response['video_hash'];
      selectedVideo?.diacritized = response['diacritized'] ?? false;
      if(context.mounted) await uploadVideo(context);
      await controller!.play();
      showControls = true;
      _resetHideControlsTimer();
      loading = false;
      emit(VideoSuccess());
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

      // if (context.mounted) {
      //   AwesomeDialog(
      //     context: context,
      //     dialogType: DialogType.success,
      //     animType: AnimType.rightSlide,
      //     title: 'Video uploaded successfully',
      //     btnOkOnPress: () {},
      //   ).show();
      // }
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
      await _videoRepository.updateVideoResult(selectedVideo!);
    } catch (e) {
      emit(VideoError(e.toString()));
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
      emit(HistorySuccess());
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
      await _videoRepository.deleteVideo(videoId);

      // Update local state
      videos.removeWhere((video) => video.id == videoId);
      if (selectedVideo?.id == videoId) {
        selectedVideo = null;
      }

      emit(HistorySuccess());
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
    try {
      emit(VideoLoading());
      selectedModel = model;
      var response = await ApiService.uploadFile(
          fileHash: selectedVideo?.fileHash,
          file: videoFile!,
          modelName: selectedModel,
          dia: isDiacritized);
      selectedVideo?.result = response['raw_transcript'] ?? '';
      selectedVideo?.fileHash = response['video_hash'];
      if (selectedVideo?.model != selectedModel) {
        selectedVideo?.model = selectedModel;
        updateVideoResult();
      }

      loading = false;
      emit(VideoSuccess());
    } catch (e) {
      loading = false;
      emit(VideoError('خطاء في الانترنت'));
    }
  }

  Future<void> onEnd(double value) async {
    debugPrint('end change');
    final position = Duration(seconds: (value * totalVideoSeconds).toInt());
    await controller!.seekTo(position);
    emit(VideoPlaying());
  }

  // Toggle diacritized setting
  void toggleDiacritized() {
    isDiacritized = !isDiacritized;
    emit(VideoSuccess()); // Emit to update UI
  }

  // Re-process video with current diacritized setting
  Future<void> reprocessWithDiacritized() async {
    if (videoFile == null || selectedVideo == null || loading) return;
    loading = true;
    try {
      emit(VideoLoading());
      var response = await ApiService.uploadFile(
          fileHash: selectedVideo?.fileHash,
          file: videoFile!,
          modelName: selectedModel,
          dia: isDiacritized);
      selectedVideo?.result = response['raw_transcript'] ?? '';
      selectedVideo?.fileHash = response['video_hash'];
      if (selectedVideo?.diacritized != isDiacritized) {
        selectedVideo?.diacritized = isDiacritized;
        await updateVideoResult();
      }
      loading = false;
      emit(VideoSuccess());
    } catch (e) {
      loading = false;
      emit(VideoError('خطاء في الانترنت'));
    }
  }
}
