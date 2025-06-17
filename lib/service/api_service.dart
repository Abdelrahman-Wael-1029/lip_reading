import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  static late Dio _dio;

  static const String _baseUrl = "https://8b3d-35-185-82-107.ngrok-free.app";

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 20),
      headers: {
        "Accept": "application/json",
      },
    ));
  }

  static Future<String> uploadVideo(File videoFile) async {
    try {
      String fileName = path.basename(videoFile.path);

      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          videoFile.path,
          filename: fileName,
          contentType: MediaType('video', 'mp4'),
        ),
      });

      Response response = await _dio.post(
        "/transcribe/",
        data: formData,
        options: Options(
          headers: {
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      if (response.statusCode == 200 && response.data['transcript'] != null) {
        return response.data['transcript'];
      } else {
        return "❌ فشل في استخراج النص من الفيديو.";
      }
    } on DioException catch (e) {
      if (e.response != null &&
          e.response?.data is Map &&
          e.response?.data['error'] != null) {
        return "❗️ ${e.response?.data['error']}";
      }
      return "❌ خطأ في الاتصال بالخادم.";
    } catch (e) {
      return "❗️ حدث خطأ غير متوقع أثناء رفع الفيديو.";
    }
  }
}
