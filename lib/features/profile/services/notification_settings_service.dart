import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationSettings {
  final bool matchReminder;
  final int matchReminderMinutes;
  final bool matchKickoff; // 경기 시작 알림 (정시)
  final bool liveScoreUpdates;
  final bool favoritePlayerEvents;
  final bool notifyResult;
  final bool pushNotifications;

  const NotificationSettings({
    this.matchReminder = true,
    this.matchReminderMinutes = 30,
    this.matchKickoff = true,
    this.liveScoreUpdates = false,
    this.favoritePlayerEvents = false,
    this.notifyResult = false,
    this.pushNotifications = true,
  });

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      matchReminder: map['matchReminder'] ?? true,
      matchReminderMinutes: map['matchReminderMinutes'] ?? 30,
      matchKickoff: map['matchKickoff'] ?? true,
      liveScoreUpdates: map['liveScoreUpdates'] ?? false,
      favoritePlayerEvents: map['favoritePlayerEvents'] ?? false,
      notifyResult: map['notifyResult'] ?? false,
      pushNotifications: map['pushNotifications'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'matchReminder': matchReminder,
      'matchReminderMinutes': matchReminderMinutes,
      'matchKickoff': matchKickoff,
      'liveScoreUpdates': liveScoreUpdates,
      'favoritePlayerEvents': favoritePlayerEvents,
      'notifyResult': notifyResult,
      'pushNotifications': pushNotifications,
    };
  }

  NotificationSettings copyWith({
    bool? matchReminder,
    int? matchReminderMinutes,
    bool? matchKickoff,
    bool? liveScoreUpdates,
    bool? favoritePlayerEvents,
    bool? notifyResult,
    bool? pushNotifications,
  }) {
    return NotificationSettings(
      matchReminder: matchReminder ?? this.matchReminder,
      matchReminderMinutes: matchReminderMinutes ?? this.matchReminderMinutes,
      matchKickoff: matchKickoff ?? this.matchKickoff,
      liveScoreUpdates: liveScoreUpdates ?? this.liveScoreUpdates,
      favoritePlayerEvents: favoritePlayerEvents ?? this.favoritePlayerEvents,
      notifyResult: notifyResult ?? this.notifyResult,
      pushNotifications: pushNotifications ?? this.pushNotifications,
    );
  }
}

class NotificationSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference _userSettingsDoc(String userId) {
    return _firestore.collection('users').doc(userId).collection('settings').doc('notifications');
  }

  Future<NotificationSettings> getSettings(String userId) async {
    final doc = await _userSettingsDoc(userId).get();
    if (doc.exists) {
      return NotificationSettings.fromMap(doc.data() as Map<String, dynamic>);
    }
    return const NotificationSettings();
  }

  Stream<NotificationSettings> settingsStream(String userId) {
    return _userSettingsDoc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return NotificationSettings.fromMap(doc.data() as Map<String, dynamic>);
      }
      return const NotificationSettings();
    });
  }

  Future<void> updateSettings(String userId, NotificationSettings settings) async {
    await _userSettingsDoc(userId).set(settings.toMap(), SetOptions(merge: true));
  }

  Future<void> updateSingleSetting(String userId, String key, dynamic value) async {
    await _userSettingsDoc(userId).set({key: value}, SetOptions(merge: true));
  }
}
