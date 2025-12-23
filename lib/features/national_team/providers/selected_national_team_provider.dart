import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_football_service.dart';
import '../../../core/constants/api_football_ids.dart';
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

  // 기본값: 대한민국
  // 참고: API-Football의 국기는 SVG만 제공하므로 countryFlag는 사용하지 않음
  static const defaultTeam = SelectedNationalTeam(
    teamId: TeamIds.southKorea,
    teamName: 'South Korea',
    teamLogo: 'https://media.api-sports.io/football/teams/17.png',
    countryCode: 'KR',
  );
}

/// 선택된 국가대표팀 Provider (SharedPreferences 저장)
class SelectedNationalTeamNotifier extends StateNotifier<SelectedNationalTeam> {
  SelectedNationalTeamNotifier() : super(SelectedNationalTeam.defaultTeam) {
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
    if (team.teamLogo != null) {
      await prefs.setString('${_prefKey}_logo', team.teamLogo!);
    }
    if (team.countryCode != null) {
      await prefs.setString('${_prefKey}_code', team.countryCode!);
    }
    if (team.countryFlag != null) {
      await prefs.setString('${_prefKey}_flag', team.countryFlag!);
    }
  }
}

final selectedNationalTeamProvider = StateNotifierProvider<SelectedNationalTeamNotifier, SelectedNationalTeam>((ref) {
  return SelectedNationalTeamNotifier();
});

/// 국가대표팀 목록 Provider (2026 월드컵 일정에 있는 나라만)
final worldCupTeamsProvider = FutureProvider<List<ApiFootballTeam>>((ref) async {
  final service = ApiFootballService();

  // 2026 월드컵 일정 조회
  final fixtures = await service.getFixturesByLeague(LeagueIds.worldCup, 2026);

  // 일정에서 팀 ID 추출 (중복 제거)
  final teamIds = <int>{};
  for (final fixture in fixtures) {
    teamIds.add(fixture.homeTeam.id);
    teamIds.add(fixture.awayTeam.id);
  }

  // 팀 상세 정보 조회
  final teams = <ApiFootballTeam>[];
  for (final id in teamIds) {
    final team = await service.getTeamById(id);
    if (team != null && team.national) {
      teams.add(team);
    }
  }

  // 이름순 정렬
  teams.sort((a, b) => a.name.compareTo(b.name));

  return teams;
});

/// 선택된 국가대표팀의 다음 경기 Provider
final selectedTeamNextMatchesProvider = FutureProvider<List<ApiFootballFixture>>((ref) async {
  final service = ApiFootballService();
  final team = ref.watch(selectedNationalTeamProvider);
  ref.watch(timezoneProvider);

  return service.getTeamNextFixtures(team.teamId, count: 10);
});

/// 선택된 국가대표팀의 지난 경기 Provider
final selectedTeamPastMatchesProvider = FutureProvider<List<ApiFootballFixture>>((ref) async {
  final service = ApiFootballService();
  final team = ref.watch(selectedNationalTeamProvider);
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
final selectedTeamFormProvider = FutureProvider<TeamForm>((ref) async {
  final pastMatches = await ref.watch(selectedTeamPastMatchesProvider.future);
  final team = ref.watch(selectedNationalTeamProvider);

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
  final service = ApiFootballService();
  final team = ref.watch(selectedNationalTeamProvider);
  return service.getTeamSquad(team.teamId);
});

/// 선택된 국가대표팀의 상세 정보 Provider
final selectedTeamInfoProvider = FutureProvider<ApiFootballTeam?>((ref) async {
  final service = ApiFootballService();
  final team = ref.watch(selectedNationalTeamProvider);
  return service.getTeamById(team.teamId);
});

/// 선택된 국가대표팀이 참가하는 대회 목록 Provider (동적)
final selectedTeamCompetitionsProvider = FutureProvider<List<ApiFootballTeamLeague>>((ref) async {
  final service = ApiFootballService();
  final team = ref.watch(selectedNationalTeamProvider);
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
