import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_football_service.dart';
import '../../profile/providers/timezone_provider.dart';

/// 선택된 국가대표팀 정보
class SelectedNationalTeam {
  final int teamId;
  final String teamName;
  final String? teamLogo;
  final String? countryCode;
  final String? countryFlag;

  const SelectedNationalTeam({
    required this.teamId,
    required this.teamName,
    this.teamLogo,
    this.countryCode,
    this.countryFlag,
  });

  Map<String, dynamic> toJson() => {
    'teamId': teamId,
    'teamName': teamName,
    'teamLogo': teamLogo,
    'countryCode': countryCode,
    'countryFlag': countryFlag,
  };

  factory SelectedNationalTeam.fromJson(Map<String, dynamic> json) {
    return SelectedNationalTeam(
      teamId: json['teamId'] as int,
      teamName: json['teamName'] as String,
      teamLogo: json['teamLogo'] as String?,
      countryCode: json['countryCode'] as String?,
      countryFlag: json['countryFlag'] as String?,
    );
  }
}

/// 선택된 국가대표팀 Provider (SharedPreferences 저장, null = 미선택)
class SelectedNationalTeamNotifier extends StateNotifier<SelectedNationalTeam?> {
  SelectedNationalTeamNotifier() : super(null) {
    _loadSavedTeam();
  }

  static const _prefKey = 'selected_national_team';

  Future<void> _loadSavedTeam() async {
    final prefs = await SharedPreferences.getInstance();
    final teamId = prefs.getInt('${_prefKey}_id');
    final teamName = prefs.getString('${_prefKey}_name');
    final teamLogo = prefs.getString('${_prefKey}_logo');
    final countryCode = prefs.getString('${_prefKey}_code');
    final countryFlag = prefs.getString('${_prefKey}_flag');

    if (teamId != null && teamName != null) {
      state = SelectedNationalTeam(
        teamId: teamId,
        teamName: teamName,
        teamLogo: teamLogo,
        countryCode: countryCode,
        countryFlag: countryFlag,
      );
    }
  }

  Future<void> selectTeam(SelectedNationalTeam team) async {
    state = team;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_prefKey}_id', team.teamId);
    await prefs.setString('${_prefKey}_name', team.teamName);

    // 기존 값 정리 후 새 값 저장
    if (team.teamLogo != null) {
      await prefs.setString('${_prefKey}_logo', team.teamLogo!);
    } else {
      await prefs.remove('${_prefKey}_logo');
    }
    if (team.countryCode != null) {
      await prefs.setString('${_prefKey}_code', team.countryCode!);
    } else {
      await prefs.remove('${_prefKey}_code');
    }
    if (team.countryFlag != null) {
      await prefs.setString('${_prefKey}_flag', team.countryFlag!);
    } else {
      await prefs.remove('${_prefKey}_flag');
    }
  }

  /// 선택 초기화 (팀 선택 해제)
  Future<void> clearSelection() async {
    state = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_prefKey}_id');
    await prefs.remove('${_prefKey}_name');
    await prefs.remove('${_prefKey}_logo');
    await prefs.remove('${_prefKey}_code');
    await prefs.remove('${_prefKey}_flag');
  }
}

final selectedNationalTeamProvider = StateNotifierProvider<SelectedNationalTeamNotifier, SelectedNationalTeam?>((ref) {
  return SelectedNationalTeamNotifier();
});

/// 2026 FIFA 월드컵 본선 진출국 정보 (하드코딩)
class WorldCup2026Team {
  final int teamId;
  final String nameKo;
  final String nameEn;
  final String countryCode; // ISO 3166-1 alpha-2 국가 코드
  final String confederation; // AFC, UEFA, CONMEBOL, CONCACAF, CAF, OFC
  final int fifaRanking;
  final String? bestResult; // 최고 성적

  const WorldCup2026Team({
    required this.teamId,
    required this.nameKo,
    required this.nameEn,
    required this.countryCode,
    required this.confederation,
    required this.fifaRanking,
    this.bestResult,
  });

