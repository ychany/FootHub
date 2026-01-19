import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_football_ids.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/services/live_event_monitor_service.dart';
import '../../../shared/models/match_model.dart';
import '../models/notification_setting.dart';
import '../services/schedule_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../league/screens/league_list_screen.dart' show userLocalLeagueIdsProvider, userNationalTeamIdProvider, userNationalTeamIdsProvider, userCountryCodeProvider, isNationalTeamOfCountry;
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

// 주요 리그 ID 목록 (5대 리그 + 국내컵/슈퍼컵 + 유럽대회 + A매치 전체)
final majorLeagueIds = [
  // 5대 리그
  LeagueIds.premierLeague, LeagueIds.laLiga, LeagueIds.serieA,
  LeagueIds.bundesliga, LeagueIds.ligue1,
  // 5대 리그 국내 컵 대회 + 슈퍼컵
  ...LeagueIds.cupCompetitionIds,
  // 유럽 대회
  LeagueIds.championsLeague, LeagueIds.europaLeague, LeagueIds.conferenceLeague,
  LeagueIds.uefaSuperCup,
  // A매치 전체 (본선 + 예선 + 네이션스리그 + 친선 + 클럽월드컵)
  ...LeagueIds.internationalLeagueIds,
];

// Filtered Schedules Provider
final filteredSchedulesProvider = FutureProvider<List<Match>>((ref) async {
  final service = ref.watch(scheduleServiceProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  final selectedLeague = ref.watch(selectedLeagueProvider);
  final favoriteTeamIds = ref.watch(favoriteTeamIdsProvider).value ?? [];
  // 타임존 변경 시 자동 갱신
  ref.watch(timezoneProvider);

  // 사용자 자국 리그 및 국가대표팀 ID
  final userLocalLeagueIds = ref.watch(userLocalLeagueIdsProvider);
  final userNationalTeamId = ref.watch(userNationalTeamIdProvider);

  var matches = await service.getSchedulesByDate(
    selectedDate,
    favoriteTeamIds: favoriteTeamIds,
  );

  // 자국 국가대표팀 ID 목록 (성인 + 연령별)
  final userNationalTeamIds = ref.watch(userNationalTeamIdsProvider);
  final userNationalTeamIdStrs = userNationalTeamIds.map((id) => id.toString()).toSet();
  final userCountryCode = ref.watch(userCountryCodeProvider);

  if (selectedLeague == 'major') {
    // 주요: 5대 리그 + 유럽대회 + A매치 + 자국 리그 + 자국 국가대표 경기
    final userNationalTeamIdStr = userNationalTeamId?.toString();
    matches = matches.where((m) {
      // 기존 주요 리그
      if (majorLeagueIds.contains(m.leagueId)) return true;
      // 자국 리그
      if (userLocalLeagueIds.contains(m.leagueId)) return true;
      // 자국 국가대표팀 경기 - ID 매칭 (성인만)
      if (userNationalTeamIdStr != null &&
          (m.homeTeamId == userNationalTeamIdStr || m.awayTeamId == userNationalTeamIdStr)) {
        return true;
      }
      // 자국 국가대표팀 경기 - 팀 이름 매칭 (U23, U20 등 연령별 포함)
      if (isNationalTeamOfCountry(m.homeTeamName, userCountryCode) ||
          isNationalTeamOfCountry(m.awayTeamName, userCountryCode)) {
        return true;
      }
      return false;
    }).toList();
  } else if (selectedLeague == 'myCountry') {
    // 자국: 자국 리그 + 국가대표(성인+연령별) 모든 경기
    matches = matches.where((m) {
      // 자국 리그
      if (userLocalLeagueIds.contains(m.leagueId)) return true;
      // 자국 국가대표팀 경기 - ID 매칭
      if (userNationalTeamIdStrs.contains(m.homeTeamId) ||
          userNationalTeamIdStrs.contains(m.awayTeamId)) {
        return true;
      }
      // 자국 국가대표팀 경기 - 팀 이름 매칭 (U23, U20 등 연령별 포함)
      if (isNationalTeamOfCountry(m.homeTeamName, userCountryCode) ||
          isNationalTeamOfCountry(m.awayTeamName, userCountryCode)) {
        return true;
      }
      return false;
    }).toList();
  } else if (selectedLeague == 'International Friendlies') {
    // A매치: 모든 국제대회 (본선 + 예선 + 네이션스리그 + 친선)
    matches = matches.where((m) =>
      LeagueIds.internationalLeagueIds.contains(m.leagueId)
    ).toList();
  } else if (selectedLeague == AppConstants.domesticCups) {
    // 컵대회: 5대 국가 국내 컵대회
    matches = matches.where((m) =>
      LeagueIds.cupCompetitionIds.contains(m.leagueId)
    ).toList();
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

/// 즐겨찾기 팀 경기 자동 알림 스케줄러
class FavoriteMatchNotificationScheduler {
  final LocalNotificationService _notificationService = LocalNotificationService();

  /// 즐겨찾기 팀의 다가오는 경기에 대한 알림 스케줄링
  Future<void> scheduleNotificationsForFavoriteMatches({
    required List<Match> matches,
    required int reminderMinutes,
  }) async {
    for (final match in matches) {
      // 이미 지난 경기는 건너뛰기
      if (match.kickoff.isBefore(DateTime.now())) continue;

      // 리마인더 알림 스케줄링
      final reminderId = LocalNotificationService.generateNotificationId(
        match.id,
        NotificationType.reminder,
      );
      await _notificationService.scheduleMatchReminder(
        notificationId: reminderId,
        matchId: match.id,
        homeTeam: match.homeTeamName,
        awayTeam: match.awayTeamName,
        league: match.league,
        kickoffTime: match.kickoff,
        minutesBefore: reminderMinutes,
      );
    }
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _notificationService.cancelAllNotifications();
  }
}

final favoriteMatchNotificationSchedulerProvider = Provider<FavoriteMatchNotificationScheduler>((ref) {
  return FavoriteMatchNotificationScheduler();
});

/// 앱 시작 시 또는 즐겨찾기 변경 시 자동으로 알림 스케줄링
final autoScheduleFavoriteNotificationsProvider = FutureProvider<void>((ref) async {
  final scheduler = ref.watch(favoriteMatchNotificationSchedulerProvider);
  final settingsAsync = ref.watch(notificationSettingsProvider);
  final favoriteTeamIds = ref.watch(favoriteTeamIdsProvider).value ?? [];

  // 설정 로드 대기
  final settings = settingsAsync.valueOrNull;
  if (settings == null) return;

  // 푸시 알림 또는 경기 시작 알림이 꺼져있으면 스킵
  if (!settings.pushNotifications || !settings.matchReminder) {
    return;
  }

  // 즐겨찾기 팀이 없으면 스킵
  if (favoriteTeamIds.isEmpty) return;

  // 즐겨찾기 팀의 다가오는 경기 조회
  final service = ref.watch(scheduleServiceProvider);
  final upcomingMatches = await service.getUpcomingMatchesForTeams(
    favoriteTeamIds,
    limit: 20,
  );

  // 알림 스케줄링
  await scheduler.scheduleNotificationsForFavoriteMatches(
    matches: upcomingMatches,
    reminderMinutes: settings.matchReminderMinutes,
  );
});

/// 라이브 이벤트 모니터링 Provider
/// 즐겨찾기 팀/선수의 골, 어시스트 등 실시간 알림
final liveEventMonitorProvider = Provider<void>((ref) {
  final settingsAsync = ref.watch(notificationSettingsProvider);
  final favoriteTeamIds = ref.watch(favoriteTeamIdsProvider).value ?? [];
  final favoritePlayerIds = ref.watch(favoritePlayerIdsProvider).value ?? [];

  final settings = settingsAsync.valueOrNull;
  // 싱글톤 인스턴스 사용 (상태 유지)
  final monitor = LiveEventMonitorService();

  // 설정이 없거나 푸시 알림이 꺼져있으면 모니터링 중지
  if (settings == null || !settings.pushNotifications) {
    monitor.stopMonitoring();
    return;
  }

  // 팀 실시간 알림과 선수 이벤트 알림, 라인업/결과 알림 모두 꺼져있으면 모니터링 중지
  if (!settings.liveScoreUpdates && !settings.favoritePlayerEvents &&
      !settings.notifyLineup && !settings.notifyResult) {
    monitor.stopMonitoring();
    return;
  }

  // 활성화된 설정에 따라 모니터링할 대상 결정
  // 팀 모니터링: liveScoreUpdates, notifyLineup, notifyResult 중 하나라도 켜져있으면 활성화
  final needTeamMonitoring = settings.liveScoreUpdates || settings.notifyLineup || settings.notifyResult;
  final teamIdsToMonitor = needTeamMonitoring
      ? favoriteTeamIds.map((id) => int.tryParse(id)).whereType<int>().toSet()
      : <int>{};
  final playerIdsToMonitor = settings.favoritePlayerEvents
      ? favoritePlayerIds.map((id) => int.tryParse(id)).whereType<int>().toSet()
      : <int>{};

  // 모니터링할 대상이 없으면 중지
  if (teamIdsToMonitor.isEmpty && playerIdsToMonitor.isEmpty) {
    monitor.stopMonitoring();
    return;
  }

  // 모니터링 시작 또는 업데이트
  if (monitor.isMonitoring) {
    monitor.updateFavorites(
      favoriteTeamIds: teamIdsToMonitor,
      favoritePlayerIds: playerIdsToMonitor,
      notifyLineup: settings.notifyLineup,
      notifyResult: settings.notifyResult,
    );
  } else {
    monitor.startMonitoring(
      favoriteTeamIds: teamIdsToMonitor,
      favoritePlayerIds: playerIdsToMonitor,
      notifyLineup: settings.notifyLineup,
      notifyResult: settings.notifyResult,
    );
  }

  // Provider가 dispose될 때 모니터링 중지
  ref.onDispose(() {
    monitor.stopMonitoring();
  });
});
