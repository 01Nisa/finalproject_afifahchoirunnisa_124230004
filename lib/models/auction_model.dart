import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'auction_model.g.dart';

@HiveType(typeId: 10)
class AuctionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int metObjectId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String artist;

  @HiveField(4)
  final String primaryImageUrl;

  @HiveField(5)
  final double minimumBid;

  @HiveField(6)
  late double currentBid;

  @HiveField(7)
  final String location;

  @HiveField(8)
  final double? latitude;

  @HiveField(9)
  final double? longitude;

  @HiveField(10)
  final DateTime auctionDate;

  @HiveField(11)
  late String status;

  @HiveField(12)
  late int totalBids;

  @HiveField(13)
  final bool isExclusive;

  @HiveField(14)
  final String category;

  AuctionModel({
    String? id,
    required this.metObjectId,
    required this.title,
    required this.artist,
    required this.primaryImageUrl,
    required this.minimumBid,
    double? currentBid,
    required this.location,
    this.latitude,
    this.longitude,
    required this.auctionDate,
    String? status,
    int? totalBids,
    required this.isExclusive,
    String? category,
  })  : id = id ?? const Uuid().v4(),
        currentBid = currentBid ?? minimumBid,
        status = status ?? _determineStatus(auctionDate),
        totalBids = totalBids ?? 0,
        category = category ?? 'Classical';

  static String _determineStatus(DateTime auctionDate) {
    final simulationService = _getSimulationService();
    final now = simulationService?.now() ?? DateTime.now();
    final start = auctionDate.subtract(const Duration(hours: 1));
    final end = auctionDate.add(const Duration(hours: 3));

    if (now.isBefore(start)) return 'upcoming';
    if (now.isAfter(end)) return 'closed';
    return 'ongoing';
  }

  static dynamic _getSimulationService() {
    try {
      return null;
    } catch (e) {
      return null;
    }
  }

  void placeBid(double amount) {
    if (amount > currentBid && status == 'ongoing') {
      currentBid = amount;
      totalBids++;
      status = _determineStatus(auctionDate);
      save();
    }
  }

  String get formattedMinBid => '\$${minimumBid.toStringAsFixed(0)}';
  String get formattedCurrentBid => '\$${currentBid.toStringAsFixed(0)}';
}
