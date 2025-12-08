import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/sports_db_service.dart';

// 대한민국 국가대표 팀 ID
const String koreaTeamId = '134517';

// 국가대표 관련 대회 ID
class NationalTeamLeagues {
  static const String worldCup = '4429';           // FIFA 월드컵
  static const String worldCupQualifying = '5513'; // 월드컵 예선 (AFC)
  static const String asianCup = '4866';           // AFC 아시안컵
  static const String asianCupQualifying = '5521'; // 아시안컵 예선
  static const String friendlies = '4562';         // 친선경기
}

/// 국가대표 팀 정보 Provider
final koreaTeamProvider = FutureProvider<SportsDbTeam?>((ref) async {
  final service = SportsDbService();
  return service.getTeamById(koreaTeamId);
});

/// 국가대표 다음 경기 Provider
final koreaNextMatchesProvider = FutureProvider<List<SportsDbEvent>>((ref) async {
  final service = SportsDbService();
  return service.getNextTeamEvents(koreaTeamId);
});

/// 국가대표 지난 경기 Provider
final koreaPastMatchesProvider = FutureProvider<List<SportsDbEvent>>((ref) async {
  final service = SportsDbService();
  return service.getPastTeamEvents(koreaTeamId);
});

/// 국가대표 전체 일정 Provider (다음 + 지난 경기)
final koreaAllMatchesProvider = FutureProvider<List<SportsDbEvent>>((ref) async {
  final nextMatches = await ref.watch(koreaNextMatchesProvider.future);
  final pastMatches = await ref.watch(koreaPastMatchesProvider.future);

  // 중복 제거 후 합치기
  final allEvents = <String, SportsDbEvent>{};
  for (final event in [...pastMatches, ...nextMatches]) {
    allEvents[event.id] = event;
  }

  // 날짜순 정렬 (최신순)
  final sorted = allEvents.values.toList()
    ..sort((a, b) {
      final aDate = a.dateTime ?? DateTime(1900);
      final bDate = b.dateTime ?? DateTime(1900);
      return bDate.compareTo(aDate);
    });

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
    final homeScore = match.homeScore ?? 0;
    final awayScore = match.awayScore ?? 0;

    // 한국이 홈팀인지 원정팀인지 확인
    final isHome = match.homeTeam?.toLowerCase().contains('korea') ?? false;
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
