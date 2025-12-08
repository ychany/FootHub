import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/sports_db_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/standings_provider.dart';

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
    final selectedLeague = ref.watch(selectedStandingsLeagueProvider);
    final selectedSeason = ref.watch(selectedSeasonProvider);
    final currentSeason = selectedSeason ?? getSeasonForLeague(selectedLeague);
    final standingsKey = StandingsKey(selectedLeague, currentSeason);
    final standingsAsync = ref.watch(leagueStandingsProvider(standingsKey));
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
                    const Text(
                      '리그 순위',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
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
                          children: AppConstants.leaguesWithStandings.map((league) {
                            final isSelected = selectedLeague == league;
                            return GestureDetector(
                              onTap: () {
                                ref.read(selectedStandingsLeagueProvider.notifier).state = league;
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
                                  AppConstants.getLeagueDisplayName(league),
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
                                  getSeasonDisplayName(season),
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

                    // Standings Table
                    Expanded(
                      child: standingsAsync.when(
                        data: (standings) {
                          if (standings.isEmpty) {
                            // UCL/UEL 등 컵 대회는 별도 안내
                            if (isCup) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.emoji_events_outlined, size: 64, color: Colors.amber.shade700),
                                    const SizedBox(height: 16),
                                    Text(
                                      AppConstants.getLeagueDisplayName(selectedLeague),
                                      style: AppTextStyles.subtitle1,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '2024-25 시즌부터 새 리그 형식으로 변경되어',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    const Text(
                                      '순위표가 아직 제공되지 않습니다',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      '일정 탭에서 경기 일정을 확인하세요',
                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // K리그 미지원 안내
                            if (selectedLeague == 'Korean K League 1') {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.sports_soccer, size: 64, color: Colors.green.shade700),
                                    const SizedBox(height: 16),
                                    Text(
                                      AppConstants.getLeagueDisplayName(selectedLeague),
                                      style: AppTextStyles.subtitle1,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'K리그 순위표는 현재 API에서 지원하지 않습니다',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      '일정 탭에서 경기 일정을 확인하세요',
                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.leaderboard_outlined, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('순위 정보가 없습니다', style: TextStyle(color: Colors.grey)),
                                  SizedBox(height: 8),
                                  Text(
                                    '해당 리그의 순위 정보를 불러올 수 없습니다',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: () async {
                              ref.invalidate(leagueStandingsProvider(standingsKey));
                            },
                            child: _StandingsTable(standings: standings),
                          );
                        },
                        loading: () => const LoadingIndicator(),
                        error: (e, _) => ErrorState(
                          message: e.toString(),
                          onRetry: () => ref.invalidate(leagueStandingsProvider(standingsKey)),
                        ),
                      ),
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
}

class _StandingsTable extends StatelessWidget {
  final List<SportsDbStanding> standings;

  const _StandingsTable({required this.standings});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const SizedBox(width: 28, child: Text('순위', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                const SizedBox(width: 8),
                const Expanded(child: Text('팀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                _HeaderCell('경기'),
                _HeaderCell('승'),
                _HeaderCell('무'),
                _HeaderCell('패'),
                _HeaderCell('득점'),
                _HeaderCell('실점'),
                _HeaderCell('득실'),
                SizedBox(
                  width: 36,
                  child: Text(
                    '승점',
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
  final SportsDbStanding standing;
  final int totalTeams;

  const _StandingRow({required this.standing, required this.totalTeams});

  @override
  Widget build(BuildContext context) {
    // description 기반으로 색상 결정
    final isChampionsLeague = standing.description?.toLowerCase().contains('champions') ?? false;
    final isEuropaLeague = standing.description?.toLowerCase().contains('europa') ?? false;
    final isConferenceLeague = standing.description?.toLowerCase().contains('conference') ?? false;
    final isRelegation = standing.description?.toLowerCase().contains('relegation') ?? false;

    Color? rowColor;
    Color rankColor = Colors.grey;

    if (isChampionsLeague) {
      rowColor = Colors.blue.withValues(alpha: 0.05);
      rankColor = Colors.blue;
    } else if (isEuropaLeague) {
      rowColor = Colors.orange.withValues(alpha: 0.05);
      rankColor = Colors.orange;
    } else if (isConferenceLeague) {
      rowColor = Colors.green.withValues(alpha: 0.05);
      rankColor = Colors.green;
    } else if (isRelegation || standing.rank > totalTeams - 3) {
      rowColor = Colors.red.withValues(alpha: 0.05);
      rankColor = Colors.red;
    }

    return InkWell(
      onTap: standing.teamId != null
          ? () => context.push('/team/${standing.teamId}')
          : null,
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
                '${standing.rank}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: rankColor,
                ),
              ),
            ),
          ),

          // Team Badge + Name
          Expanded(
            child: Row(
              children: [
                if (standing.teamBadge != null)
                  CachedNetworkImage(
                    imageUrl: standing.teamBadge!,
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
                    standing.teamName ?? '-',
                    style: AppTextStyles.body2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Stats
          _StatCell('${standing.played}'),
          _StatCell('${standing.wins}', color: Colors.green),
          _StatCell('${standing.draws}'),
          _StatCell('${standing.losses}', color: Colors.red),
          _StatCell('${standing.goalsFor}'),
          _StatCell('${standing.goalsAgainst}'),
          _StatCell(
            standing.goalDifference >= 0 ? '+${standing.goalDifference}' : '${standing.goalDifference}',
            color: standing.goalDifference > 0 ? Colors.green : (standing.goalDifference < 0 ? Colors.red : null),
          ),

          // Points
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
