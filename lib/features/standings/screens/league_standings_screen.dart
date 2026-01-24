import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_football_service.dart';
import '../../../core/utils/error_helper.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/banner_ad_widget.dart';
import '../providers/standings_provider.dart';
import '../../../l10n/app_localizations.dart';

// League info provider
final leagueInfoProvider = FutureProvider.family<ApiFootballLeague?, int>((ref, leagueId) async {
  final service = ApiFootballService();
  final leagues = await service.getLeagueById(leagueId);
  return leagues;
});

// League standings provider for specific league
final externalLeagueStandingsProvider = FutureProvider.family<List<ApiFootballStanding>, StandingsKey>((ref, key) async {
  final service = ApiFootballService();
  return service.getStandings(key.leagueId, key.season);
});

class LeagueStandingsScreen extends ConsumerStatefulWidget {
  final String leagueId;

  const LeagueStandingsScreen({super.key, required this.leagueId});

  @override
  ConsumerState<LeagueStandingsScreen> createState() => _LeagueStandingsScreenState();
}

class _LeagueStandingsScreenState extends ConsumerState<LeagueStandingsScreen> {
  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _background = Color(0xFFF9FAFB);

  int? _selectedSeason;
  int _selectedTab = 0; // 0: 순위, 1: 득점, 2: 어시스트

  int get _leagueIdInt => int.tryParse(widget.leagueId) ?? 0;

  int get _currentSeason {
    if (_selectedSeason != null) return _selectedSeason!;
    return getCurrentSeasonForLeague(_leagueIdInt);
  }

  List<int> get _availableSeasons => getAvailableSeasons(_leagueIdInt);

