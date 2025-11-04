import 'package:hive/hive.dart';
import '../models/tawaran_model.dart';
import '../services/local_db_service.dart';
import 'auction_service.dart';
import 'user_service.dart';
import '../utils/constants.dart';

class BidService {
  static final BidService _instance = BidService._internal();
  factory BidService() => _instance;
  BidService._internal();

  final _auctionService = AuctionService();
  final _userService = UserService();
  final _localDb = LocalDbService();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  Box<TawaranModel> get _bidsBox => _localDb.bidsBox;

  Future<Map<String, dynamic>> placeBid({
    required String lelangId,
    required String userId,
    required String userName,
    required double hargaTawaran,
  }) async {
    try {
      final currentHighest = await getHighestBid(lelangId);
      final currentPrice = (currentHighest['harga'] as num?)?.toDouble() ?? 0.0;

      final auction = _auctionService.getAuctionById(lelangId);
      if (auction == null) {
        return {
          'success': false,
          'message': 'Lelang tidak ditemukan',
        };
      }

      final now = DateTime.now();
      final startTime = auction.auctionDate;
      final endTime = startTime.add(AppAnimations.auctionDuration);
      if (now.isBefore(startTime)) {
        return {
          'success': false,
          'message': 'Lelang belum dimulai',
        };
      }
      if (now.isAfter(endTime)) {
        return {
          'success': false,
          'message': 'Lelang telah berakhir',
        };
      }

      final minBid = auction.minimumBid;
      final finalMinBid = currentPrice > minBid ? currentPrice : minBid;

      if (hargaTawaran <= finalMinBid) {
        return {
          'success': false,
          'message':
              'Tawaran harus lebih besar dari \$${finalMinBid.toStringAsFixed(0)}',
        };
      }

      final isRegistered = _userService.isAuctionRegistered(userId, lelangId);
      if (!isRegistered) {
        await _userService.registerAuction(userId: userId, auction: auction);
      }

      final tawaran = TawaranModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        lelangId: lelangId,
        userId: userId,
        hargaTawaran: hargaTawaran,
        timestamp: DateTime.now(),
      );

      await _bidsBox.put(tawaran.id, tawaran);

      return {
        'success': true,
        'message': 'Tawaran berhasil disimpan',
        'data': tawaran,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal menyimpan tawaran: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getHighestBid(String lelangId) async {
    try {
      final bids = _bidsBox.values
          .where((b) => b.lelangId == lelangId)
          .toList(growable: false);
      if (bids.isEmpty) {
        final auction = _auctionService.getAuctionById(lelangId);
        return {
          'harga': auction?.minimumBid ?? 0.0,
          'data': null,
        };
      }

      bids.sort((a, b) => b.hargaTawaran.compareTo(a.hargaTawaran));
      final top = bids.first;
      return {
        'harga': top.hargaTawaran,
        'data': top,
      };
    } catch (e) {
      final auction = _auctionService.getAuctionById(lelangId);
      return {
        'harga': auction?.minimumBid ?? 0.0,
        'data': null,
      };
    }
  }

  Future<List<TawaranModel>> getBidsByLelangId(String lelangId) async {
    try {
      final bids =
          _bidsBox.values.where((b) => b.lelangId == lelangId).toList();
      bids.sort((a, b) => b.hargaTawaran.compareTo(a.hargaTawaran));
      return bids;
    } catch (e) {
      return [];
    }
  }

  Future<TawaranModel?> getUserLastBid({
    required String lelangId,
    required String userId,
  }) async {
    try {
      final bids = _bidsBox.values
          .where((b) => b.lelangId == lelangId && b.userId == userId)
          .toList();
      if (bids.isEmpty) return null;
      bids.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return bids.first;
    } catch (e) {
      return null;
    }
  }

  Future<TawaranModel?> getAuctionWinner(String lelangId) async {
    try {
      final highest = await getHighestBid(lelangId);
      final data = highest['data'];
      return data is TawaranModel ? data : null;
    } catch (e) {
      return null;
    }
  }

  List<String> getUserAuctionIds(String userId) {
    try {
      final userBids =
          _bidsBox.values.where((b) => b.userId == userId).toList();

      final auctionIds = <String>{};
      for (var bid in userBids) {
        auctionIds.add(bid.lelangId);
      }

      return auctionIds.toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> updateBid({
    required String tawaranId,
    required double newHargaTawaran,
  }) async {
    try {
      final tawaran = _bidsBox.get(tawaranId);
      if (tawaran == null) {
        return {
          'success': false,
          'message': 'Tawaran tidak ditemukan',
        };
      }

      final updated = tawaran.copyWith(hargaTawaran: newHargaTawaran);
      await _bidsBox.put(tawaranId, updated);

      return {
        'success': true,
        'message': 'Tawaran berhasil diperbarui',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal memperbarui tawaran: ${e.toString()}',
      };
    }
  }

  dynamic subscribeToBids(
      String lelangId, Function(Map<String, dynamic>) callback) {
    return null;
  }
}