  /// 국기 이미지 URL (flagcdn.com 사용)
  String get flagUrl {
    // 영국 하위 지역 처리 (스코틀랜드, 잉글랜드, 웨일스 등)
    final code = countryCode.toLowerCase();
    if (code == 'gb-eng') return 'https://flagcdn.com/w80/gb-eng.png';
    if (code == 'gb-sct') return 'https://flagcdn.com/w80/gb-sct.png';
    if (code == 'gb-wls') return 'https://flagcdn.com/w80/gb-wls.png';
    return 'https://flagcdn.com/w80/$code.png';
  }
}

/// 2026 FIFA 월드컵 본선 진출국 목록
const List<WorldCup2026Team> worldCup2026Teams = [
  // 북중미카리브 (CONCACAF) - 개최국 3팀 + 예선 3팀 = 6팀
  WorldCup2026Team(teamId: 5529, nameKo: '캐나다', nameEn: 'Canada', countryCode: 'CA', confederation: 'CONCACAF', fifaRanking: 27, bestResult: '조별리그'),
  WorldCup2026Team(teamId: 16, nameKo: '멕시코', nameEn: 'Mexico', countryCode: 'MX', confederation: 'CONCACAF', fifaRanking: 15, bestResult: '8강'),
  WorldCup2026Team(teamId: 2384, nameKo: '미국', nameEn: 'USA', countryCode: 'US', confederation: 'CONCACAF', fifaRanking: 14, bestResult: '3위'),
  WorldCup2026Team(teamId: 1530, nameKo: '파나마', nameEn: 'Panama', countryCode: 'PA', confederation: 'CONCACAF', fifaRanking: 30, bestResult: '조별리그'),
  WorldCup2026Team(teamId: 5564, nameKo: '퀴라소', nameEn: 'Curaçao', countryCode: 'CW', confederation: 'CONCACAF', fifaRanking: 82, bestResult: null),
  WorldCup2026Team(teamId: 5555, nameKo: '아이티', nameEn: 'Haiti', countryCode: 'HT', confederation: 'CONCACAF', fifaRanking: 84, bestResult: '조별리그'),

  // 아시아 (AFC) - 8팀
  WorldCup2026Team(teamId: 22, nameKo: '이란', nameEn: 'Iran', countryCode: 'IR', confederation: 'AFC', fifaRanking: 20, bestResult: '조별리그'),
  WorldCup2026Team(teamId: 2387, nameKo: '우즈베키스탄', nameEn: 'Uzbekistan', countryCode: 'UZ', confederation: 'AFC', fifaRanking: 50, bestResult: null),
  WorldCup2026Team(teamId: 17, nameKo: '대한민국', nameEn: 'South Korea', countryCode: 'KR', confederation: 'AFC', fifaRanking: 22, bestResult: '4위'),
  WorldCup2026Team(teamId: 2379, nameKo: '요르단', nameEn: 'Jordan', countryCode: 'JO', confederation: 'AFC', fifaRanking: 66, bestResult: null),
  WorldCup2026Team(teamId: 12, nameKo: '일본', nameEn: 'Japan', countryCode: 'JP', confederation: 'AFC', fifaRanking: 18, bestResult: '16강'),
  WorldCup2026Team(teamId: 20, nameKo: '호주', nameEn: 'Australia', countryCode: 'AU', confederation: 'AFC', fifaRanking: 26, bestResult: '16강'),
  WorldCup2026Team(teamId: 1570, nameKo: '카타르', nameEn: 'Qatar', countryCode: 'QA', confederation: 'AFC', fifaRanking: 51, bestResult: '조별리그'),
  WorldCup2026Team(teamId: 23, nameKo: '사우디아라비아', nameEn: 'Saudi Arabia', countryCode: 'SA', confederation: 'AFC', fifaRanking: 60, bestResult: '16강'),

  // 아프리카 (CAF) - 9팀
  WorldCup2026Team(teamId: 2382, nameKo: '이집트', nameEn: 'Egypt', countryCode: 'EG', confederation: 'CAF', fifaRanking: 34, bestResult: '16강'),
  WorldCup2026Team(teamId: 28, nameKo: '세네갈', nameEn: 'Senegal', countryCode: 'SN', confederation: 'CAF', fifaRanking: 19, bestResult: '8강'),
  WorldCup2026Team(teamId: 15, nameKo: '남아프리카공화국', nameEn: 'South Africa', countryCode: 'ZA', confederation: 'CAF', fifaRanking: 61, bestResult: '조별리그'),
  WorldCup2026Team(teamId: 5563, nameKo: '카보베르데', nameEn: 'Cape Verde', countryCode: 'CV', confederation: 'CAF', fifaRanking: 68, bestResult: null),
  WorldCup2026Team(teamId: 31, nameKo: '모로코', nameEn: 'Morocco', countryCode: 'MA', confederation: 'CAF', fifaRanking: 11, bestResult: '4위'),
  WorldCup2026Team(teamId: 5765, nameKo: '코트디부아르', nameEn: 'Ivory Coast', countryCode: 'CI', confederation: 'CAF', fifaRanking: 42, bestResult: '조별리그'),
  WorldCup2026Team(teamId: 1536, nameKo: '알제리', nameEn: 'Algeria', countryCode: 'DZ', confederation: 'CAF', fifaRanking: 35, bestResult: '16강'),
  WorldCup2026Team(teamId: 27, nameKo: '튀니지', nameEn: 'Tunisia', countryCode: 'TN', confederation: 'CAF', fifaRanking: 40, bestResult: '조별리그'),
  WorldCup2026Team(teamId: 1534, nameKo: '가나', nameEn: 'Ghana', countryCode: 'GH', confederation: 'CAF', fifaRanking: 72, bestResult: '8강'),

  // 남미 (CONMEBOL) - 6팀
  WorldCup2026Team(teamId: 26, nameKo: '아르헨티나', nameEn: 'Argentina', countryCode: 'AR', confederation: 'CONMEBOL', fifaRanking: 2, bestResult: '우승'),
  WorldCup2026Team(teamId: 2382, nameKo: '에콰도르', nameEn: 'Ecuador', countryCode: 'EC', confederation: 'CONMEBOL', fifaRanking: 23, bestResult: '16강'),
  WorldCup2026Team(teamId: 1521, nameKo: '콜롬비아', nameEn: 'Colombia', countryCode: 'CO', confederation: 'CONMEBOL', fifaRanking: 13, bestResult: '8강'),
  WorldCup2026Team(teamId: 7, nameKo: '우루과이', nameEn: 'Uruguay', countryCode: 'UY', confederation: 'CONMEBOL', fifaRanking: 16, bestResult: '우승'),
  WorldCup2026Team(teamId: 6, nameKo: '브라질', nameEn: 'Brazil', countryCode: 'BR', confederation: 'CONMEBOL', fifaRanking: 5, bestResult: '우승'),
  WorldCup2026Team(teamId: 1528, nameKo: '파라과이', nameEn: 'Paraguay', countryCode: 'PY', confederation: 'CONMEBOL', fifaRanking: 39, bestResult: '8강'),

  // 오세아니아 (OFC) - 1팀
  WorldCup2026Team(teamId: 1524, nameKo: '뉴질랜드', nameEn: 'New Zealand', countryCode: 'NZ', confederation: 'OFC', fifaRanking: 86, bestResult: '조별리그'),

  // 유럽 (UEFA) - 12팀
  WorldCup2026Team(teamId: 25, nameKo: '독일', nameEn: 'Germany', countryCode: 'DE', confederation: 'UEFA', fifaRanking: 9, bestResult: '우승'),
  WorldCup2026Team(teamId: 15, nameKo: '스위스', nameEn: 'Switzerland', countryCode: 'CH', confederation: 'UEFA', fifaRanking: 17, bestResult: '8강'),
  WorldCup2026Team(teamId: 1108, nameKo: '스코틀랜드', nameEn: 'Scotland', countryCode: 'GB-SCT', confederation: 'UEFA', fifaRanking: 36, bestResult: '조별리그'),
  WorldCup2026Team(teamId: 2, nameKo: '프랑스', nameEn: 'France', countryCode: 'FR', confederation: 'UEFA', fifaRanking: 3, bestResult: '우승'),
  WorldCup2026Team(teamId: 9, nameKo: '스페인', nameEn: 'Spain', countryCode: 'ES', confederation: 'UEFA', fifaRanking: 1, bestResult: '우승'),
  WorldCup2026Team(teamId: 27, nameKo: '포르투갈', nameEn: 'Portugal', countryCode: 'PT', confederation: 'UEFA', fifaRanking: 6, bestResult: '3위'),
  WorldCup2026Team(teamId: 1118, nameKo: '네덜란드', nameEn: 'Netherlands', countryCode: 'NL', confederation: 'UEFA', fifaRanking: 7, bestResult: '준우승'),
  WorldCup2026Team(teamId: 775, nameKo: '오스트리아', nameEn: 'Austria', countryCode: 'AT', confederation: 'UEFA', fifaRanking: 24, bestResult: '3위'),
  WorldCup2026Team(teamId: 1107, nameKo: '노르웨이', nameEn: 'Norway', countryCode: 'NO', confederation: 'UEFA', fifaRanking: 29, bestResult: '16강'),
  WorldCup2026Team(teamId: 1, nameKo: '벨기에', nameEn: 'Belgium', countryCode: 'BE', confederation: 'UEFA', fifaRanking: 8, bestResult: '3위'),
  WorldCup2026Team(teamId: 10, nameKo: '잉글랜드', nameEn: 'England', countryCode: 'GB-ENG', confederation: 'UEFA', fifaRanking: 4, bestResult: '우승'),
  WorldCup2026Team(teamId: 3, nameKo: '크로아티아', nameEn: 'Croatia', countryCode: 'HR', confederation: 'UEFA', fifaRanking: 10, bestResult: '준우승'),
];

