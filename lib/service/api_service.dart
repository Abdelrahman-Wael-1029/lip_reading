import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:lip_reading/model/progress_model.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Primary API service for interacting with the Arabic Lip Reading backend
/// This service consolidates all API functionality including:
/// - Model configuration retrieval
/// - File upload and transcription (both sync and async)
/// - Progress tracking and streaming
/// - Task management and cancellation
///
/// Replaces the previous ProgressService by merging all related functionality
class ApiService {
  static const String baseUrl = "https://arabic-lip-reading.loca.lt";

  // Get models
  static Future<List<String>> getModels() async {
    final url = Uri.parse('$baseUrl/config');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> models = data['model']['available_models'];
      return models.map((e) => e.toString()).toList();
    } else {
      throw Exception("Failed to fetch available models");
    }
  }

  /// Start transcription process and return task ID with fallback logic
  /// This is the enhanced version supporting progress tracking and additional features
  static Future<String> startTranscription({
    File? file,
    required String modelName,
    bool dia = false,
    String? fileHash,
    String? videoUrl, // Firebase storage URL for history videos
    bool enhance = false,
    bool includeSummary = false,
    bool includeTranslation = false,
    String targetLanguage = "English",
    Function(double)? onUploadProgress,
  }) async {
    final url = Uri.parse('$baseUrl/transcribe/');

    // First attempt: Try with file hash if available
    if (fileHash != null) {
      debugPrint('[ApiService] Attempting with cached file hash: $fileHash');

      final hashRequest = http.MultipartRequest('POST', url)
        ..fields['model_name'] = modelName
        ..fields['diacritized'] = dia.toString()
        ..fields['enhance'] = enhance.toString()
        ..fields['include_summary'] = includeSummary.toString()
        ..fields['include_translation'] = includeTranslation.toString()
        ..fields['target_language'] = targetLanguage
        ..fields['file_hash'] = fileHash;

      try {
        final hashStreamedResponse = await hashRequest.send();
        final hashResponse =
            await http.Response.fromStream(hashStreamedResponse);

        if (hashResponse.statusCode == 200) {
          final data = jsonDecode(hashResponse.body);
          final taskId = data['task_id'] as String;
          debugPrint(
              '[ApiService] Successfully used cached file hash, task ID: $taskId');
          return taskId;
        } else if (hashResponse.statusCode == 404) {
          debugPrint(
              '[ApiService] File hash not found (404), falling back to file upload');
          // Continue to file upload fallback
        } else {
          debugPrint(
              '[ApiService] Hash request failed with status: ${hashResponse.statusCode}');
          throw Exception(
              "Network error occurred during transcription (hash): ${hashResponse.statusCode}");
        }
      } catch (e) {
        debugPrint('[ApiService] Hash request failed: $e');
        // Continue to file upload fallback
      }
    }

    // Fallback: Upload the actual file
    File? fileToUpload = file;

    // If file is null but we have a video URL (history video), download it from Firebase
    if (fileToUpload == null && videoUrl != null) {
      debugPrint('[ApiService] Downloading video from Firebase: $videoUrl');
      try {
        fileToUpload = await _downloadVideoFromFirebase(videoUrl);
      } catch (e) {
        debugPrint('[ApiService] Failed to download video from Firebase: $e');
        throw Exception("Failed to download video from storage: $e");
      }
    }

    if (fileToUpload == null) {
      throw Exception("No file available for upload and no valid file hash");
    }

    debugPrint('[ApiService] Uploading file: ${fileToUpload.path}');
    final fileRequest = http.MultipartRequest('POST', url)
      ..fields['model_name'] = modelName
      ..fields['diacritized'] = dia.toString()
      ..fields['enhance'] = enhance.toString()
      ..fields['include_summary'] = includeSummary.toString()
      ..fields['include_translation'] = includeTranslation.toString()
      ..fields['target_language'] = targetLanguage;

    fileRequest.files.add(
      await http.MultipartFile.fromPath(
        'file',
        fileToUpload.path,
        filename: basename(fileToUpload.path),
      ),
    );

    final fileStreamedResponse = await fileRequest.send();
    final fileResponse = await http.Response.fromStream(fileStreamedResponse);

    if (fileResponse.statusCode == 200) {
      final data = jsonDecode(fileResponse.body);
      final taskId = data['task_id'] as String;
      debugPrint('[ApiService] File upload successful, task ID: $taskId');
      return taskId;
    } else {
      debugPrint(
          '[ApiService] File upload failed with status: ${fileResponse.statusCode}');
      throw Exception("Failed to start transcription: ${fileResponse.body}");
    }
  }

  /// Get single progress status
  static Future<ProgressModel> getProgressStatus(String taskId) async {
    final url = Uri.parse('$baseUrl/progress/$taskId/status');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ProgressModel.fromBackendData(taskId, data);
    } else if (response.statusCode == 404) {
      throw Exception("Task not found");
    } else {
      throw Exception("Failed to get progress: ${response.body}");
    }
  }

  /// Stream progress updates using Server-Sent Events
  static Stream<ProgressModel> streamProgress(String taskId) async* {
    final url = Uri.parse('$baseUrl/progress/$taskId');
    final client = http.Client();

    try {
      final request = http.Request('GET', url);
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        throw Exception(
            "Failed to connect to progress stream: ${streamedResponse.reasonPhrase}");
      }

      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final jsonData = line.substring(6); // Remove 'data: ' prefix

            if (jsonData.trim().isEmpty) continue;

            try {
              debugPrint('[ApiService] Raw JSON data: $jsonData');
              final data = jsonDecode(jsonData);
              debugPrint('[ApiService] Parsed data: $data');

              // Check for errors - only throw if error is present and not null
              if (data.containsKey('error')) {
                if (data['error'] != null) {
                  debugPrint('[ApiService] Backend error: ${data['error']}');
                  throw Exception(data['error']);
                } else {
                  debugPrint(
                      '[ApiService] Error key present but null (normal)');
                }
              }

              // Validate required fields
              if (data is! Map<String, dynamic>) {
                debugPrint(
                    '[ApiService] Invalid data format: expected Map, got ${data.runtimeType}');
                continue;
              }

              final progress = ProgressModel.fromBackendData(taskId, data);
              yield progress;

              // Stop streaming if completed or failed
              if (progress.status == ProgressStatus.completed ||
                  progress.status == ProgressStatus.failed) {
                debugPrint(
                    '[ApiService] Stream completed with status: ${progress.status}');
                break;
              }
            } catch (e) {
              debugPrint('[ApiService] Error parsing progress data: $e');
              debugPrint('[ApiService] Raw data that failed: "$jsonData"');
              continue;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Stream error: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Cancel a task (if supported by backend)
  static Future<void> cancelTask(String taskId) async {
    try {
      final url = Uri.parse('$baseUrl/progress/$taskId/cancel');
      final response = await http.post(url);

      if (response.statusCode != 200) {
        debugPrint('[ApiService] Failed to cancel task: ${response.body}');
        // Don't throw error as cancellation might not be critical
      }
    } catch (e) {
      debugPrint('[ApiService] Error cancelling task: $e');
      // Don't rethrow as cancellation is best-effort
    }
  }

  // Helper method to download video from Firebase Storage
  static Future<File> _downloadVideoFromFirebase(String videoUrl) async {
    try {
      final response = await http.get(Uri.parse(videoUrl));
      if (response.statusCode != 200) {
        throw Exception("Failed to download video: ${response.statusCode}");
      }

      final tempDir = await getTemporaryDirectory();
      final fileName =
          'temp_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final tempFile = File('${tempDir.path}/$fileName');

      await tempFile.writeAsBytes(response.bodyBytes);
      debugPrint('[ApiService] Video downloaded to: ${tempFile.path}');

      return tempFile;
    } catch (e) {
      throw Exception("Failed to download video from Firebase: $e");
    }
  }
}
