import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_football_ids.dart';
import '../../../core/services/api_football_service.dart';
import '../../../core/utils/error_helper.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/standings_provider.dart';
import '../../../l10n/app_localizations.dart';

class StandingsScreen extends ConsumerWidget {
  const StandingsScreen({super.key});

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _background = Color(0xFFF9FAFB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedLeague = ref.watch(selectedStandingsLeagueProvider);
    final selectedSeason = ref.watch(selectedSeasonProvider);
    final selectedTab = ref.watch(selectedStandingsTabProvider);
    final currentSeason = selectedSeason ?? getCurrentSeasonForLeague(selectedLeague);
    final standingsKey = StandingsKey(selectedLeague, currentSeason);
    final standingsAsync = ref.watch(leagueStandingsProvider(standingsKey));
    final topScorersAsync = ref.watch(topScorersProvider(standingsKey));
    final topAssistsAsync = ref.watch(topAssistsProvider(standingsKey));
    final isCup = isCupCompetition(selectedLeague);
    final availableSeasons = getAvailableSeasons(selectedLeague);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Column(
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        l10n.leagueStandings,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 국가별 리그 버튼
                    GestureDetector(
                      onTap: () => context.push('/leagues-by-country'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.public, size: 16, color: _primary),
                            const SizedBox(width: 4),
                            Text(
                              l10n.byCountry,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 본문
              Expanded(
                child: Column(
                  children: [
                    // League Filter - 탭바 스타일
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: LeagueIds.supportedLeagues.map((league) {
                            final isSelected = selectedLeague == league.id;
                            return GestureDetector(
                              onTap: () {
                                ref.read(selectedStandingsLeagueProvider.notifier).state = league.id;
                                ref.read(selectedSeasonProvider.notifier).state = null;
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? _primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  league.name,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : _textSecondary,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Season Selector - 알약 버튼 스타일
                    SizedBox(
                      height: 32,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: availableSeasons.map((season) {
                          final isSelected = season == currentSeason;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                ref.read(selectedSeasonProvider.notifier).state = season;
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? _primaryLight : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? _primary : _border,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  getSeasonDisplayName(season, selectedLeague),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? _primary : _textSecondary,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 탭 선택 (순위 | 득점 | 어시스트 | 통계)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        children: [
                          _TabButton(
                            label: l10n.rank,
                            isSelected: selectedTab == 0,
                            onTap: () => ref.read(selectedStandingsTabProvider.notifier).state = 0,
                          ),
                          _TabButton(
                            label: l10n.goals,
                            isSelected: selectedTab == 1,
                            onTap: () => ref.read(selectedStandingsTabProvider.notifier).state = 1,
                          ),
                          _TabButton(
                            label: l10n.assists,
                            isSelected: selectedTab == 2,
                            onTap: () => ref.read(selectedStandingsTabProvider.notifier).state = 2,
                          ),
                          _TabButton(
                            label: l10n.stats,
                            isSelected: selectedTab == 3,
                            onTap: () => ref.read(selectedStandingsTabProvider.notifier).state = 3,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 탭별 컨텐츠
                    Expanded(
                      child: selectedTab == 0
                          ? _buildStandingsContent(context, ref, standingsAsync, standingsKey, isCup, selectedLeague)
                          : selectedTab == 1
                              ? _buildTopScorersContent(context, ref, topScorersAsync, standingsKey)
                              : selectedTab == 2
                                  ? _buildTopAssistsContent(context, ref, topAssistsAsync, standingsKey)
                                  : _buildLeagueStatsContent(context, ref, standingsAsync, standingsKey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandingsContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ApiFootballStanding>> standingsAsync,
    StandingsKey standingsKey,
    bool isCup,
    int selectedLeague,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return standingsAsync.when(
      data: (standings) {
        if (standings.isEmpty) {
          if (isCup) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined, size: 64, color: Colors.amber.shade700),
                  const SizedBox(height: 16),
                  Text(
                    LeagueIds.getLeagueInfo(selectedLeague)?.name ?? l10n.competition,
                    style: AppTextStyles.subtitle1,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.seasonFormatChanged,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    l10n.standingsNotAvailable,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.checkScheduleTab,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.leaderboard_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(l10n.noStandingsInfo, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  l10n.cannotLoadStandings,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(leagueStandingsProvider(standingsKey));
          },
          child: Column(
            children: [
              _buildLeagueLegend(context, selectedLeague, standings),
              Expanded(
                child: _StandingsTable(standings: standings),
              ),
            ],
          ),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => ErrorState(
        message: ErrorHelper.getLocalizedErrorMessage(context, e),
        onRetry: () => ref.invalidate(leagueStandingsProvider(standingsKey)),
      ),
    );
  }

  Widget _buildTopScorersContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ApiFootballTopScorer>> topScorersAsync,
    StandingsKey standingsKey,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return topScorersAsync.when(
      data: (scorers) {
        if (scorers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(l10n.noGoalRankInfo, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(topScorersProvider(standingsKey));
          },
          child: _TopScorersTable(scorers: scorers, isGoals: true),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => ErrorState(
        message: ErrorHelper.getLocalizedErrorMessage(context, e),
        onRetry: () => ref.invalidate(topScorersProvider(standingsKey)),
      ),
    );
  }

  Widget _buildTopAssistsContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ApiFootballTopScorer>> topAssistsAsync,
    StandingsKey standingsKey,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return topAssistsAsync.when(
      data: (assists) {
        if (assists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.handshake_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(l10n.noAssistRankInfo, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(topAssistsProvider(standingsKey));
          },
          child: _TopScorersTable(scorers: assists, isGoals: false),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => ErrorState(
        message: ErrorHelper.getLocalizedErrorMessage(context, e),
        onRetry: () => ref.invalidate(topAssistsProvider(standingsKey)),
      ),
    );
  }

  Widget _buildLeagueStatsContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ApiFootballStanding>> standingsAsync,
    StandingsKey standingsKey,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final topYellowAsync = ref.watch(topYellowCardsProvider(standingsKey));
    final topRedAsync = ref.watch(topRedCardsProvider(standingsKey));

    return standingsAsync.when(
      data: (standings) {
        if (standings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 64, color: _textSecondary),
                const SizedBox(height: 16),
                Text(l10n.noLeagueStats, style: const TextStyle(color: _textSecondary)),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _LeagueOverviewCard(standings: standings),
              const SizedBox(height: 12),
              _RecentFormCard(standings: standings),
              const SizedBox(height: 12),
              _TopTeamsCard(standings: standings),
              const SizedBox(height: 12),
              _HomeAwayComparisonCard(standings: standings),
              const SizedBox(height: 12),
              _GoalStatsCard(standings: standings),
              const SizedBox(height: 12),
              _BottomTeamsCard(standings: standings),
              const SizedBox(height: 12),
              _TopCardsCard(
                topYellowAsync: topYellowAsync,
                topRedAsync: topRedAsync,
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(
        child: Text(ErrorHelper.getLocalizedErrorMessage(context, e), style: const TextStyle(color: _textSecondary)),
      ),
    );
  }

  Widget _buildLeagueLegend(BuildContext context, int leagueId, List<ApiFootballStanding> standings) {
    final l10n = AppLocalizations.of(context)!;
    final descriptions = standings
        .where((s) => s.description != null && s.description!.isNotEmpty)
        .map((s) => s.description!.toLowerCase())
        .toSet();

    final legendItems = <Widget>[];

    final hasUclDirect = descriptions.any((d) => d.contains('champions') && !d.contains('championship') && d.contains('1/8'));
    final hasUclPlayoff = descriptions.any((d) => d.contains('champions') && !d.contains('championship') && d.contains('1/16'));
    final hasUclQualification = descriptions.any((d) => d.contains('champions') && !d.contains('championship') && (d.contains('qualification') || d.contains('qualifying')));
    final hasUclGeneral = descriptions.any((d) => d.contains('champions') && !d.contains('championship') && !d.contains('1/8') && !d.contains('1/16') && !d.contains('qualification') && !d.contains('qualifying'));

    if (hasUclDirect) {
      legendItems.add(_LegendItem(color: Colors.blue.shade800, label: l10n.uclDirect));
    }
    if (hasUclPlayoff) {
      legendItems.add(_LegendItem(color: Colors.cyan.shade600, label: 'UCL PO'));
    }
    if (hasUclGeneral) {
      legendItems.add(_LegendItem(color: Colors.blue, label: 'UCL'));
    }
    if (hasUclQualification && !hasUclPlayoff) {
      legendItems.add(_LegendItem(color: Colors.cyan.shade600, label: l10n.uclQualification));
    }

    final hasUelDirect = descriptions.any((d) => d.contains('europa') && d.contains('1/8'));
    final hasUelPlayoff = descriptions.any((d) => d.contains('europa') && d.contains('1/16'));
    final hasUelGeneral = descriptions.any((d) => d.contains('europa') && !d.contains('1/8') && !d.contains('1/16') && !d.contains('qualification') && !d.contains('qualifying') && !d.contains('relegation'));

    if (hasUelDirect) {
      legendItems.add(_LegendItem(color: Colors.orange.shade800, label: l10n.uelDirect));
    }
    if (hasUelPlayoff) {
      legendItems.add(_LegendItem(color: Colors.amber.shade700, label: 'UEL PO'));
    }
    if (hasUelGeneral) {
      legendItems.add(_LegendItem(color: Colors.orange, label: 'UEL'));
    }

    if (descriptions.any((d) => d.contains('conference') && !d.contains('relegation'))) {
      legendItems.add(_LegendItem(color: Colors.green, label: 'UECL'));
    }

    final hasChampionshipRound = descriptions.any((d) => d.contains('championship round'));
    final hasRelegationRound = descriptions.any((d) => d.contains('relegation round'));
    final hasPromotion = descriptions.any((d) => d.contains('promotion') && !d.contains('champions') && !d.contains('europa') && !d.contains('conference'));
    final hasPromotionPlayoff = descriptions.any((d) => d.contains('promotion') && d.contains('playoff') && !d.contains('champions') && !d.contains('europa'));

    if (hasChampionshipRound) {
      legendItems.add(_LegendItem(color: Colors.blue, label: l10n.championship));
    }
    if (hasRelegationRound) {
      legendItems.add(_LegendItem(color: Colors.grey, label: l10n.lowerSplit));
    }
    if (hasPromotion && !hasPromotionPlayoff) {
      legendItems.add(_LegendItem(color: Colors.green, label: l10n.promotion));
    }
    if (hasPromotionPlayoff) {
      legendItems.add(_LegendItem(color: Colors.teal, label: l10n.promotionPlayoff));
    }

    if (descriptions.any((d) => d.contains('relegation') && !d.contains('europa') && !d.contains('conference') && !d.contains('round'))) {
      legendItems.add(_LegendItem(color: Colors.red, label: l10n.relegation));
    }

    if (legendItems.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: legendItems,
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const _primary = Color(0xFF2563EB);
  static const _textSecondary = Color(0xFF6B7280);

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? _primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : _textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TopScorersTable extends StatelessWidget {
  final List<ApiFootballTopScorer> scorers;
  final bool isGoals;

  const _TopScorersTable({required this.scorers, required this.isGoals});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(width: 28, child: Text(l10n.rankHeader, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.playerHeader, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                SizedBox(
                  width: 50,
                  child: Text(
                    l10n.appsHeader,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    isGoals ? l10n.goalsHeader : l10n.assistsHeader,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Rows
          ...scorers.asMap().entries.map((entry) => _TopScorerRow(
            rank: entry.key + 1,
            scorer: entry.value,
            isGoals: isGoals,
          )),
        ],
      ),
    );
  }
}

class _TopScorerRow extends StatelessWidget {
  final int rank;
  final ApiFootballTopScorer scorer;
  final bool isGoals;

  static const _primary = Color(0xFF2563EB);

  const _TopScorerRow({
    required this.rank,
    required this.scorer,
    required this.isGoals,
  });

  @override
  Widget build(BuildContext context) {
    Color rankColor = Colors.grey;
    Color? rowColor;

    if (rank == 1) {
      rankColor = Colors.amber.shade700;
      rowColor = Colors.amber.withValues(alpha: 0.08);
    } else if (rank == 2) {
      rankColor = Colors.grey.shade500;
      rowColor = Colors.grey.withValues(alpha: 0.05);
    } else if (rank == 3) {
      rankColor = Colors.brown.shade400;
      rowColor = Colors.brown.withValues(alpha: 0.05);
    }

    return InkWell(
      onTap: () => context.push('/player/${scorer.playerId}'),
      child: Container(
        color: rowColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Rank
            Container(
              width: 28,
              alignment: Alignment.center,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: rankColor,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Player Photo + Name + Team
            Expanded(
              child: Row(
                children: [
                  if (scorer.playerPhoto != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: scorer.playerPhoto!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, size: 20, color: Colors.grey),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, size: 20, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, size: 20, color: Colors.grey),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scorer.playerName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            if (scorer.teamLogo != null) ...[
                              CachedNetworkImage(
                                imageUrl: scorer.teamLogo!,
                                width: 14,
                                height: 14,
                                placeholder: (_, __) => const SizedBox(width: 14, height: 14),
                                errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 14, color: Colors.grey),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                scorer.teamName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Appearances
            SizedBox(
              width: 50,
              child: Text(
                '${scorer.appearances ?? 0}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),

            // Goals or Assists
            Container(
              width: 50,
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${isGoals ? (scorer.goals ?? 0) : (scorer.assists ?? 0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StandingsTable extends StatelessWidget {
  final List<ApiFootballStanding> standings;

  const _StandingsTable({required this.standings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(width: 28, child: Text(l10n.rankHeader, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.teamHeader, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                _HeaderCell(l10n.matchesHeader),
                _HeaderCell(l10n.wonHeader),
                _HeaderCell(l10n.drawnHeader),
                _HeaderCell(l10n.lostHeader),
                _HeaderCell(l10n.gfHeader),
                _HeaderCell(l10n.gaHeader),
                _HeaderCell(l10n.gdHeader),
                SizedBox(
                  width: 36,
                  child: Text(
                    l10n.ptsHeader,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Rows
          ...standings.map((standing) => _StandingRow(
            standing: standing,
            totalTeams: standings.length,
          )),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;

  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  final ApiFootballStanding standing;
  final int totalTeams;

  const _StandingRow({required this.standing, required this.totalTeams});

  @override
  Widget build(BuildContext context) {
    final desc = standing.description?.toLowerCase() ?? '';

    final isUclDirect = desc.contains('champions') && !desc.contains('championship') && desc.contains('1/8');
    final isUclPlayoff = desc.contains('champions') && !desc.contains('championship') && (desc.contains('qualifying') || desc.contains('qualification') || desc.contains('1/16'));
    final isUelDirect = desc.contains('europa') && desc.contains('1/8');
    final isUelPlayoff = desc.contains('europa') && (desc.contains('qualifying') || desc.contains('qualification') || desc.contains('1/16'));
    final isConferenceDirect = desc.contains('conference') && desc.contains('1/8');
    final isConferencePlayoff = desc.contains('conference') && (desc.contains('qualifying') || desc.contains('qualification') || desc.contains('1/16'));

    final isChampionshipRound = desc.contains('championship round');
    final isRelegationRound = desc.contains('relegation round');
    final isPromotion = desc.contains('promotion') && !desc.contains('champions') && !desc.contains('europa') && !desc.contains('conference');
    final isPromotionPlayoff = desc.contains('promotion') && desc.contains('playoff') && !desc.contains('champions') && !desc.contains('europa');

    final isRelegation = desc.contains('relegation') &&
        !desc.contains('playoff') && !desc.contains('europa') && !desc.contains('conference') && !desc.contains('round');
    final isRelegationPlayoff = (desc.contains('relegation') && desc.contains('playoff') && !desc.contains('round')) ||
        (desc.contains('bundesliga') && desc.contains('relegation'));

    final isChampionsLeague = desc.contains('champions') && !desc.contains('championship') &&
        !desc.contains('qualifying') && !desc.contains('qualification') && !desc.contains('1/8') && !desc.contains('1/16');
    final isEuropaLeague = desc.contains('europa') &&
        !desc.contains('qualifying') && !desc.contains('qualification') && !desc.contains('1/8') && !desc.contains('1/16') &&
        !desc.contains('relegation');
    final isConferenceLeague = desc.contains('conference') &&
        !desc.contains('qualifying') && !desc.contains('qualification') && !desc.contains('1/8') && !desc.contains('1/16') &&
        !desc.contains('relegation');
    final isToEuropa = desc.contains('relegation') && desc.contains('europa');
    final isToConference = desc.contains('relegation') && desc.contains('conference');

    Color? rowColor;
    Color rankColor = Colors.grey;

    if (isUclDirect) {
      rowColor = Colors.blue.shade800.withValues(alpha: 0.12);
      rankColor = Colors.blue.shade800;
    } else if (isUclPlayoff) {
      rowColor = Colors.cyan.shade300.withValues(alpha: 0.15);
      rankColor = Colors.cyan.shade600;
    } else if (isUelDirect) {
      rowColor = Colors.orange.shade800.withValues(alpha: 0.12);
      rankColor = Colors.orange.shade800;
    } else if (isUelPlayoff || isToEuropa) {
      rowColor = Colors.amber.shade300.withValues(alpha: 0.15);
      rankColor = Colors.amber.shade700;
    } else if (isConferenceDirect || isConferencePlayoff || isToConference) {
      rowColor = Colors.green.withValues(alpha: 0.08);
      rankColor = Colors.green;
    } else if (isChampionsLeague) {
      rowColor = Colors.blue.withValues(alpha: 0.08);
      rankColor = Colors.blue;
    } else if (isEuropaLeague) {
      rowColor = Colors.orange.withValues(alpha: 0.08);
      rankColor = Colors.orange;
    } else if (isConferenceLeague) {
      rowColor = Colors.green.withValues(alpha: 0.08);
      rankColor = Colors.green;
    } else if (isRelegationPlayoff || isRelegation) {
      rowColor = Colors.red.withValues(alpha: 0.08);
      rankColor = Colors.red;
    } else if (isChampionshipRound) {
      rowColor = Colors.blue.withValues(alpha: 0.08);
      rankColor = Colors.blue;
    } else if (isRelegationRound) {
      rowColor = Colors.grey.withValues(alpha: 0.08);
      rankColor = Colors.grey;
    } else if (isPromotion && !isPromotionPlayoff) {
      rowColor = Colors.green.withValues(alpha: 0.08);
      rankColor = Colors.green;
    } else if (isPromotionPlayoff) {
      rowColor = Colors.teal.withValues(alpha: 0.08);
      rankColor = Colors.teal;
    }

    return InkWell(
      onTap: () => context.push('/team/${standing.teamId}'),
      child: Container(
        color: rowColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
        children: [
          Container(
            width: 28,
            alignment: Alignment.center,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: rankColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                '${standing.rank}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: rankColor,
                ),
              ),
            ),
          ),

          Expanded(
            child: Row(
              children: [
                if (standing.teamLogo != null)
                  CachedNetworkImage(
                    imageUrl: standing.teamLogo!,
                    width: 24,
                    height: 24,
                    placeholder: (_, __) => const SizedBox(width: 24, height: 24),
                    errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 24, color: Colors.grey),
                  )
                else
                  const Icon(Icons.shield, size: 24, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    standing.teamName,
                    style: AppTextStyles.body2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          _StatCell('${standing.played}'),
          _StatCell('${standing.win}', color: Colors.green),
          _StatCell('${standing.draw}'),
          _StatCell('${standing.lose}', color: Colors.red),
          _StatCell('${standing.goalsFor}'),
          _StatCell('${standing.goalsAgainst}'),
          _StatCell(
            standing.goalsDiff >= 0 ? '+${standing.goalsDiff}' : '${standing.goalsDiff}',
            color: standing.goalsDiff > 0 ? Colors.green : (standing.goalsDiff < 0 ? Colors.red : null),
          ),

          Container(
            width: 36,
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${standing.points}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String text;
  final Color? color;

  const _StatCell(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// 최근 폼 카드
class _RecentFormCard extends StatelessWidget {
  final List<ApiFootballStanding> standings;

  static const _primary = Color(0xFF2563EB);
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);
  static const _error = Color(0xFFEF4444);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _RecentFormCard({required this.standings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final teamsWithForm = standings.where((s) => s.form != null && s.form!.isNotEmpty).toList();
    if (teamsWithForm.isEmpty) return const SizedBox.shrink();

    final topTeams = teamsWithForm.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.trending_up, color: _warning, size: 20),
              ),
              const SizedBox(width: 12),
              Text(l10n.recentFormTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary)),
              const Spacer(),
              Text(l10n.last5Matches, style: TextStyle(fontSize: 11, color: _textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          ...topTeams.map((team) => _buildFormRow(context, team)),
        ],
      ),
    );
  }

  Widget _buildFormRow(BuildContext context, ApiFootballStanding team) {
    final form = team.form ?? '';
    final formChars = form.split('').take(5).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.push('/team/${team.teamId}'),
        child: Row(
          children: [
            Container(
              width: 22, height: 22, alignment: Alignment.center,
              decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: Text('${team.rank}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _primary)),
            ),
            const SizedBox(width: 8),
            if (team.teamLogo != null)
              CachedNetworkImage(imageUrl: team.teamLogo!, width: 20, height: 20, errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 20)),
            const SizedBox(width: 8),
            Expanded(child: Text(team.teamName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Row(children: formChars.map((char) => _buildFormBadge(context, char)).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildFormBadge(BuildContext context, String result) {
    final l10n = AppLocalizations.of(context)!;
    Color bgColor;
    String label;
    switch (result.toUpperCase()) {
      case 'W': bgColor = _success; label = l10n.winShort; break;
      case 'D': bgColor = _textSecondary; label = l10n.drawShort; break;
      case 'L': bgColor = _error; label = l10n.lossShort; break;
      default: bgColor = Colors.grey.shade300; label = '-';
    }
    return Container(
      width: 22, height: 22, margin: const EdgeInsets.only(left: 3), alignment: Alignment.center,
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }
}

// 홈/원정 성적 비교 카드
class _HomeAwayComparisonCard extends StatelessWidget {
  final List<ApiFootballStanding> standings;

  static const _primary = Color(0xFF2563EB);
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _HomeAwayComparisonCard({required this.standings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final homeWinRateSorted = [...standings]..sort((a, b) {
      final aHomeGames = (a.homeWin ?? 0) + (a.homeDraw ?? 0) + (a.homeLose ?? 0);
      final bHomeGames = (b.homeWin ?? 0) + (b.homeDraw ?? 0) + (b.homeLose ?? 0);
      final aRate = aHomeGames > 0 ? (a.homeWin ?? 0) / aHomeGames : 0.0;
      final bRate = bHomeGames > 0 ? (b.homeWin ?? 0) / bHomeGames : 0.0;
      return bRate.compareTo(aRate);
    });

    final awayWinRateSorted = [...standings]..sort((a, b) {
      final aAwayGames = (a.awayWin ?? 0) + (a.awayDraw ?? 0) + (a.awayLose ?? 0);
      final bAwayGames = (b.awayWin ?? 0) + (b.awayDraw ?? 0) + (b.awayLose ?? 0);
      final aRate = aAwayGames > 0 ? (a.awayWin ?? 0) / aAwayGames : 0.0;
      final bRate = bAwayGames > 0 ? (b.awayWin ?? 0) / bAwayGames : 0.0;
      return bRate.compareTo(aRate);
    });

    final topHomeTeams = homeWinRateSorted.take(3).toList();
    final topAwayTeams = awayWinRateSorted.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.compare_arrows, color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(l10n.homeAwayStrong, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(Icons.home, size: 16, color: _success), const SizedBox(width: 4), Text(l10n.homeStrong, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _success))]),
                    const SizedBox(height: 10),
                    ...topHomeTeams.asMap().entries.map((entry) {
                      final team = entry.value;
                      final homeGames = (team.homeWin ?? 0) + (team.homeDraw ?? 0) + (team.homeLose ?? 0);
                      final winRate = homeGames > 0 ? ((team.homeWin ?? 0) / homeGames * 100).toInt() : 0;
                      return _buildCompactTeamRow(context, entry.key + 1, team, '$winRate%', _success);
                    }),
                  ],
                ),
              ),
              Container(width: 1, height: 120, color: _border, margin: const EdgeInsets.symmetric(horizontal: 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(Icons.flight, size: 16, color: _warning), const SizedBox(width: 4), Text(l10n.awayStrong, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _warning))]),
                    const SizedBox(height: 10),
                    ...topAwayTeams.asMap().entries.map((entry) {
                      final team = entry.value;
                      final awayGames = (team.awayWin ?? 0) + (team.awayDraw ?? 0) + (team.awayLose ?? 0);
                      final winRate = awayGames > 0 ? ((team.awayWin ?? 0) / awayGames * 100).toInt() : 0;
                      return _buildCompactTeamRow(context, entry.key + 1, team, '$winRate%', _warning);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTeamRow(BuildContext context, int rank, ApiFootballStanding team, String rate, Color color) {
    return InkWell(
      onTap: () => context.push('/team/${team.teamId}'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Text('$rank', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textSecondary)),
            const SizedBox(width: 6),
            if (team.teamLogo != null) CachedNetworkImage(imageUrl: team.teamLogo!, width: 18, height: 18, errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 18)),
            const SizedBox(width: 6),
            Expanded(child: Text(team.teamName, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(rate, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

// 하위 팀 분석 카드
class _BottomTeamsCard extends StatelessWidget {
  final List<ApiFootballStanding> standings;

  static const _error = Color(0xFFEF4444);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _BottomTeamsCard({required this.standings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sortedByLose = [...standings]..sort((a, b) => b.lose.compareTo(a.lose));
    final topLosers = sortedByLose.take(3).toList();

    final sortedByGoalsAgainst = [...standings]..sort((a, b) => b.goalsAgainst.compareTo(a.goalsAgainst));
    final topConceding = sortedByGoalsAgainst.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.trending_down, color: _error, size: 20),
              ),
              const SizedBox(width: 12),
              Text(l10n.bottomAnalysisTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.mostLossesLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textSecondary)),
                    const SizedBox(height: 10),
                    ...topLosers.asMap().entries.map((entry) => _buildBottomTeamRow(context, entry.key + 1, entry.value, l10n.lossesCount(entry.value.lose))),
                  ],
                ),
              ),
              Container(width: 1, height: 100, color: _border, margin: const EdgeInsets.symmetric(horizontal: 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.mostConcededLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textSecondary)),
                    const SizedBox(height: 10),
                    ...topConceding.asMap().entries.map((entry) => _buildBottomTeamRow(context, entry.key + 1, entry.value, l10n.concededCount(entry.value.goalsAgainst))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTeamRow(BuildContext context, int rank, ApiFootballStanding team, String stat) {
    return InkWell(
      onTap: () => context.push('/team/${team.teamId}'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Text('$rank', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textSecondary)),
            const SizedBox(width: 6),
            if (team.teamLogo != null) CachedNetworkImage(imageUrl: team.teamLogo!, width: 18, height: 18, errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 18)),
            const SizedBox(width: 6),
            Expanded(child: Text(team.teamName, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: _error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(stat, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _error)),
            ),
          ],
        ),
      ),
    );
  }
}

// 리그 개요 카드
class _LeagueOverviewCard extends StatelessWidget {
  final List<ApiFootballStanding> standings;

  static const _primary = Color(0xFF2563EB);
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);
  static const _textPrimary = Color(0xFF111827);
  static const _border = Color(0xFFE5E7EB);

  const _LeagueOverviewCard({required this.standings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    int totalMatches = 0;
    int totalGoals = 0;
    int totalHomeWins = 0;
    int totalAwayWins = 0;
    int totalDraws = 0;

    for (final team in standings) {
      totalMatches += team.played;
      totalGoals += team.goalsFor;
    }

    final matchesPlayed = totalMatches ~/ 2;
    final goalsPerMatch = matchesPlayed > 0 ? totalGoals / matchesPlayed : 0.0;

    for (final team in standings) {
      totalHomeWins += team.homeWin ?? 0;
      totalAwayWins += team.awayWin ?? 0;
      totalDraws += team.draw;
    }
    totalDraws = totalDraws ~/ 2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.analytics, color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.leagueOverviewTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _OverviewStatBox(
                icon: Icons.sports_soccer,
                label: l10n.totalGoalsLabel,
                value: '$totalGoals',
                color: _success,
              ),
              const SizedBox(width: 12),
              _OverviewStatBox(
                icon: Icons.speed,
                label: l10n.goalsPerGameLabel,
                value: goalsPerMatch.toStringAsFixed(2),
                color: _primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _OverviewStatBox(
                icon: Icons.home,
                label: l10n.homeWinsLabel,
                value: '$totalHomeWins',
                color: _success,
              ),
              const SizedBox(width: 12),
              _OverviewStatBox(
                icon: Icons.flight,
                label: l10n.awayWinsLabel,
                value: '$totalAwayWins',
                color: _warning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.homeWinShort, style: TextStyle(fontSize: 12, color: _success, fontWeight: FontWeight.w600)),
                    Text(l10n.draw, style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                    Text(l10n.awayWinShort, style: TextStyle(fontSize: 12, color: _warning, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: totalHomeWins > 0 ? totalHomeWins : 1,
                        child: Container(height: 8, color: _success),
                      ),
                      Expanded(
                        flex: totalDraws > 0 ? totalDraws : 1,
                        child: Container(height: 8, color: Colors.grey.shade400),
                      ),
                      Expanded(
                        flex: totalAwayWins > 0 ? totalAwayWins : 1,
                        child: Container(height: 8, color: _warning),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.gamesCount(totalHomeWins), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    Text(l10n.gamesCount(totalDraws), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    Text(l10n.gamesCount(totalAwayWins), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _OverviewStatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: color.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 상위 팀 카드
class _TopTeamsCard extends StatelessWidget {
  final List<ApiFootballStanding> standings;

  static const _primary = Color(0xFF2563EB);
  static const _success = Color(0xFF10B981);
  static const _error = Color(0xFFEF4444);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _TopTeamsCard({required this.standings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topScorer = standings.reduce((a, b) => a.goalsFor > b.goalsFor ? a : b);
    final topConceder = standings.reduce((a, b) => a.goalsAgainst > b.goalsAgainst ? a : b);
    final topWinner = standings.reduce((a, b) => a.win > b.win ? a : b);
    final topDrawer = standings.reduce((a, b) => a.draw > b.draw ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.emoji_events, color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.teamRanking,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TeamStatRow(
            icon: Icons.sports_soccer,
            label: l10n.mostGoals,
            team: topScorer,
            value: l10n.nGoals(topScorer.goalsFor),
            color: _success,
          ),
          _TeamStatRow(
            icon: Icons.gpp_bad,
            label: l10n.mostConcededGoals,
            team: topConceder,
            value: l10n.nGoals(topConceder.goalsAgainst),
            color: _error,
          ),
          _TeamStatRow(
            icon: Icons.military_tech,
            label: l10n.mostWins,
            team: topWinner,
            value: l10n.nWins(topWinner.win),
            color: _primary,
          ),
          _TeamStatRow(
            icon: Icons.balance,
            label: l10n.mostDraws,
            team: topDrawer,
            value: l10n.nDraws(topDrawer.draw),
            color: _textSecondary,
          ),
        ],
      ),
    );
  }
}

class _TeamStatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final ApiFootballStanding team;
  final String value;
  final Color color;

  static const _textSecondary = Color(0xFF6B7280);

  const _TeamStatRow({
    required this.icon,
    required this.label,
    required this.team,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: _textSecondary),
            ),
          ),
          if (team.teamLogo != null)
            CachedNetworkImage(
              imageUrl: team.teamLogo!,
              width: 20,
              height: 20,
              errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 20),
            ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              team.teamName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 골 통계 카드
class _GoalStatsCard extends StatelessWidget {
  final List<ApiFootballStanding> standings;

  static const _primary = Color(0xFF2563EB);
  static const _success = Color(0xFF10B981);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _GoalStatsCard({required this.standings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    int totalHomeGoals = 0;
    int totalAwayGoals = 0;

    for (final team in standings) {
      totalHomeGoals += team.homeGoalsFor ?? 0;
      totalAwayGoals += team.awayGoalsFor ?? 0;
    }

    final sortedByGD = [...standings]..sort((a, b) => b.goalsDiff.compareTo(a.goalsDiff));
    final topGDTeams = sortedByGD.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.sports_soccer, color: _success, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.goalAnalysis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.homeGoals, style: TextStyle(fontSize: 12, color: _textSecondary)),
                        Text('$totalHomeGoals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _primary)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        l10n.nGoals(totalHomeGoals + totalAwayGoals),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textPrimary),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(l10n.awayGoals, style: TextStyle(fontSize: 12, color: _textSecondary)),
                        Text('$totalAwayGoals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _success)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: totalHomeGoals > 0 ? totalHomeGoals : 1,
                        child: Container(height: 8, color: _primary),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: totalAwayGoals > 0 ? totalAwayGoals : 1,
                        child: Container(height: 8, color: _success),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.top5GD,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary),
          ),
          const SizedBox(height: 12),
          ...topGDTeams.asMap().entries.map((entry) {
            final index = entry.key;
            final team = entry.value;
            final maxGD = topGDTeams.first.goalsDiff;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: index == 0 ? _primary : _textSecondary,
                      ),
                    ),
                  ),
                  if (team.teamLogo != null)
                    CachedNetworkImage(
                      imageUrl: team.teamLogo!,
                      width: 18,
                      height: 18,
                      errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 18),
                    ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: Text(
                      team.teamName,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: maxGD > 0 ? team.goalsDiff / maxGD : 0,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          team.goalsDiff > 0 ? _success : Colors.grey,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text(
                      team.goalsDiff >= 0 ? '+${team.goalsDiff}' : '${team.goalsDiff}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: team.goalsDiff > 0 ? _success : _textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// 최다 경고/퇴장 카드
class _TopCardsCard extends StatelessWidget {
  final AsyncValue<List<ApiFootballTopScorer>> topYellowAsync;
  final AsyncValue<List<ApiFootballTopScorer>> topRedAsync;

  static const _warning = Color(0xFFF59E0B);
  static const _error = Color(0xFFEF4444);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _TopCardsCard({
    required this.topYellowAsync,
    required this.topRedAsync,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.style, color: _warning, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.cardRanking,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 최다 경고
          _buildCardSection(
            context: context,
            title: l10n.mostYellows,
            icon: Icons.square,
            color: _warning,
            asyncData: topYellowAsync,
            isYellow: true,
          ),
          const SizedBox(height: 16),
          // 최다 퇴장
          _buildCardSection(
            context: context,
            title: l10n.mostReds,
            icon: Icons.square,
            color: _error,
            asyncData: topRedAsync,
            isYellow: false,
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required AsyncValue<List<ApiFootballTopScorer>> asyncData,
    required bool isYellow,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        asyncData.when(
          data: (players) {
            final l10n = AppLocalizations.of(context)!;
            if (players.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.noData,
                  style: TextStyle(fontSize: 12, color: _textSecondary),
                ),
              );
            }
            final top5 = players.take(5).toList();
            return Column(
              children: top5.asMap().entries.map((entry) {
                final index = entry.key;
                final player = entry.value;
                final cardCount = isYellow
                    ? (player.yellowCards ?? 0)
                    : (player.redCards ?? 0);

                return InkWell(
                  onTap: () => context.push('/player/${player.playerId}'),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: index == 0 ? color : _textSecondary,
                            ),
                          ),
                        ),
                        if (player.playerPhoto != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: player.playerPhoto!,
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.person, size: 14, color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person, size: 14, color: Colors.grey),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                player.playerName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  if (player.teamLogo != null) ...[
                                    CachedNetworkImage(
                                      imageUrl: player.teamLogo!,
                                      width: 12,
                                      height: 12,
                                      errorWidget: (_, __, ___) =>
                                          const Icon(Icons.shield, size: 12),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Expanded(
                                    child: Text(
                                      player.teamName,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$cardCount',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (e, _) {
            final l10n = AppLocalizations.of(context)!;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.loadFailed,
                style: TextStyle(fontSize: 12, color: _textSecondary),
              ),
            );
          },
        ),
      ],
    );
  }
}
