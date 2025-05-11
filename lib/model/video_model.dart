// lib/models/video_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String id;
  final String title;
  final String url;
  final String result;
  final DateTime? createdAt;

  VideoModel({
    required this.id,
    required this.title,
    required this.url,
    required this.result,
    this.createdAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return VideoModel(
      id: docId ?? json['id'] ?? '',
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      result: json['result'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'result': result,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  VideoModel copyWith({
    String? title,
    String? url,
    String? result,
  }) {
    return VideoModel(
      id: id,
      title: title ?? this.title,
      url: url ?? this.url,
      result: result ?? this.result,
      createdAt: createdAt,
    );
  }

  @override
  String toString() {
    return 'VideoModel(id: $id, title: $title, url: $url, result: $result)';
  }
}
