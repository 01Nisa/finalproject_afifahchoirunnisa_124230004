import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'interest_model.g.dart';

@HiveType(typeId: 4)
class InterestModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String auctionId;

  @HiveField(3)
  final String auctionTitle;

  @HiveField(4)
  final String artistName;

  @HiveField(5)
  final String imageUrl;

  @HiveField(6)
  final double minimumBid;

  @HiveField(7)
  final String location;

  @HiveField(8)
  final DateTime auctionDate;

  @HiveField(9)
  bool isNotificationEnabled;

  InterestModel({
    String? id,
    required this.userId,
    required this.auctionId,
    required this.auctionTitle,
    required this.artistName,
    required this.imageUrl,
    required this.minimumBid,
    required this.location,
    required this.auctionDate,
    this.isNotificationEnabled = true,
  }) : id = id ?? const Uuid().v4();

  void toggleNotification() {
    isNotificationEnabled = !isNotificationEnabled;
    save();
  }
}