  @override
  Widget build(BuildContext context) {
    final leagueId = _leagueIdInt;
    final l10n = AppLocalizations.of(context)!;
    if (leagueId == 0) {
      return Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, null),
              Expanded(
                child: Center(
                  child: Text(l10n.invalidLeagueId),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final leagueAsync = ref.watch(leagueInfoProvider(leagueId));
    final standingsKey = StandingsKey(leagueId, _currentSeason);
    final standingsAsync = ref.watch(externalLeagueStandingsProvider(standingsKey));
    final topScorersAsync = ref.watch(topScorersProvider(standingsKey));
    final topAssistsAsync = ref.watch(topAssistsProvider(standingsKey));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _background,
        bottomNavigationBar: const BottomBannerAdWidget(),
        body: SafeArea(
          child: Column(
            children: [
              // Header with league info
              leagueAsync.when(
                data: (league) => _buildHeader(context, league),
                loading: () => _buildAppBar(context, null),
                error: (_, __) => _buildAppBar(context, null),
              ),

              // Season selector
              _buildSeasonSelector(),

              const SizedBox(height: 12),

              // Tab selector
              _buildTabSelector(),

              const SizedBox(height: 12),

              // Content
              Expanded(
                child: _selectedTab == 0
                    ? _buildStandingsContent(standingsAsync, standingsKey)
                    : _selectedTab == 1
                        ? _buildTopScorersContent(topScorersAsync, standingsKey)
                        : _selectedTab == 2
                            ? _buildTopAssistsContent(topAssistsAsync, standingsKey)
                            : _buildLeagueStatsContent(standingsAsync),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ApiFootballLeague? league) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            color: _textPrimary,
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Builder(
              builder: (context) => Text(
                league?.name ?? AppLocalizations.of(context)!.leagueStandings,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ApiFootballLeague? league) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // App bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  color: _textPrimary,
                  onPressed: () => context.pop(),
                ),
                if (league?.logo != null) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _border),
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: league!.logo!,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Icon(Icons.emoji_events, size: 18),
                        errorWidget: (_, __, ___) => const Icon(Icons.emoji_events, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Builder(
                    builder: (context) => Text(
                      league?.name ?? AppLocalizations.of(context)!.leagueStandings,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (league?.countryName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      league!.countryName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonSelector() {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _availableSeasons.map((season) {
          final isSelected = season == _currentSeason;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSeason = season;
                });
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
                  getSeasonDisplayName(season, _leagueIdInt),
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
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return Row(
            children: [
              _buildTabButton(l10n.standingsTab, 0),
              _buildTabButton(l10n.scorersTab, 1),
              _buildTabButton(l10n.assistsTab, 2),
              _buildTabButton(l10n.statsTab, 3),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
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

  Widget _buildStandingsContent(
    AsyncValue<List<ApiFootballStanding>> standingsAsync,
    StandingsKey standingsKey,
  ) {
    // 조별리그 여부 확인
    final isGroupStageAsync = ref.watch(isGroupStageProvider(standingsKey));

    return isGroupStageAsync.when(
      data: (isGroupStage) {
        if (isGroupStage) {
          // 조별리그인 경우 그룹별로 표시
          return _buildGroupedStandingsContent(standingsKey);
        } else {
          // 단일 리그인 경우 기존 테이블 표시
          return _buildSingleStandingsContent(standingsAsync, standingsKey);
        }
      },
      loading: () => const LoadingIndicator(),
      error: (_, __) => _buildSingleStandingsContent(standingsAsync, standingsKey),
    );
  }

  Widget _buildSingleStandingsContent(
    AsyncValue<List<ApiFootballStanding>> standingsAsync,
    StandingsKey standingsKey,
  ) {
    return standingsAsync.when(
      data: (standings) {
        if (standings.isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.leaderboard_outlined, size: 64, color: _textSecondary),
                const SizedBox(height: 16),
                Text(l10n.noStandingsData, style: const TextStyle(color: _textSecondary)),
                const SizedBox(height: 8),
                Text(
                  l10n.cannotLoadStandingsForSeason,
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(externalLeagueStandingsProvider(standingsKey));
          },
          child: _StandingsTable(standings: standings),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => ErrorState(
        message: ErrorHelper.getLocalizedErrorMessage(context, e),
        onRetry: () => ref.invalidate(externalLeagueStandingsProvider(standingsKey)),
      ),
    );
  }

  Widget _buildGroupedStandingsContent(StandingsKey standingsKey) {
    final groupedAsync = ref.watch(leagueStandingsGroupedProvider(standingsKey));

    return groupedAsync.when(
      data: (groupedStandings) {
        if (groupedStandings.isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.leaderboard_outlined, size: 64, color: _textSecondary),
                const SizedBox(height: 16),
                Text(l10n.noStandingsData, style: const TextStyle(color: _textSecondary)),
              ],
            ),
          );
        }

        // 그룹 이름으로 정렬 (A조, B조, C조...)
        final sortedGroups = groupedStandings.keys.toList()
          ..sort((a, b) => a.compareTo(b));

        // 범례를 위해 모든 standings 합치기
        final allStandings = groupedStandings.values.expand((e) => e).toList();

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(leagueStandingsGroupedProvider(standingsKey));
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 범례
                _buildLeagueLegend(allStandings),
                const SizedBox(height: 12),
                // 그룹별 순위표
                ...sortedGroups.map((groupName) {
                  final standings = groupedStandings[groupName]!;
                  return _buildGroupCard(groupName, standings);
                }),
              ],
            ),
          ),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => ErrorState(
        message: ErrorHelper.getLocalizedErrorMessage(context, e),
        onRetry: () => ref.invalidate(leagueStandingsGroupedProvider(standingsKey)),
      ),
    );
  }

  Widget _buildGroupCard(String groupName, List<ApiFootballStanding> standings) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // 그룹 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    groupName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 테이블 헤더
          _buildCompactTableHeader(),
          // 팀 행들
          ...standings.map((standing) => _buildCompactStandingRow(standing)),
        ],
      ),
    );
  }

  Widget _buildCompactTableHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 28, child: _buildCompactHeaderCell(l10n.rankColumn)),
          const SizedBox(width: 4),
          Expanded(child: Text(l10n.teamColumn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
          _buildCompactHeaderCell(l10n.matchesColumn),
          _buildCompactHeaderCell(l10n.winColumn),
          _buildCompactHeaderCell(l10n.drawColumn),
          _buildCompactHeaderCell(l10n.loseColumn),
          _buildCompactHeaderCell(l10n.goalDiffColumn),
          SizedBox(
            width: 30,
            child: Text(l10n.pointsColumn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeaderCell(String text) {
    return SizedBox(
      width: 24,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center),
    );
  }

  Widget _buildCompactStandingRow(ApiFootballStanding standing) {
    final desc = standing.description?.toLowerCase() ?? '';
    final rankColor = _getGroupRankColor(standing.rank, desc);
    final rowColor = _getRowColor(desc);

    return InkWell(
      onTap: () => context.push('/team/${standing.teamId}'),
      child: Container(
        color: rowColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: rankColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                '${standing.rank}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: rankColor),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Row(
                children: [
                  if (standing.teamLogo != null)
                    CachedNetworkImage(
                      imageUrl: standing.teamLogo!,
                      width: 20,
                      height: 20,
                      placeholder: (_, __) => const SizedBox(width: 20, height: 20),
                      errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 20, color: Colors.grey),
                    )
                  else
                    const Icon(Icons.shield, size: 20, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      standing.teamName,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            _buildCompactStatCell('${standing.played}'),
            _buildCompactStatCell('${standing.win}', color: Colors.green),
            _buildCompactStatCell('${standing.draw}'),
            _buildCompactStatCell('${standing.lose}', color: Colors.red),
            _buildCompactStatCell(
              standing.goalsDiff >= 0 ? '+${standing.goalsDiff}' : '${standing.goalsDiff}',
              color: standing.goalsDiff > 0 ? Colors.green : (standing.goalsDiff < 0 ? Colors.red : null),
            ),
            Container(
              width: 30,
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${standing.points}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _primary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStatCell(String text, {Color? color}) {
    return SizedBox(
      width: 24,
      child: Text(text, style: TextStyle(fontSize: 11, color: color), textAlign: TextAlign.center),
    );
  }

  Color _getGroupRankColor(int rank, String desc) {
    // UCL/UEL/UECL 리그 페이즈 순위 색상
    final isR16 = desc.contains('1/8') || desc.contains('round of 16');
    final isPlayoff = desc.contains('1/16') || desc.contains('playoff') || desc.contains('play-off');
    final isEliminated = desc.contains('elimination');
    final isQualified = desc.contains('qualification') || desc.contains('knockout') || desc.contains('next round');

    if (isR16) return Colors.blue.shade800;
    if (isPlayoff) return Colors.cyan.shade600;
    if (isEliminated) return Colors.red;
    if (isQualified) return Colors.green;

    // 조별리그에서 1, 2위는 16강 진출
    if (rank <= 2) return Colors.green;
    return Colors.grey;
  }

  Color? _getRowColor(String desc) {
    final isR16 = desc.contains('1/8') || desc.contains('round of 16');
    final isPlayoff = desc.contains('1/16') || desc.contains('playoff') || desc.contains('play-off');
    final isEliminated = desc.contains('elimination');
    final isQualified = desc.contains('qualification') || desc.contains('knockout') || desc.contains('next round');

    if (isR16) return Colors.blue.shade800.withValues(alpha: 0.12);
    if (isPlayoff) return Colors.cyan.shade300.withValues(alpha: 0.15);
    if (isEliminated) return Colors.red.withValues(alpha: 0.08);
    if (isQualified) return Colors.green.withValues(alpha: 0.1);

    return null;
  }

  Widget _buildLeagueLegend(List<ApiFootballStanding> standings) {
    final l10n = AppLocalizations.of(context)!;
    final legendItems = <Widget>[];

    // 모든 description 수집
    final descriptions = standings.map((s) => s.description?.toLowerCase() ?? '').toSet();

    // UCL/UEL/UECL 리그 페이즈 (36팀 단일 리그)
    final hasR16 = descriptions.any((d) => d.contains('1/8') || d.contains('round of 16'));
    final hasPlayoff = descriptions.any((d) => d.contains('1/16') || d.contains('playoff') || d.contains('play-off'));
    final hasElimination = descriptions.any((d) => d.contains('elimination'));

    // 조별리그 (유로, 월드컵 등 - 진출/탈락)
    final hasQualification = descriptions.any((d) =>
        d.contains('qualification') || d.contains('knockout') || d.contains('next round'));

    if (hasR16) {
      legendItems.add(_buildLegendItem(Colors.blue.shade800, l10n.roundOf16));
    }
    if (hasPlayoff) {
      legendItems.add(_buildLegendItem(Colors.cyan.shade600, l10n.playoffLabel));
    }
    if (hasElimination) {
      legendItems.add(_buildLegendItem(Colors.red, l10n.relegation));
    }
    if (hasQualification && !hasR16 && !hasPlayoff) {
      // 조별리그 진출 (녹색)
      legendItems.add(_buildLegendItem(Colors.green, l10n.advanceLabel));
    }

    if (legendItems.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: legendItems,
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildTopScorersContent(
    AsyncValue<List<ApiFootballTopScorer>> topScorersAsync,
    StandingsKey standingsKey,
  ) {
    return topScorersAsync.when(
      data: (scorers) {
        if (scorers.isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_soccer, size: 64, color: _textSecondary),
                const SizedBox(height: 16),
                Text(l10n.noGoalRankData, style: const TextStyle(color: _textSecondary)),
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
    AsyncValue<List<ApiFootballTopScorer>> topAssistsAsync,
    StandingsKey standingsKey,
  ) {
    return topAssistsAsync.when(
      data: (assists) {
        if (assists.isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.handshake_outlined, size: 64, color: _textSecondary),
                const SizedBox(height: 16),
                Text(l10n.noAssistRankData, style: const TextStyle(color: _textSecondary)),
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
    AsyncValue<List<ApiFootballStanding>> standingsAsync,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return standingsAsync.when(
      data: (standings) {
        if (standings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 64, color: _textSecondary),
                const SizedBox(height: 16),
                Text(l10n.noLeagueStatsData, style: const TextStyle(color: _textSecondary)),
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
              _TopTeamsCard(standings: standings),
              const SizedBox(height: 12),
              _GoalStatsCard(standings: standings),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(
        child: Text(ErrorHelper.getLocalizedErrorMessage(context, e), style: TextStyle(color: _textSecondary)),
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
    // 리그 전체 통계 계산
    int totalMatches = 0;
    int totalGoals = 0;
    int totalHomeWins = 0;
    int totalAwayWins = 0;
    int totalDraws = 0;

    for (final team in standings) {
      totalMatches += team.played;
      totalGoals += team.goalsFor;
    }

    // 경기당 골 수 계산 (각 경기는 두 팀이 참여하므로 /2)
    final matchesPlayed = totalMatches ~/ 2;
    final goalsPerMatch = matchesPlayed > 0 ? totalGoals / matchesPlayed : 0.0;

    // 홈/어웨이 승리 및 무승부 계산
    for (final team in standings) {
      totalHomeWins += team.homeWin ?? 0;
      totalAwayWins += team.awayWin ?? 0;
      totalDraws += team.draw;
    }
    // 무승부는 양 팀에 기록되므로 /2
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
                l10n.leagueOverviewCard,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 주요 통계 그리드
          Row(
            children: [
              _OverviewStatBox(
                icon: Icons.sports_soccer,
                label: l10n.totalGoals,
                value: '$totalGoals',
                color: _success,
              ),
              const SizedBox(width: 12),
              _OverviewStatBox(
                icon: Icons.speed,
                label: l10n.goalsPerGame,
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
                label: l10n.homeWins,
                value: '$totalHomeWins',
                color: _success,
              ),
              const SizedBox(width: 12),
              _OverviewStatBox(
                icon: Icons.flight,
                label: l10n.awayWins,
                value: '$totalAwayWins',
                color: _warning,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 승/무/패 비율 바
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
                    Text(l10n.homeWin, style: TextStyle(fontSize: 12, color: _success, fontWeight: FontWeight.w600)),
                    Text(l10n.drawLabel, style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                    Text(l10n.awayWin, style: TextStyle(fontSize: 12, color: _warning, fontWeight: FontWeight.w600)),
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
                    Text(l10n.nGamesLabel(totalHomeWins), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    Text(l10n.nGamesLabel(totalDraws), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    Text(l10n.nGamesLabel(totalAwayWins), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
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
    // 최다 득점 팀
    final topScorer = standings.reduce((a, b) => a.goalsFor > b.goalsFor ? a : b);
    // 최다 실점 팀
    final topConceder = standings.reduce((a, b) => a.goalsAgainst > b.goalsAgainst ? a : b);
    // 최다 승리 팀
    final topWinner = standings.reduce((a, b) => a.win > b.win ? a : b);
    // 최다 무승부 팀
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
                l10n.teamRankingCard,
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
            label: l10n.mostScoringTeam,
            team: topScorer,
            value: l10n.nGoalsLabel(topScorer.goalsFor),
            color: _success,
          ),
          _TeamStatRow(
            icon: Icons.gpp_bad,
            label: l10n.mostConcededTeam,
            team: topConceder,
            value: l10n.nGoalsLabel(topConceder.goalsAgainst),
            color: _error,
          ),
          _TeamStatRow(
            icon: Icons.military_tech,
            label: l10n.mostWinsTeam,
            team: topWinner,
            value: l10n.nWinsLabel(topWinner.win),
            color: _primary,
          ),
          _TeamStatRow(
            icon: Icons.balance,
            label: l10n.mostDrawsTeam,
            team: topDrawer,
            value: l10n.nDrawsLabel(topDrawer.draw),
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
    // 홈/어웨이 득점 비교
    int totalHomeGoals = 0;
    int totalAwayGoals = 0;

    for (final team in standings) {
      totalHomeGoals += team.homeGoalsFor ?? 0;
      totalAwayGoals += team.awayGoalsFor ?? 0;
    }

    // 득실차 상위 5팀
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
                l10n.goalAnalysisCard,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 홈/어웨이 골 비교
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
                        l10n.totalNGoals(totalHomeGoals + totalAwayGoals),
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

          // 득실차 상위 팀
          Text(
            l10n.top5GoalDiff,
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
                SizedBox(width: 36, child: Text(l10n.rankColumn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.teamColumn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                _HeaderCell(l10n.matchesColumn),
                _HeaderCell(l10n.winColumn),
                _HeaderCell(l10n.drawColumn),
                _HeaderCell(l10n.loseColumn),
                _HeaderCell(l10n.goalsForColumn),
                _HeaderCell(l10n.goalsAgainstColumn),
                _HeaderCell(l10n.goalDiffColumn),
                SizedBox(
                  width: 36,
                  child: Text(
                    l10n.pointsColumn,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Rows
          ...standings.map((standing) => _StandingRow(standing: standing)),
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

  static const _primary = Color(0xFF2563EB);

  const _StandingRow({required this.standing});

  @override
  Widget build(BuildContext context) {
    final desc = standing.description?.toLowerCase() ?? '';

    Color rankColor = Colors.grey;
    Color? rowColor;

    // Determine colors based on description
    if (desc.contains('champions') && !desc.contains('championship')) {
      rowColor = Colors.blue.withValues(alpha: 0.08);
      rankColor = Colors.blue;
    } else if (desc.contains('europa') && !desc.contains('relegation')) {
      rowColor = Colors.orange.withValues(alpha: 0.08);
      rankColor = Colors.orange;
    } else if (desc.contains('conference') && !desc.contains('relegation')) {
      rowColor = Colors.green.withValues(alpha: 0.08);
      rankColor = Colors.green;
    } else if (desc.contains('promotion')) {
      rowColor = Colors.green.withValues(alpha: 0.08);
      rankColor = Colors.green;
    } else if (desc.contains('relegation') && !desc.contains('europa') && !desc.contains('conference')) {
      rowColor = Colors.red.withValues(alpha: 0.08);
      rankColor = Colors.red;
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
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${standing.points}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _primary,
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
                SizedBox(width: 36, child: Text(l10n.rankColumn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.playerColumn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                SizedBox(
                  width: 50,
                  child: Text(
                    l10n.appsColumn,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    isGoals ? l10n.goalsColumn : l10n.assistsColumn,
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
                  style: const TextStyle(
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
