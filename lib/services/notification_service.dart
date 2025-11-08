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

  // Tracks auction IDs that were displayed as in-app popups during this
  // session so we don't also show a snackbar for the same event.
  final Set<String> _popupShownAuctions = {};
  // Whether an in-app popup is currently visible. Used to prevent showing
  // snackbars while a popup is shown.
  bool _isPopupVisible = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _notificationsBox =
        await Hive.openBox<NotificationModel>('notifications_box');

    // nothing extra to init here for now

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

    // Request permission untuk Android
    final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      
      // Buat notification channel untuk Android
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

    // Request permission untuk iOS
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
    // Currently we don't perform direct navigation from the notification
    // service to UI screens. The app listens for lifecycle events and
    // reads persisted notifications to decide navigation. Keeping this
    // method minimal avoids bringing UI/navigation code into the service.
    return;
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
  }) {
    // If an in-app popup is visible, avoid showing snackbars so the UI
    // doesn't show duplicate messages (popup above + snackbar below).
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

  // Scheduling via timezone-aware zonedSchedule is not used here to keep
  // behavior simple and reliable across platforms in the current setup.
  // We still display immediate local notifications and persist records.

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
    // If caller provides an auctionId, record that this auction was shown
    // as a popup so the service can avoid duplicate snackbars later.
    if (auctionId != null) instance._popupShownAuctions.add(auctionId);
    // Mark popup visible while dialog is up so snackbars are suppressed.
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
    ).then((v) {
      instance._isPopupVisible = false;
      return v;
    });
  }

  /// Register that an auction popup was shown. Public helper for callers
  /// that display a popup through other means and want the notification
  /// service to avoid duplicate snackbars for the same auction.
  static void registerPopupShown(String auctionId) {
    NotificationService()._popupShownAuctions.add(auctionId);
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

  // Note: 5-minute OS-level reminders were intentionally removed to avoid
  // extra dependencies and platform scheduling complexity. The app instead
  // generates notifications when it checks auction states (on resume or
  // after fetching data).

  // helper removed: not needed in current simplified notification flow

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

    // If this auction was already shown as a popup during this session,
    // avoid showing a duplicate snackbar.
    if (context != null && !_popupShownAuctions.contains(auctionId)) {
     
    }

    await showLocalNotification(
      title: 'Lelang Aktif! 🎨',
      body: '$auctionTitle - $message',
      payload: payload ?? 'auction_active',
    );
  }

  /// Public helper to persist a notification and optionally show a local
  /// system notification and in-app snackbar/dialog.
  Future<void> addNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? auctionId,
    BuildContext? context,
    bool showLocal = true,
    /// If true, shows the in-app dialog (popup) instead of a snackbar.
    /// When [showPopup] is true we do NOT also show a snackbar to avoid
    /// duplicate UI (popup + snackbar) for the same notification.
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
      // Show either an in-app dialog (popup) or a snackbar, but not both.
      if (showPopup) {
        // Record that this auction (if provided) was shown as a popup so
        // other service methods won't duplicate with a snackbar.
        if (auctionId != null) _popupShownAuctions.add(auctionId);
        // Fire-and-forget the dialog; callers who need to await can call
        // showInAppNotification themselves.
        try {
          showInAppNotification(context, title: title, message: message, auctionId: auctionId);
        } catch (_) {
          // If dialog fails for any reason, fall back to snackbar so user
          // still sees feedback.
          showSnackBar(context, message, icon: Icons.notifications);
        }
      } else {
        // If this notification is tied to an auction that was already shown
        // as a popup earlier in the session, skip showing a snackbar to
        // avoid duplicate UI. Also, if a system/local notification will be
        // shown (showLocal == true) prefer the OS notification and do not
        // show an in-app snackbar.
        if (auctionId != null && _popupShownAuctions.contains(auctionId)) {
          // no-op: popup was already shown for this auction
        } else {
          if (!showLocal) {
            // Lightweight in-app feedback via snackbar
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

    // If this auction was already shown as a popup, skip showing a snackbar
    // to avoid duplicate UI. Additionally, if a system (local) notification
    // will be shown (showLocal == true) prefer the OS notification and do
    // not show an in-app snackbar.
    if (context != null && !_popupShownAuctions.contains(auctionId)) {
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

      // Notifikasi 10 menit sebelum lelang dimulai (range 9-11 menit untuk toleransi)
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
    // If this auction was already shown as a popup, or if a system/local
    // notification will be shown, avoid showing a duplicate snackbar.
    if (context != null && (auctionId == null || !_popupShownAuctions.contains(auctionId))) {
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

  /// Check for finished auctions among user's registered auctions and
  /// notify user about the result (win/lose). This should be called when
  /// the app resumes or after fetching latest auction/bid data.
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
      if (now.isBefore(endTime)) continue; // not finished yet

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
        // Use system/local notification so it appears in the OS notification
        // tray and is persisted (shown in bell icon). We still persist the
        // record via addNotification — but prefer the OS popup over an
        // in-app dialog for finished-auction results so users see it even
        // when the app is backgrounded.
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
        // No context (app backgrounded); show a local/system notification
        // and persist the record.
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

  /// Perform a background check for finished auctions across all users.
  /// This method is safe to call from a background isolate (headless)
  /// as long as the environment has Flutter bindings initialized.
  static Future<void> performBackgroundCheck() async {
    try {
      // Initialize services required in background
      WidgetsFlutterBinding.ensureInitialized();
      await Hive.initFlutter();
      // Register adapters if not already registered in this isolate
      // (Adapters registration is idempotent)
      Hive.registerAdapter(NotificationModelAdapter());

      final notif = NotificationService();
      if (!notif._isInitialized) await notif.initialize();

      // Initialize local DB and auction data
      final localDb = LocalDbService();
      await localDb.initialize();

      final auctionService = AuctionService();
      final allAuctions = await auctionService.fetchAuctions();

      // Iterate users stored locally and check results for their interests
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
          // non-fatal per-user error
        }
      }
    } catch (e) {
      // If background check failed, there's nothing to do here. We'll try
      // again on the next scheduled run.
    }
  }
}
