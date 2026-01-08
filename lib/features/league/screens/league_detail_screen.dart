import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_football_service.dart';
import '../../../core/constants/api_football_ids.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/banner_ad_widget.dart';

/// 리그 정보 Provider
final leagueInfoProvider = FutureProvider.family<ApiFootballLeague?, int>((ref, leagueId) async {
  final service = ApiFootballService();
  return service.getLeagueById(leagueId);
});

/// 선택된 시즌 Provider (사용자가 선택한 시즌 저장)
final selectedSeasonProvider = StateProvider.family<int?, int>((ref, leagueId) => null);

/// 리그 시즌 Provider (선택된 시즌 또는 최신 시즌 반환)
final leagueSeasonProvider = FutureProvider.family<int, int>((ref, leagueId) async {
  final selectedSeason = ref.watch(selectedSeasonProvider(leagueId));
  if (selectedSeason != null) return selectedSeason;

  final leagueInfo = await ref.watch(leagueInfoProvider(leagueId).future);
  // 리그 정보에서 최신 시즌 사용, 없으면 현재 연도 사용
  return leagueInfo?.latestSeason ?? LeagueIds.getCurrentSeason();
});

/// 리그 순위 Provider
final leagueStandingsProvider = FutureProvider.family<List<ApiFootballStanding>, int>((ref, leagueId) async {
  final service = ApiFootballService();
  final season = await ref.watch(leagueSeasonProvider(leagueId).future);
  return service.getStandings(leagueId, season);
});

/// 조별 리그 순위 Provider (그룹별로 반환)
final leagueStandingsGroupedProvider = FutureProvider.family<Map<String, List<ApiFootballStanding>>, int>((ref, leagueId) async {
  final service = ApiFootballService();
  final season = await ref.watch(leagueSeasonProvider(leagueId).future);
  return service.getStandingsGrouped(leagueId, season);
});

/// 조별 리그 여부 확인 Provider
final isGroupStageLeagueProvider = FutureProvider.family<bool, int>((ref, leagueId) async {
  final service = ApiFootballService();
  final season = await ref.watch(leagueSeasonProvider(leagueId).future);
  return service.isGroupStageLeague(leagueId, season);
});

/// 리그 경기 일정 Provider
final leagueFixturesDetailProvider = FutureProvider.family<List<ApiFootballFixture>, int>((ref, leagueId) async {
  final service = ApiFootballService();
  final season = await ref.watch(leagueSeasonProvider(leagueId).future);
  return service.getFixturesByLeague(leagueId, season);
});

/// 리그 득점 순위 Provider
final leagueTopScorersProvider = FutureProvider.family<List<ApiFootballTopScorer>, int>((ref, leagueId) async {
  final service = ApiFootballService();
  final season = await ref.watch(leagueSeasonProvider(leagueId).future);
  return service.getTopScorers(leagueId, season);
});

/// 리그 도움 순위 Provider
final leagueTopAssistsProvider = FutureProvider.family<List<ApiFootballTopScorer>, int>((ref, leagueId) async {
  final service = ApiFootballService();
  final season = await ref.watch(leagueSeasonProvider(leagueId).future);
  return service.getTopAssists(leagueId, season);
});

/// 최다 경고 Provider
final leagueTopYellowCardsProvider = FutureProvider.family<List<ApiFootballTopScorer>, int>((ref, leagueId) async {
  final service = ApiFootballService();
  final season = await ref.watch(leagueSeasonProvider(leagueId).future);
  return service.getTopYellowCards(leagueId, season);
});

/// 최다 퇴장 Provider
final leagueTopRedCardsProvider = FutureProvider.family<List<ApiFootballTopScorer>, int>((ref, leagueId) async {
  final service = ApiFootballService();
  final season = await ref.watch(leagueSeasonProvider(leagueId).future);
  return service.getTopRedCards(leagueId, season);
});

/// 우승팀/준우승팀 정보 클래스
class LeagueChampionInfo {
  // 리그용 (순위표 기반)
  final ApiFootballStanding? champion;
  final ApiFootballStanding? runnerUp;
  // 컵 대회용 (결승전 기반)
  final ApiFootballFixtureTeam? cupWinner;
  final ApiFootballFixtureTeam? cupRunnerUp;
  final ApiFootballFixture? finalMatch;
  final bool isSeasonComplete;
  final bool isCupCompetition;

  LeagueChampionInfo({
    this.champion,
    this.runnerUp,
    this.cupWinner,
    this.cupRunnerUp,
    this.finalMatch,
    this.isSeasonComplete = false,
    this.isCupCompetition = false,
  });

  bool get hasChampion => champion != null || cupWinner != null;
}

/// 리그 우승팀 Provider (리그: 순위표, 컵: 결승전)
final leagueChampionProvider = FutureProvider.family<LeagueChampionInfo, int>((ref, leagueId) async {
  final leagueInfo = await ref.watch(leagueInfoProvider(leagueId).future);
  final fixtures = await ref.watch(leagueFixturesDetailProvider(leagueId).future);

  // 컵 대회 여부 확인
  final isCup = leagueInfo?.type == 'Cup';

  if (isCup) {
    // 컵 대회: 결승전에서 우승팀 찾기
    final finalMatch = fixtures.where((f) {
      final round = f.league.round?.toLowerCase() ?? '';
      return round.contains('final') && !round.contains('semi') && !round.contains('quarter');
    }).toList();

    if (finalMatch.isNotEmpty) {
      // 가장 최근(마지막) 결승전
      finalMatch.sort((a, b) => b.date.compareTo(a.date));
      final theFinal = finalMatch.first;

      // 결승전이 끝났는지 확인
      if (theFinal.status.short == 'FT' || theFinal.status.short == 'AET' || theFinal.status.short == 'PEN') {
        final homeWinner = theFinal.homeTeam.winner == true;
        final awayWinner = theFinal.awayTeam.winner == true;

        if (homeWinner || awayWinner) {
          return LeagueChampionInfo(
            cupWinner: homeWinner ? theFinal.homeTeam : theFinal.awayTeam,
            cupRunnerUp: homeWinner ? theFinal.awayTeam : theFinal.homeTeam,
            finalMatch: theFinal,
            isSeasonComplete: true,
            isCupCompetition: true,
          );
        }
      }
    }

    // 결승전이 아직 없거나 안 끝남 - 빈 결과 반환
    return LeagueChampionInfo(isCupCompetition: true);
  }

  // 리그: 순위표에서 1, 2위 추출
  final standings = await ref.watch(leagueStandingsProvider(leagueId).future);

  if (standings.isEmpty) {
    return LeagueChampionInfo();
  }

  final champion = standings.firstWhere((s) => s.rank == 1, orElse: () => standings.first);
  final runnerUp = standings.length > 1
      ? standings.firstWhere((s) => s.rank == 2, orElse: () => standings[1])
      : null;

  // 시즌 완료 여부 판단
  final now = DateTime.now();
  final allMatchesFinished = fixtures.isNotEmpty &&
      fixtures.every((f) => f.date.isBefore(now) && f.status.short == 'FT');

  final totalMatches = standings.isNotEmpty ? standings.first.played : 0;
  final expectedMatches = (standings.length - 1) * 2;
  final isSeasonComplete = allMatchesFinished ||
      (expectedMatches > 0 && totalMatches >= expectedMatches * 0.95);

  return LeagueChampionInfo(
    champion: champion,
    runnerUp: runnerUp,
    isSeasonComplete: isSeasonComplete,
  );
});

