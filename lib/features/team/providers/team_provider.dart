import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_football_service.dart';
import '../../../core/constants/api_football_ids.dart';
import '../../profile/providers/timezone_provider.dart';

/// API-Football 서비스 Provider (재사용)
final _apiFootballServiceProvider = Provider<ApiFootballService>((ref) {
  return ApiFootballService();
});

/// 팀 정보 Provider
final teamInfoProvider = FutureProvider.family<ApiFootballTeam?, String>((ref, teamId) async {
  final service = ref.watch(_apiFootballServiceProvider);

  final apiTeamId = int.tryParse(teamId);
  if (apiTeamId == null) return null;

  return service.getTeamById(apiTeamId);
});

/// 팀의 다음 경기 목록 Provider
final teamNextEventsProvider = FutureProvider.family<List<ApiFootballFixture>, String>((ref, teamId) async {
  final service = ref.watch(_apiFootballServiceProvider);
  // 타임존 변경 시 자동 갱신
  ref.watch(timezoneProvider);

  final apiTeamId = int.tryParse(teamId);
  if (apiTeamId == null) return [];

  return service.getTeamNextFixtures(apiTeamId, count: 5);
});

/// 팀의 지난 경기 목록 Provider
final teamPastEventsProvider = FutureProvider.family<List<ApiFootballFixture>, String>((ref, teamId) async {
  final service = ref.watch(_apiFootballServiceProvider);
  // 타임존 변경 시 자동 갱신
  ref.watch(timezoneProvider);

  final apiTeamId = int.tryParse(teamId);
  if (apiTeamId == null) return [];

  return service.getTeamLastFixtures(apiTeamId, count: 5);
});

/// 팀의 선수 목록 Provider
final teamPlayersProvider = FutureProvider.family<List<ApiFootballSquadPlayer>, String>((ref, teamId) async {
  final service = ref.watch(_apiFootballServiceProvider);

  final apiTeamId = int.tryParse(teamId);
  if (apiTeamId == null) return [];

  return service.getTeamSquad(apiTeamId);
});

/// 팀의 전체 시즌 일정 Provider
final teamFullScheduleProvider = FutureProvider.family<List<ApiFootballFixture>, String>((ref, teamId) async {
  final service = ref.watch(_apiFootballServiceProvider);
  // 타임존 변경 시 자동 갱신
  ref.watch(timezoneProvider);

  final apiTeamId = int.tryParse(teamId);
  if (apiTeamId == null) return [];

  final now = DateTime.now();
  final currentYear = now.year;

  // 현재 연도, 이전 연도, 2년 전 모두 조회하여 현재 날짜 기준 과거+미래 경기가 있는 시즌 선택
  for (final season in [currentYear, currentYear - 1, currentYear - 2]) {
    final fixtures = await service.getTeamSeasonFixtures(apiTeamId, season);
    if (fixtures.isEmpty) continue;

    // 현재 날짜 기준으로 과거 경기와 미래 경기가 모두 있는지 확인
    final hasPast = fixtures.any((f) => f.date.isBefore(now));
    final hasFuture = fixtures.any((f) => f.date.isAfter(now));

    // 과거와 미래 경기가 모두 있으면 현재 진행 중인 시즌
    if (hasPast && hasFuture) {
      return fixtures;
    }
  }

  // 진행 중인 시즌을 못 찾으면 가장 많은 경기가 있는 시즌 반환
  List<ApiFootballFixture> bestFixtures = [];
  for (final season in [currentYear, currentYear - 1, currentYear - 2]) {
    final fixtures = await service.getTeamSeasonFixtures(apiTeamId, season);
    if (fixtures.length > bestFixtures.length) {
      bestFixtures = fixtures;
    }
  }
  return bestFixtures;
});

/// 팀 검색 Provider
final teamSearchProvider = FutureProvider.family<List<ApiFootballTeam>, String>((ref, query) async {
  if (query.isEmpty) return [];

  final service = ref.watch(_apiFootballServiceProvider);
  return service.searchTeams(query);
});

/// 상대전적 Provider
final headToHeadProvider = FutureProvider.family<List<ApiFootballFixture>, (int, int)>((ref, teams) async {
  final service = ref.watch(_apiFootballServiceProvider);
  // 타임존 변경 시 자동 갱신
  ref.watch(timezoneProvider);
  return service.getHeadToHead(teams.$1, teams.$2);
});

