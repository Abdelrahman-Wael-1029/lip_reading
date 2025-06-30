import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lip_reading/model/video_model.dart';
import 'package:lip_reading/service/firestore_service.dart';
import 'package:lip_reading/service/storage_service.dart';

class VideoRepository {
  final FirestoreService _firestoreService;
  final StorageService _storageService;

  VideoRepository({
    FirestoreService? firestoreService,
    StorageService? storageService,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _storageService = storageService ?? StorageService();

  // Constants
  String get _collection {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }
    return 'users/${user.uid}/videos';
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

  Future<void> 
  updateVideoResult(VideoModel videoModel) async {
    try {
      await _firestoreService.updateDocument(
        collection: _collection,
        documentId: videoModel.id,
        data: {'result': videoModel.result,
        'model': videoModel.model,
        'diacritized': videoModel.diacritized,
        },
      );
    } catch (e) {
      throw Exception('Failed to update video results: $e');
    }
  }

  Future<void> updateVideoTitle(String videoId, String newTitle) async {
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

  Future<String> uploadVideoFile(File videoFile, String fileName) async {
    try {
      return await _storageService.uploadData(
        data: videoFile.readAsBytesSync(),
        storagePath: 'videos',
        fileName: fileName,
      );
    } catch (e) {
      throw Exception('Failed to upload video file: $e');
    }
  }

  Future<int> getVideosCount() async {
    try {
      return await _firestoreService.getCollectionCount(
          collection: _collection);
    } catch (e) {
      return 0;
    }
  }

  Future<String> getNextTitle() async {
    try {
      int count = await getVideosCount();
      if(count > 15) throw Exception("You have reached the maximum number of videos");
      return "Video ${count + 1}";
    } catch (e) {
      return "";
    }
  }
}
