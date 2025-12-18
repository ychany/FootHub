import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_football_service.dart';
import '../../../core/constants/api_football_ids.dart';

/// API-Football 서비스 Provider (재사용)
final _apiFootballServiceProvider = Provider<ApiFootballService>((ref) {
  return ApiFootballService();
});

/// 팀 정보 Provider
final teamInfoProvider = FutureProvider.family<ApiFootballTeam?, String>((ref, teamId) async {
  final service = ref.watch(_apiFootballServiceProvider);

  // API-Football ID로 변환 시도
  final apiTeamId = ApiFootballIds.convertTeamId(teamId) ?? int.tryParse(teamId);
  if (apiTeamId == null) return null;

  return service.getTeamById(apiTeamId);
});

/// 팀의 다음 경기 목록 Provider
final teamNextEventsProvider = FutureProvider.family<List<ApiFootballFixture>, String>((ref, teamId) async {
  final service = ref.watch(_apiFootballServiceProvider);

  // API-Football ID로 변환 시도
  final apiTeamId = ApiFootballIds.convertTeamId(teamId) ?? int.tryParse(teamId);
  if (apiTeamId == null) return [];

  return service.getTeamNextFixtures(apiTeamId, count: 5);
});

/// 팀의 지난 경기 목록 Provider
final teamPastEventsProvider = FutureProvider.family<List<ApiFootballFixture>, String>((ref, teamId) async {
  final service = ref.watch(_apiFootballServiceProvider);

  // API-Football ID로 변환 시도
  final apiTeamId = ApiFootballIds.convertTeamId(teamId) ?? int.tryParse(teamId);
  if (apiTeamId == null) return [];

  return service.getTeamLastFixtures(apiTeamId, count: 5);
});

/// 팀의 선수 목록 Provider
final teamPlayersProvider = FutureProvider.family<List<ApiFootballSquadPlayer>, String>((ref, teamId) async {
  final service = ref.watch(_apiFootballServiceProvider);

  // API-Football ID로 변환 시도
  final apiTeamId = ApiFootballIds.convertTeamId(teamId) ?? int.tryParse(teamId);
  if (apiTeamId == null) return [];

  return service.getTeamSquad(apiTeamId);
});

/// 팀의 전체 시즌 일정 Provider
final teamFullScheduleProvider = FutureProvider.family<List<ApiFootballFixture>, String>((ref, teamId) async {
  final service = ref.watch(_apiFootballServiceProvider);

  // API-Football ID로 변환 시도
  final apiTeamId = ApiFootballIds.convertTeamId(teamId) ?? int.tryParse(teamId);
  if (apiTeamId == null) return [];

  final season = LeagueIds.getCurrentSeason();
  return service.getTeamSeasonFixtures(apiTeamId, season);
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
  return service.getHeadToHead(teams.$1, teams.$2);
});