/// 대륙별 정렬 순서
const Map<String, int> confederationOrder = {
  'AFC': 0,      // 아시아
  'UEFA': 1,     // 유럽
  'CONMEBOL': 2, // 남미
  'CAF': 3,      // 아프리카
  'CONCACAF': 4, // 북중미카리브
  'OFC': 5,      // 오세아니아
};

/// 국가대표팀 목록 Provider (하드코딩된 2026 월드컵 참가국)
final worldCupTeamsProvider = Provider<List<WorldCup2026Team>>((ref) {
  // 대륙별 → FIFA 랭킹순 정렬
  final sorted = List<WorldCup2026Team>.from(worldCup2026Teams);
  sorted.sort((a, b) {
    final confCompare = (confederationOrder[a.confederation] ?? 99)
        .compareTo(confederationOrder[b.confederation] ?? 99);
    if (confCompare != 0) return confCompare;
    return a.fifaRanking.compareTo(b.fifaRanking);
  });
  return sorted;
});

/// 선택된 국가대표팀의 다음 경기 Provider
final selectedTeamNextMatchesProvider = FutureProvider<List<ApiFootballFixture>>((ref) async {
  final team = ref.watch(selectedNationalTeamProvider);
  if (team == null) return [];

  final service = ApiFootballService();
  ref.watch(timezoneProvider);

  return service.getTeamNextFixtures(team.teamId, count: 10);
});

