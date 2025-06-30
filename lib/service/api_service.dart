import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

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
      throw Exception("حدث خطأ في جلب الموديلات");
    }
  }

  // Upload file and transcribe
  static Future<Map<String, dynamic>> uploadFile(
      {File? file,
      required String modelName,
      bool dia = false, // Changed from diacritized to dia
      String? fileHash}) async {
    final url = Uri.parse('$baseUrl/transcribe/');

    final request = http.MultipartRequest('POST', url)
      ..fields['model_name'] = modelName
      ..fields['diacritized'] = dia.toString();

    if (fileHash != null) {
      debugPrint('fileHash: $fileHash');
      request.fields['file_hash'] = fileHash;
    } else if (file != null) {
      debugPrint('fileHash is null');
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
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception("حدث خطأ في الانترنت");
    }
  }
}
