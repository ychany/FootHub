import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/sports_db_service.dart';
import '../../../core/constants/app_constants.dart';

/// 선택된 리그 상태
final selectedStandingsLeagueProvider = StateProvider<String>((ref) {
  return AppConstants.supportedLeagues.first;
});

/// 리그 ID 매핑 (리그 이름 -> 리그 ID)
/// TheSportsDB에서 확인된 정확한 ID
final leagueIdMapping = <String, String>{
  'English Premier League': '4328',
  'Spanish La Liga': '4335',
  'Italian Serie A': '4332',
  'German Bundesliga': '4331',
  'French Ligue 1': '4334',
  'Korean K League 1': '7034', // K리그1
  'UEFA Champions League': '4480',
  'UEFA Europa League': '4481',
};

/// 리그별 시즌 포맷 (K리그 등 일부 리그는 단일 연도 시즌)
String getSeasonForLeague(String leagueName) {
  // K리그는 단일 연도 시즌 (3월~11월)
  // 2025 시즌은 3월 시작 예정이므로 아직 2024 데이터 사용
  if (leagueName == 'Korean K League 1') {
    return '2024'; // 가장 최근 완료된 시즌
  }

  // 유럽 리그 - 현재 2024-2025 시즌 진행 중
  return '2024-2025';
}

/// 순위표 미지원 대회 확인
bool isUnsupportedLeague(String leagueName) {
  // TheSportsDB API에서 순위표를 제공하지 않는 대회
  return leagueName == 'UEFA Champions League' ||
         leagueName == 'UEFA Europa League';
}

/// UCL/UEL 등 컵 대회 여부 확인
bool isCupCompetition(String leagueName) {
  return leagueName == 'UEFA Champions League' ||
         leagueName == 'UEFA Europa League';
}

/// 리그 순위 Provider
final leagueStandingsProvider = FutureProvider.family<List<SportsDbStanding>, String>((ref, leagueName) async {
  final service = SportsDbService();

  // 리그 ID 가져오기
  String? leagueId = leagueIdMapping[leagueName];

  // 매핑에 없으면 API로 조회
  leagueId ??= await service.getLeagueId(leagueName);

  if (leagueId == null) {
    return [];
  }

  final season = getSeasonForLeague(leagueName);
  return service.getLeagueStandings(leagueId, season: season);
});

/// 선택된 리그의 순위
final selectedLeagueStandingsProvider = FutureProvider<List<SportsDbStanding>>((ref) async {
  final selectedLeague = ref.watch(selectedStandingsLeagueProvider);
  return ref.watch(leagueStandingsProvider(selectedLeague).future);
});
