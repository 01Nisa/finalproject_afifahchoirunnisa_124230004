import '../models/auction_model.dart';
import '../models/tawaran_model.dart';
import '../utils/constants.dart';
import 'bid_service.dart';
import 'auction_service.dart';

class AuctionSchedulerService {
  static final AuctionSchedulerService _instance =
      AuctionSchedulerService._internal();
  factory AuctionSchedulerService() => _instance;
  AuctionSchedulerService._internal();

  final _bidService = BidService();
  final _auctionService = AuctionService();

  Future<void> updateAuctionStatuses() async {
    try {
      final auctions = await _auctionService.fetchAuctions(forceRefresh: false);

      for (final auction in auctions) {
        final oldStatus = auction.status;
        final newStatus = _calculateAuctionStatus(auction);

        if (oldStatus != newStatus) {
          auction.status = newStatus;
          await auction.save();

          if (newStatus == 'closed' && oldStatus != 'closed') {
            await _determineWinner(auction);
          }
        }
      }
    } catch (e) {
      print('Error updating auction statuses: $e');
    }
  }

  String _calculateAuctionStatus(AuctionModel auction) {
    final now = DateTime.now();
    final start = auction.auctionDate;
    final end =
        start.add(AppAnimations.auctionDuration); // 15 menit durasi lelang

    if (now.isBefore(start)) return 'upcoming';
    if (now.isAfter(end)) return 'closed';
    return 'ongoing';
  }

  Future<void> _determineWinner(AuctionModel auction) async {
    try {
      final highestBid = await _bidService.getHighestBid(auction.id);
      final winnerBid = highestBid['data'] as TawaranModel?;

      if (winnerBid != null) {
        await _bidService.updateBid(
          tawaranId: winnerBid.id,
          newHargaTawaran:
              winnerBid.hargaTawaran, 
        );

        auction.currentBid = winnerBid.hargaTawaran;
        await auction.save();

        print(
            'Winner determined for auction ${auction.id}: ${winnerBid.userId} with bid ${winnerBid.hargaTawaran}');
      } else {
        print('No bids for auction ${auction.id}');
      }
    } catch (e) {
      print('Error determining winner for auction ${auction.id}: $e');
    }
  }

  bool isAuctionOngoing(AuctionModel auction) {
    return _calculateAuctionStatus(auction) == 'ongoing';
  }

  bool isAuctionClosed(AuctionModel auction) {
    return _calculateAuctionStatus(auction) == 'closed';
  }

  int getRemainingTime(AuctionModel auction) {
    final now = DateTime.now();
    final end = auction.auctionDate.add(const Duration(hours: 3));
    final remaining = end.difference(now);

    return remaining.isNegative ? 0 : remaining.inSeconds;
  }

  String formatRemainingTime(AuctionModel auction) {
    final remaining = getRemainingTime(auction);

    if (remaining <= 0) return 'Selesai';

    final hours = remaining ~/ 3600;
    final minutes = (remaining % 3600) ~/ 60;
    final seconds = remaining % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
