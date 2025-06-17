import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class ApiService {
 static Future<String> uploadVideo(File videoFile) async {
    // Public URL from localtunnel
    final uri =
        Uri.parse("https://lip-reading-transcription.loca.lt/transcribe/");

    try {
      final request = http.MultipartRequest('POST', uri);

      // Prepare file stream
      final fileStream = http.ByteStream(videoFile.openRead());
      final length = await videoFile.length();
      final filename = path.basename(videoFile.path);

      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        length,
        filename: filename,
      );

      request.files.add(multipartFile);

      // Send request
      final response = await request.send();
      print('response::: ${response}');

      // Handle response
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        print("✅ Success: $respStr");
        // convert from string into json and return key transcript
        return jsonDecode(respStr)['transcript'];
      } else {
        print("❌ Failed: ${response.statusCode}");
        return 'حاول مرة أخرى';
      }
    } catch (e) {
      print("❗️ Error uploading video: $e");
      return 'حدث خطأ في التحميل ، برجاء المحاوله لاحقا';
    }
  }
}
