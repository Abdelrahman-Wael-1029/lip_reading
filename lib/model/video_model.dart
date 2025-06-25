// lib/models/video_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lip_reading/enum/model_enum.dart';

class VideoModel {
  final String id;
  final String title;
  String url;
  String result;
  final DateTime? createdAt;
  Model model;

  VideoModel({
    required this.id,
    required this.title,
    required this.url,
    required this.result,
    this.createdAt,
    required this.model,
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
      model: Model.values[json['model'] ?? 0],
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
      'model': model.index
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
      model: model,
    );
  }

  @override
  String toString() {
    return 'VideoModel(id: $id, title: $title, url: $url, result: $result createdAt: $createdAt, model: $model)';
  }
}
