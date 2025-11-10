import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/notification_model.dart';
import '../models/auction_model.dart';
import '../models/interest_model.dart';
import 'bid_service.dart';
import 'local_db_service.dart';
import 'auction_service.dart';
import '../utils/constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  Box<NotificationModel>? _notificationsBox;

  final Set<String> _notifiedAuctions = {};
  final Map<String, DateTime> _lastPopupShown = {};
  final Set<String> _dismissedPopups = {};
  static const Duration _popupCooldown = Duration(minutes: 30);
  bool _isPopupVisible = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _notificationsBox =
        await Hive.openBox<NotificationModel>('notifications_box');

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      const androidChannel = AndroidNotificationChannel(
        'auction_channel',
        'Lelang Notifikasi',
        description: 'Notifikasi untuk lelang aktif dan peringatan',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      
      await androidImplementation.createNotificationChannel(androidChannel);
    }
    final iosImplementation = _localNotifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    return;
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
  }) {
    if (NotificationService()._isPopupVisible) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? AppColors.vintageBrown,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'auction_channel',
      'Lelang Notifikasi',
      channelDescription: 'Notifikasi untuk lelang aktif dan peringatan',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  static Future<void> showInAppNotification(
    BuildContext context, {
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
    bool isDismissible = true,
    String? auctionId,
  }) {
    final instance = NotificationService();
    // If this auction was explicitly dismissed by the user, don't show again
    if (auctionId != null && instance._dismissedPopups.contains(auctionId)) {
      return Future.value();
    }

    // Rate-limit popups per-auction to avoid spamming the user
    if (auctionId != null) {
      final last = instance._lastPopupShown[auctionId];
      if (last != null && DateTime.now().difference(last) < _popupCooldown) {
        return Future.value();
      }
      instance._lastPopupShown[auctionId] = DateTime.now();
    }

    instance._isPopupVisible = true;
    return showDialog(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.vintageCream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.notifications_active,
              color: AppColors.vintageGold,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.vintageBrown,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          if (isDismissible)
            TextButton(
              onPressed: () {
                // If user actively closes the popup, mark it dismissed so it won't show again
                if (auctionId != null) instance._dismissedPopups.add(auctionId);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Tutup',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          if (actionText != null && onAction != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onAction();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vintageGold,
                foregroundColor: Colors.white,
              ),
              child: Text(actionText),
            ),
        ],
      ),
    ).then((v) {
      instance._isPopupVisible = false;
      return v;
    });
  }

  static void registerPopupShown(String auctionId) {
    NotificationService()._lastPopupShown[auctionId] = DateTime.now();
  }

  bool _canShowPopup(String? auctionId) {
    if (auctionId == null) return true;
    if (_dismissedPopups.contains(auctionId)) return false;
    final last = _lastPopupShown[auctionId];
    if (last != null && DateTime.now().difference(last) < _popupCooldown) return false;
    return true;
  }

  Future<void> _saveNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? auctionId,
  }) async {
    if (_notificationsBox == null) return;

    final notification = NotificationModel(
      userId: userId,
      title: title,
      message: message,
      type: type,
      auctionId: auctionId,
    );

    await _notificationsBox!.put(notification.id, notification);
  }

  List<NotificationModel> getUserNotifications(String userId) {
    if (_notificationsBox == null) return [];

    final notifications = _notificationsBox!.values
        .where((n) => n.userId == userId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return notifications;
  }

  int getUnreadCount(String userId) {
    if (_notificationsBox == null) return 0;

    return _notificationsBox!.values
        .where((n) => n.userId == userId && !n.isRead)
        .length;
  }

  Future<void> markAllAsRead(String userId) async {
    if (_notificationsBox == null) return;

    final userNotifications =
        _notificationsBox!.values.where((n) => n.userId == userId && !n.isRead);

    for (var notification in userNotifications) {
      notification.markAsRead();
    }
  }

  Future<void> notifyAuctionActive({
    required String userId,
    required String auctionId,
    required String auctionTitle,
    required String message,
    String? payload,
    BuildContext? context,
  }) async {
    await _saveNotification(
      userId: userId,
      title: 'Lelang Aktif! 🎨',
      message: '$auctionTitle - $message',
      type: 'auction_active',
      auctionId: auctionId,
    );
    if (context != null && _canShowPopup(auctionId)) {
      try {
        // show in-app dialog for active auction if allowed by cooldown/dismissal
        await showInAppNotification(
          context,
          title: 'Lelang Aktif! 🎨',
          message: '$auctionTitle - $message',
          auctionId: auctionId,
        );
      } catch (_) {
        showSnackBar(context, '$auctionTitle - $message', icon: Icons.notifications);
      }
    }

    await showLocalNotification(
      title: 'Lelang Aktif! 🎨',
      body: '$auctionTitle - $message',
      payload: payload ?? 'auction_active',
    );
  }
  Future<void> addNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? auctionId,
    BuildContext? context,
    bool showLocal = true,
    bool showPopup = false,
  }) async {
    await _saveNotification(
      userId: userId,
      title: title,
      message: message,
      type: type,
      auctionId: auctionId,
    );
    if (context != null) {
      if (showPopup) {
        if (_canShowPopup(auctionId)) {
          try {
            showInAppNotification(context, title: title, message: message, auctionId: auctionId);
          } catch (_) {
            showSnackBar(context, message, icon: Icons.notifications);
          }
        }
      } else {
        // if user has explicitly dismissed popups for this auction, don't show inline snack
        if (auctionId != null && _dismissedPopups.contains(auctionId)) {
          // skip
        } else {
          if (!showLocal) {
            showSnackBar(context, message, icon: Icons.notifications);
          }
        }
      }
    }

    if (showLocal) {
      await showLocalNotification(title: title, body: message, payload: type);
    }
  }

  Future<void> notifyAuctionStarting({
    required String userId,
    required String auctionId,
    required String auctionTitle,
    required DateTime startTime,
    BuildContext? context,
    bool showLocal = true,
  }) async {
    final notificationKey = '${auctionId}_starting';
    if (_notifiedAuctions.contains(notificationKey)) return;
    _notifiedAuctions.add(notificationKey);

    final now = DateTime.now();
    final minutesUntil = startTime.difference(now).inMinutes;

    await _saveNotification(
      userId: userId,
      title: 'Lelang Segera Dimulai ⏰',
      message: '$auctionTitle akan dimulai dalam $minutesUntil menit',
      type: 'auction_starting',
      auctionId: auctionId,
    );

    if (context != null && _canShowPopup(auctionId)) {
      if (!showLocal) {
        showSnackBar(
          context,
          'Lelang akan dimulai dalam $minutesUntil menit: $auctionTitle',
          icon: Icons.access_time,
          backgroundColor: AppColors.warning,
        );
      }
    }

    if (showLocal) {
      await showLocalNotification(
        title: 'Lelang Segera Dimulai ⏰',
        body: '$auctionTitle akan dimulai dalam $minutesUntil menit',
        payload: 'auction_starting',
      );
    }
  }

  Future<void> checkUpcomingAuctions({
    required String userId,
    required List<InterestModel> registeredAuctions,
    required List<AuctionModel> allAuctions,
    BuildContext? context,
  }) async {
    final now = DateTime.now();

    for (var interest in registeredAuctions) {
      final auction =
          allAuctions.where((a) => a.id == interest.auctionId).firstOrNull;
      if (auction == null) continue;

      final startTime = auction.auctionDate;
      final minutesUntilStart = startTime.difference(now).inMinutes;

      if (minutesUntilStart >= 9 && minutesUntilStart <= 11) {
        await notifyAuctionStarting(
          userId: userId,
          auctionId: auction.id,
          auctionTitle: auction.title,
          startTime: startTime,
          context: context,
        );
      }
    }
  }

  Future<void> notifyBidUpdate({
    required String auctionTitle,
    required double newBid,
    String currency = AppConstants.defaultCurrency,
    BuildContext? context,
    String? auctionId,
    bool showLocal = true,
  }) async {
    if (context != null && (auctionId == null || _canShowPopup(auctionId))) {
      if (!showLocal) {
        showSnackBar(
          context,
          'Tawaran baru: ${_formatCurrency(newBid, currency)}',
          icon: Icons.trending_up,
          backgroundColor: AppColors.info,
        );
      }
    }

    if (showLocal) {
      await showLocalNotification(
        title: 'Tawaran Baru 📈',
        body:
            '$auctionTitle - Tawaran baru: ${_formatCurrency(newBid, currency)}',
        payload: 'bid_update',
      );
    }
  }

  Future<void> checkFinishedAuctionsForUser({
    required String userId,
    required List<InterestModel> registeredAuctions,
    required List<AuctionModel> allAuctions,
    BuildContext? context,
  }) async {
    final now = DateTime.now();
    final bidService = BidService();

    for (var interest in registeredAuctions) {
      final auction = allAuctions.where((a) => a.id == interest.auctionId).firstOrNull;
      if (auction == null) continue;

      final endTime = auction.auctionDate.add(AppAnimations.auctionDuration);
      if (now.isBefore(endTime)) continue; 

      final key = '${userId}_${auction.id}_result';
      if (_notifiedAuctions.contains(key)) continue;

      final winner = await bidService.getAuctionWinner(auction.id);
      final bool isWinner = winner != null && winner.userId == userId;

      final title = isWinner ? 'Selamat! Anda Menang 🏆' : 'Lelang Selesai';
      final message = isWinner
          ? '${auction.title} - Anda memenangkan lelang dengan tawaran tertinggi.'
          : '${auction.title} - Lelang telah selesai. Anda tidak memenangkan lelang ini.';

      await _saveNotification(
        userId: userId,
        title: title,
        message: message,
        type: 'auction_result',
        auctionId: auction.id,
      );

      if (context != null) {
        await addNotification(
          userId: userId,
          title: title,
          message: message,
          type: 'auction_result',
          auctionId: auction.id,
          context: context,
          showPopup: false,
          showLocal: true,
        );
      } else {
        await addNotification(
          userId: userId,
          title: title,
          message: message,
          type: 'auction_result',
          auctionId: auction.id,
          context: null,
          showPopup: false,
          showLocal: true,
        );
      }

      _notifiedAuctions.add(key);
    }
  }

  String _formatCurrency(double amount, String currency) {
    final symbol = CurrencyConstants.currencySymbols[currency] ?? '\$';
    return '$symbol${amount.toStringAsFixed(0)}';
  }

  Future<void> scheduleAuctionCheck() async {}

  static Future<void> performBackgroundCheck() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Hive.initFlutter();
      Hive.registerAdapter(NotificationModelAdapter());
      final notif = NotificationService();
      if (!notif._isInitialized) await notif.initialize();
      final localDb = LocalDbService();
      await localDb.initialize();
      final auctionService = AuctionService();
      final allAuctions = await auctionService.fetchAuctions();
      final usersBox = localDb.usersBox;
      final regBox = localDb.registeredAuctionsBox;

      for (final user in usersBox.values) {
        try {
          final userId = user.id;
          final registered = regBox.values.where((i) => i.userId == userId).toList().cast<InterestModel>();
          if (registered.isEmpty) continue;

          await notif.checkFinishedAuctionsForUser(
            userId: userId,
            registeredAuctions: registered,
            allAuctions: allAuctions,
            context: null,
          );
        } catch (e) {
         
        }
      }
    } catch (e) {
    
    }
  }
}