/// 선택된 국가대표팀의 지난 경기 Provider
final selectedTeamPastMatchesProvider = FutureProvider<List<ApiFootballFixture>>((ref) async {
  final team = ref.watch(selectedNationalTeamProvider);
  if (team == null) return [];

  final service = ApiFootballService();
  ref.watch(timezoneProvider);

  return service.getTeamLastFixtures(team.teamId, count: 10);
});

/// 선택된 국가대표팀의 전체 일정 Provider
final selectedTeamAllMatchesProvider = FutureProvider<List<ApiFootballFixture>>((ref) async {
  final nextMatches = await ref.watch(selectedTeamNextMatchesProvider.future);
  final pastMatches = await ref.watch(selectedTeamPastMatchesProvider.future);

  final allEvents = <int, ApiFootballFixture>{};
  for (final event in [...pastMatches, ...nextMatches]) {
    allEvents[event.id] = event;
  }

  final sorted = allEvents.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  return sorted;
});

/// 선택된 국가대표팀의 최근 폼 Provider
final selectedTeamFormProvider = FutureProvider<TeamForm?>((ref) async {
  final team = ref.watch(selectedNationalTeamProvider);
  if (team == null) return null;

  final pastMatches = await ref.watch(selectedTeamPastMatchesProvider.future);

  final recent = pastMatches.take(5).toList();
  final results = <String>[];
  int wins = 0, draws = 0, losses = 0;

  for (final match in recent) {
    final homeScore = match.homeGoals ?? 0;
    final awayScore = match.awayGoals ?? 0;
    final isHome = match.homeTeam.id == team.teamId;
    final teamScore = isHome ? homeScore : awayScore;
    final opponentScore = isHome ? awayScore : homeScore;

    if (teamScore > opponentScore) {
      results.add('W');
      wins++;
    } else if (teamScore < opponentScore) {
      results.add('L');
      losses++;
    } else {
      results.add('D');
      draws++;
    }
  }

  return TeamForm(results: results, wins: wins, draws: draws, losses: losses);
});

