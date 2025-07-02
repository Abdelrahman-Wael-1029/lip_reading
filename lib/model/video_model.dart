// lib/models/video_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String id;
  String title;
  String url;
  String result;
  final DateTime? createdAt;
  String model;
  String? fileHash;
  bool? diacritized;

  VideoModel({
    required this.id,
    required this.title,
    required this.url,
    required this.result,
    this.createdAt,
    required this.model,
    this.fileHash,
    this.diacritized,
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
      model: json['model'],
      fileHash: json['fileHash'],
      diacritized: json['diacritized'] ?? false,
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
      'model': model,
      'fileHash': fileHash,
      'diacritized': diacritized ?? false,
    };
  }

  VideoModel copyWith({
    String? title,
    String? url,
    String? result,
    String? model,
    String? fileHash,
    bool? diacritized,
  }) {
    return VideoModel(
      id: id,
      title: title ?? this.title,
      url: url ?? this.url,
      result: result ?? this.result,
      createdAt: createdAt,
      model: model ?? this.model,
      fileHash: fileHash ?? this.fileHash,
      diacritized: diacritized ?? this.diacritized,
    );
  }

  @override
  String toString() {
    return 'VideoModel(id: $id, title: $title, url: $url, result: $result createdAt: $createdAt, model: $model fileHash: $fileHash, diacritized: $diacritized)';
  }
}
