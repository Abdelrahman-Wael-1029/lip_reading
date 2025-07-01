import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:lip_reading/model/progress_model.dart';
import 'package:path/path.dart';

class ProgressService {
  static const String baseUrl = "https://arabic-lip-reading.loca.lt";

  /// Start transcription process and return task ID
  static Future<String> startTranscription({
    File? file,
    required String modelName,
    bool dia = false,
    String? fileHash,
    bool enhance = false,
    bool includeSummary = false,
    bool includeTranslation = false,
    String targetLanguage = "English",
    Function(double)? onUploadProgress,
  }) async {
    final url = Uri.parse('$baseUrl/transcribe/');

    final request = http.MultipartRequest('POST', url)
      ..fields['model_name'] = modelName
      ..fields['diacritized'] = dia.toString()
      ..fields['enhance'] = enhance.toString()
      ..fields['include_summary'] = includeSummary.toString()
      ..fields['include_translation'] = includeTranslation.toString()
      ..fields['target_language'] = targetLanguage;

    if (fileHash != null) {
      debugPrint('[ProgressService] Using cached file hash: $fileHash');
      request.fields['file_hash'] = fileHash;
    } else if (file != null) {
      debugPrint('[ProgressService] Uploading file: ${file.path}');
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: basename(file.path),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final taskId = data['task_id'] as String;
      debugPrint('[ProgressService] Task started with ID: $taskId');
      return taskId;
    } else {
      throw Exception("Failed to start transcription: ${response.body}");
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
              debugPrint('[ProgressService] Raw JSON data: $jsonData');
              final data = jsonDecode(jsonData);
              debugPrint('[ProgressService] Parsed data: $data');

              // Check for errors - only throw if error is present and not null
              if (data.containsKey('error')) {
                if (data['error'] != null) {
                  debugPrint(
                      '[ProgressService] Backend error: ${data['error']}');
                  throw Exception(data['error']);
                } else {
                  debugPrint(
                      '[ProgressService] Error key present but null (normal)');
                }
              }

              // Validate required fields
              if (data is! Map<String, dynamic>) {
                debugPrint(
                    '[ProgressService] Invalid data format: expected Map, got ${data.runtimeType}');
                continue;
              }

              final progress = ProgressModel.fromBackendData(taskId, data);
              yield progress;

              // Stop streaming if completed or failed
              if (progress.status == ProgressStatus.completed ||
                  progress.status == ProgressStatus.failed) {
                debugPrint(
                    '[ProgressService] Stream completed with status: ${progress.status}');
                break;
              }
            } catch (e) {
              debugPrint('[ProgressService] Error parsing progress data: $e');
              debugPrint('[ProgressService] Raw data that failed: "$jsonData"');
              continue;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[ProgressService] Stream error: $e');
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
        debugPrint('[ProgressService] Failed to cancel task: ${response.body}');
        // Don't throw error as cancellation might not be critical
      }
    } catch (e) {
      debugPrint('[ProgressService] Error cancelling task: $e');
      // Don't rethrow as cancellation is best-effort
    }
  }
}
