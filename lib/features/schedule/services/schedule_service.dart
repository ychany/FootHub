import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/api_football_ids.dart';
import '../../../core/services/api_football_service.dart';
import '../../../shared/models/match_model.dart';
import '../models/notification_setting.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiFootballService _apiService = ApiFootballService();

  CollectionReference<Map<String, dynamic>> get _schedulesCollection =>
      _firestore.collection(AppConstants.schedulesCollection);

  CollectionReference<Map<String, dynamic>> get _notificationCollection =>
      _firestore.collection(AppConstants.notificationSettingsCollection);

  // Get schedules by date range
  Stream<List<Match>> getSchedules({
    required DateTime startDate,
    required DateTime endDate,
    String? league,
    List<String>? favoriteTeamIds,
  }) {
    Query<Map<String, dynamic>> query = _schedulesCollection
        .where('kickoff',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('kickoff', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('kickoff');

    if (league != null) {
      query = query.where('league', isEqualTo: league);
    }

    return query.snapshots().map((snapshot) {
      final matches =
          snapshot.docs.map((doc) => Match.fromFirestore(doc)).toList();

      // Sort: followed teams first, then by kickoff time
      if (favoriteTeamIds != null && favoriteTeamIds.isNotEmpty) {
        matches.sort((a, b) {
          final aFollowed = favoriteTeamIds.contains(a.homeTeamId) ||
              favoriteTeamIds.contains(a.awayTeamId);
          final bFollowed = favoriteTeamIds.contains(b.homeTeamId) ||
              favoriteTeamIds.contains(b.awayTeamId);

          if (aFollowed && !bFollowed) return -1;
          if (!aFollowed && bFollowed) return 1;
          return a.kickoff.compareTo(b.kickoff);
        });
      }

      return matches;
    });
  }

  // Get schedules for a specific date (using API-Football)
  // 한국시간 기준으로 해당 날짜의 경기를 반환
  Future<List<Match>> getSchedulesByDate(
    DateTime date, {
    List<String>? favoriteTeamIds,
  }) async {
    try {
      // API에서 timezone=Asia/Seoul 파라미터로 한국 시간 기준 경기 조회
      final fixtures = await _apiService.getFixturesByDate(date);

      // ApiFootballFixture를 Match로 변환
      final matches = fixtures.map((fixture) => _convertFixtureToMatch(fixture)).toList();

      if (favoriteTeamIds != null && favoriteTeamIds.isNotEmpty) {
        matches.sort((a, b) {
          final aFollowed = favoriteTeamIds.contains(a.homeTeamId) ||
              favoriteTeamIds.contains(a.awayTeamId);
          final bFollowed = favoriteTeamIds.contains(b.homeTeamId) ||
              favoriteTeamIds.contains(b.awayTeamId);

          if (aFollowed && !bFollowed) return -1;
          if (!aFollowed && bFollowed) return 1;
          return a.kickoff.compareTo(b.kickoff);
        });
      }

      return matches;
    } catch (e) {
      // API 오류 시 Firestore fallback
      return _getSchedulesByDateFromFirestore(date, favoriteTeamIds: favoriteTeamIds);
    }
  }

  // Firestore에서 경기 데이터 가져오기 (fallback)
  Future<List<Match>> _getSchedulesByDateFromFirestore(
    DateTime date, {
    List<String>? favoriteTeamIds,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _schedulesCollection
        .where('kickoff',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('kickoff', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('kickoff')
        .get();

    final matches =
        snapshot.docs.map((doc) => Match.fromFirestore(doc)).toList();

    if (favoriteTeamIds != null && favoriteTeamIds.isNotEmpty) {
      matches.sort((a, b) {
        final aFollowed = favoriteTeamIds.contains(a.homeTeamId) ||
            favoriteTeamIds.contains(a.awayTeamId);
        final bFollowed = favoriteTeamIds.contains(b.homeTeamId) ||
            favoriteTeamIds.contains(b.awayTeamId);

        if (aFollowed && !bFollowed) return -1;
        if (!aFollowed && bFollowed) return 1;
        return a.kickoff.compareTo(b.kickoff);
      });
    }

    return matches;
  }

  // ApiFootballFixture를 Match로 변환
  // API에서 timezone 파라미터로 이미 변환된 시간을 받으므로 date를 그대로 사용
  Match _convertFixtureToMatch(ApiFootballFixture fixture) {
    return Match(
      id: fixture.id.toString(),
      league: fixture.league.name,
      leagueId: fixture.league.id,
      leagueCountry: fixture.league.country,
      homeTeamId: fixture.homeTeam.id.toString(),
      homeTeamName: fixture.homeTeam.name,
      homeTeamLogo: fixture.homeTeam.logo,
      awayTeamId: fixture.awayTeam.id.toString(),
      awayTeamName: fixture.awayTeam.name,
      awayTeamLogo: fixture.awayTeam.logo,
      kickoff: fixture.date, // API timezone 파라미터로 변환된 시간
      stadium: fixture.venue?.name ?? '',
      homeScore: fixture.homeGoals,
      awayScore: fixture.awayGoals,
      status: _convertStatus(fixture),
      elapsed: fixture.status.elapsed, // 라이브 경기 경과 시간
      extra: fixture.status.extra, // 라이브 경기 추가 시간
      statusShort: fixture.status.short, // API 상태 코드 (1H, HT, 2H 등)
      penaltyHome: fixture.score.penaltyHome, // 승부차기 홈팀 점수
      penaltyAway: fixture.score.penaltyAway, // 승부차기 원정팀 점수
    );
  }

  // API 상태를 MatchStatus enum으로 변환
  MatchStatus _convertStatus(ApiFootballFixture fixture) {
    if (fixture.isFinished) return MatchStatus.finished;
    if (fixture.isLive) return MatchStatus.live;
    if (fixture.isScheduled) return MatchStatus.scheduled;

    switch (fixture.status.short.toUpperCase()) {
      case 'FT':
      case 'AET':
      case 'PEN':
        return MatchStatus.finished;
      case 'LIVE':
      case '1H':
      case '2H':
      case 'HT':
      case 'ET':
      case 'BT':
      case 'P':
        return MatchStatus.live;
      case 'PST':
      case 'POSTP':
        return MatchStatus.postponed;
      case 'CANC':
      case 'ABD':
        return MatchStatus.cancelled;
      default:
        return MatchStatus.scheduled;
    }
  }

  // Get upcoming matches for favorite teams (API-Football 사용)
  Future<List<Match>> getUpcomingMatchesForTeams(
    List<String> teamIds, {
    int limit = 10,
  }) async {
    if (teamIds.isEmpty) return [];

    final matches = <Match>[];

    for (final teamId in teamIds) {
      try {
        final apiTeamId = int.tryParse(teamId);
        if (apiTeamId == null) continue;

        final fixtures = await _apiService.getTeamNextFixtures(apiTeamId, count: 3);
        matches.addAll(fixtures.map((f) => _convertFixtureToMatch(f)));
      } catch (e) {
        // 개별 팀 조회 실패 시 continue
        continue;
      }
    }

    // Remove duplicates and sort
    final seen = <String>{};
    final uniqueMatches =
        matches.where((match) => seen.add(match.id)).toList();
    uniqueMatches.sort((a, b) => a.kickoff.compareTo(b.kickoff));

    return uniqueMatches.take(limit).toList();
  }

  // Get match by ID (API-Football 사용)
  Future<Match?> getMatch(String matchId) async {
    try {
      final fixtureId = int.tryParse(matchId);
      if (fixtureId == null) {
        // Firestore fallback
        final doc = await _schedulesCollection.doc(matchId).get();
        if (!doc.exists) return null;
        return Match.fromFirestore(doc);
      }

      final fixture = await _apiService.getFixtureById(fixtureId);
      if (fixture == null) return null;
      return _convertFixtureToMatch(fixture);
    } catch (e) {
      // Firestore fallback
      final doc = await _schedulesCollection.doc(matchId).get();
      if (!doc.exists) return null;
      return Match.fromFirestore(doc);
    }
  }

  // Get matches by league (API-Football 사용)
  Future<List<Match>> getMatchesByLeague(
    String league, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final leagueId = ApiFootballIds.getLeagueId(league);
      if (leagueId == null) {
        // Firestore fallback
        return _getMatchesByLeagueFromFirestore(league, startDate: startDate, endDate: endDate);
      }

      final currentYear = DateTime.now().year;
      // 현재 연도와 이전 연도 둘 다 시도 - 데이터가 있는 시즌 사용
      List<ApiFootballFixture> fixtures = [];
      for (final season in [currentYear, currentYear - 1]) {
        fixtures = await _apiService.getFixturesByLeague(leagueId, season);
        if (fixtures.isNotEmpty) break;
      }

      var matches = fixtures.map((f) => _convertFixtureToMatch(f)).toList();

      // 날짜 필터링
      if (startDate != null) {
        matches = matches.where((m) => m.kickoff.isAfter(startDate) || m.kickoff.isAtSameMomentAs(startDate)).toList();
      }
      if (endDate != null) {
        matches = matches.where((m) => m.kickoff.isBefore(endDate) || m.kickoff.isAtSameMomentAs(endDate)).toList();
      }

      matches.sort((a, b) => a.kickoff.compareTo(b.kickoff));
      return matches;
    } catch (e) {
      return _getMatchesByLeagueFromFirestore(league, startDate: startDate, endDate: endDate);
    }
  }

  // Firestore에서 리그별 경기 가져오기 (fallback)
  Future<List<Match>> _getMatchesByLeagueFromFirestore(
    String league, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query<Map<String, dynamic>> query =
        _schedulesCollection.where('league', isEqualTo: league);

    if (startDate != null) {
      query = query.where('kickoff',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query =
          query.where('kickoff', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    final snapshot = await query.orderBy('kickoff').get();
    return snapshot.docs.map((doc) => Match.fromFirestore(doc)).toList();
  }

  // === Notification Settings ===

  // Get notification setting for a match
  Future<NotificationSetting?> getNotificationSetting(
    String userId,
    String matchId,
  ) async {
    final snapshot = await _notificationCollection
        .where('userId', isEqualTo: userId)
        .where('matchId', isEqualTo: matchId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return NotificationSetting.fromFirestore(snapshot.docs.first);
  }

  // Set notification for a match
  Future<void> setNotification({
    required String userId,
    required String matchId,
    bool notifyKickoff = true,
    bool notifyResult = true,
  }) async {
    final existing = await getNotificationSetting(userId, matchId);

    final setting = NotificationSetting(
      id: existing?.id ?? '',
      userId: userId,
      matchId: matchId,
      notifyKickoff: notifyKickoff,
      notifyResult: notifyResult,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    if (existing != null) {
      await _notificationCollection.doc(existing.id).update(setting.toFirestore());
    } else {
      await _notificationCollection.add(setting.toFirestore());
    }
  }

  // Toggle specific notification type
  Future<void> toggleNotification({
    required String userId,
    required String matchId,
    required String type, // 'kickoff', 'result'
    required bool value,
  }) async {
    final existing = await getNotificationSetting(userId, matchId);

    if (existing != null) {
      final updates = <String, dynamic>{};
      switch (type) {
        case 'kickoff':
          updates['notifyKickoff'] = value;
          break;
        case 'result':
          updates['notifyResult'] = value;
          break;
      }
      await _notificationCollection.doc(existing.id).update(updates);
    } else {
      // Create new setting with default values
      await setNotification(
        userId: userId,
        matchId: matchId,
        notifyKickoff: type == 'kickoff' ? value : true,
        notifyResult: type == 'result' ? value : true,
      );
    }
  }

  // Remove notification setting
  Future<void> removeNotification(String userId, String matchId) async {
    final existing = await getNotificationSetting(userId, matchId);
    if (existing != null) {
      await _notificationCollection.doc(existing.id).delete();
    }
  }

  // Get all notification settings for user
  Future<List<NotificationSetting>> getUserNotificationSettings(
      String userId) async {
    final snapshot = await _notificationCollection
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => NotificationSetting.fromFirestore(doc))
        .toList();
  }

  // Check if user has notification for match
  Future<bool> hasNotification(String userId, String matchId) async {
    final setting = await getNotificationSetting(userId, matchId);
    return setting != null && setting.hasAnyNotification;
  }
}
