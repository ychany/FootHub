import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_football_service.dart';
import '../../l10n/app_localizations.dart';

/// 팀 비교 탭 위젯 (비교 분석)
class TeamComparisonTab extends ConsumerWidget {
  final int homeTeamId;
  final int awayTeamId;
  final String homeTeamName;
  final String awayTeamName;
  final String? homeTeamLogo;
  final String? awayTeamLogo;
  final int leagueId;
  final int season;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _success = Color(0xFF10B981);
  static const _error = Color(0xFFEF4444);
  static const _warning = Color(0xFFF59E0B);

  const TeamComparisonTab({
    super.key,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
    this.homeTeamLogo,
    this.awayTeamLogo,
    required this.leagueId,
    required this.season,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // Providers
    final homeStandingAsync = ref.watch(
        teamStandingProvider((leagueId: leagueId, season: season, teamId: homeTeamId)));
    final awayStandingAsync = ref.watch(
        teamStandingProvider((leagueId: leagueId, season: season, teamId: awayTeamId)));
    final homeFormAsync =
        ref.watch(teamRecentFormProvider((teamId: homeTeamId, last: 5)));
    final awayFormAsync =
        ref.watch(teamRecentFormProvider((teamId: awayTeamId, last: 5)));
    final homeSeasonStatsAsync =
        ref.watch(teamSeasonStatsProvider((teamId: homeTeamId, season: season, leagueId: leagueId)));
    final awaySeasonStatsAsync =
        ref.watch(teamSeasonStatsProvider((teamId: awayTeamId, season: season, leagueId: leagueId)));
    final scorersAsync = ref.watch(
        leagueTopScorersProvider((leagueId: leagueId, season: season)));
    final assistsAsync = ref.watch(
        leagueTopAssistsProvider((leagueId: leagueId, season: season)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 리그 순위 비교
          _buildSectionHeader(l10n.leagueStandings, Icons.leaderboard),
          const SizedBox(height: 12),
          _buildStandingsComparison(
              context, homeStandingAsync, awayStandingAsync),
          const SizedBox(height: 24),

          // 2. 홈/원정 성적 비교
          _buildSectionHeader(l10n.homeAwayRecord, Icons.stadium),
          const SizedBox(height: 12),
          _buildHomeAwayComparison(
              context, homeStandingAsync, awayStandingAsync),
          const SizedBox(height: 24),

          // 3. 최근 폼 비교
          _buildSectionHeader(l10n.recentFormTitle, Icons.trending_up),
          const SizedBox(height: 12),
          _buildFormComparison(
              context, homeFormAsync, awayFormAsync, homeTeamId, awayTeamId),
          const SizedBox(height: 24),

          // 4. 득점/실점 통계
          _buildSectionHeader(l10n.goalStats, Icons.sports_soccer),
          const SizedBox(height: 12),
          _buildGoalStatsComparison(
              context, homeStandingAsync, awayStandingAsync),
          const SizedBox(height: 24),

          // 5. 주요 선수 비교
          _buildSectionHeader(l10n.keyPlayers, Icons.person),
          const SizedBox(height: 12),
          _buildTopPlayersComparison(
              context, scorersAsync, assistsAsync, homeTeamId, awayTeamId),
          const SizedBox(height: 24),

          // 6. 팀 스타일 비교 (레이더 차트)
          _buildSectionHeader(l10n.teamStyleComparison, Icons.radar),
          const SizedBox(height: 12),
          _buildRadarChartComparison(
              context, homeSeasonStatsAsync, awaySeasonStatsAsync),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }

  // 1. 리그 순위 비교
  Widget _buildStandingsComparison(
    BuildContext context,
    AsyncValue<ApiFootballStanding?> homeAsync,
    AsyncValue<ApiFootballStanding?> awayAsync,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // 팀 이름 헤더
          Row(
            children: [
              Expanded(
                child: _buildTeamHeader(homeTeamName, homeTeamLogo),
              ),
              const SizedBox(width: 16),
              const Text('VS',
                  style: TextStyle(
                      color: _textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Expanded(
                child:
                    _buildTeamHeader(awayTeamName, awayTeamLogo, isAway: true),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // 순위 비교 행들
          homeAsync.when(
            data: (homeSt) => awayAsync.when(
              data: (awaySt) {
                if (homeSt == null && awaySt == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(l10n.noRankingInfo,
                          style: const TextStyle(color: _textSecondary)),
                    ),
                  );
                }
                return Column(
                  children: [
                    _buildCompareRow(
                        l10n.rankingLabel,
                        '${homeSt?.rank ?? '-'}',
                        '${awaySt?.rank ?? '-'}',
                        homeBetter:
                            (homeSt?.rank ?? 99) < (awaySt?.rank ?? 99)),
                    _buildCompareRow(
                        l10n.pointsLabel,
                        '${homeSt?.points ?? '-'}',
                        '${awaySt?.points ?? '-'}',
                        homeBetter:
                            (homeSt?.points ?? 0) > (awaySt?.points ?? 0)),
                    _buildCompareRow(l10n.matchesPlayedLabel,
                        '${homeSt?.played ?? '-'}', '${awaySt?.played ?? '-'}'),
                    _buildCompareRow(
                      l10n.winDrawLossLabel,
                      '${homeSt?.win ?? 0}-${homeSt?.draw ?? 0}-${homeSt?.lose ?? 0}',
                      '${awaySt?.win ?? 0}-${awaySt?.draw ?? 0}-${awaySt?.lose ?? 0}',
                    ),
                    _buildCompareRow(
                        l10n.goalsForLabel,
                        '${homeSt?.goalsFor ?? '-'}',
                        '${awaySt?.goalsFor ?? '-'}',
                        homeBetter:
                            (homeSt?.goalsFor ?? 0) > (awaySt?.goalsFor ?? 0)),
                    _buildCompareRow(
                        l10n.goalsAgainstLabel,
                        '${homeSt?.goalsAgainst ?? '-'}',
                        '${awaySt?.goalsAgainst ?? '-'}',
                        homeBetter: (homeSt?.goalsAgainst ?? 99) <
                            (awaySt?.goalsAgainst ?? 99)),
                    _buildCompareRow(
                        l10n.goalDiffLabel,
                        _formatGoalDiff(homeSt?.goalsDiff),
                        _formatGoalDiff(awaySt?.goalsDiff),
                        homeBetter: (homeSt?.goalsDiff ?? -99) >
                            (awaySt?.goalsDiff ?? -99)),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Text(l10n.dataLoadFailed,
                  style: const TextStyle(color: _textSecondary)),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(l10n.dataLoadFailed,
                style: const TextStyle(color: _textSecondary)),
          ),
        ],
      ),
    );
  }

  String _formatGoalDiff(int? diff) {
    if (diff == null) return '-';
    return diff > 0 ? '+$diff' : '$diff';
  }

  Widget _buildTeamHeader(String name, String? logo, {bool isAway = false}) {
    return Row(
      mainAxisAlignment:
          isAway ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isAway && logo != null) ...[
          CachedNetworkImage(
            imageUrl: logo,
            width: 28,
            height: 28,
            placeholder: (_, __) => const SizedBox(width: 28, height: 28),
            errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 28),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: isAway ? TextAlign.end : TextAlign.start,
          ),
        ),
        if (isAway && logo != null) ...[
          const SizedBox(width: 8),
          CachedNetworkImage(
            imageUrl: logo,
            width: 28,
            height: 28,
            placeholder: (_, __) => const SizedBox(width: 28, height: 28),
            errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 28),
          ),
        ],
      ],
    );
  }

  Widget _buildCompareRow(String label, String homeValue, String awayValue,
      {bool? homeBetter}) {
    Color homeColor = _textPrimary;
    Color awayColor = _textPrimary;

    if (homeBetter != null) {
      homeColor = homeBetter ? _success : _textSecondary;
      awayColor = homeBetter ? _textSecondary : _success;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              homeValue,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: homeColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: _textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              awayValue,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: awayColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // 2. 홈/원정 성적 비교
  Widget _buildHomeAwayComparison(
    BuildContext context,
    AsyncValue<ApiFootballStanding?> homeAsync,
    AsyncValue<ApiFootballStanding?> awayAsync,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: homeAsync.when(
        data: (homeSt) => awayAsync.when(
          data: (awaySt) {
            if (homeSt == null && awaySt == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.noRecordInfo,
                      style: const TextStyle(color: _textSecondary)),
                ),
              );
            }
            return Column(
              children: [
                // 홈팀의 홈 성적 vs 원정팀의 원정 성적
                Row(
                  children: [
                    Expanded(
                      child: _buildRecordCard(
                        context,
                        '$homeTeamName\n${l10n.homeShort}',
                        homeSt?.homeWin ?? 0,
                        homeSt?.homeDraw ?? 0,
                        homeSt?.homeLose ?? 0,
                        homeSt?.homeGoalsFor ?? 0,
                        homeSt?.homeGoalsAgainst ?? 0,
                        _primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRecordCard(
                        context,
                        '$awayTeamName\n${l10n.awayShort}',
                        awaySt?.awayWin ?? 0,
                        awaySt?.awayDraw ?? 0,
                        awaySt?.awayLose ?? 0,
                        awaySt?.awayGoalsFor ?? 0,
                        awaySt?.awayGoalsAgainst ?? 0,
                        _warning,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Text(l10n.dataLoadFailed),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Text(l10n.dataLoadFailed),
      ),
    );
  }

  Widget _buildRecordCard(BuildContext context, String title, int win, int draw,
      int lose, int gf, int ga, Color accentColor) {
    final l10n = AppLocalizations.of(context)!;
    final played = win + draw + lose;
    final avgGf = played > 0 ? (gf / played).toStringAsFixed(1) : '0.0';
    final avgGa = played > 0 ? (ga / played).toStringAsFixed(1) : '0.0';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '$win${l10n.winShort} $draw${l10n.drawShort} $lose${l10n.lossShort}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatMini(l10n.avgGoalsFor, avgGf),
              _buildStatMini(l10n.avgGoalsAgainst, avgGa),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMini(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: _textSecondary,
          ),
        ),
      ],
    );
  }

  // 3. 최근 폼 비교
  Widget _buildFormComparison(
    BuildContext context,
    AsyncValue<List<ApiFootballFixture>> homeFormAsync,
    AsyncValue<List<ApiFootballFixture>> awayFormAsync,
    int homeTeamId,
    int awayTeamId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // 홈팀 폼
          homeFormAsync.when(
            data: (fixtures) =>
                _buildFormRow(context, homeTeamName, fixtures, homeTeamId),
            loading: () => const SizedBox(
                height: 40, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => Text(l10n.loadFailed),
          ),
          const SizedBox(height: 16),
          // 원정팀 폼
          awayFormAsync.when(
            data: (fixtures) =>
                _buildFormRow(context, awayTeamName, fixtures, awayTeamId),
            loading: () => const SizedBox(
                height: 40, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => Text(l10n.loadFailed),
          ),
        ],
      ),
    );
  }

  Widget _buildFormRow(BuildContext context, String teamName,
      List<ApiFootballFixture> fixtures, int teamId) {
    final l10n = AppLocalizations.of(context)!;
    final results = <String>[];
    int wins = 0, draws = 0, losses = 0;

    for (final f in fixtures.take(5)) {
      final isHome = f.homeTeam.id == teamId;
      final teamGoals = isHome ? (f.homeGoals ?? 0) : (f.awayGoals ?? 0);
      final oppGoals = isHome ? (f.awayGoals ?? 0) : (f.homeGoals ?? 0);

      if (teamGoals > oppGoals) {
        results.add('W');
        wins++;
      } else if (teamGoals < oppGoals) {
        results.add('L');
        losses++;
      } else {
        results.add('D');
        draws++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              teamName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            Text(
              '$wins${l10n.winShort} $draws${l10n.drawShort} $losses${l10n.lossShort}',
              style: const TextStyle(
                fontSize: 12,
                color: _textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: results.map((r) => _buildFormBadge(r)).toList(),
        ),
      ],
    );
  }

  Widget _buildFormBadge(String result) {
    Color bgColor;
    Color textColor = Colors.white;

    switch (result) {
      case 'W':
        bgColor = _success;
        break;
      case 'L':
        bgColor = _error;
        break;
      default:
        bgColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(right: 6),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          result,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 4. 득점/실점 통계
  Widget _buildGoalStatsComparison(
    BuildContext context,
    AsyncValue<ApiFootballStanding?> homeAsync,
    AsyncValue<ApiFootballStanding?> awayAsync,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: homeAsync.when(
        data: (homeSt) => awayAsync.when(
          data: (awaySt) {
            if (homeSt == null && awaySt == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.noStatsInfo,
                      style: const TextStyle(color: _textSecondary)),
                ),
              );
            }

            final homePlayed = homeSt?.played ?? 1;
            final awayPlayed = awaySt?.played ?? 1;
            final homeAvgGf =
                ((homeSt?.goalsFor ?? 0) / homePlayed).toStringAsFixed(1);
            final homeAvgGa =
                ((homeSt?.goalsAgainst ?? 0) / homePlayed).toStringAsFixed(1);
            final awayAvgGf =
                ((awaySt?.goalsFor ?? 0) / awayPlayed).toStringAsFixed(1);
            final awayAvgGa =
                ((awaySt?.goalsAgainst ?? 0) / awayPlayed).toStringAsFixed(1);

            return Column(
              children: [
                _buildCompareRow(
                    l10n.totalGoalsFor,
                    '${homeSt?.goalsFor ?? 0}',
                    '${awaySt?.goalsFor ?? 0}',
                    homeBetter:
                        (homeSt?.goalsFor ?? 0) > (awaySt?.goalsFor ?? 0)),
                _buildCompareRow(
                    l10n.totalGoalsAgainst,
                    '${homeSt?.goalsAgainst ?? 0}',
                    '${awaySt?.goalsAgainst ?? 0}',
                    homeBetter: (homeSt?.goalsAgainst ?? 99) <
                        (awaySt?.goalsAgainst ?? 99)),
                _buildCompareRow(l10n.goalsPerMatch, homeAvgGf, awayAvgGf,
                    homeBetter:
                        double.parse(homeAvgGf) > double.parse(awayAvgGf)),
                _buildCompareRow(l10n.concededPerMatch, homeAvgGa, awayAvgGa,
                    homeBetter:
                        double.parse(homeAvgGa) < double.parse(awayAvgGa)),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Text(l10n.dataLoadFailed),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Text(l10n.dataLoadFailed),
      ),
    );
  }

  // 5. 주요 선수 비교
  Widget _buildTopPlayersComparison(
    BuildContext context,
    AsyncValue<List<ApiFootballTopScorer>> scorersAsync,
    AsyncValue<List<ApiFootballTopScorer>> assistsAsync,
    int homeTeamId,
    int awayTeamId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: scorersAsync.when(
        data: (scorers) {
          final homeScorer =
              scorers.where((s) => s.teamId == homeTeamId).toList();
          final awayScorer =
              scorers.where((s) => s.teamId == awayTeamId).toList();

          return assistsAsync.when(
            data: (assists) {
              final homeAssist =
                  assists.where((a) => a.teamId == homeTeamId).toList();
              final awayAssist =
                  assists.where((a) => a.teamId == awayTeamId).toList();

              if (homeScorer.isEmpty &&
                  awayScorer.isEmpty &&
                  homeAssist.isEmpty &&
                  awayAssist.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.noPlayerStatsInfo,
                        style: const TextStyle(color: _textSecondary)),
                  ),
                );
              }

              return Column(
                children: [
                  // 득점 리더
                  _buildPlayerCompareSection(
                    context,
                    l10n.topScorer,
                    Icons.sports_soccer,
                    homeScorer.isNotEmpty ? homeScorer.first : null,
                    awayScorer.isNotEmpty ? awayScorer.first : null,
                    (p) => l10n.nGoals(p.goals ?? 0),
                  ),
                  const SizedBox(height: 16),
                  // 도움 리더
                  _buildPlayerCompareSection(
                    context,
                    l10n.topAssister,
                    Icons.handshake_outlined,
                    homeAssist.isNotEmpty ? homeAssist.first : null,
                    awayAssist.isNotEmpty ? awayAssist.first : null,
                    (p) => l10n.nAssists(p.assists ?? 0),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(l10n.assistDataLoadFailed),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.cannotLoadPlayerStats,
                style: const TextStyle(color: _textSecondary)),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCompareSection(
    BuildContext context,
    String title,
    IconData icon,
    ApiFootballTopScorer? homePlayer,
    ApiFootballTopScorer? awayPlayer,
    String Function(ApiFootballTopScorer) statBuilder,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: _primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildPlayerCard(context, homePlayer, statBuilder)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('vs', style: TextStyle(color: _textSecondary)),
            ),
            Expanded(
                child: _buildPlayerCard(context, awayPlayer, statBuilder,
                    isAway: true)),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayerCard(BuildContext context, ApiFootballTopScorer? player,
      String Function(ApiFootballTopScorer) statBuilder,
      {bool isAway = false}) {
    if (player == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('-', style: TextStyle(color: _textSecondary)),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        if (player.playerId > 0) {
          context.push('/player/${player.playerId}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment:
              isAway ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isAway && player.playerPhoto != null)
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: player.playerPhoto!,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 36,
                    height: 36,
                    color: Colors.grey.shade200,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 36,
                    height: 36,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.person, size: 20),
                  ),
                ),
              ),
            if (!isAway) const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    isAway ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    player.playerName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    statBuilder(player),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                ],
              ),
            ),
            if (isAway) const SizedBox(width: 8),
            if (isAway && player.playerPhoto != null)
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: player.playerPhoto!,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 36,
                    height: 36,
                    color: Colors.grey.shade200,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 36,
                    height: 36,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.person, size: 20),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 6. 팀 스타일 비교 (레이더 차트)
  Widget _buildRadarChartComparison(
    BuildContext context,
    AsyncValue<ApiFootballTeamSeasonStats?> homeStatsAsync,
    AsyncValue<ApiFootballTeamSeasonStats?> awayStatsAsync,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: homeStatsAsync.when(
        data: (homeStats) => awayStatsAsync.when(
          data: (awayStats) {
            if (homeStats == null && awayStats == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.noSeasonStats,
                      style: const TextStyle(color: _textSecondary)),
                ),
              );
            }

            // 레이더 차트 데이터 계산 (0-100 스케일로 정규화)
            final homeData = _calculateRadarData(homeStats);
            final awayData = _calculateRadarData(awayStats);

            return Column(
              children: [
                // 범례
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(homeTeamName, const Color(0xFF2563EB)),
                    const SizedBox(width: 24),
                    _buildLegendItem(awayTeamName, const Color(0xFFEF4444)),
                  ],
                ),
                const SizedBox(height: 16),
                // 레이더 차트
                SizedBox(
                  height: 280,
                  child: RadarChart(
                    RadarChartData(
                      dataSets: [
                        RadarDataSet(
                          dataEntries:
                              homeData.map((e) => RadarEntry(value: e)).toList(),
                          fillColor:
                              const Color(0xFF2563EB).withValues(alpha: 0.2),
                          borderColor: const Color(0xFF2563EB),
                          borderWidth: 2,
                          entryRadius: 3,
                        ),
                        RadarDataSet(
                          dataEntries:
                              awayData.map((e) => RadarEntry(value: e)).toList(),
                          fillColor:
                              const Color(0xFFEF4444).withValues(alpha: 0.2),
                          borderColor: const Color(0xFFEF4444),
                          borderWidth: 2,
                          entryRadius: 3,
                        ),
                      ],
                      radarBackgroundColor: Colors.transparent,
                      borderData: FlBorderData(show: false),
                      radarBorderData:
                          const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                      titlePositionPercentageOffset: 0.2,
                      titleTextStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                      ),
                      getTitle: (index, angle) {
                        final titles = [
                          l10n.radarWinRate,
                          l10n.radarAttack,
                          l10n.radarDefense,
                          l10n.radarCleanSheet,
                          l10n.radarHomeRecord
                        ];
                        return RadarChartTitle(
                          text: titles[index],
                          angle: 0,
                        );
                      },
                      tickCount: 4,
                      ticksTextStyle: const TextStyle(
                        fontSize: 10,
                        color: _textSecondary,
                      ),
                      tickBorderData:
                          const BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
                      gridBorderData:
                          const BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 상세 수치
                _buildRadarStatsDetail(context, homeStats, awayStats),
              ],
            );
          },
          loading: () => const Center(
              child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          )),
          error: (_, __) => Text(l10n.dataLoadFailed,
              style: const TextStyle(color: _textSecondary)),
        ),
        loading: () => const Center(
            child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        )),
        error: (_, __) => Text(l10n.dataLoadFailed,
            style: const TextStyle(color: _textSecondary)),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label.length > 10 ? '${label.substring(0, 10)}...' : label,
          style: const TextStyle(fontSize: 12, color: _textPrimary),
        ),
      ],
    );
  }

  List<double> _calculateRadarData(ApiFootballTeamSeasonStats? stats) {
    if (stats == null) return [0, 0, 0, 0, 0];

    final totalPlayed = stats.fixtures.played.total;
    if (totalPlayed == 0) return [0, 0, 0, 0, 0];

    // 1. 승률 (0-100)
    final winRate = (stats.fixtures.wins.total / totalPlayed) * 100;

    // 2. 공격력 (평균 득점 * 33, 최대 100) - 경기당 3골 이상이면 100
    final avgGoals = stats.goals.goalsFor.total / totalPlayed;
    final attackPower = math.min(avgGoals * 33, 100.0);

    // 3. 수비력 (100 - 평균 실점 * 33) - 실점이 적을수록 높음
    final avgConceded = stats.goals.goalsAgainst.total / totalPlayed;
    final defensePower = math.max(100 - (avgConceded * 33), 0.0);

    // 4. 클린시트 비율 (0-100)
    final cleanSheetRate = (stats.cleanSheet.total / totalPlayed) * 100;

    // 5. 홈 성적 (홈 승률 0-100)
    final homePlayed = stats.fixtures.played.home;
    final homeWinRate =
        homePlayed > 0 ? (stats.fixtures.wins.home / homePlayed) * 100 : 0.0;

    return [winRate, attackPower, defensePower, cleanSheetRate, homeWinRate];
  }

  Widget _buildRadarStatsDetail(
    BuildContext context,
    ApiFootballTeamSeasonStats? homeStats,
    ApiFootballTeamSeasonStats? awayStats,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final homePlayed = homeStats?.fixtures.played.total ?? 0;
    final awayPlayed = awayStats?.fixtures.played.total ?? 0;

    return Column(
      children: [
        const Divider(height: 24),
        _buildCompareRow(
          l10n.radarWinRate,
          homePlayed > 0
              ? '${((homeStats!.fixtures.wins.total / homePlayed) * 100).toStringAsFixed(1)}%'
              : '-',
          awayPlayed > 0
              ? '${((awayStats!.fixtures.wins.total / awayPlayed) * 100).toStringAsFixed(1)}%'
              : '-',
          homeBetter: homePlayed > 0 && awayPlayed > 0
              ? (homeStats!.fixtures.wins.total / homePlayed) >
                  (awayStats!.fixtures.wins.total / awayPlayed)
              : null,
        ),
        _buildCompareRow(
          l10n.avgGoalsFor,
          homePlayed > 0
              ? (homeStats!.goals.goalsFor.total / homePlayed)
                  .toStringAsFixed(2)
              : '-',
          awayPlayed > 0
              ? (awayStats!.goals.goalsFor.total / awayPlayed)
                  .toStringAsFixed(2)
              : '-',
          homeBetter: homePlayed > 0 && awayPlayed > 0
              ? (homeStats!.goals.goalsFor.total / homePlayed) >
                  (awayStats!.goals.goalsFor.total / awayPlayed)
              : null,
        ),
        _buildCompareRow(
          l10n.avgGoalsAgainst,
          homePlayed > 0
              ? (homeStats!.goals.goalsAgainst.total / homePlayed)
                  .toStringAsFixed(2)
              : '-',
          awayPlayed > 0
              ? (awayStats!.goals.goalsAgainst.total / awayPlayed)
                  .toStringAsFixed(2)
              : '-',
          homeBetter: homePlayed > 0 && awayPlayed > 0
              ? (homeStats!.goals.goalsAgainst.total / homePlayed) <
                  (awayStats!.goals.goalsAgainst.total / awayPlayed)
              : null,
        ),
        _buildCompareRow(
          l10n.cleanSheetLabel,
          '${homeStats?.cleanSheet.total ?? 0}',
          '${awayStats?.cleanSheet.total ?? 0}',
          homeBetter: (homeStats?.cleanSheet.total ?? 0) >
              (awayStats?.cleanSheet.total ?? 0),
        ),
        _buildCompareRow(
          l10n.failedToScoreLabel,
          '${homeStats?.failedToScore.total ?? 0}',
          '${awayStats?.failedToScore.total ?? 0}',
          homeBetter: (homeStats?.failedToScore.total ?? 0) <
              (awayStats?.failedToScore.total ?? 0),
        ),
      ],
    );
  }
}

// Providers for team comparison
final teamStandingProvider = FutureProvider.family<ApiFootballStanding?,
    ({int leagueId, int season, int teamId})>((ref, params) async {
  final service = ApiFootballService();
  final standings = await service.getStandings(params.leagueId, params.season);
  try {
    return standings.firstWhere((s) => s.teamId == params.teamId);
  } catch (_) {
    return null;
  }
});

final teamRecentFormProvider = FutureProvider.family<List<ApiFootballFixture>,
    ({int teamId, int last})>((ref, params) async {
  final service = ApiFootballService();
  return service.getTeamLastFixtures(params.teamId, count: params.last);
});

final teamSeasonStatsProvider = FutureProvider.family<
    ApiFootballTeamSeasonStats?,
    ({int teamId, int season, int leagueId})>((ref, params) async {
  final service = ApiFootballService();
  return service.getTeamStatistics(params.teamId, params.leagueId, params.season);
});

final leagueTopScorersProvider = FutureProvider.family<
    List<ApiFootballTopScorer>,
    ({int leagueId, int season})>((ref, params) async {
  final service = ApiFootballService();
  return service.getTopScorers(params.leagueId, params.season);
});

final leagueTopAssistsProvider = FutureProvider.family<
    List<ApiFootballTopScorer>,
    ({int leagueId, int season})>((ref, params) async {
  final service = ApiFootballService();
  return service.getTopAssists(params.leagueId, params.season);
});
