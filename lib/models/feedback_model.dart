import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'feedback_model.g.dart';

@HiveType(typeId: 12)
class FeedbackModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String userName;

  @HiveField(3)
  final String category; 

  @HiveField(4)
  final String subject;

  @HiveField(5)
  final String message;

  @HiveField(6)
  final int rating; 

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  late String status; 

  FeedbackModel({
    String? id,
    required this.userId,
    required this.userName,
    required this.category,
    required this.subject,
    required this.message,
    required this.rating,
    DateTime? createdAt,
    String? status,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        status = status ?? 'pending';

  void updateStatus(String newStatus) {
    if (['pending', 'reviewed', 'resolved'].contains(newStatus)) {
      status = newStatus;
      save();
    }
  }
}
