import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_football_service.dart';
import '../../l10n/app_localizations.dart';

/// 토너먼트 라운드 정보
class TournamentRound {
  final String name;
  final String nameKo;
  final int order; // 결승이 가장 높은 숫자
  final List<ApiFootballFixture> fixtures;

  TournamentRound({
    required this.name,
    required this.nameKo,
    required this.order,
    required this.fixtures,
  });
}

/// 팀 진출/탈락 정보
class TeamAdvancement {
  final int teamId;
  final String teamName;
  final String? teamLogo;
  final bool advanced; // true = 진출, false = 탈락
  final int? goalsFor;
  final int? goalsAgainst;
  final bool isPenaltyWin;
  final String? opponentName;

  TeamAdvancement({
    required this.teamId,
    required this.teamName,
    this.teamLogo,
    required this.advanced,
    this.goalsFor,
    this.goalsAgainst,
    this.isPenaltyWin = false,
    this.opponentName,
  });
}

/// 토너먼트 브라켓 위젯
class TournamentBracketWidget extends StatelessWidget {
  final List<ApiFootballFixture> fixtures;
  final String? locale;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _winnerBg = Color(0xFFDCFCE7);
  static const _winnerText = Color(0xFF166534);

  const TournamentBracketWidget({
    super.key,
    required this.fixtures,
    this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final rounds = _groupByRound(fixtures);
    final l10n = AppLocalizations.of(context)!;

    if (rounds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.leaderboard_outlined, size: 48, color: _textSecondary),
              const SizedBox(height: 16),
              Text(
                l10n.noStandingsData,
                style: TextStyle(color: _textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rounds.length,
      itemBuilder: (context, index) {
        final round = rounds[index];
        return _buildAdvancementSection(context, round);
      },
    );
  }

  /// 라운드별로 경기 그룹화 (예선 라운드 제외, 64강 이상만)
  List<TournamentRound> _groupByRound(List<ApiFootballFixture> fixtures) {
    final Map<String, List<ApiFootballFixture>> grouped = {};

    for (final fixture in fixtures) {
      final roundName = fixture.league.round ?? 'Unknown';
      grouped.putIfAbsent(roundName, () => []).add(fixture);
    }

    // 라운드명을 순서대로 정렬
    final rounds = grouped.entries.map((entry) {
      final order = _getRoundOrder(entry.key);
      final nameKo = _getRoundNameKo(entry.key);
      // 경기를 날짜순으로 정렬
      entry.value.sort((a, b) => a.date.compareTo(b.date));
      return TournamentRound(
        name: entry.key,
        nameKo: nameKo,
        order: order,
        fixtures: entry.value,
      );
    }).toList();

    // 예선 라운드 필터링 (order >= 50인 라운드만 = 64강 이상)
    final mainRounds = rounds.where((r) => r.order >= 50).toList();

    // 결승에 가까운 순서대로 정렬 (결승이 맨 위)
    mainRounds.sort((a, b) => b.order.compareTo(a.order));

    return mainRounds;
  }

  /// 라운드 순서 반환 (결승이 가장 높은 숫자)
  int _getRoundOrder(String round) {
    final lower = round.toLowerCase();

    // 1/N-finals 형식 먼저 체크 (예: 1/128-finals, 1/64-finals)
    final fractionMatch = RegExp(r'1/(\d+)-finals?').firstMatch(lower);
    if (fractionMatch != null) {
      final n = int.tryParse(fractionMatch.group(1)!) ?? 0;
      // 숫자가 작을수록 결승에 가까움 (1/2 = 결승, 1/4 = 8강, 1/128 = 초반)
      if (n == 2) return 100; // Final
      if (n == 4) return 80;  // Quarter-final
      if (n == 8) return 70;  // Round of 16
      if (n == 16) return 60; // Round of 32
      if (n == 32) return 50; // Round of 64
      if (n == 64) return 40; // Round of 128
      if (n == 128) return 30; // Round of 256
      return 20; // 더 큰 숫자는 초반 라운드
    }

    // Round of N 형식 체크
    final roundOfMatch = RegExp(r'round of (\d+)').firstMatch(lower);
    if (roundOfMatch != null) {
      final n = int.tryParse(roundOfMatch.group(1)!) ?? 0;
      if (n == 16) return 70;
      if (n == 32) return 60;
      if (n == 64) return 50;
      if (n == 128) return 40;
      if (n == 256) return 30;
      return 25; // 더 큰 숫자
    }

    // 일반적인 라운드명
    if (lower.contains('final') && !lower.contains('semi') && !lower.contains('quarter')) {
      return 100;
    }
    if (lower.contains('semi')) return 90;
    if (lower.contains('quarter')) return 80;
    if (lower.contains('5th round') || lower.contains('round 5')) return 55;
    if (lower.contains('4th round') || lower.contains('round 4')) return 50;
    if (lower.contains('3rd round') || lower.contains('round 3')) return 45;
    if (lower.contains('2nd round') || lower.contains('round 2')) return 35;
    if (lower.contains('1st round') || lower.contains('round 1')) return 25;

    // 예선 라운드 (Qualifying 라운드 세분화)
    if (lower.contains('3rd') && lower.contains('qualifying')) return 15;
    if (lower.contains('2nd') && lower.contains('qualifying')) return 12;
    if (lower.contains('1st') && lower.contains('qualifying')) return 10;
    if (lower.contains('preliminary') && lower.contains('replay')) return 6;
    if (lower.contains('preliminary')) return 5;
    if (lower.contains('extra preliminary')) return 3;
    if (lower.contains('qualifying') && lower.contains('replay')) return 8;
    if (lower.contains('qualifying')) return 7;

    return 0;
  }

  /// 라운드명 한글화
  String _getRoundNameKo(String round) {
    final lower = round.toLowerCase();

    // 1/N-finals 형식 체크
    final fractionMatch = RegExp(r'1/(\d+)-finals?').firstMatch(lower);
    if (fractionMatch != null) {
      final n = int.tryParse(fractionMatch.group(1)!) ?? 0;
      if (n == 2) return '결승';
      if (n == 4) return '8강';
      if (n == 8) return '16강';
      if (n == 16) return '32강';
      if (n == 32) return '64강';
      if (n == 64) return '128강';
      if (n == 128) return '256강';
      return '${n * 2}강';
    }

    // Round of N 형식 체크
    final roundOfMatch = RegExp(r'round of (\d+)').firstMatch(lower);
    if (roundOfMatch != null) {
      final n = int.tryParse(roundOfMatch.group(1)!) ?? 0;
      return '$n강';
    }

    if (lower.contains('final') && !lower.contains('semi') && !lower.contains('quarter')) {
      return '결승';
    }
    if (lower.contains('semi-final') || lower.contains('semi final')) return '준결승';
    if (lower.contains('quarter-final') || lower.contains('quarter final')) return '8강';
    if (lower.contains('5th round') || lower.contains('round 5')) return '5라운드';
    if (lower.contains('4th round') || lower.contains('round 4')) return '4라운드';
    if (lower.contains('3rd round') || lower.contains('round 3')) return '3라운드';
    if (lower.contains('2nd round') || lower.contains('round 2')) return '2라운드';
    if (lower.contains('1st round') || lower.contains('round 1')) return '1라운드';

    // 예선 라운드
    if (lower.contains('3rd') && lower.contains('qualifying')) return '예선 3라운드';
    if (lower.contains('2nd') && lower.contains('qualifying')) return '예선 2라운드';
    if (lower.contains('1st') && lower.contains('qualifying')) return '예선 1라운드';
    if (lower.contains('extra preliminary')) return '엑스트라 예선';
    if (lower.contains('preliminary') && lower.contains('replay')) return '예선 재경기';
    if (lower.contains('preliminary')) return '예선';
    if (lower.contains('qualifying') && lower.contains('replay')) return '예선 재경기';
    if (lower.contains('qualifying')) return '예선';

    return round;
  }

  /// 진출/탈락 정보를 추출
  List<TeamAdvancement> _extractAdvancements(TournamentRound round) {
    final List<TeamAdvancement> advancements = [];

    for (final fixture in round.fixtures) {
      final isFinished = fixture.status.short == 'FT' ||
                         fixture.status.short == 'AET' ||
                         fixture.status.short == 'PEN';

      if (isFinished) {
        final homeWinner = fixture.homeTeam.winner == true;
        final awayWinner = fixture.awayTeam.winner == true;
        final isPenalty = fixture.status.short == 'PEN';

        // 홈팀
        advancements.add(TeamAdvancement(
          teamId: fixture.homeTeam.id,
          teamName: fixture.homeTeam.name,
          teamLogo: fixture.homeTeam.logo,
          advanced: homeWinner,
          goalsFor: fixture.homeGoals,
          goalsAgainst: fixture.awayGoals,
          isPenaltyWin: isPenalty && homeWinner,
          opponentName: fixture.awayTeam.name,
        ));

        // 원정팀
        advancements.add(TeamAdvancement(
          teamId: fixture.awayTeam.id,
          teamName: fixture.awayTeam.name,
          teamLogo: fixture.awayTeam.logo,
          advanced: awayWinner,
          goalsFor: fixture.awayGoals,
          goalsAgainst: fixture.homeGoals,
          isPenaltyWin: isPenalty && awayWinner,
          opponentName: fixture.homeTeam.name,
        ));
      }
    }

    // 진출팀을 먼저, 탈락팀을 나중에 정렬
    advancements.sort((a, b) {
      if (a.advanced && !b.advanced) return -1;
      if (!a.advanced && b.advanced) return 1;
      return a.teamName.compareTo(b.teamName);
    });

    return advancements;
  }

  /// 라운드별 진출/탈락 섹션
  Widget _buildAdvancementSection(BuildContext context, TournamentRound round) {
    final isKorean = locale == 'ko' || Localizations.localeOf(context).languageCode == 'ko';
    final displayName = isKorean ? round.nameKo : round.name;
    final isFinal = round.order == 100;

    final advancements = _extractAdvancements(round);
    final advancedTeams = advancements.where((a) => a.advanced).toList();
    final eliminatedTeams = advancements.where((a) => !a.advanced).toList();

    // 아직 진행되지 않은 경기 수
    final pendingFixtures = round.fixtures.where((f) =>
      f.status.short != 'FT' &&
      f.status.short != 'AET' &&
      f.status.short != 'PEN'
    ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라운드 헤더
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isFinal ? const Color(0xFFFEF3C7) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isFinal ? const Color(0xFFFBBF24) : _border,
              width: isFinal ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              if (isFinal)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.emoji_events, color: Color(0xFFF59E0B), size: 22),
                ),
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isFinal ? const Color(0xFFB45309) : _textPrimary,
                ),
              ),
              const Spacer(),
              // 진출/탈락/대기 카운트
              Row(
                children: [
                  if (advancedTeams.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _winnerBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '✓ ${advancedTeams.length}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _winnerText),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (eliminatedTeams.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '✗ ${eliminatedTeams.length}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (pendingFixtures.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '⏳ ${pendingFixtures.length * 2}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textSecondary),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 진출팀 목록
        if (advancedTeams.isNotEmpty) ...[
          _buildTeamList(context, advancedTeams, isAdvanced: true, isFinal: isFinal),
          const SizedBox(height: 8),
        ],

        // 탈락팀 목록
        if (eliminatedTeams.isNotEmpty) ...[
          _buildTeamList(context, eliminatedTeams, isAdvanced: false, isFinal: false),
          const SizedBox(height: 8),
        ],

        // 대기 중인 경기
        if (pendingFixtures.isNotEmpty) ...[
          _buildPendingFixtures(context, pendingFixtures),
        ],

        const SizedBox(height: 16),
      ],
    );
  }

  /// 팀 목록 빌드 (진출/탈락)
  Widget _buildTeamList(BuildContext context, List<TeamAdvancement> teams, {required bool isAdvanced, required bool isFinal}) {
    return Container(
      decoration: BoxDecoration(
        color: isAdvanced ? _winnerBg.withValues(alpha: 0.5) : const Color(0xFFFEE2E2).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAdvanced ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
        ),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isAdvanced ? const Color(0xFF86EFAC).withValues(alpha: 0.3) : const Color(0xFFFCA5A5).withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                Icon(
                  isAdvanced ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 16,
                  color: isAdvanced ? _winnerText : const Color(0xFFDC2626),
                ),
                const SizedBox(width: 6),
                Text(
                  isAdvanced ? (isFinal ? '우승' : '진출') : '탈락',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isAdvanced ? _winnerText : const Color(0xFFDC2626),
                  ),
                ),
                const Spacer(),
                Text(
                  '${teams.length}팀',
                  style: TextStyle(
                    fontSize: 11,
                    color: isAdvanced ? _winnerText : const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
          // 팀 목록
          ...teams.map((team) => _buildTeamRow(context, team, isAdvanced: isAdvanced, isFinal: isFinal && isAdvanced)),
        ],
      ),
    );
  }

