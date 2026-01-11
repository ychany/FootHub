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
              Icon(Icons.emoji_events_outlined, size: 48, color: _textSecondary),
              const SizedBox(height: 16),
              Text(
                l10n.noScheduledMatches,
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
        return _buildRoundSection(context, round);
      },
    );
  }

  /// 라운드별로 경기 그룹화
  List<TournamentRound> _groupByRound(List<ApiFootballFixture> fixtures) {
    final Map<String, List<ApiFootballFixture>> grouped = {};

    debugPrint('🔍 [TournamentBracket] _groupByRound called with ${fixtures.length} fixtures');

    for (final fixture in fixtures) {
      final roundName = fixture.league.round ?? 'Unknown';
      grouped.putIfAbsent(roundName, () => []).add(fixture);
    }

    debugPrint('🔍 [TournamentBracket] Grouped rounds: ${grouped.keys.toList()}');
    for (final entry in grouped.entries) {
      debugPrint('  📍 "${entry.key}" -> ${entry.value.length} fixtures, order=${_getRoundOrder(entry.key)}');
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

    // 결승에 가까운 순서대로 정렬 (결승이 맨 위)
    rounds.sort((a, b) => b.order.compareTo(a.order));

    return rounds;
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

  Widget _buildRoundSection(BuildContext context, TournamentRound round) {
    final isKorean = locale == 'ko' || Localizations.localeOf(context).languageCode == 'ko';
    final displayName = isKorean ? round.nameKo : round.name;
    final isFinal = round.order == 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라운드 헤더
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isFinal ? const Color(0xFFFEF3C7) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isFinal ? const Color(0xFFFBBF24) : _border,
            ),
          ),
          child: Row(
            children: [
              if (isFinal)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.emoji_events, color: Color(0xFFF59E0B), size: 20),
                ),
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isFinal ? const Color(0xFFB45309) : _textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${round.fixtures.length}경기',
                style: TextStyle(
                  fontSize: 12,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 경기 목록
        ...round.fixtures.map((fixture) => _buildMatchCard(context, fixture, isFinal)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMatchCard(BuildContext context, ApiFootballFixture fixture, bool isFinal) {
    final isFinished = fixture.status.short == 'FT' ||
                       fixture.status.short == 'AET' ||
                       fixture.status.short == 'PEN';
    final homeWinner = fixture.homeTeam.winner == true;
    final awayWinner = fixture.awayTeam.winner == true;
    final dateFormat = DateFormat('MM/dd HH:mm');

    return GestureDetector(
      onTap: () => context.push('/match/${fixture.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFinal && isFinished ? const Color(0xFFFBBF24) : _border,
            width: isFinal && isFinished ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // 날짜/상태
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dateFormat.format(fixture.date.toLocal()),
                  style: TextStyle(
                    fontSize: 11,
                    color: _textSecondary,
                  ),
                ),
                if (isFinished) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getStatusText(fixture.status.short),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ),
                ] else if (fixture.status.short == 'NS') ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '예정',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            // 팀 vs 팀
            Row(
              children: [
                // 홈팀
                Expanded(
                  child: _buildTeamRow(
                    fixture.homeTeam,
                    isWinner: homeWinner && isFinished,
                    isHome: true,
                  ),
                ),
                // 스코어
                Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: isFinished || fixture.status.short != 'NS'
                      ? FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${fixture.homeGoals ?? '-'} - ${fixture.awayGoals ?? '-'}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                          ),
                        )
                      : Text(
                          'vs',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textSecondary,
                          ),
                        ),
                ),
                // 원정팀
                Expanded(
                  child: _buildTeamRow(
                    fixture.awayTeam,
                    isWinner: awayWinner && isFinished,
                    isHome: false,
                  ),
                ),
              ],
            ),
            // 승부차기 표시
            if (fixture.status.short == 'PEN' && fixture.score.penaltyHome != null) ...[
              const SizedBox(height: 6),
              Text(
                '(PK ${fixture.score.penaltyHome} - ${fixture.score.penaltyAway})',
                style: TextStyle(
                  fontSize: 11,
                  color: _textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamRow(ApiFootballFixtureTeam team, {required bool isWinner, required bool isHome}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isWinner ? _winnerBg : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: isHome ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isHome) ...[
            _buildTeamLogo(team.logo),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              team.name,
              textAlign: isHome ? TextAlign.right : TextAlign.left,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
                color: isWinner ? _winnerText : _textPrimary,
              ),
            ),
          ),
          if (isHome) ...[
            const SizedBox(width: 8),
            _buildTeamLogo(team.logo),
          ],
          if (isWinner) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.emoji_events,
              size: 14,
              color: const Color(0xFFF59E0B),
            ),
          ],
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

  String _getStatusText(String status) {
    switch (status) {
      case 'FT':
        return '종료';
      case 'AET':
        return '연장';
      case 'PEN':
        return '승부차기';
      case 'HT':
        return '하프타임';
      case '1H':
      case '2H':
      case 'ET':
        return '진행중';
      default:
        return status;
    }
  }
}
