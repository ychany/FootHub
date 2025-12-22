import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_football_service.dart';
import '../../../core/constants/api_football_ids.dart';

/// API-Football 서비스 Provider
final _apiFootballServiceProvider = Provider<ApiFootballService>((ref) {
  return ApiFootballService();
});

/// 선택된 리그 상태 (API-Football 리그 ID)
final selectedStandingsLeagueProvider = StateProvider<int>((ref) {
  return LeagueIds.premierLeague; // 기본값: EPL
});

/// 선택된 시즌 상태 (null이면 현재 시즌)
final selectedSeasonProvider = StateProvider<int?>((ref) => null);

/// 리그별 현재 시즌 계산
int getCurrentSeasonForLeague(int leagueId) {
  final now = DateTime.now();
  final year = now.year;
  final month = now.month;

  // K리그는 단일 연도 시즌 (3월~11월)
  if (leagueId == LeagueIds.kLeague1 || leagueId == LeagueIds.kLeague2) {
    // 1-2월은 이전 시즌, 3월부터 현재 연도 시즌
    if (month < 3) {
      return year - 1;
    }
    return year;
  }

  // 유럽 리그 - 8월 시작, 다음해 5월 종료
  // 8월~12월: 현재연도 시즌 (예: 2024 = 2024-2025)
  // 1월~7월: 이전연도 시즌 (예: 2024 = 2023-2024)
  if (month >= 8) {
    return year;
  }
  return year - 1;
}

/// 순위표 미지원 대회 확인
bool isUnsupportedLeague(int leagueId) {
  // 순위표가 없는 대회
  return leagueId == LeagueIds.friendlies;
}

/// UCL/UEL 등 컵 대회 여부 확인
bool isCupCompetition(int leagueId) {
  return leagueId == LeagueIds.championsLeague ||
         leagueId == LeagueIds.europaLeague ||
         leagueId == LeagueIds.conferenceLeague;
}

/// 리그별 선택 가능한 시즌 목록 생성
List<int> getAvailableSeasons(int leagueId) {
  final now = DateTime.now();
  final year = now.year;
  final month = now.month;
  final seasons = <int>[];

  if (leagueId == LeagueIds.kLeague1 || leagueId == LeagueIds.kLeague2) {
    // K리그: 단일 연도 시즌, 최근 5년
    final currentSeason = month < 3 ? year - 1 : year;
    for (int i = 0; i < 5; i++) {
      seasons.add(currentSeason - i);
    }
  } else {
    // 유럽 리그: 시즌 시작 연도 기준, 최근 5시즌
    final currentSeasonStart = month >= 8 ? year : year - 1;
    for (int i = 0; i < 5; i++) {
      seasons.add(currentSeasonStart - i);
    }
  }

  return seasons;
}

/// 시즌 표시명 (예: 2024 -> 24/25 또는 2024)
String getSeasonDisplayName(int season, int leagueId) {
  if (leagueId == LeagueIds.kLeague1 || leagueId == LeagueIds.kLeague2) {
    return season.toString();
  }
  // 유럽 리그: YYYY-YYYY 형식으로 표시
  return "${season.toString().substring(2)}/${(season + 1).toString().substring(2)}";
}

/// 리그+시즌 조합 키
class StandingsKey {
  final int leagueId;
  final int season;

  StandingsKey(this.leagueId, this.season);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StandingsKey &&
          leagueId == other.leagueId &&
          season == other.season;

  @override
  int get hashCode => leagueId.hashCode ^ season.hashCode;
}

/// 리그 순위 Provider (리그+시즌 조합)
final leagueStandingsProvider = FutureProvider.family<List<ApiFootballStanding>, StandingsKey>((ref, key) async {
  final service = ref.watch(_apiFootballServiceProvider);
  return service.getStandings(key.leagueId, key.season);
});

/// 리그 순위 Provider - 그룹별 (조별 리그용)
final leagueStandingsGroupedProvider = FutureProvider.family<Map<String, List<ApiFootballStanding>>, StandingsKey>((ref, key) async {
  final service = ref.watch(_apiFootballServiceProvider);
  return service.getStandingsGrouped(key.leagueId, key.season);
});

/// 조별 리그 여부 확인 Provider
final isGroupStageProvider = FutureProvider.family<bool, StandingsKey>((ref, key) async {
  final service = ref.watch(_apiFootballServiceProvider);
  return service.isGroupStageLeague(key.leagueId, key.season);
});

/// 선택된 리그+시즌의 순위
final selectedLeagueStandingsProvider = FutureProvider<List<ApiFootballStanding>>((ref) async {
  final selectedLeague = ref.watch(selectedStandingsLeagueProvider);
  final selectedSeason = ref.watch(selectedSeasonProvider);
  final season = selectedSeason ?? getCurrentSeasonForLeague(selectedLeague);
  final key = StandingsKey(selectedLeague, season);
  return ref.watch(leagueStandingsProvider(key).future);
});

/// 지원되는 리그 목록 (순위표가 있는 리그만)
final supportedLeaguesForStandingsProvider = Provider<List<LeagueInfo>>((ref) {
  return LeagueIds.supportedLeagues;
});

/// 리그 이름으로 ID 가져오기
int? getLeagueIdByName(String leagueName) {
  return ApiFootballIds.getLeagueId(leagueName);
}

/// 선택된 탭 상태 (0: 순위, 1: 득점, 2: 어시스트)
final selectedStandingsTabProvider = StateProvider<int>((ref) => 0);

/// 득점왕 순위 Provider
final topScorersProvider = FutureProvider.family<List<ApiFootballTopScorer>, StandingsKey>((ref, key) async {
  final service = ref.watch(_apiFootballServiceProvider);
  return service.getTopScorers(key.leagueId, key.season);
});

/// 어시스트왕 순위 Provider
final topAssistsProvider = FutureProvider.family<List<ApiFootballTopScorer>, StandingsKey>((ref, key) async {
  final service = ref.watch(_apiFootballServiceProvider);
  return service.getTopAssists(key.leagueId, key.season);
});

/// 최다 경고 선수 Provider
final topYellowCardsProvider = FutureProvider.family<List<ApiFootballTopScorer>, StandingsKey>((ref, key) async {
  final service = ref.watch(_apiFootballServiceProvider);
  return service.getTopYellowCards(key.leagueId, key.season);
});

/// 최다 퇴장 선수 Provider
final topRedCardsProvider = FutureProvider.family<List<ApiFootballTopScorer>, StandingsKey>((ref, key) async {
  final service = ref.watch(_apiFootballServiceProvider);
  return service.getTopRedCards(key.leagueId, key.season);
});
