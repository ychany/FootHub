import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_football_service.dart';
import 'local_notification_service.dart';

/// 라이브 경기 이벤트 모니터링 서비스
/// 즐겨찾기 팀/선수의 골, 어시스트 등 이벤트 발생 시 알림
class LiveEventMonitorService {
  static final LiveEventMonitorService _instance = LiveEventMonitorService._internal();
  factory LiveEventMonitorService() => _instance;
  LiveEventMonitorService._internal();

  final ApiFootballService _apiService = ApiFootballService();
  final LocalNotificationService _notificationService = LocalNotificationService();

  Timer? _monitorTimer;
  bool _isMonitoring = false;

  // 이미 알림을 보낸 이벤트 추적 (fixtureId_eventKey)
  final Set<String> _notifiedEvents = {};

  // 모니터링 중인 경기 ID들과 마지막 이벤트 수
  final Map<int, int> _lastEventCounts = {};

  // 현재 즐겨찾기 팀/선수 ID
  Set<int> _favoriteTeamIds = {};
  Set<int> _favoritePlayerIds = {};

  /// 모니터링 시작
  void startMonitoring({
    required Set<int> favoriteTeamIds,
    required Set<int> favoritePlayerIds,
  }) {
    if (_isMonitoring) return;

    _favoriteTeamIds = favoriteTeamIds;
    _favoritePlayerIds = favoritePlayerIds;
    _isMonitoring = true;

    // 즉시 한번 체크
    _checkLiveEvents();

    // 2분마다 체크 (API 호출 제한 고려)
    _monitorTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _checkLiveEvents(),
    );