/// 팀 이적 기록 Provider
final teamTransfersProvider = FutureProvider.family<List<ApiFootballTeamTransfer>, String>((ref, teamId) async {
  final service = ref.watch(_apiFootballServiceProvider);

  final apiTeamId = int.tryParse(teamId);
  if (apiTeamId == null) return [];

  return service.getTeamTransfers(apiTeamId);
});

/// 팀 부상/결장 선수 Provider
final teamInjuriesProvider = FutureProvider.family<List<ApiFootballInjury>, String>((ref, teamId) async {
  final service = ref.watch(_apiFootballServiceProvider);

  final apiTeamId = int.tryParse(teamId);
  if (apiTeamId == null) return [];

  final currentYear = DateTime.now().year;
  // 현재 연도, 이전 연도, 2년 전 모두 조회하여 가장 많은 데이터가 있는 시즌 사용
  List<ApiFootballInjury> bestInjuries = [];

  for (final season in [currentYear, currentYear - 1, currentYear - 2]) {
    final injuries = await service.getTeamInjuries(apiTeamId, season);
    if (injuries.length > bestInjuries.length) {
      bestInjuries = injuries;
    }
  }
  return bestInjuries;
});

/// 팀 시즌 통계 Provider (리그별)
final teamStatisticsProvider = FutureProvider.family<List<ApiFootballTeamSeasonStats>, String>((ref, teamId) async {
  final service = ref.watch(_apiFootballServiceProvider);

  final apiTeamId = int.tryParse(teamId);
  if (apiTeamId == null) return [];

  final currentYear = DateTime.now().year;

  // 지원하는 주요 리그들에서 통계 조회 시도
  final leagueIds = [
    LeagueIds.kLeague1,
    LeagueIds.kLeague2,
    LeagueIds.premierLeague,
    LeagueIds.laLiga,
    LeagueIds.bundesliga,
    LeagueIds.serieA,
    LeagueIds.ligue1,
    LeagueIds.championsLeague,
    LeagueIds.europaLeague,
  ];

  final statsList = <ApiFootballTeamSeasonStats>[];

  // 현재 연도와 이전 연도 둘 다 시도 - 데이터가 있는 시즌 사용
  for (final season in [currentYear, currentYear - 1]) {
    for (final leagueId in leagueIds) {
      try {
        final stats = await service.getTeamStatistics(apiTeamId, leagueId, season);
        if (stats != null && stats.totalPlayed > 0) {
          statsList.add(stats);
        }
      } catch (e) {
        // 해당 리그에 참가하지 않으면 무시
      }
    }
    if (statsList.isNotEmpty) break; // 데이터 찾으면 중단
  }

  return statsList;
});

/// 팀이 참가하는 리그 목록 Provider
final teamLeaguesProvider = FutureProvider.family<List<ApiFootballTeamLeague>, String>((ref, teamId) async {
  final service = ref.watch(_apiFootballServiceProvider);

  final apiTeamId = int.tryParse(teamId);
  if (apiTeamId == null) return [];

  final now = DateTime.now();
  final currentYear = now.year;

  // 축구 시즌은 보통 8월에 시작하므로, 8월 이전이면 이전 연도가 현재 시즌
  // 예: 2025년 1월 = 2024-25 시즌 = season 파라미터 2024
  // 예: 2025년 9월 = 2025-26 시즌 = season 파라미터 2025
  final seasonYear = now.month < 8 ? currentYear - 1 : currentYear;

  // 현재 시즌, 이전 시즌 순서로 시도
  for (final season in [seasonYear, seasonYear - 1]) {
    final leagues = await service.getTeamLeagues(apiTeamId, season: season);
    // Friendlies만 있는 경우 건너뛰기
    final realLeagues = leagues.where((l) =>
      l.type == 'League' || l.type == 'Cup' && !l.name.toLowerCase().contains('friendl')
    ).toList();
    if (realLeagues.isNotEmpty) return realLeagues;
  }

  // 실제 대회를 못 찾으면 전체 반환
  for (final season in [seasonYear, seasonYear - 1]) {
    final leagues = await service.getTeamLeagues(apiTeamId, season: season);
    if (leagues.isNotEmpty) return leagues;
  }
  return [];
});
