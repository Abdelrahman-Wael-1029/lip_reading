import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lip_reading/cubit/video_cubit/video_state.dart';
import 'package:lip_reading/model/video_model.dart';
import 'package:lip_reading/service/firestore_service.dart';
import 'package:lip_reading/service/storage_service.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

class VideoCubit extends Cubit<VideoState> {
  VideoCubit() : super(VideoInitial());
  double videoProgress = 0.0;
  int totalVideoSeconds = 0;
  String currentPosition = "0:00";
  String totalDuration = "0:00";
  Timer? _hideControlsTimer;
  String? _currentVideoPath;
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final String _collection = 'videos';
  List<VideoModel> videos = [];
  String? result;
  String name = '';

  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? controller;
  StreamSubscription? _videoProgressSubscription;

  bool showControls = true;

  void toggleControls() {
    showControls = !showControls;
    emit(VideoSuccess());
    if (showControls) {
      _resetHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  //initialize network video
  Future<void> initializeNetworkVideo(String videoUrl) async {
    await _cleanupController();
    controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    await controller!.initialize();
    totalVideoSeconds = controller!.value.duration.inSeconds;
    totalDuration = _formatDuration(controller!.value.duration);
    emit(VideoSuccess());
  }

  void updateVideoPosition(double progress) {
    videoProgress = progress;
    showControls = true;
    emit(VideoSuccess());

    _resetHideControlsTimer();
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();

    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      showControls = false;
      emit(VideoSuccess());
    });
  }

  void updatePlayPauseIcon(bool isPlaying) {
    emit(VideoSuccess());
  }

  Future<void> pauseVideo() async {
    if (controller != null) {
      await controller!.pause();
    }
  }

  Future<void> pickVideoFromGallery() async {
    await pauseVideo();
    await _pickVideo(ImageSource.gallery);
  }

  Future<void> recordVideo() async {
    await pauseVideo();
    await _pickVideo(ImageSource.camera);
  }

  Future<void> _cleanupController() async {
    _videoProgressSubscription?.cancel();
    _videoProgressSubscription = null;

    _hideControlsTimer?.cancel();
    _hideControlsTimer = null;

    if (controller != null) {
      await controller!.pause();
      await controller!.dispose();
      controller = null;
    }
  }

  // Call this method when returning to the screen
  Future<void> reInitializeLastVideo() async {
    print('reinitial ');
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
        await _cleanupController();
        String videoPath = pickedFile.path;
        _currentVideoPath = videoPath;
        final file = File(videoPath);

        if (await file.exists()) {
          await _cleanupController();
          await _initializeVideoController(file);
          uploadVideo();
        } else {
          emit(VideoError('Video file not found'));
        }
      } else {
        // User canceled picking video
        if (controller == null && _currentVideoPath != null) {
          // Try to reinitialize previous video
          await reInitializeLastVideo();
        } else {
          emit(VideoSuccess());
        }
      }
    } catch (e) {
      emit(VideoError('Failed to load video: ${e.toString()}'));
    }
  }

  Future<void> _initializeVideoController(File videoFile) async {
    try {
      controller = VideoPlayerController.file(videoFile);

      // Wait for controller to initialize
      await controller!.initialize();

      totalVideoSeconds = controller!.value.duration.inSeconds;
      totalDuration = _formatDuration(controller!.value.duration);

      // Use a separate stream subscription instead of the listener
      _videoProgressSubscription =
          Stream.periodic(const Duration(milliseconds: 200)).listen((_) {
        // check is playing or pause
        if (controller != null &&
            controller!.value.isInitialized &&
            controller!.value.isPlaying) {
          final position = controller!.value.position;
          final duration = controller!.value.duration;

          if (duration.inSeconds > 0) {
            videoProgress = position.inSeconds / duration.inSeconds;
            currentPosition = _formatDuration(position);
            result =
                'this is the result from video cubit ${videoProgress} ${currentPosition} ${totalDuration} in initialize video for the video cubit at video vor ljsdlj ljs ls jsl jsl jsl jslj lsj ljs';
            emit(VideoSuccess());
          }
        }
      });

      await controller!.play();
      showControls = true;
      _resetHideControlsTimer();
      emit(VideoSuccess());
    } catch (e) {
      emit(VideoError('Failed to initialize video: ${e.toString()}'));
    }
  }

  // initalize controller and seek to the current position
  Future<void> seekToCurrentPosition() async {
    try {
      final currentPosition = controller!.value.position;
      await controller!.initialize();
      await controller!.seekTo(currentPosition);
      emit(VideoSuccess());
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Future<void> close() async {
    await _cleanupController();
    return super.close();
  }

  Future<void> uploadVideo() async {
    try {
      emit(VideoLoading());
      String name = await getNextTitle();
      String videoUrl = await _storageService.uploadData(
        data: File(_currentVideoPath!).readAsBytesSync(),
        storagePath: 'videos',
        fileName: name,
      );
      String id = const Uuid().v4();

      await addVideo(
          VideoModel(id: id, title: name, url: videoUrl, result: result!));

      emit(VideoSuccess());
    } catch (e) {
      print('error in upload video ' + e.toString());
      emit(VideoError(e.toString()));
    }
  }

  Future<void> fetchVideos() async {
    emit(VideoLoading());
    try {
      videos = await getVideoHistory();
      emit(VideoSuccess());
    } catch (e) {
      emit(VideoError(e.toString()));
    }
  }

  // Get a video by ID
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

  // Get all videos (history)
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
      throw Exception('Failed to get video history: $e');
    }
  }

  // Create a new video
  Future<String> addVideo(VideoModel video) async {
    try {
      return await _firestoreService.addDocument(
        collection: _collection,
        data: video.toJson(),
      );
    } catch (e) {
      throw Exception('Failed to add video: $e');
    }
  }

  // Update video title
  Future<void> updateVideoTitle({
    required String videoId,
    required String newTitle,
  }) async {
    try {
      await _firestoreService.updateDocument(
        collection: _collection,
        documentId: videoId,
        data: {'title': newTitle},
      );
    } catch (e) {
      throw Exception('Failed to update video title: $e');
    }
  }

  // Update entire video
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

  // Delete a video
  Future<void> deleteVideo(String videoId) async {
    try {
      await _firestoreService.deleteDocument(
        collection: _collection,
        documentId: videoId,
      );
    } catch (e) {
      throw Exception('Failed to delete video: $e');
    }
  }

  Future<String> getNextTitle() async {
    name =
        "Video ${(await _firestoreService.getLenthDocsCollection(collection: _collection))}";
    return name;
  }
}
