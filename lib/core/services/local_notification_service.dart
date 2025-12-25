import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Notification channel for Android
  static const AndroidNotificationChannel _matchChannel = AndroidNotificationChannel(
    'match_notifications',
    'Match Notifications',
    description: 'Notifications for upcoming matches',
    importance: Importance.high,
    playSound: true,
  );

  static const AndroidNotificationChannel _liveChannel = AndroidNotificationChannel(
    'live_notifications',
    'Live Match Updates',
    description: 'Real-time match score updates',
    importance: Importance.high,
    playSound: true,
  );

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_matchChannel);
      await androidPlugin?.createNotificationChannel(_liveChannel);
    }

    _isInitialized = true;
    debugPrint('LocalNotificationService initialized');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Navigation can be handled here if needed
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    } else if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  /// Check if notifications are permitted
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }
    // iOS doesn't have a direct check, assume true if we reach here
    return true;
  }

  /// Schedule a match reminder notification
  Future<void> scheduleMatchReminder({
    required int notificationId,
    required String matchId,
    required String homeTeam,
    required String awayTeam,
    required String league,
    required DateTime kickoffTime,
    required int minutesBefore,
  }) async {
    final scheduledTime = kickoffTime.subtract(Duration(minutes: minutesBefore));

    // Don't schedule if the time has already passed
    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint('Skipping notification - scheduled time has passed');
      return;
    }

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    final androidDetails = AndroidNotificationDetails(
      _matchChannel.id,
      _matchChannel.name,
      channelDescription: _matchChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        '$league\n$homeTeam vs $awayTeam',
        contentTitle: '경기 시작 $minutesBefore분 전!',
        summaryText: league,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      '경기 시작 $minutesBefore분 전!',
      '$homeTeam vs $awayTeam',
      tzScheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: matchId,
    );

    debugPrint('Scheduled notification for match $matchId at $scheduledTime');
  }

  /// Schedule kickoff notification (at match start)
  Future<void> scheduleKickoffNotification({
    required int notificationId,
    required String matchId,
    required String homeTeam,
    required String awayTeam,
    required String league,
    required DateTime kickoffTime,
  }) async {
    // Don't schedule if the time has already passed
    if (kickoffTime.isBefore(DateTime.now())) {
      debugPrint('Skipping kickoff notification - time has passed');
      return;
    }

    final tzScheduledTime = tz.TZDateTime.from(kickoffTime, tz.local);

    final androidDetails = AndroidNotificationDetails(
      _matchChannel.id,
      _matchChannel.name,
      channelDescription: _matchChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      '⚽ 경기 시작!',
      '$homeTeam vs $awayTeam - $league',
      tzScheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: matchId,
    );

    debugPrint('Scheduled kickoff notification for match $matchId at $kickoffTime');
  }

  /// Show immediate notification (for live updates)
  Future<void> showLiveUpdateNotification({
    required int notificationId,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _liveChannel.id,
      _liveChannel.name,
      channelDescription: _liveChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      notificationId,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int notificationId) async {
    await _notifications.cancel(notificationId);
    debugPrint('Cancelled notification: $notificationId');
  }

  /// Cancel all notifications for a match (using matchId hash)
  Future<void> cancelMatchNotifications(String matchId) async {
    // We use hashCode-based IDs, so cancel the main ones
    final baseId = matchId.hashCode.abs() % 100000;
    await _notifications.cancel(baseId); // Reminder
    await _notifications.cancel(baseId + 1); // Kickoff
    await _notifications.cancel(baseId + 2); // Lineup
    await _notifications.cancel(baseId + 3); // Result
    debugPrint('Cancelled all notifications for match: $matchId');
  }

  /// Cancel all pending notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('Cancelled all notifications');
  }

  /// Get list of pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Generate notification ID from matchId and type
  static int generateNotificationId(String matchId, NotificationType type) {
    final baseId = matchId.hashCode.abs() % 100000;
    return baseId + type.index;
  }
}

enum NotificationType {
  reminder,
  kickoff,
  lineup,
  result,
}