    debugPrint('[LiveEventMonitor] Started monitoring - Teams: ${favoriteTeamIds.length}, Players: ${favoritePlayerIds.length}');
  }

  /// 모니터링 중지
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _isMonitoring = false;
    _notifiedEvents.clear();
    _lastEventCounts.clear();
    debugPrint('[LiveEventMonitor] Stopped monitoring');
  }

  /// 즐겨찾기 업데이트
  void updateFavorites({
    required Set<int> favoriteTeamIds,
    required Set<int> favoritePlayerIds,
  }) {
    _favoriteTeamIds = favoriteTeamIds;
    _favoritePlayerIds = favoritePlayerIds;
  }

  /// 라이브 경기 이벤트 체크
  Future<void> _checkLiveEvents() async {
    if (_favoriteTeamIds.isEmpty && _favoritePlayerIds.isEmpty) return;

    try {
      // 현재 진행 중인 경기 가져오기
      final liveFixtures = await _apiService.getLiveFixtures();

      // 즐겨찾기 팀이 참여하는 라이브 경기 필터링
      final relevantFixtures = liveFixtures.where((fixture) {
        return _favoriteTeamIds.contains(fixture.homeTeam.id) ||
               _favoriteTeamIds.contains(fixture.awayTeam.id);
      }).toList();

      debugPrint('[LiveEventMonitor] Found ${relevantFixtures.length} relevant live matches');

      // 각 경기의 이벤트 체크
      for (final fixture in relevantFixtures) {
        await _checkFixtureEvents(fixture);
      }
    } catch (e) {
      debugPrint('[LiveEventMonitor] Error checking live events: $e');
    }
  }

  /// 개별 경기 이벤트 체크
  Future<void> _checkFixtureEvents(ApiFootballFixture fixture) async {
    try {
      final events = await _apiService.getFixtureEvents(fixture.id);

      // 이전에 체크한 이벤트 수와 비교
      final lastCount = _lastEventCounts[fixture.id] ?? 0;
      _lastEventCounts[fixture.id] = events.length;

      // 새로운 이벤트만 처리 (처음 체크시 제외)
      if (lastCount == 0) return;

      final newEvents = events.skip(lastCount).toList();

      for (final event in newEvents) {
        await _processEvent(fixture, event);
      }
    } catch (e) {
      debugPrint('[LiveEventMonitor] Error checking fixture ${fixture.id}: $e');
    }
  }

  /// 이벤트 처리 및 알림 발송
  Future<void> _processEvent(ApiFootballFixture fixture, ApiFootballEvent event) async {
    // 중복 알림 방지
    final eventKey = '${fixture.id}_${event.elapsed}_${event.type}_${event.playerId}';
    if (_notifiedEvents.contains(eventKey)) return;
    _notifiedEvents.add(eventKey);

    // 골 이벤트 처리
    if (event.isGoal) {
      await _handleGoalEvent(fixture, event);
    }
    // 레드카드 이벤트 처리
    else if (event.isCard && event.detail == 'Red Card') {
      await _handleRedCardEvent(fixture, event);
    }
  }

  /// 골 이벤트 처리
  Future<void> _handleGoalEvent(ApiFootballFixture fixture, ApiFootballEvent event) async {
    final isFavoriteTeam = _favoriteTeamIds.contains(event.teamId);
    final isFavoritePlayer = _favoritePlayerIds.contains(event.playerId);
    final isFavoriteAssist = _favoritePlayerIds.contains(event.assistId);

    // 즐겨찾기 팀 골
    if (isFavoriteTeam) {
      final title = '⚽ ${event.teamName} 골!';
      final scorer = event.playerName ?? '득점자 불명';
      final assist = event.assistName != null ? ' (어시스트: ${event.assistName})' : '';
      final time = event.elapsed != null ? "${event.elapsed}'" : '';
      final body = '$time $scorer$assist\n${fixture.homeTeam.name} vs ${fixture.awayTeam.name}';

      await _sendNotification(
        title: title,
        body: body,
        fixtureId: fixture.id,
        eventType: 'goal_team',
      );
    }

    // 즐겨찾기 선수 골
    if (isFavoritePlayer && !isFavoriteTeam) {
      final title = '⚽ ${event.playerName} 골!';
      final time = event.elapsed != null ? "${event.elapsed}'" : '';
      final body = '$time ${event.teamName}\n${fixture.homeTeam.name} vs ${fixture.awayTeam.name}';

      await _sendNotification(
        title: title,
        body: body,
        fixtureId: fixture.id,
        eventType: 'goal_player',
      );
    }

    // 즐겨찾기 선수 어시스트
    if (isFavoriteAssist && !isFavoriteTeam && !isFavoritePlayer) {
      final title = '🅰️ ${event.assistName} 어시스트!';
      final time = event.elapsed != null ? "${event.elapsed}'" : '';
      final body = '$time ${event.playerName} 골 (${event.teamName})\n${fixture.homeTeam.name} vs ${fixture.awayTeam.name}';

      await _sendNotification(
        title: title,
        body: body,
        fixtureId: fixture.id,
        eventType: 'assist_player',
      );
    }
  }

  /// 레드카드 이벤트 처리
  Future<void> _handleRedCardEvent(ApiFootballFixture fixture, ApiFootballEvent event) async {
    final isFavoriteTeam = _favoriteTeamIds.contains(event.teamId);
    final isFavoritePlayer = _favoritePlayerIds.contains(event.playerId);

    if (isFavoriteTeam || isFavoritePlayer) {
      final title = '🟥 레드카드!';
      final time = event.elapsed != null ? "${event.elapsed}'" : '';
      final body = '$time ${event.playerName} (${event.teamName})\n${fixture.homeTeam.name} vs ${fixture.awayTeam.name}';

      await _sendNotification(
        title: title,
        body: body,
        fixtureId: fixture.id,
        eventType: 'red_card',
      );
    }
  }

  /// 알림 발송
  Future<void> _sendNotification({
    required String title,
    required String body,
    required int fixtureId,
    required String eventType,
  }) async {
    final notificationId = '${fixtureId}_$eventType'.hashCode.abs() % 100000 + 10000;

    await _notificationService.showLiveUpdateNotification(
      notificationId: notificationId,
      title: title,
      body: body,
      payload: fixtureId.toString(),
    );

    debugPrint('[LiveEventMonitor] Sent notification: $title');
  }

  /// 저장된 알림 상태 복원 (앱 재시작 시)
  Future<void> loadNotifiedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('notified_events') ?? [];
      _notifiedEvents.addAll(saved);

      // 24시간 이상 지난 이벤트는 정리
      if (_notifiedEvents.length > 1000) {
        _notifiedEvents.clear();
        await prefs.remove('notified_events');
      }
    } catch (e) {
      debugPrint('[LiveEventMonitor] Error loading notified events: $e');
    }
  }

  /// 알림 상태 저장 (앱 종료 시)
  Future<void> saveNotifiedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('notified_events', _notifiedEvents.toList());
    } catch (e) {
      debugPrint('[LiveEventMonitor] Error saving notified events: $e');
    }
  }

  bool get isMonitoring => _isMonitoring;
}
