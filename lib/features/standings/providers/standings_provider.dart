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
/// 현재 날짜를 기준으로 자동 계산
String getSeasonForLeague(String leagueName) {
  final now = DateTime.now();
  final year = now.year;
  final month = now.month;

  // K리그는 단일 연도 시즌 (3월~11월)
  if (leagueName == 'Korean K League 1') {
    // 1-2월은 이전 시즌, 3월부터 현재 연도 시즌
    if (month < 3) {
      return '${year - 1}';
    }
    return '$year';
  }

  // 유럽 리그 - 8월 시작, 다음해 5월 종료
  // 8월~12월: 현재연도-다음연도 시즌 (예: 2025-2026)
  // 1월~7월: 이전연도-현재연도 시즌 (예: 2024-2025)
  if (month >= 8) {
    return '$year-${year + 1}';
  }
  return '${year - 1}-$year';
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
