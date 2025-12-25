import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../shared/models/match_model.dart';
import '../models/notification_setting.dart';
import '../services/schedule_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../profile/providers/notification_settings_provider.dart';
import '../../profile/providers/timezone_provider.dart';

// Schedule Service Provider
final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  return ScheduleService();
});

// Selected Date Provider
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

// Schedules by Date Provider
final schedulesByDateProvider = FutureProvider<List<Match>>((ref) async {
  final service = ref.watch(scheduleServiceProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  final favoriteTeamIds = ref.watch(favoriteTeamIdsProvider).value ?? [];
  // 타임존 변경 시 자동 갱신
  ref.watch(timezoneProvider);

  return service.getSchedulesByDate(
    selectedDate,
    favoriteTeamIds: favoriteTeamIds,
  );
});

// Schedules Stream Provider (for date range)
class ScheduleDateRange {
  final DateTime startDate;
  final DateTime endDate;
  final String? league;

  ScheduleDateRange({
    required this.startDate,
    required this.endDate,
    this.league,
  });
}

final schedulesStreamProvider =
    StreamProvider.family<List<Match>, ScheduleDateRange>((ref, range) {
  final service = ref.watch(scheduleServiceProvider);
  final favoriteTeamIds = ref.watch(favoriteTeamIdsProvider).value ?? [];

  return service.getSchedules(
    startDate: range.startDate,
    endDate: range.endDate,
    league: range.league,
    favoriteTeamIds: favoriteTeamIds,
  );
});

// Upcoming Matches for Favorite Teams Provider
final upcomingFavoriteMatchesProvider =
    FutureProvider<List<Match>>((ref) async {
  final service = ref.watch(scheduleServiceProvider);
  final favoriteTeamIds = ref.watch(favoriteTeamIdsProvider).value ?? [];
  // 타임존 변경 시 자동 갱신
  ref.watch(timezoneProvider);

  if (favoriteTeamIds.isEmpty) return [];
  return service.getUpcomingMatchesForTeams(favoriteTeamIds, limit: 10);
});

// Match by ID Provider
final matchByIdProvider =
    FutureProvider.family<Match?, String>((ref, matchId) async {
  final service = ref.watch(scheduleServiceProvider);
  // 타임존 변경 시 자동 갱신
  ref.watch(timezoneProvider);
  return service.getMatch(matchId);
});

// Matches by League Provider
final matchesByLeagueProvider =
    FutureProvider.family<List<Match>, String>((ref, league) async {
  final service = ref.watch(scheduleServiceProvider);
  // 타임존 변경 시 자동 갱신
  ref.watch(timezoneProvider);
  final now = DateTime.now();
  return service.getMatchesByLeague(
    league,
    startDate: now.subtract(const Duration(days: 7)),
    endDate: now.add(const Duration(days: 14)),
  );
});

// === Notification Providers ===

// Notification Setting for Match Provider
final matchNotificationProvider =
    FutureProvider.family<NotificationSetting?, String>((ref, matchId) async {
  final service = ref.watch(scheduleServiceProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return null;
  return service.getNotificationSetting(userId, matchId);
});

// Has Notification Provider
final hasNotificationProvider =
    FutureProvider.family<bool, String>((ref, matchId) async {
  final service = ref.watch(scheduleServiceProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return false;
  return service.hasNotification(userId, matchId);
});

// User Notification Settings Provider
final userNotificationSettingsProvider =
    FutureProvider<List<NotificationSetting>>((ref) async {
  final service = ref.watch(scheduleServiceProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return [];
  return service.getUserNotificationSettings(userId);
});

// Schedule Notifier for actions
class ScheduleNotifier extends StateNotifier<AsyncValue<void>> {
  final ScheduleService _service;
  final Ref _ref;
  final LocalNotificationService _notificationService = LocalNotificationService();

  ScheduleNotifier(this._service, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> setNotification({
    required String matchId,
    bool notifyKickoff = true,
    bool notifyLineup = false,
    bool notifyResult = true,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncValue.loading();
    try {
      await _service.setNotification(
        userId: userId,
        matchId: matchId,
        notifyKickoff: notifyKickoff,
        notifyLineup: notifyLineup,
        notifyResult: notifyResult,
      );

      // Schedule actual local notifications
      await _scheduleMatchNotifications(
        matchId: matchId,
        notifyKickoff: notifyKickoff,
      );

      state = const AsyncValue.data(null);
      // Invalidate related providers
      _ref.invalidate(matchNotificationProvider(matchId));
      _ref.invalidate(hasNotificationProvider(matchId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _scheduleMatchNotifications({
    required String matchId,
    required bool notifyKickoff,
  }) async {
    try {
      // Get match details
      final match = await _service.getMatch(matchId);
      if (match == null) return;

      // Get user's notification settings
      final settingsAsync = _ref.read(notificationSettingsProvider);
      final settings = settingsAsync.value;
      if (settings == null || !settings.pushNotifications) return;

      // Cancel any existing notifications for this match
      await _notificationService.cancelMatchNotifications(matchId);

      // Schedule reminder notification if match reminder is enabled
      if (settings.matchReminder) {
        final reminderId = LocalNotificationService.generateNotificationId(
          matchId,
          NotificationType.reminder,
        );
        await _notificationService.scheduleMatchReminder(
          notificationId: reminderId,
          matchId: matchId,
          homeTeam: match.homeTeamName,
          awayTeam: match.awayTeamName,
          league: match.league,
          kickoffTime: match.kickoff,
          minutesBefore: settings.matchReminderMinutes,
        );
      }

      // Schedule kickoff notification if enabled
      if (notifyKickoff) {
        final kickoffId = LocalNotificationService.generateNotificationId(
          matchId,
          NotificationType.kickoff,
        );
        await _notificationService.scheduleKickoffNotification(
          notificationId: kickoffId,
          matchId: matchId,
          homeTeam: match.homeTeamName,
          awayTeam: match.awayTeamName,
          league: match.league,
          kickoffTime: match.kickoff,
        );
      }
    } catch (e) {
      // Log error but don't fail the main operation
      // ignore: avoid_print
      print('Failed to schedule notifications: $e');
    }
  }

  Future<void> toggleNotification({
    required String matchId,
    required String type,
    required bool value,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncValue.loading();
    try {
      await _service.toggleNotification(
        userId: userId,
        matchId: matchId,
        type: type,
        value: value,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(matchNotificationProvider(matchId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeNotification(String matchId) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncValue.loading();
    try {
      await _service.removeNotification(userId, matchId);

      // Cancel local notifications for this match
      await _notificationService.cancelMatchNotifications(matchId);

      state = const AsyncValue.data(null);
      _ref.invalidate(matchNotificationProvider(matchId));
      _ref.invalidate(hasNotificationProvider(matchId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final scheduleNotifierProvider =
    StateNotifierProvider<ScheduleNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(scheduleServiceProvider);
  return ScheduleNotifier(service, ref);
});

// League Filter Provider (기본값: 주요 - 5대 리그 + 대륙컵 + 국제대회)
// null = 전체, 'major' = 주요, 그 외 = 특정 리그
final selectedLeagueProvider = StateProvider<String?>((ref) => 'major');

// 주요 리그 ID 목록 (5대 리그 + 대륙컵 + 국제대회)
const majorLeagueIds = [
  // 5대 리그
  39, 140, 135, 78, 61, // EPL, 라리가, 세리에A, 분데스, 리그1
  // 유럽 대회
  2, 3, 848, // UCL, UEL, UECL
  // 국제대회
  1, 4, 81, 6, 9, // 월드컵, 유로, 아시안컵, 아프리카네이션스컵, 코파아메리카
];

// Filtered Schedules Provider
final filteredSchedulesProvider = FutureProvider<List<Match>>((ref) async {
  final service = ref.watch(scheduleServiceProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  final selectedLeague = ref.watch(selectedLeagueProvider);
  final favoriteTeamIds = ref.watch(favoriteTeamIdsProvider).value ?? [];
  // 타임존 변경 시 자동 갱신
  ref.watch(timezoneProvider);

  var matches = await service.getSchedulesByDate(
    selectedDate,
    favoriteTeamIds: favoriteTeamIds,
  );

  if (selectedLeague == 'major') {
    // 주요: 5대 리그만 필터링
    matches = matches.where((m) => majorLeagueIds.contains(m.leagueId)).toList();
  } else if (selectedLeague != null) {
    // 특정 리그 필터링
    final targetLeagueId = AppConstants.getLeagueIdByName(selectedLeague);

    if (targetLeagueId != null) {
      // ID 기반 필터링
      matches = matches.where((m) => m.leagueId == targetLeagueId).toList();
    } else {
      // ID가 없는 경우 이름 기반 fallback
      matches = matches.where((m) {
        return AppConstants.isLeagueMatch(m.league, selectedLeague);
      }).toList();
    }
  }
  // selectedLeague == null 이면 전체 (필터링 없음)

  // 시간순 정렬 (빠른 시간이 먼저)
  matches.sort((a, b) => a.kickoff.compareTo(b.kickoff));

  return matches;
});
