import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/interest_model.dart';
import '../models/feedback_model.dart';
import '../models/auction_model.dart';
import '../utils/constants.dart';
import 'notification_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final _uuid = const Uuid();

  late Box<UserModel> _usersBox;
  late Box<InterestModel> _registeredAuctionsBox;
  late Box<FeedbackModel> _feedbackBox;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _usersBox = await Hive.openBox<UserModel>(AppConstants.usersBox);
      try {
        for (var user in _usersBox.values.toList()) {
          var changed = false;
          if (user.defaultCurrency.isEmpty || user.defaultCurrency == 'USD') {
            user.defaultCurrency = AppConstants.defaultCurrency;
            changed = true;
          }
          if (user.defaultTimezone.isEmpty || user.defaultTimezone == 'UTC') {
            user.defaultTimezone = AppConstants.defaultTimezone;
            changed = true;
          }
          if (changed) {
            await _usersBox.put(user.id, user);
            print('🔁 Migrated user ${user.id} defaults to ${AppConstants.defaultCurrency}/${AppConstants.defaultTimezone}');
          }
        }
      } catch (e) {
        print('⚠️ UserService: migration failed: $e');
      }
      _registeredAuctionsBox =
          await Hive.openBox<InterestModel>(AppConstants.registeredAuctionsBox);
      _feedbackBox =
          await Hive.openBox<FeedbackModel>(AppConstants.feedbackBox);
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize UserService: $e');
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      return _usersBox.get(userId);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? profileImageUrl,
  }) async {
    try {
      final user = _usersBox.get(userId);

      if (user == null) {
        return {
          'success': false,
          'message': 'User tidak ditemukan',
        };
      }

      final updatedUser = user.copyWith(
        name: name ?? user.name,
        phone: phone ?? user.phone,
        profileImageUrl: profileImageUrl ?? user.profileImageUrl,
        updatedAt: DateTime.now(),
      );

      await _usersBox.put(userId, updatedUser);

      return {
        'success': true,
        'message': 'Profil berhasil diperbarui',
        'user': updatedUser,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> updatePreferences({
    required String userId,
    String? defaultCurrency,
    String? defaultTimezone,
    bool? notificationsEnabled,
  }) async {
    try {
      final user = _usersBox.get(userId);

      if (user == null) {
        return {
          'success': false,
          'message': 'User tidak ditemukan',
        };
      }

      final updatedUser = user.copyWith(
        defaultCurrency: defaultCurrency ?? user.defaultCurrency,
        defaultTimezone: defaultTimezone ?? user.defaultTimezone,
        notificationsEnabled: notificationsEnabled ?? user.notificationsEnabled,
        updatedAt: DateTime.now(),
      );

      await _usersBox.put(userId, updatedUser);

      return {
        'success': true,
        'message': 'Preferensi berhasil diperbarui',
        'user': updatedUser,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> registerAuction({
    required String userId,
    required AuctionModel auction,
  }) async {
    try {
      final exists = _registeredAuctionsBox.values.any(
        (interest) =>
            interest.userId == userId && interest.auctionId == auction.id,
      );
      if (exists) {
        return {
          'success': false,
          'message': 'Lelang sudah terdaftar',
        };
      }

      final interestId = _uuid.v4();
      final newInterest = InterestModel(
        id: interestId,
        userId: userId,
        auctionId: auction.id,
        auctionTitle: auction.title,
        artistName: auction.artist,
        imageUrl: auction.primaryImageUrl,
        minimumBid: auction.minimumBid,
        location: auction.location,
        auctionDate: auction.auctionDate,
      );

      await _registeredAuctionsBox.put(interestId, newInterest);
      try {
        await NotificationService().addNotification(
          userId: userId,
          title: 'Berhasil Mendaftar Lelang',
          message: 'Anda berhasil mendaftar untuk lelang "${auction.title}"',
          type: 'registration',
          auctionId: auction.id,
        );
      } catch (_) {}

      return {
        'success': true,
        'message': 'Berhasil mendaftar untuk lelang',
        'interest': newInterest,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> unregisterAuction(String interestId) async {
    try {
      print('🎯 UserService: Unregistering auction $interestId');

      final interest = _registeredAuctionsBox.get(interestId);
      if (interest == null) {
        return {
          'success': false,
          'message': 'Pendaftaran tidak ditemukan',
        };
      }

      await _registeredAuctionsBox.delete(interestId);
      try {
        await NotificationService().addNotification(
          userId: interest.userId,
          title: 'Pembatalan Pendaftaran Lelang',
          message: 'Pendaftaran Anda untuk lelang "${interest.auctionTitle}" telah dibatalkan.',
          type: 'cancellation',
          auctionId: interest.auctionId,
        );
      } catch (_) {}

      return {
        'success': true,
        'message': 'Pendaftaran berhasil dibatalkan',
      };
    } catch (e) {
      print('❌ Error in unregisterAuction: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  List<InterestModel> getRegisteredAuctions(String userId) {
    try {
      return _registeredAuctionsBox.values
          .where((interest) => interest.userId == userId)
          .toList()
        ..sort((a, b) => a.auctionDate.compareTo(b.auctionDate));
    } catch (e) {
      return [];
    }
  }

  bool isAuctionRegistered(String userId, String auctionId) {
    try {
      return _registeredAuctionsBox.values.any(
        (interest) =>
            interest.userId == userId && interest.auctionId == auctionId,
      );
    } catch (e) {
      return false;
    }
  }

  List<InterestModel> getUserInterests(String userId) =>
      getRegisteredAuctions(userId);
  bool isAuctionInInterests(String userId, String auctionId) =>
      isAuctionRegistered(userId, auctionId);

  Future<Map<String, dynamic>> submitFeedback({
    required String userId,
    required String userName,
    required String category,
    required String subject,
    required String message,
    required int rating,
  }) async {
    try {
      final feedbackId = _uuid.v4();

      final newFeedback = FeedbackModel(
        id: feedbackId,
        userId: userId,
        userName: userName,
        category: category,
        subject: subject,
        message: message,
        rating: rating,
        createdAt: DateTime.now(),
      );

      await _feedbackBox.put(feedbackId, newFeedback);

      return {
        'success': true,
        'message': 'Terima kasih atas feedback Anda!',
        'feedback': newFeedback,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  List<FeedbackModel> getUserFeedbacks(String userId) {
    try {
      return _feedbackBox.values
          .where((feedback) => feedback.userId == userId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      return [];
    }
  }

  List<FeedbackModel> getAllFeedbacks() {
    try {
      return _feedbackBox.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      return [];
    }
  }

  Map<String, dynamic> getUserStatistics(String userId) {
    try {
      final interests = getUserInterests(userId);
      final feedbacks = getUserFeedbacks(userId);

      final now = DateTime.now();
      final upcomingInterests =
          interests.where((i) => i.auctionDate.isAfter(now)).length;

      final totalFeedbacks = feedbacks.length;
      final avgRating = feedbacks.isEmpty
          ? 0.0
          : feedbacks.map((f) => f.rating).reduce((a, b) => a + b) /
              feedbacks.length;

      return {
        'totalInterests': interests.length,
        'upcomingInterests': upcomingInterests,
        'totalFeedbacks': totalFeedbacks,
        'averageRating': avgRating,
      };
    } catch (e) {
      return {
        'totalInterests': 0,
        'upcomingInterests': 0,
        'totalFeedbacks': 0,
        'averageRating': 0.0,
      };
    }
  }
}