  /// 개별 팀 행
  Widget _buildTeamRow(BuildContext context, TeamAdvancement team, {required bool isAdvanced, required bool isFinal}) {
    return InkWell(
      onTap: () => context.push('/team/${team.teamId}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isAdvanced ? const Color(0xFF86EFAC).withValues(alpha: 0.5) : const Color(0xFFFCA5A5).withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            // 팀 로고
            _buildTeamLogo(team.teamLogo),
            const SizedBox(width: 10),
            // 팀 이름
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          team.teamName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isFinal ? FontWeight.w700 : FontWeight.w500,
                            color: _textPrimary,
                          ),
                        ),
                      ),
                      if (isFinal) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.emoji_events, size: 16, color: Color(0xFFF59E0B)),
                      ],
                    ],
                  ),
                  if (team.opponentName != null)
                    Text(
                      'vs ${team.opponentName}',
                      style: TextStyle(fontSize: 11, color: _textSecondary),
                    ),
                ],
              ),
            ),
            // 스코어
            if (team.goalsFor != null && team.goalsAgainst != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Text(
                      '${team.goalsFor} - ${team.goalsAgainst}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    if (team.isPenaltyWin) ...[
                      const SizedBox(width: 4),
                      Text(
                        'PK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 대기 중인 경기 표시
  Widget _buildPendingFixtures(BuildContext context, List<ApiFootballFixture> fixtures) {
    final dateFormat = DateFormat('MM/dd HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, size: 16, color: _textSecondary),
                const SizedBox(width: 6),
                Text(
                  '예정',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${fixtures.length}경기',
                  style: TextStyle(fontSize: 11, color: _textSecondary),
                ),
              ],
            ),
          ),
          // 경기 목록
          ...fixtures.map((fixture) => InkWell(
            onTap: () => context.push('/match/${fixture.id}'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: _border.withValues(alpha: 0.5)),
                ),
              ),
              child: Row(
                children: [
                  // 홈팀
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            fixture.homeTeam.name,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 12, color: _textPrimary),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildTeamLogo(fixture.homeTeam.logo),
                      ],
                    ),
                  ),
                  // 날짜/시간
                  Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Text(
                          dateFormat.format(fixture.date.toLocal()),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, color: _textSecondary),
                        ),
                        const Icon(Icons.hourglass_empty, size: 14, color: Color(0xFF9CA3AF)),
                      ],
                    ),
                  ),
                  // 원정팀
                  Expanded(
                    child: Row(
                      children: [
                        _buildTeamLogo(fixture.awayTeam.logo),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            fixture.awayTeam.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: _textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(String? logo) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: logo != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: logo,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => const Icon(
                  Icons.sports_soccer,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            )
          : const Icon(
              Icons.sports_soccer,
              size: 14,
              color: Color(0xFF9CA3AF),
            ),
    );
  }

}
