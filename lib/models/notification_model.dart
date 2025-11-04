import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'notification_model.g.dart';

@HiveType(typeId: 7)
class NotificationModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String message;

  @HiveField(4)
  final String type; 

  @HiveField(5)
  final String? auctionId;

  @HiveField(6)
  final DateTime timestamp;

  @HiveField(7)
  bool isRead;

  NotificationModel({
    String? id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.auctionId,
    DateTime? timestamp,
    this.isRead = false,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  void markAsRead() {
    isRead = true;
    save();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'auctionId': auctionId,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      auctionId: json['auctionId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}