class LeagueDetailScreen extends ConsumerStatefulWidget {
  final String leagueId;

  const LeagueDetailScreen({super.key, required this.leagueId});

  @override
  ConsumerState<LeagueDetailScreen> createState() => _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends ConsumerState<LeagueDetailScreen> with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _background = Color(0xFFF9FAFB);

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leagueIdInt = int.tryParse(widget.leagueId) ?? 0;
    final leagueAsync = ref.watch(leagueInfoProvider(leagueIdInt));

    return Scaffold(
      backgroundColor: _background,
      bottomNavigationBar: const BottomBannerAdWidget(),
      body: leagueAsync.when(
        data: (league) => _buildContent(league, leagueIdInt),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildError(leagueIdInt),
      ),
    );
  }

  Widget _buildContent(ApiFootballLeague? league, int leagueId) {
    final seasonAsync = ref.watch(leagueSeasonProvider(leagueId));

    return Column(
      children: [
        // 고정 헤더 영역
        Container(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 앱바 + 리그 정보
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 16, 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: _textPrimary),
                        onPressed: () => context.pop(),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: league?.logo != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: league!.logo!,
                                  fit: BoxFit.contain,
                                  errorWidget: (_, __, ___) => _buildLogoPlaceholder(),
                                ),
                              )
                            : _buildLogoPlaceholder(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              league?.name ?? AppLocalizations.of(context)!.leagueLabel,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                            if (league?.countryName != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                league!.countryName!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // 시즌 선택 드롭다운
                      if (league != null && league.seasons.isNotEmpty)
                        _SeasonDropdown(
                          seasons: league.seasons,
                          currentSeason: seasonAsync.valueOrNull ?? league.latestSeason ?? LeagueIds.getCurrentSeason(),
                          leagueType: league.type,
                          onSeasonChanged: (season) {
                            ref.read(selectedSeasonProvider(leagueId).notifier).state = season;
                          },
                        ),
                    ],
                  ),
                ),
                // 탭바
                TabBar(
                  controller: _tabController,
                  labelColor: _primary,
                  unselectedLabelColor: _textSecondary,
                  indicatorColor: _primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  tabs: [
                    Tab(text: AppLocalizations.of(context)!.schedule),
                    Tab(text: AppLocalizations.of(context)!.standings),
                    Tab(text: AppLocalizations.of(context)!.stats),
                  ],
                ),
              ],
            ),
          ),
        ),
        // 탭 콘텐츠
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _FixturesTab(leagueId: leagueId),
              _StandingsTab(leagueId: leagueId),
              _StatsTab(leagueId: leagueId),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoPlaceholder() {
    return Center(
      child: Icon(Icons.sports_soccer, color: _textSecondary, size: 28),
    );
  }

  Widget _buildError(int leagueId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: _textSecondary),
          const SizedBox(height: 16),
          Builder(
            builder: (context) => Text(
              AppLocalizations.of(context)!.cannotLoadLeagueInfo,
              style: TextStyle(color: _textSecondary, fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.invalidate(leagueInfoProvider(leagueId)),
            child: Builder(
              builder: (context) => Text(AppLocalizations.of(context)!.retry),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 순위 탭 (서브탭: 순위, 득점, 도움)
// ============================================================================
/// 서브탭 선택 상태 Provider
final _standingsSubTabProvider = StateProvider.autoDispose<int>((ref) => 0);

class _StandingsTab extends ConsumerWidget {
  final int leagueId;

  static const _border = Color(0xFFE5E7EB);

  const _StandingsTab({required this.leagueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSubTab = ref.watch(_standingsSubTabProvider);

    return Column(
      children: [
        // 서브탭 선택 (순위 | 득점 | 도움)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  _SubTabButton(
                    label: l10n.standings,
                    isSelected: selectedSubTab == 0,
                    onTap: () => ref.read(_standingsSubTabProvider.notifier).state = 0,
                  ),
                  _SubTabButton(
                    label: l10n.goals,
                    isSelected: selectedSubTab == 1,
                    onTap: () => ref.read(_standingsSubTabProvider.notifier).state = 1,
                  ),
                  _SubTabButton(
                    label: l10n.assists,
                    isSelected: selectedSubTab == 2,
                    onTap: () => ref.read(_standingsSubTabProvider.notifier).state = 2,
                  ),
                ],
              );
            },
          ),
        ),
        // 서브탭 컨텐츠
        Expanded(
          child: selectedSubTab == 0
              ? _StandingsContent(leagueId: leagueId)
              : selectedSubTab == 1
                  ? _TopScorersContent(leagueId: leagueId)
                  : _TopAssistsContent(leagueId: leagueId),
        ),
      ],
    );
  }
}

