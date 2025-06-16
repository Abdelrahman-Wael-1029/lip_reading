import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
   static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: '192.168.1.4:8000',
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
    ),
  );

 static Future<String> uploadVideo(File videoFile) async {
    try {
      String fileName = videoFile.path.split('/').last;

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          videoFile.path,
          filename: fileName,
          contentType: MediaType('video', 'mp4'),
        ),
      });

      Response response = await _dio.post(
        '/upload',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data.toString();
      } else {
        return 'Upload failed with status: ${response.statusCode}';
      }
    } catch (e) {
      return 'Upload error: $e';
    }
  }
}
