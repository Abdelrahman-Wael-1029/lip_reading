import 'dart:io';
import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio;
  final String baseUrl;

  ApiService({required this.baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: Duration(seconds: 5000),
          receiveTimeout: Duration(seconds: 3000),
          headers: {
            'Accept': 'application/json',
          },
        ));

  Future<Response> uploadVideo({
    required File file,
    Map<String, dynamic>? data,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
  }) async {
    String fileName = file.path.split(Platform.pathSeparator).last;
    FormData formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
      if (data != null) ...data,
    });

    try {
      final response = await _dio.post(
        '/upload-video/',
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
      return response;
    } on DioException catch (e) {
      // Handle error
      throw e;
    }
  }

  /// Example: GET request
  Future<Response> getItems(String endpoint) async {
    try {
      final response = await _dio.get(endpoint);
      return response;
    } on DioException catch (_) {
      rethrow;
    }
  }

  /// Example: POST request with JSON body
  Future<Response> postData(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: body,
      );
      return response;
    } on DioError catch (e) {
      throw e;
    }
  }
}
