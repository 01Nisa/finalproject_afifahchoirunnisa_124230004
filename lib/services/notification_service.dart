import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/notification_model.dart';
import '../models/auction_model.dart';
import '../models/interest_model.dart';
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

  String _lbsLink = 'https://maps.google.com';

  String get lbsLink => _lbsLink;
  set lbsLink(String link) => _lbsLink = link;

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

    if (_localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>() !=
        null) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()!
          .requestNotificationsPermission();
    }

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null && response.payload!.startsWith('lbs://')) {
      _openLBSLink();
    }
  }

  Future<void> _openLBSLink() async {
    final uri = Uri.parse(_lbsLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
  }) {
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
  }) {
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
              onPressed: () => Navigator.of(context).pop(),
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
    );
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

    if (context != null) {
      showSnackBar(
        context,
        'Lelang Aktif: $auctionTitle',
        icon: Icons.gavel,
        backgroundColor: AppColors.success,
      );
    }

    await showLocalNotification(
      title: 'Lelang Aktif! 🎨',
      body: '$auctionTitle - $message',
      payload: payload ?? 'auction_active',
    );
  }

  Future<void> notifyAuctionStarting({
    required String userId,
    required String auctionId,
    required String auctionTitle,
    required DateTime startTime,
    BuildContext? context,
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

    if (context != null) {
      showSnackBar(
        context,
        'Lelang akan dimulai dalam $minutesUntil menit: $auctionTitle',
        icon: Icons.access_time,
        backgroundColor: AppColors.warning,
      );
    }

    await showLocalNotification(
      title: 'Lelang Segera Dimulai ⏰',
      body: '$auctionTitle akan dimulai dalam $minutesUntil menit',
      payload: 'auction_starting',
    );
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

      if (minutesUntilStart >= 4 && minutesUntilStart <= 6) {
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
    String currency = 'USD',
    BuildContext? context,
  }) async {
    if (context != null) {
      showSnackBar(
        context,
        'Tawaran baru: ${_formatCurrency(newBid, currency)}',
        icon: Icons.trending_up,
        backgroundColor: AppColors.info,
      );
    }

    await showLocalNotification(
      title: 'Tawaran Baru 📈',
      body:
          '$auctionTitle - Tawaran baru: ${_formatCurrency(newBid, currency)}',
      payload: 'bid_update',
    );
  }

  String _formatCurrency(double amount, String currency) {
    final symbol = CurrencyConstants.currencySymbols[currency] ?? '\$';
    return '$symbol${amount.toStringAsFixed(0)}';
  }

  Future<void> scheduleAuctionCheck() async {}
}