/// 선택된 국가대표팀의 선수단 Provider
final selectedTeamSquadProvider = FutureProvider<List<ApiFootballSquadPlayer>>((ref) async {
  final team = ref.watch(selectedNationalTeamProvider);
  if (team == null) return [];

  final service = ApiFootballService();
  return service.getTeamSquad(team.teamId);
});

/// 선택된 국가대표팀의 상세 정보 Provider
final selectedTeamInfoProvider = FutureProvider<ApiFootballTeam?>((ref) async {
  final team = ref.watch(selectedNationalTeamProvider);
  if (team == null) return null;

  final service = ApiFootballService();
  return service.getTeamById(team.teamId);
});

/// 선택된 국가대표팀이 참가하는 대회 목록 Provider (동적)
final selectedTeamCompetitionsProvider = FutureProvider<List<ApiFootballTeamLeague>>((ref) async {
  final team = ref.watch(selectedNationalTeamProvider);
  if (team == null) return [];

  final service = ApiFootballService();
  final currentYear = DateTime.now().year;

  // 최근 3년치 시즌 조회 (국제 대회는 2~4년 주기이므로)
  final allLeagues = <int, ApiFootballTeamLeague>{};

  for (int year = currentYear; year >= currentYear - 2; year--) {
    final leagues = await service.getTeamLeagues(team.teamId, season: year);
    for (final league in leagues) {
      // 중복 제거 (리그 ID 기준, 최신 시즌 우선)
      if (!allLeagues.containsKey(league.id)) {
        allLeagues[league.id] = league;
      }
    }
  }

  // friendlies만 제외하고 모든 대회 표시 (국가대표팀은 클럽 리그에 참가하지 않음)
  final nationalCompetitions = allLeagues.values.where((league) {
    final name = league.name.toLowerCase();
    // friendlies(친선경기)만 제외
    if (name.contains('friendlies') || name.contains('friendly')) {
      return false;
    }
    return true;
  }).toList();

  return nationalCompetitions;
});

/// 팀 폼 클래스
class TeamForm {
  final List<String> results;
  final int wins;
  final int draws;
  final int losses;

  TeamForm({
    required this.results,
    required this.wins,
    required this.draws,
    required this.losses,
  });

  String get formString => results.join('-');
}
