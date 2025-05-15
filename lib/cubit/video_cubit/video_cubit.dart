import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lip_reading/cubit/video_cubit/video_state.dart';
import 'package:lip_reading/model/video_model.dart';
import 'package:lip_reading/service/firestore_service.dart';
import 'package:lip_reading/service/storage_service.dart';
import 'package:lip_reading/utils/color_scheme_extension.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

class VideoCubit extends Cubit<VideoState> {
  // Services
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  // Constants
  String get _collection {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }
    return 'users/${user.uid}/videos';
  }

  // Controllers
  VideoPlayerController? controller;
  final nameVideoController = TextEditingController();

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

  VideoCubit() : super(VideoInitial());

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
      await cleanupController();

      // Store selected video before initializing controller
      selectedVideo = video;
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
      debugPrint('Network video initialization error: ${e.toString()}');
      emit(VideoError('Failed to initialize network video: ${e.toString()}'));
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
      debugPrint('Error seeking to position: ${e.toString()}');
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
      if (controller != null &&
          controller!.value.isInitialized &&
          controller!.value.isPlaying) {
        final position = controller!.value.position;
        final duration = controller!.value.duration;

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

  // Video Pick Methods
  Future<void> pickVideoFromGallery() async {
    await pauseVideo();
    await _pickVideo(ImageSource.gallery);
  }

  Future<void> recordVideo() async {
    await pauseVideo();
    await _pickVideo(ImageSource.camera);
  }

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
        maxDuration: const Duration(minutes: 1),
      );

      if (pickedFile != null) {
        await cleanupController();
        _currentVideoPath = pickedFile.path;
        final file = File(_currentVideoPath!);

        if (await file.exists()) {
          var success = await _initializeVideoController(file);
          if (!success) return;
          uploadVideo();
        } else {
          emit(VideoError('Video file not found'));
        }
      } else {
        // User canceled picking video
        if (controller == null && _currentVideoPath != null) {
          await reInitializeLastVideo();
        } else {
          emit(VideoPlaying());
        }
      }
    } catch (e) {
      emit(VideoError('Failed to load video: ${e.toString()}'));
    }
  }

  Future<bool> _initializeVideoController(File videoFile) async {
    if (state is VideoLoading) return false;
    emit(VideoLoading());
    try {
      await cleanupController();

      var temp = VideoPlayerController.file(videoFile);
      await temp.initialize();
      // check on time duration of video max is 1 minute
      print("time of video in initialize${temp.value.duration.inMinutes}");
      if (temp.value.duration.inSeconds > 60) {
        emit(VideoError('Video duration exceeds 1 minute'));
        return false;
      }

      controller = temp;
      _setupVideoProgressTracking();

      totalVideoSeconds = controller!.value.duration.inSeconds;
      totalDuration = _formatDuration(controller!.value.duration);

      await controller!.play();
      showControls = true;
      _resetHideControlsTimer();

      emit(VideoSuccess());
      return true;
    } catch (e) {
      emit(VideoError('Failed to process video try again'));
      return false;
    }
  }

  // Firestore Methods
  Future<void> uploadVideo() async {
    try {
      if (_currentVideoPath == null) {
        emit(VideoError('No video selected'));
        return;
      }
      String id = const Uuid().v4();
      String result =
          'Video analysis result for ${nameVideoController.text} and this is my result for this video and this is vidoe iven t tell me is if continue for the video';
      nameVideoController.text = await getNextTitle();
      selectedVideo = VideoModel(
        id: id,
        title: nameVideoController.text,
        url: '',
        result: result,
      );

      await addVideo(selectedVideo!);
      emit(VideoSuccess());

      String videoUrl = await _storageService.uploadData(
        data: File(_currentVideoPath!).readAsBytesSync(),
        storagePath: 'videos',
        fileName: id,
      );

      selectedVideo!.url = videoUrl;
      await updateVideo(selectedVideo!);

      emit(VideoSuccess());
    } catch (e) {
      debugPrint('Error in upload video: ${e.toString()}');
      emit(VideoError(e.toString()));
    }
  }

  Future<void> fetchVideos() async {
    emit(HistoryLoading());
    try {
      videos = await getVideoHistory();
      emit(HistorySuccess());
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }

  Future<VideoModel?> getVideo(String videoId) async {
    try {
      final videoData = await _firestoreService.getDocument(
        collection: _collection,
        documentId: videoId,
      );

      if (videoData != null) {
        return VideoModel.fromJson(videoData, docId: videoId);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get video: $e');
    }
  }

  Future<List<VideoModel>> getVideoHistory({
    String? orderBy = 'createdAt',
    bool descending = true,
    int? limit,
  }) async {
    try {
      final videosData = await _firestoreService.getCollection(
        collection: _collection,
        orderBy: orderBy,
        descending: descending,
        limit: limit,
      );

      return videosData.map((data) {
        final String id = data['id'];
        data.remove('id');
        return VideoModel.fromJson(data, docId: id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get video history');
    }
  }

  Future<String> addVideo(VideoModel video) async {
    try {
      return await _firestoreService.setDocument(
        collection: _collection,
        documentId: video.id,
        data: video.toJson(),
      );
    } catch (e) {
      throw Exception('Failed to add video: $e');
    }
  }

  Future<void> updateVideoTitle(BuildContext context) async {
    try {
      if (selectedVideo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No video selected. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      await _firestoreService.updateDocument(
        collection: _collection,
        documentId: selectedVideo!.id,
        data: {'title': nameVideoController.text},
      );

      // Update local state
      selectedVideo = selectedVideo!.copyWith(title: nameVideoController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Video title updated successfully!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).colorScheme.success,
        ),
      );
      emit(VideoSuccess());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Failed to update title try again later',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> updateVideo(VideoModel video) async {
    try {
      await _firestoreService.updateDocument(
        collection: _collection,
        documentId: video.id,
        data: video.toJson(),
      );
    } catch (e) {
      throw Exception('Failed to update video: $e');
    }
  }

  Future<void> deleteVideo(String videoId) async {
    try {
      await _firestoreService.deleteDocument(
        collection: _collection,
        documentId: videoId,
      );

      // Update local state if needed
      videos.removeWhere((video) => video.id == videoId);
      if (selectedVideo?.id == videoId) {
        selectedVideo = null;
      }

      emit(VideoPlaying());
    } catch (e) {
      throw Exception('Failed to delete video: $e');
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

  Future<String> getNextTitle() async {
    try {
      int count =
          await _firestoreService.getCollectionCount(collection: _collection);
      return "Video ${count + 1}";
    } catch (e) {
      return "New Video";
    }
  }

  @override
  Future<void> close() async {
    await cleanupController();
    nameVideoController.dispose();
    return super.close();
  }
}
