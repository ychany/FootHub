import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_football_service.dart';
import '../../../core/constants/api_football_ids.dart';

// 대한민국 국가대표 팀 ID (API-Football)
const int koreaTeamId = TeamIds.southKorea; // 17

// 국가대표 관련 대회 정보
class NationalTeamCompetition {
  final int id;
  final String name;
  final String shortName;
  final String icon;

  const NationalTeamCompetition({
    required this.id,
    required this.name,
    required this.shortName,
    required this.icon,
  });
}

class NationalTeamLeagues {
  static const int worldCup = LeagueIds.worldCup;                 // 1 - FIFA 월드컵 (본선)
  static const int worldCupQualAsia = LeagueIds.worldCupQualAsia; // 30 - 월드컵 예선 (AFC)
  static const int asianCup = LeagueIds.asianCup;                 // 81 - AFC 아시안컵
  static const int friendlies = LeagueIds.friendlies;             // 10 - 친선경기

  static const List<NationalTeamCompetition> competitions = [
    NationalTeamCompetition(
      id: worldCup,
      name: 'FIFA 월드컵 본선',
      shortName: '월드컵',
      icon: '🏆',
    ),
    NationalTeamCompetition(
      id: worldCupQualAsia,
      name: '월드컵 예선 (AFC)',
      shortName: 'WC예선',
      icon: '⚽',
    ),
    NationalTeamCompetition(
      id: asianCup,
      name: 'AFC 아시안컵',
      shortName: '아시안컵',
      icon: '🏅',
    ),
    NationalTeamCompetition(
      id: friendlies,
      name: '친선경기',
      shortName: 'A매치',
      icon: '🤝',
    ),
  ];
}

/// API-Football 서비스 Provider
final apiFootballServiceProvider = Provider<ApiFootballService>((ref) {
  return ApiFootballService();
});

/// 국가대표 팀 정보 Provider
final koreaTeamProvider = FutureProvider<ApiFootballTeam?>((ref) async {
  final service = ref.watch(apiFootballServiceProvider);
  return service.getTeamById(koreaTeamId);
});

/// 국가대표 다음 경기 Provider
final koreaNextMatchesProvider = FutureProvider<List<ApiFootballFixture>>((ref) async {
  final service = ref.watch(apiFootballServiceProvider);
  return service.getTeamNextFixtures(koreaTeamId, count: 10);
});

/// 국가대표 지난 경기 Provider
final koreaPastMatchesProvider = FutureProvider<List<ApiFootballFixture>>((ref) async {
  final service = ref.watch(apiFootballServiceProvider);
  return service.getTeamLastFixtures(koreaTeamId, count: 10);
});

/// 국가대표 전체 일정 Provider (다음 + 지난 경기)
final koreaAllMatchesProvider = FutureProvider<List<ApiFootballFixture>>((ref) async {
  final nextMatches = await ref.watch(koreaNextMatchesProvider.future);
  final pastMatches = await ref.watch(koreaPastMatchesProvider.future);

  // 중복 제거 후 합치기
  final allEvents = <int, ApiFootballFixture>{};
  for (final event in [...pastMatches, ...nextMatches]) {
    allEvents[event.id] = event;
  }

  // 날짜순 정렬 (최신순)
  final sorted = allEvents.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  return sorted;
});

/// 2026 월드컵 카운트다운 정보
class WorldCupCountdown {
  final DateTime worldCupStart;
  final int daysRemaining;
  final String tournamentName;

  WorldCupCountdown({
    required this.worldCupStart,
    required this.daysRemaining,
    required this.tournamentName,
  });
}

/// 2026 월드컵 카운트다운 Provider
final worldCupCountdownProvider = Provider<WorldCupCountdown>((ref) {
  // 2026 FIFA 월드컵 개막일 (미국, 캐나다, 멕시코 공동 개최)
  final worldCupStart = DateTime(2026, 6, 11);
  final now = DateTime.now();
  final daysRemaining = worldCupStart.difference(now).inDays;

  return WorldCupCountdown(
    worldCupStart: worldCupStart,
    daysRemaining: daysRemaining,
    tournamentName: '2026 FIFA 월드컵',
  );
});

/// 최근 5경기 폼 계산
class TeamForm {
  final List<String> results; // W, D, L
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

final koreaFormProvider = FutureProvider<TeamForm>((ref) async {
  final pastMatches = await ref.watch(koreaPastMatchesProvider.future);

  // 최근 5경기만
  final recent = pastMatches.take(5).toList();

  final results = <String>[];
  int wins = 0, draws = 0, losses = 0;

  for (final match in recent) {
    final homeScore = match.homeGoals ?? 0;
    final awayScore = match.awayGoals ?? 0;

    // 한국이 홈팀인지 원정팀인지 확인
    final isHome = match.homeTeam.id == koreaTeamId;
    final koreaScore = isHome ? homeScore : awayScore;
    final opponentScore = isHome ? awayScore : homeScore;

    if (koreaScore > opponentScore) {
      results.add('W');
      wins++;
    } else if (koreaScore < opponentScore) {
      results.add('L');
      losses++;
    } else {
      results.add('D');
      draws++;
    }
  }

  return TeamForm(
    results: results,
    wins: wins,
    draws: draws,
    losses: losses,
  );
});

/// 국가대표 선수단 Provider (API에서 가져옴)
final koreaSquadProvider = FutureProvider<List<ApiFootballSquadPlayer>>((ref) async {
  final service = ref.watch(apiFootballServiceProvider);
  return service.getTeamSquad(koreaTeamId);
});

/// 선택된 대회 필터 Provider (null = 전체)
final selectedCompetitionProvider = StateProvider<int?>((ref) => null);

/// 대회별 일정 Provider
final competitionMatchesProvider = FutureProvider.family<List<ApiFootballFixture>, int>((ref, leagueId) async {
  final allMatches = await ref.watch(koreaAllMatchesProvider.future);

  // 해당 대회 경기만 필터링
  final filtered = allMatches.where((match) => match.league.id == leagueId).toList();

  // 날짜순 정렬 (최신순)
  filtered.sort((a, b) => b.date.compareTo(a.date));

  return filtered;
});

/// 특정 시즌 월드컵 경기 Provider
final worldCupSeasonMatchesProvider = FutureProvider.family<List<ApiFootballFixture>, int>((ref, season) async {
  final service = ref.watch(apiFootballServiceProvider);
  final fixtures = await service.getFixturesByLeague(NationalTeamLeagues.worldCup, season);

  // 한국 경기만 필터링
  return fixtures.where((f) =>
    f.homeTeam.id == koreaTeamId || f.awayTeam.id == koreaTeamId
  ).toList();
});