class _SubTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const _primary = Color(0xFF2563EB);
  static const _textSecondary = Color(0xFF6B7280);

  const _SubTabButton({
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

// 순위 컨텐츠 (조별 리그 지원)
class _StandingsContent extends ConsumerWidget {
  final int leagueId;

  static const _primary = Color(0xFF2563EB);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _StandingsContent({required this.leagueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGroupStageAsync = ref.watch(isGroupStageLeagueProvider(leagueId));

    return isGroupStageAsync.when(
      data: (isGroupStage) {
        if (isGroupStage) {
          return _buildGroupedStandings(context, ref);
        } else {
          return _buildSingleStandings(context, ref);
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildSingleStandings(context, ref), // 에러시 일반 순위 표시
    );
  }

  // 조별 리그 순위 표시
  Widget _buildGroupedStandings(BuildContext context, WidgetRef ref) {
    final groupedAsync = ref.watch(leagueStandingsGroupedProvider(leagueId));

    return groupedAsync.when(
      data: (groupedStandings) {
        if (groupedStandings.isEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context)!.noStandingsInfo, style: TextStyle(color: _textSecondary)),
          );
        }

        // 그룹 이름으로 정렬 (A조, B조, C조...)
        final sortedGroups = groupedStandings.keys.toList()
          ..sort((a, b) => a.compareTo(b));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sortedGroups.map((groupName) {
              final standings = groupedStandings[groupName]!;
              return _buildGroupCard(context, groupName, standings);
            }).toList(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(AppLocalizations.of(context)!.cannotLoadStandings, style: TextStyle(color: _textSecondary)),
      ),
    );
  }

  // 그룹 카드 위젯
  Widget _buildGroupCard(BuildContext context, String groupName, List<ApiFootballStanding> standings) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 그룹 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
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
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const SizedBox(width: 24, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(l10n.team, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    _buildCompactHeaderCell(l10n.matches),
                    _buildCompactHeaderCell(l10n.winShort),
                    _buildCompactHeaderCell(l10n.drawShort),
                    _buildCompactHeaderCell(l10n.lossShort),
                    _buildCompactHeaderCell(l10n.goalsFor),
                    _buildCompactHeaderCell(l10n.goalsAgainst),
                    _buildCompactHeaderCell(l10n.goalDifference),
                    SizedBox(
                      width: 32,
                      child: Text(l10n.pts, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
                    ),
                  ],
                ),
              );
            },
          ),
          // 팀 행들
          ...standings.map((standing) => _buildCompactStandingRow(context, standing)),
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

  Widget _buildCompactStandingRow(BuildContext context, ApiFootballStanding standing) {
    final rankColor = _getGroupRankColor(standing.rank);

    return InkWell(
      onTap: () => context.push('/team/${standing.teamId}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _border, width: 0.5)),
        ),
        child: Row(
          children: [
            // 순위
            Container(
              width: 24,
              alignment: Alignment.center,
              child: Container(
                width: 20,
                height: 20,
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
            ),
            const SizedBox(width: 6),
            // 팀
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
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // 통계
            _buildCompactStatCell('${standing.played}'),
            _buildCompactStatCell('${standing.win}', color: Colors.green),
            _buildCompactStatCell('${standing.draw}'),
            _buildCompactStatCell('${standing.lose}', color: Colors.red),
            _buildCompactStatCell('${standing.goalsFor}'),
            _buildCompactStatCell('${standing.goalsAgainst}'),
            _buildCompactStatCell(
              standing.goalsDiff >= 0 ? '+${standing.goalsDiff}' : '${standing.goalsDiff}',
              color: standing.goalsDiff > 0 ? Colors.green : (standing.goalsDiff < 0 ? Colors.red : null),
            ),
            // 승점
            Container(
              width: 32,
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${standing.points}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _primary),
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

  Color _getGroupRankColor(int rank) {
    // 조별 리그에서 1, 2위는 16강 진출
    if (rank <= 2) return Colors.green;
    return Colors.grey;
  }

  // 일반 리그 순위 표시 (기존 코드)
  Widget _buildSingleStandings(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(leagueStandingsProvider(leagueId));

    return standingsAsync.when(
      data: (standings) {
        if (standings.isEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context)!.noStandingsInfo, style: TextStyle(color: _textSecondary)),
          );
        }

        final l10n = AppLocalizations.of(context)!;
        return Column(
          children: [
            _buildLeagueLegend(context, standings),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 헤더
                    Container(
                      color: Colors.grey.shade100,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          SizedBox(width: 36, child: Text(l10n.rank, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          const SizedBox(width: 8),
                          Expanded(child: Text(l10n.team, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          _buildHeaderCell(l10n.matches),
                          _buildHeaderCell(l10n.winShort),
                          _buildHeaderCell(l10n.drawShort),
                          _buildHeaderCell(l10n.lossShort),
                          _buildHeaderCell(l10n.goalsFor),
                          _buildHeaderCell(l10n.goalsAgainst),
                          _buildHeaderCell(l10n.goalDifference),
                          SizedBox(
                            width: 36,
                            child: Text(l10n.pts, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
                          ),
                        ],
                      ),
                    ),
                    // 순위 행들
                    ...standings.map((standing) => _buildStandingRow(context, standing)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(AppLocalizations.of(context)!.cannotLoadStandings, style: TextStyle(color: _textSecondary)),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return SizedBox(
      width: 28,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
    );
  }

  Widget _buildLeagueLegend(BuildContext context, List<ApiFootballStanding> standings) {
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

    if (hasUclDirect) legendItems.add(_LegendItem(color: Colors.blue.shade800, label: l10n.uclDirect));
    if (hasUclPlayoff) legendItems.add(_LegendItem(color: Colors.cyan.shade600, label: 'UCL PO'));
    if (hasUclGeneral) legendItems.add(_LegendItem(color: Colors.blue, label: 'UCL'));
    if (hasUclQualification && !hasUclPlayoff) legendItems.add(_LegendItem(color: Colors.cyan.shade600, label: l10n.uclQualification));

    final hasUelDirect = descriptions.any((d) => d.contains('europa') && d.contains('1/8'));
    final hasUelPlayoff = descriptions.any((d) => d.contains('europa') && d.contains('1/16'));
    final hasUelGeneral = descriptions.any((d) => d.contains('europa') && !d.contains('1/8') && !d.contains('1/16') && !d.contains('qualification') && !d.contains('qualifying') && !d.contains('relegation'));

    if (hasUelDirect) legendItems.add(_LegendItem(color: Colors.orange.shade800, label: l10n.uelDirect));
    if (hasUelPlayoff) legendItems.add(_LegendItem(color: Colors.amber.shade700, label: 'UEL PO'));
    if (hasUelGeneral) legendItems.add(_LegendItem(color: Colors.orange, label: 'UEL'));

    if (descriptions.any((d) => d.contains('conference') && !d.contains('relegation'))) {
      legendItems.add(_LegendItem(color: Colors.green, label: 'UECL'));
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

  Color _getRankColor(ApiFootballStanding standing) {
    final desc = standing.description?.toLowerCase() ?? '';

    final isUclDirect = desc.contains('champions') && !desc.contains('championship') && desc.contains('1/8');
    final isUclPlayoff = desc.contains('champions') && !desc.contains('championship') && (desc.contains('qualifying') || desc.contains('qualification') || desc.contains('1/16'));
    final isUelDirect = desc.contains('europa') && desc.contains('1/8');
    final isUelPlayoff = desc.contains('europa') && (desc.contains('qualifying') || desc.contains('qualification') || desc.contains('1/16'));
    final isConference = desc.contains('conference') && !desc.contains('relegation');
    final isChampionsLeague = desc.contains('champions') && !desc.contains('championship') && !desc.contains('qualifying') && !desc.contains('qualification') && !desc.contains('1/8') && !desc.contains('1/16');
    final isEuropaLeague = desc.contains('europa') && !desc.contains('qualifying') && !desc.contains('qualification') && !desc.contains('1/8') && !desc.contains('1/16') && !desc.contains('relegation');
    final isRelegation = desc.contains('relegation') && !desc.contains('playoff') && !desc.contains('europa') && !desc.contains('conference') && !desc.contains('round');
    final isToEuropa = desc.contains('relegation') && desc.contains('europa');

    if (isUclDirect) return Colors.blue.shade800;
    if (isUclPlayoff) return Colors.cyan.shade600;
    if (isUelDirect) return Colors.orange.shade800;
    if (isUelPlayoff || isToEuropa) return Colors.amber.shade700;
    if (isConference) return Colors.green;
    if (isChampionsLeague) return Colors.blue;
    if (isEuropaLeague) return Colors.orange;
    if (isRelegation) return Colors.red;
    return Colors.grey;
  }

  Color? _getRowColor(ApiFootballStanding standing) {
    final desc = standing.description?.toLowerCase() ?? '';

    final isUclDirect = desc.contains('champions') && !desc.contains('championship') && desc.contains('1/8');
    final isUclPlayoff = desc.contains('champions') && !desc.contains('championship') && (desc.contains('qualifying') || desc.contains('qualification') || desc.contains('1/16'));
    final isUelDirect = desc.contains('europa') && desc.contains('1/8');
    final isUelPlayoff = desc.contains('europa') && (desc.contains('qualifying') || desc.contains('qualification') || desc.contains('1/16'));
    final isConference = desc.contains('conference') && !desc.contains('relegation');
    final isChampionsLeague = desc.contains('champions') && !desc.contains('championship') && !desc.contains('qualifying') && !desc.contains('qualification') && !desc.contains('1/8') && !desc.contains('1/16');
    final isEuropaLeague = desc.contains('europa') && !desc.contains('qualifying') && !desc.contains('qualification') && !desc.contains('1/8') && !desc.contains('1/16') && !desc.contains('relegation');
    final isRelegation = desc.contains('relegation') && !desc.contains('playoff') && !desc.contains('europa') && !desc.contains('conference') && !desc.contains('round');
    final isToEuropa = desc.contains('relegation') && desc.contains('europa');

    if (isUclDirect) return Colors.blue.shade800.withValues(alpha: 0.12);
    if (isUclPlayoff) return Colors.cyan.shade300.withValues(alpha: 0.15);
    if (isUelDirect) return Colors.orange.shade800.withValues(alpha: 0.12);
    if (isUelPlayoff || isToEuropa) return Colors.amber.shade300.withValues(alpha: 0.15);
    if (isConference) return Colors.green.withValues(alpha: 0.08);
    if (isChampionsLeague) return Colors.blue.withValues(alpha: 0.08);
    if (isEuropaLeague) return Colors.orange.withValues(alpha: 0.08);
    if (isRelegation) return Colors.red.withValues(alpha: 0.08);
    return null;
  }

  Widget _buildStandingRow(BuildContext context, ApiFootballStanding standing) {
    final rankColor = _getRankColor(standing);
    final rowColor = _getRowColor(standing);

    return InkWell(
      onTap: () => context.push('/team/${standing.teamId}'),
      child: Container(
        color: rowColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // 순위
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: rankColor),
                ),
              ),
            ),
            // 팀
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
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // 통계
            _buildStatCell('${standing.played}'),
            _buildStatCell('${standing.win}', color: Colors.green),
            _buildStatCell('${standing.draw}'),
            _buildStatCell('${standing.lose}', color: Colors.red),
            _buildStatCell('${standing.goalsFor}'),
            _buildStatCell('${standing.goalsAgainst}'),
            _buildStatCell(
              standing.goalsDiff >= 0 ? '+${standing.goalsDiff}' : '${standing.goalsDiff}',
              color: standing.goalsDiff > 0 ? Colors.green : (standing.goalsDiff < 0 ? Colors.red : null),
            ),
            // 승점
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _primary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCell(String text, {Color? color}) {
    return SizedBox(
      width: 28,
      child: Text(text, style: TextStyle(fontSize: 12, color: color), textAlign: TextAlign.center),
    );
  }
}

// 득점 순위 컨텐츠
class _TopScorersContent extends ConsumerWidget {
  final int leagueId;

  static const _textSecondary = Color(0xFF6B7280);

  const _TopScorersContent({required this.leagueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scorersAsync = ref.watch(leagueTopScorersProvider(leagueId));

    return scorersAsync.when(
      data: (scorers) {
        final l10n = AppLocalizations.of(context)!;
        if (scorers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_soccer, size: 48, color: _textSecondary),
                const SizedBox(height: 16),
                Text(l10n.noTopScorersInfo, style: TextStyle(color: _textSecondary)),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // 헤더
              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    SizedBox(width: 36, child: Text(l10n.rank, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    const SizedBox(width: 8),
                    Expanded(child: Text(l10n.player, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    SizedBox(
                      width: 50,
                      child: Text(l10n.matchesPlayed, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(l10n.goals, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
              // 선수 행들
              ...scorers.asMap().entries.map((entry) => _TopScorerRow(
                rank: entry.key + 1,
                scorer: entry.value,
                isGoals: true,
              )),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(AppLocalizations.of(context)!.cannotLoadTopScorers, style: TextStyle(color: _textSecondary)),
      ),
    );
  }
}

// 도움 순위 컨텐츠
class _TopAssistsContent extends ConsumerWidget {
  final int leagueId;

  static const _textSecondary = Color(0xFF6B7280);

  const _TopAssistsContent({required this.leagueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assistsAsync = ref.watch(leagueTopAssistsProvider(leagueId));

    return assistsAsync.when(
      data: (assists) {
        final l10n = AppLocalizations.of(context)!;
        if (assists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.handshake_outlined, size: 48, color: _textSecondary),
                const SizedBox(height: 16),
                Text(l10n.noTopAssistsInfo, style: TextStyle(color: _textSecondary)),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // 헤더
              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    SizedBox(width: 36, child: Text(l10n.rank, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    const SizedBox(width: 8),
                    Expanded(child: Text(l10n.player, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    SizedBox(
                      width: 50,
                      child: Text(l10n.matchesPlayed, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(l10n.assists, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
              // 선수 행들
              ...assists.asMap().entries.map((entry) => _TopScorerRow(
                rank: entry.key + 1,
                scorer: entry.value,
                isGoals: false,
              )),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(AppLocalizations.of(context)!.cannotLoadTopAssists, style: TextStyle(color: _textSecondary)),
      ),
    );
  }
}

// 득점/도움 선수 행
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
            // 순위
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: rankColor),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 선수 정보
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
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
            // 출전
            SizedBox(
              width: 50,
              child: Text(
                '${scorer.appearances ?? 0}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
            // 득점/도움
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _primary),
                ),
              ),
            ),
          ],
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
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ============================================================================
// 일정 탭
// ============================================================================
class _FixturesTab extends ConsumerStatefulWidget {
  final int leagueId;

  const _FixturesTab({required this.leagueId});

  @override
  ConsumerState<_FixturesTab> createState() => _FixturesTabState();
}

class _FixturesTabState extends ConsumerState<_FixturesTab> {
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _fixtureKeys = {};
  bool _hasScrolled = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  ApiFootballFixture? _findClosestFixture(List<ApiFootballFixture> fixtures) {
    if (fixtures.isEmpty) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final sorted = List<ApiFootballFixture>.from(fixtures);
    sorted.sort((a, b) {
      final aDate = DateTime(a.date.year, a.date.month, a.date.day);
      final bDate = DateTime(b.date.year, b.date.month, b.date.day);
      final aDiff = (aDate.difference(today).inDays).abs();
      final bDiff = (bDate.difference(today).inDays).abs();
      return aDiff.compareTo(bDiff);
    });

    return sorted.first;
  }

  void _scrollToClosestFixture(int? fixtureId) {
    if (_hasScrolled || fixtureId == null) return;

    if (_fixtureKeys[fixtureId]?.currentContext != null) {
      Scrollable.ensureVisible(
        _fixtureKeys[fixtureId]!.currentContext!,
        duration: Duration.zero,
        alignment: 0.5,
      );
      _hasScrolled = true;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    return targetDate == today;
  }

  String _formatDateHeader(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    final weekdays = [l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri, l10n.sat, l10n.sun];
    final weekday = weekdays[date.weekday - 1];
    final dateStr = l10n.dateWithWeekday(date.day.toString(), date.month.toString(), weekday);

    if (targetDate == today) {
      return l10n.todayWithDate(dateStr);
    } else if (targetDate == tomorrow) {
      return l10n.tomorrowWithDate(dateStr);
    } else if (targetDate == yesterday) {
      return l10n.yesterdayWithDate(dateStr);
    }

    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    final fixturesAsync = ref.watch(leagueFixturesDetailProvider(widget.leagueId));

    return fixturesAsync.when(
      data: (fixtures) {
        if (fixtures.isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return Center(
            child: Text(l10n.noMatchSchedule, style: TextStyle(color: _textSecondary)),
          );
        }

        // 날짜순 정렬
        final sortedFixtures = List<ApiFootballFixture>.from(fixtures)
          ..sort((a, b) => a.date.compareTo(b.date));

        // 오늘과 가장 가까운 경기 찾기
        final closestFixture = _findClosestFixture(sortedFixtures);
        if (closestFixture != null) {
          _fixtureKeys.putIfAbsent(closestFixture.id, () => GlobalKey());
        }

        // 라운드별로 그룹화 (라운드가 없으면 날짜를 키로 사용)
        final groupedByRound = <String, List<ApiFootballFixture>>{};
        for (final fixture in sortedFixtures) {
          final roundKey = fixture.league.round ?? DateFormat('yyyy-MM-dd').format(fixture.date);
          groupedByRound.putIfAbsent(roundKey, () => []).add(fixture);
        }

        // 라운드 키를 첫 번째 경기 날짜 기준으로 정렬
        final roundKeys = groupedByRound.keys.toList()
          ..sort((a, b) {
            final aDate = groupedByRound[a]!.first.date;
            final bDate = groupedByRound[b]!.first.date;
            return aDate.compareTo(bDate);
          });

        // 스크롤 이동
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToClosestFixture(closestFixture?.id);
        });

        return Container(
          color: const Color(0xFFF3F4F6),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: roundKeys.map((roundKey) {
                final roundFixtures = groupedByRound[roundKey]!;

                // 라운드 내 날짜별로 그룹화
                final groupedByDate = <String, List<ApiFootballFixture>>{};
                for (final fixture in roundFixtures) {
                  final dateKey = DateFormat('yyyy-MM-dd').format(fixture.date);
                  groupedByDate.putIfAbsent(dateKey, () => []).add(fixture);
                }
                final dateKeys = groupedByDate.keys.toList()..sort();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 라운드 헤더
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        roundKey,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    // 날짜별 경기들
                    ...dateKeys.map((dateKey) {
                      final dateFixtures = groupedByDate[dateKey]!;
                      final date = DateTime.parse(dateKey);
                      final isToday = _isToday(date);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 날짜 헤더
                          Padding(
                            padding: const EdgeInsets.only(left: 4, top: 4, bottom: 6),
                            child: Text(
                              _formatDateHeader(context, date),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isToday ? const Color(0xFF2563EB) : _textSecondary,
                              ),
                            ),
                          ),
                          // 경기 카드들
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: dateFixtures.asMap().entries.map((entry) {
                                final i = entry.key;
                                final fixture = entry.value;
                                final hasKey = _fixtureKeys.containsKey(fixture.id);
                                return Column(
                                  key: hasKey ? _fixtureKeys[fixture.id] : null,
                                  children: [
                                    if (i > 0) Divider(height: 1, color: _border, indent: 14, endIndent: 14),
                                    _FixtureCard(fixture: fixture),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 4),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return Center(
            child: Text(l10n.cannotLoadSchedule, style: TextStyle(color: _textSecondary)),
          );
        },
      ),
    );
  }
}

class _FixtureCard extends StatelessWidget {
  final ApiFootballFixture fixture;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _error = Color(0xFFEF4444);

  const _FixtureCard({required this.fixture});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/match/${fixture.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // 시간/상태
            SizedBox(
              width: 48,
              child: _buildTimeOrStatus(context),
            ),
            const SizedBox(width: 12),
            // 팀 정보
            Expanded(
              child: Column(
                children: [
                  _buildTeamRow(fixture.homeTeam.name, fixture.homeTeam.logo, fixture.homeGoals, true),
                  const SizedBox(height: 6),
                  _buildTeamRow(fixture.awayTeam.name, fixture.awayTeam.logo, fixture.awayGoals, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeOrStatus(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (fixture.isLive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: _error,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          fixture.status.elapsed != null ? "${fixture.status.elapsed}'" : 'LIVE',
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
      );
    } else if (fixture.isFinished) {
      return Text(
        l10n.matchFinished,
        style: TextStyle(fontSize: 12, color: _textSecondary, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      );
    } else {
      return Text(
        DateFormat('HH:mm').format(fixture.date),
        style: TextStyle(fontSize: 13, color: _primary, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      );
    }
  }

  Widget _buildTeamRow(String name, String? logo, int? goals, bool isHome) {
    final isWinner = fixture.isFinished && goals != null &&
        ((isHome && goals > (fixture.awayGoals ?? 0)) ||
         (!isHome && goals > (fixture.homeGoals ?? 0)));

    return Row(
      children: [
        if (logo != null)
          CachedNetworkImage(
            imageUrl: logo,
            width: 20,
            height: 20,
            errorWidget: (_, __, ___) => const Icon(Icons.sports_soccer, size: 20, color: Colors.grey),
          )
        else
          const Icon(Icons.sports_soccer, size: 20, color: Colors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isWinner ? FontWeight.w600 : FontWeight.w400,
              color: isWinner ? _textPrimary : _textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (goals != null)
          Text(
            '$goals',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isWinner ? _textPrimary : _textSecondary,
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// 통계 탭 (리그 개요, 팀 순위, 골 분석)
// ============================================================================
class _StatsTab extends ConsumerWidget {
  final int leagueId;

  static const _textSecondary = Color(0xFF6B7280);

  const _StatsTab({required this.leagueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(leagueStandingsProvider(leagueId));
    final championAsync = ref.watch(leagueChampionProvider(leagueId));
    final topYellowAsync = ref.watch(leagueTopYellowCardsProvider(leagueId));
    final topRedAsync = ref.watch(leagueTopRedCardsProvider(leagueId));

    final l10n = AppLocalizations.of(context)!;
    return standingsAsync.when(
      data: (standings) {
        if (standings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 48, color: _textSecondary),
                const SizedBox(height: 16),
                Text(l10n.noLeagueStats, style: TextStyle(color: _textSecondary)),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 우승팀/현재 순위 카드 (상단에 배치)
              championAsync.when(
                data: (championInfo) => championInfo.hasChampion
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ChampionCard(championInfo: championInfo),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(l10n.cannotLoadStats, style: TextStyle(color: _textSecondary)),
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
    // form 데이터가 있는 팀만 필터링
    final teamsWithForm = standings.where((s) => s.form != null && s.form!.isNotEmpty).toList();

    if (teamsWithForm.isEmpty) {
      return const SizedBox.shrink();
    }

    // 상위 5팀의 폼
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
              Text(
                l10n.recentForm,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary),
              ),
              const Spacer(),
              Text(
                l10n.last5Matches,
                style: TextStyle(fontSize: 11, color: _textSecondary),
              ),
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
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${team.rank}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _primary),
              ),
            ),
            const SizedBox(width: 8),
            if (team.teamLogo != null)
              CachedNetworkImage(
                imageUrl: team.teamLogo!,
                width: 20,
                height: 20,
                errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 20),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                team.teamName,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: formChars.map((char) => _buildFormBadge(context, char)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormBadge(BuildContext context, String result) {
    final l10n = AppLocalizations.of(context)!;
    Color bgColor;
    Color textColor;
    String label;

    switch (result.toUpperCase()) {
      case 'W':
        bgColor = _success;
        textColor = Colors.white;
        label = l10n.winShortForm;
        break;
      case 'D':
        bgColor = _textSecondary;
        textColor = Colors.white;
        label = l10n.drawShortForm;
        break;
      case 'L':
        bgColor = _error;
        textColor = Colors.white;
        label = l10n.lossShortForm;
        break;
      default:
        bgColor = Colors.grey.shade300;
        textColor = _textSecondary;
        label = '-';
    }

    return Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.only(left: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}

// 우승팀/준우승팀 카드
class _ChampionCard extends StatelessWidget {
  final LeagueChampionInfo championInfo;

  static const _gold = Color(0xFFFFD700);
  static const _silver = Color(0xFFC0C0C0);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _ChampionCard({required this.championInfo});

  @override
  Widget build(BuildContext context) {
    // 컵 대회인 경우
    if (championInfo.isCupCompetition) {
      return _buildCupCard(context);
    }

    // 리그인 경우
    return _buildLeagueCard(context);
  }

  /// 컵 대회 우승팀 카드
  Widget _buildCupCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final winner = championInfo.cupWinner;
    final runnerUp = championInfo.cupRunnerUp;
    final finalMatch = championInfo.finalMatch;

    if (winner == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _gold.withValues(alpha: 0.12),
            _gold.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: _gold, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.champion,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.finalMatch,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.amber[800]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 우승팀
          _buildCupTeamRow(context: context, rank: 1, team: winner),
          if (runnerUp != null) ...[
            const SizedBox(height: 6),
            _buildCupTeamRow(context: context, rank: 2, team: runnerUp),
          ],
          // 결승전 스코어 표시
          if (finalMatch != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      finalMatch.homeTeam.name,
                      style: TextStyle(fontSize: 11, color: _textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '${finalMatch.homeGoals ?? 0} - ${finalMatch.awayGoals ?? 0}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textPrimary),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      finalMatch.awayTeam.name,
                      style: TextStyle(fontSize: 11, color: _textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 컵 대회 팀 행
  Widget _buildCupTeamRow({
    required BuildContext context,
    required int rank,
    required ApiFootballFixtureTeam team,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final medalColor = rank == 1 ? _gold : _silver;

    return InkWell(
      onTap: () => context.push('/team/${team.id}'),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: medalColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Text(rank == 1 ? '🥇' : '🥈', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            if (team.logo != null)
              CachedNetworkImage(
                imageUrl: team.logo!,
                width: 24,
                height: 24,
                errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 24),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                team.name,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: medalColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                rank == 1 ? l10n.champion : l10n.runnerUp,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: rank == 1 ? Colors.amber[800] : Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 리그 우승팀 카드
  Widget _buildLeagueCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final champion = championInfo.champion;
    final runnerUp = championInfo.runnerUp;

    if (champion == null) return const SizedBox.shrink();

    final isComplete = championInfo.isSeasonComplete;
    final title = isComplete ? l10n.champion : l10n.currentRank;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: isComplete
            ? LinearGradient(
                colors: [
                  _gold.withValues(alpha: 0.12),
                  _gold.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isComplete ? null : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isComplete ? _gold.withValues(alpha: 0.25) : _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isComplete ? Icons.emoji_events : Icons.leaderboard,
                color: isComplete ? _gold : Colors.amber[700],
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary),
              ),
              if (isComplete) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.seasonEnd,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.amber[800]),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // 우승팀 (또는 현재 1위)
          _buildLeagueTeamRow(context: context, rank: 1, team: champion),
          if (runnerUp != null) ...[
            const SizedBox(height: 6),
            _buildLeagueTeamRow(context: context, rank: 2, team: runnerUp),
          ],
        ],
      ),
    );
  }

  Widget _buildLeagueTeamRow({
    required BuildContext context,
    required int rank,
    required ApiFootballStanding team,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final medalColor = rank == 1 ? _gold : _silver;

    return InkWell(
      onTap: () => context.push('/team/${team.teamId}'),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: medalColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Text(rank == 1 ? '🥇' : '🥈', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            if (team.teamLogo != null)
              CachedNetworkImage(
                imageUrl: team.teamLogo!,
                width: 24,
                height: 24,
                errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 24),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                team.teamName,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              l10n.xPoints(team.points),
              style: TextStyle(fontSize: 11, color: _textSecondary),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: medalColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l10n.xGoals(team.goalsFor),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: rank == 1 ? Colors.amber[800] : Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
                l10n.leagueOverview,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _OverviewStatBox(icon: Icons.sports_soccer, label: l10n.totalGoals, value: '$totalGoals', color: _success),
              const SizedBox(width: 12),
              _OverviewStatBox(icon: Icons.speed, label: l10n.goalsPerMatch, value: goalsPerMatch.toStringAsFixed(2), color: _primary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _OverviewStatBox(icon: Icons.home, label: l10n.homeWins, value: '$totalHomeWins', color: _success),
              const SizedBox(width: 12),
              _OverviewStatBox(icon: Icons.flight, label: l10n.awayWins, value: '$totalAwayWins', color: _warning),
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
                    Text(l10n.homeWin, style: TextStyle(fontSize: 12, color: _success, fontWeight: FontWeight.w600)),
                    Text(l10n.draw, style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
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
                    Text(l10n.xMatches(totalHomeWins), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    Text(l10n.xMatches(totalDraws), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    Text(l10n.xMatches(totalAwayWins), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color),
                  ),
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
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
                AppLocalizations.of(context)!.teamRanking,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TeamStatRow(icon: Icons.sports_soccer, label: AppLocalizations.of(context)!.mostGoals, team: topScorer, value: AppLocalizations.of(context)!.nGoals(topScorer.goalsFor), color: _success),
          _TeamStatRow(icon: Icons.gpp_bad, label: AppLocalizations.of(context)!.mostConceded, team: topConceder, value: AppLocalizations.of(context)!.nGoals(topConceder.goalsAgainst), color: _error),
          _TeamStatRow(icon: Icons.military_tech, label: AppLocalizations.of(context)!.mostWins, team: topWinner, value: AppLocalizations.of(context)!.nWins(topWinner.win), color: _primary),
          _TeamStatRow(icon: Icons.balance, label: AppLocalizations.of(context)!.mostDraws, team: topDrawer, value: AppLocalizations.of(context)!.nDraws(topDrawer.draw), color: _textSecondary),
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
            child: Text(label, style: TextStyle(fontSize: 12, color: _textSecondary)),
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
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
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
                AppLocalizations.of(context)!.goalAnalysis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary),
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
                        Text(AppLocalizations.of(context)!.homeGoal, style: TextStyle(fontSize: 12, color: _textSecondary)),
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
                        AppLocalizations.of(context)!.totalNGoals(totalHomeGoals + totalAwayGoals),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textPrimary),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(AppLocalizations.of(context)!.awayGoal, style: TextStyle(fontSize: 12, color: _textSecondary)),
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
            AppLocalizations.of(context)!.top5GD,
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
    // 홈 승률 상위 3팀
    final homeWinRateSorted = [...standings]
      ..sort((a, b) {
        final aHomeGames = (a.homeWin ?? 0) + (a.homeDraw ?? 0) + (a.homeLose ?? 0);
        final bHomeGames = (b.homeWin ?? 0) + (b.homeDraw ?? 0) + (b.homeLose ?? 0);
        final aRate = aHomeGames > 0 ? (a.homeWin ?? 0) / aHomeGames : 0.0;
        final bRate = bHomeGames > 0 ? (b.homeWin ?? 0) / bHomeGames : 0.0;
        return bRate.compareTo(aRate);
      });

    // 원정 승률 상위 3팀
    final awayWinRateSorted = [...standings]
      ..sort((a, b) {
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
                child: Icon(Icons.compare_arrows, color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.homeAwayStrong,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 홈 강자
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.home, size: 16, color: _success),
                        const SizedBox(width: 4),
                        Text(AppLocalizations.of(context)!.homeStrong, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _success)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...topHomeTeams.asMap().entries.map((entry) {
                      final index = entry.key;
                      final team = entry.value;
                      final homeGames = (team.homeWin ?? 0) + (team.homeDraw ?? 0) + (team.homeLose ?? 0);
                      final winRate = homeGames > 0 ? ((team.homeWin ?? 0) / homeGames * 100).toInt() : 0;
                      return _buildCompactTeamRow(context, index + 1, team, AppLocalizations.of(context)!.nWins(team.homeWin ?? 0), '$winRate%', _success);
                    }),
                  ],
                ),
              ),
              Container(width: 1, height: 120, color: _border, margin: const EdgeInsets.symmetric(horizontal: 12)),
              // 원정 강자
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.flight, size: 16, color: _warning),
                        const SizedBox(width: 4),
                        Text(AppLocalizations.of(context)!.awayStrong, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _warning)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...topAwayTeams.asMap().entries.map((entry) {
                      final index = entry.key;
                      final team = entry.value;
                      final awayGames = (team.awayWin ?? 0) + (team.awayDraw ?? 0) + (team.awayLose ?? 0);
                      final winRate = awayGames > 0 ? ((team.awayWin ?? 0) / awayGames * 100).toInt() : 0;
                      return _buildCompactTeamRow(context, index + 1, team, AppLocalizations.of(context)!.nWins(team.awayWin ?? 0), '$winRate%', _warning);
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

  Widget _buildCompactTeamRow(BuildContext context, int rank, ApiFootballStanding team, String wins, String rate, Color color) {
    return InkWell(
      onTap: () => context.push('/team/${team.teamId}'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Text('$rank', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textSecondary)),
            const SizedBox(width: 6),
            if (team.teamLogo != null)
              CachedNetworkImage(
                imageUrl: team.teamLogo!,
                width: 18,
                height: 18,
                errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 18),
              ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                team.teamName,
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                rate,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
              ),
            ),
          ],
        ),
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
              Text(AppLocalizations.of(context)!.cardRanking, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          _buildCardSection(context: context, title: AppLocalizations.of(context)!.mostYellows, icon: Icons.square, color: _warning, asyncData: topYellowAsync, isYellow: true),
          const SizedBox(height: 16),
          _buildCardSection(context: context, title: AppLocalizations.of(context)!.mostReds, icon: Icons.square, color: _error, asyncData: topRedAsync, isYellow: false),
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
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary)),
          ],
        ),
        const SizedBox(height: 10),
        asyncData.when(
          data: (players) {
            if (players.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(AppLocalizations.of(context)!.noDataAvailable, style: TextStyle(fontSize: 12, color: _textSecondary)),
              );
            }
            final top5 = players.take(5).toList();
            return Column(
              children: top5.asMap().entries.map((entry) {
                final index = entry.key;
                final player = entry.value;
                final cardCount = isYellow ? (player.yellowCards ?? 0) : (player.redCards ?? 0);

                return InkWell(
                  onTap: () => context.push('/player/${player.playerId}'),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Text('${index + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: index == 0 ? color : _textSecondary)),
                        ),
                        if (player.playerPhoto != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: player.playerPhoto!,
                              width: 24, height: 24, fit: BoxFit.cover,
                              placeholder: (_, __) => Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle)),
                              errorWidget: (_, __, ___) => Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle), child: Icon(Icons.person, size: 14, color: Colors.grey)),
                            ),
                          )
                        else
                          Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle), child: Icon(Icons.person, size: 14, color: Colors.grey)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(player.playerName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                              Row(
                                children: [
                                  if (player.teamLogo != null) ...[
                                    CachedNetworkImage(imageUrl: player.teamLogo!, width: 12, height: 12, errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 12)),
                                    const SizedBox(width: 4),
                                  ],
                                  Expanded(child: Text(player.teamName, style: TextStyle(fontSize: 10, color: _textSecondary), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text('$cardCount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
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
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(AppLocalizations.of(context)!.loadFailedShort, style: TextStyle(fontSize: 12, color: _textSecondary)),
          ),
        ),
      ],
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
    // 최다 패배
    final sortedByLose = [...standings]..sort((a, b) => b.lose.compareTo(a.lose));
    final topLosers = sortedByLose.take(3).toList();

    // 최다 실점
    final sortedByGoalsAgainst = [...standings]..sort((a, b) => b.goalsAgainst.compareTo(a.goalsAgainst));
    final topConceding = sortedByGoalsAgainst.take(3).toList();

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
                  color: _error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.trending_down, color: _error, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.bottomAnalysis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 최다 패배
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.mostLosses, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textSecondary)),
                    const SizedBox(height: 10),
                    ...topLosers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final team = entry.value;
                      return _buildBottomTeamRow(context, index + 1, team, '${team.lose}패');
                    }),
                  ],
                ),
              ),
              Container(width: 1, height: 100, color: _border, margin: const EdgeInsets.symmetric(horizontal: 12)),
              // 최다 실점
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.mostConceded, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textSecondary)),
                    const SizedBox(height: 10),
                    ...topConceding.asMap().entries.map((entry) {
                      final index = entry.key;
                      final team = entry.value;
                      return _buildBottomTeamRow(context, index + 1, team, '${team.goalsAgainst}실점');
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

  Widget _buildBottomTeamRow(BuildContext context, int rank, ApiFootballStanding team, String stat) {
    return InkWell(
      onTap: () => context.push('/team/${team.teamId}'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Text('$rank', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textSecondary)),
            const SizedBox(width: 6),
            if (team.teamLogo != null)
              CachedNetworkImage(
                imageUrl: team.teamLogo!,
                width: 18,
                height: 18,
                errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 18),
              ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                team.teamName,
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                stat,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 시즌 선택 드롭다운
class _SeasonDropdown extends StatelessWidget {
  final List<int> seasons;
  final int currentSeason;
  final ValueChanged<int> onSeasonChanged;
  final String? leagueType; // "League" or "Cup"

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _SeasonDropdown({
    required this.seasons,
    required this.currentSeason,
    required this.onSeasonChanged,
    this.leagueType,
  });

  @override
  Widget build(BuildContext context) {
    // 시즌을 최신순으로 정렬
    final sortedSeasons = seasons.toList()..sort((a, b) => b.compareTo(a));

    return GestureDetector(
      onTap: () => _showSeasonPicker(context, sortedSeasons),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatSeason(currentSeason),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 18, color: _primary),
          ],
        ),
      ),
    );
  }

  String _formatSeason(int season) {
    // 컵 대회(월드컵, 아시안컵 등)는 단일 연도로 표시
    // 리그(EPL, 라리가 등)는 시즌 형식(2024-25)으로 표시
    if (leagueType == 'Cup') {
      return '$season';
    }
    return '$season-${(season + 1) % 100}';
  }

  void _showSeasonPicker(BuildContext context, List<int> sortedSeasons) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 헤더
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppLocalizations.of(context)!.selectSeason,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
            ),
            // 시즌 목록
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: sortedSeasons.length,
                itemBuilder: (context, index) {
                  final season = sortedSeasons[index];
                  final isSelected = season == currentSeason;

                  return ListTile(
                    onTap: () {
                      Navigator.pop(context);
                      onSeasonChanged(season);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    tileColor: isSelected ? _primary.withValues(alpha: 0.08) : null,
                    leading: Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: isSelected ? _primary : _textSecondary,
                    ),
                    title: Text(
                      _formatSeason(season),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? _primary : _textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: _primary)
                        : null,
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
