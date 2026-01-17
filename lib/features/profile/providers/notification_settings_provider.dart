import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_settings_service.dart';
import '../../auth/providers/auth_provider.dart';

// Service Provider
final notificationSettingsServiceProvider = Provider<NotificationSettingsService>((ref) {
  return NotificationSettingsService();
});

// Settings Stream Provider
final notificationSettingsProvider = StreamProvider<NotificationSettings>((ref) {
  final service = ref.watch(notificationSettingsServiceProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return Stream.value(const NotificationSettings());
  }
  return service.settingsStream(userId);
});

// Settings Notifier for updates
class NotificationSettingsNotifier extends StateNotifier<AsyncValue<void>> {
  final NotificationSettingsService _service;
  final Ref _ref;

  NotificationSettingsNotifier(this._service, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> updateMatchReminder(bool value) async {
    await _updateSetting('matchReminder', value);
  }

  Future<void> updateMatchReminderMinutes(int value) async {
    await _updateSetting('matchReminderMinutes', value);
  }

  Future<void> updateLiveScoreUpdates(bool value) async {
    await _updateSetting('liveScoreUpdates', value);
  }

  Future<void> updateFavoritePlayerEvents(bool value) async {
    await _updateSetting('favoritePlayerEvents', value);
  }

  Future<void> updatePushNotifications(bool value) async {
    await _updateSetting('pushNotifications', value);
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncValue.loading();
    try {
      await _service.updateSingleSetting(userId, key, value);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final notificationSettingsNotifierProvider =
    StateNotifierProvider<NotificationSettingsNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(notificationSettingsServiceProvider);
  return NotificationSettingsNotifier(service, ref);
});
