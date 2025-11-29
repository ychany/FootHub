import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/sports_db_service.dart';

/// 팀 정보 Provider
final teamInfoProvider = FutureProvider.family<SportsDbTeam?, String>((ref, teamId) async {
  final service = SportsDbService();
  return service.getTeamById(teamId);
});

/// 팀의 다음 경기 목록 Provider
final teamNextEventsProvider = FutureProvider.family<List<SportsDbEvent>, String>((ref, teamId) async {
  final service = SportsDbService();
  return service.getNextTeamEvents(teamId);
});

/// 팀의 지난 경기 목록 Provider
final teamPastEventsProvider = FutureProvider.family<List<SportsDbEvent>, String>((ref, teamId) async {
  final service = SportsDbService();
  return service.getPastTeamEvents(teamId);
});

/// 팀의 선수 목록 Provider
final teamPlayersProvider = FutureProvider.family<List<SportsDbPlayer>, String>((ref, teamId) async {
  final service = SportsDbService();
  return service.getPlayersByTeam(teamId);
});
