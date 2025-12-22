import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_football_service.dart';
import '../../../core/constants/api_football_ids.dart';

/// 리그 정보 Provider
final leagueInfoProvider = FutureProvider.family<ApiFootballLeague?, int>((ref, leagueId) async {
  final service = ApiFootballService();
  return service.getLeagueById(leagueId);
});

/// 리그 순위 Provider
final leagueStandingsProvider = FutureProvider.family<List<ApiFootballStanding>, int>((ref, leagueId) async {
  final service = ApiFootballService();
  final season = LeagueIds.getCurrentSeason();
  return service.getStandings(leagueId, season);
});

/// 조별 리그 순위 Provider (그룹별로 반환)
final leagueStandingsGroupedProvider = FutureProvider.family<Map<String, List<ApiFootballStanding>>, int>((ref, leagueId) async {
  final service = ApiFootballService();
  final season = LeagueIds.getCurrentSeason();
  return service.getStandingsGrouped(leagueId, season);
});

/// 조별 리그 여부 확인 Provider
final isGroupStageLeagueProvider = FutureProvider.family<bool, int>((ref, leagueId) async {
  final service = ApiFootballService();
  final season = LeagueIds.getCurrentSeason();
  return service.isGroupStageLeague(leagueId, season);
});

/// 리그 경기 일정 Provider
final leagueFixturesDetailProvider = FutureProvider.family<List<ApiFootballFixture>, int>((ref, leagueId) async {
  final service = ApiFootballService();
  final season = LeagueIds.getCurrentSeason();
  return service.getFixturesByLeague(leagueId, season);
});

/// 리그 득점 순위 Provider
final leagueTopScorersProvider = FutureProvider.family<List<ApiFootballTopScorer>, int>((ref, leagueId) async {
  final service = ApiFootballService();
  final season = LeagueIds.getCurrentSeason();
  return service.getTopScorers(leagueId, season);
});

/// 리그 도움 순위 Provider
final leagueTopAssistsProvider = FutureProvider.family<List<ApiFootballTopScorer>, int>((ref, leagueId) async {
  final service = ApiFootballService();
  final season = LeagueIds.getCurrentSeason();
  return service.getTopAssists(leagueId, season);
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
      body: leagueAsync.when(
        data: (league) => _buildContent(league, leagueIdInt),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildError(leagueIdInt),
      ),
    );
  }

  Widget _buildContent(ApiFootballLeague? league, int leagueId) {
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
                              league?.name ?? '리그',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                            if (league?.countryName != null) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (league?.countryFlag != null) ...[
                                    CachedNetworkImage(
                                      imageUrl: league!.countryFlag!,
                                      width: 14,
                                      height: 10,
                                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    league!.countryName!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
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
                  tabs: const [
                    Tab(text: '일정'),
                    Tab(text: '순위'),
                    Tab(text: '통계'),
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
          Text(
            '리그 정보를 불러올 수 없습니다',
            style: TextStyle(color: _textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.invalidate(leagueInfoProvider(leagueId)),
            child: const Text('다시 시도'),
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
          child: Row(
            children: [
              _SubTabButton(
                label: '순위',
                isSelected: selectedSubTab == 0,
                onTap: () => ref.read(_standingsSubTabProvider.notifier).state = 0,
              ),
              _SubTabButton(
                label: '득점',
                isSelected: selectedSubTab == 1,
                onTap: () => ref.read(_standingsSubTabProvider.notifier).state = 1,
              ),
              _SubTabButton(
                label: '도움',
                isSelected: selectedSubTab == 2,
                onTap: () => ref.read(_standingsSubTabProvider.notifier).state = 2,
              ),
            ],
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
            child: Text('순위 정보가 없습니다', style: TextStyle(color: _textSecondary)),
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
        child: Text('순위를 불러올 수 없습니다', style: TextStyle(color: _textSecondary)),
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
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const SizedBox(width: 24, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
                const SizedBox(width: 6),
                const Expanded(child: Text('팀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                _buildCompactHeaderCell('경'),
                _buildCompactHeaderCell('승'),
                _buildCompactHeaderCell('무'),
                _buildCompactHeaderCell('패'),
                _buildCompactHeaderCell('득'),
                _buildCompactHeaderCell('실'),
                _buildCompactHeaderCell('득실'),
                const SizedBox(
                  width: 32,
                  child: Text('점', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
                ),
              ],
            ),
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
            child: Text('순위 정보가 없습니다', style: TextStyle(color: _textSecondary)),
          );
        }

        return Column(
          children: [
            _buildLeagueLegend(standings),
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
                          const SizedBox(width: 28, child: Text('순위', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('팀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          _buildHeaderCell('경기'),
                          _buildHeaderCell('승'),
                          _buildHeaderCell('무'),
                          _buildHeaderCell('패'),
                          _buildHeaderCell('득점'),
                          _buildHeaderCell('실점'),
                          _buildHeaderCell('득실'),
                          const SizedBox(
                            width: 36,
                            child: Text('승점', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
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
        child: Text('순위를 불러올 수 없습니다', style: TextStyle(color: _textSecondary)),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return SizedBox(
      width: 28,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
    );
  }

  Widget _buildLeagueLegend(List<ApiFootballStanding> standings) {
    final descriptions = standings
        .where((s) => s.description != null && s.description!.isNotEmpty)
        .map((s) => s.description!.toLowerCase())
        .toSet();

    final legendItems = <Widget>[];

    final hasUclDirect = descriptions.any((d) => d.contains('champions') && !d.contains('championship') && d.contains('1/8'));
    final hasUclPlayoff = descriptions.any((d) => d.contains('champions') && !d.contains('championship') && d.contains('1/16'));
    final hasUclQualification = descriptions.any((d) => d.contains('champions') && !d.contains('championship') && (d.contains('qualification') || d.contains('qualifying')));
    final hasUclGeneral = descriptions.any((d) => d.contains('champions') && !d.contains('championship') && !d.contains('1/8') && !d.contains('1/16') && !d.contains('qualification') && !d.contains('qualifying'));

    if (hasUclDirect) legendItems.add(_LegendItem(color: Colors.blue.shade800, label: 'UCL 직행'));
    if (hasUclPlayoff) legendItems.add(_LegendItem(color: Colors.cyan.shade600, label: 'UCL PO'));
    if (hasUclGeneral) legendItems.add(_LegendItem(color: Colors.blue, label: 'UCL'));
    if (hasUclQualification && !hasUclPlayoff) legendItems.add(_LegendItem(color: Colors.cyan.shade600, label: 'UCL 예선'));

    final hasUelDirect = descriptions.any((d) => d.contains('europa') && d.contains('1/8'));
    final hasUelPlayoff = descriptions.any((d) => d.contains('europa') && d.contains('1/16'));
    final hasUelGeneral = descriptions.any((d) => d.contains('europa') && !d.contains('1/8') && !d.contains('1/16') && !d.contains('qualification') && !d.contains('qualifying') && !d.contains('relegation'));

    if (hasUelDirect) legendItems.add(_LegendItem(color: Colors.orange.shade800, label: 'UEL 직행'));
    if (hasUelPlayoff) legendItems.add(_LegendItem(color: Colors.amber.shade700, label: 'UEL PO'));
    if (hasUelGeneral) legendItems.add(_LegendItem(color: Colors.orange, label: 'UEL'));

    if (descriptions.any((d) => d.contains('conference') && !d.contains('relegation'))) {
      legendItems.add(_LegendItem(color: Colors.green, label: 'UECL'));
    }

    if (descriptions.any((d) => d.contains('relegation') && !d.contains('europa') && !d.contains('conference') && !d.contains('round'))) {
      legendItems.add(_LegendItem(color: Colors.red, label: '강등'));
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
        if (scorers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_soccer, size: 48, color: _textSecondary),
                const SizedBox(height: 16),
                Text('득점 순위 정보가 없습니다', style: TextStyle(color: _textSecondary)),
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
                    const SizedBox(width: 28, child: Text('순위', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('선수', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    const SizedBox(
                      width: 50,
                      child: Text('출전', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
                    ),
                    const SizedBox(
                      width: 50,
                      child: Text('득점', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
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
        child: Text('득점 순위를 불러올 수 없습니다', style: TextStyle(color: _textSecondary)),
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
        if (assists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.handshake_outlined, size: 48, color: _textSecondary),
                const SizedBox(height: 16),
                Text('도움 순위 정보가 없습니다', style: TextStyle(color: _textSecondary)),
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
                    const SizedBox(width: 28, child: Text('순위', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('선수', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    const SizedBox(
                      width: 50,
                      child: Text('출전', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
                    ),
                    const SizedBox(
                      width: 50,
                      child: Text('도움', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
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
        child: Text('도움 순위를 불러올 수 없습니다', style: TextStyle(color: _textSecondary)),
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

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    final dateStr = '${date.month}월 ${date.day}일 ($weekday)';

    if (targetDate == today) {
      return '오늘 $dateStr';
    } else if (targetDate == tomorrow) {
      return '내일 $dateStr';
    } else if (targetDate == yesterday) {
      return '어제 $dateStr';
    }

    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    final fixturesAsync = ref.watch(leagueFixturesDetailProvider(widget.leagueId));

    return fixturesAsync.when(
      data: (fixtures) {
        if (fixtures.isEmpty) {
          return Center(
            child: Text('경기 일정이 없습니다', style: TextStyle(color: _textSecondary)),
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

        // 날짜별로 그룹화
        final groupedByDate = <String, List<ApiFootballFixture>>{};
        for (final fixture in sortedFixtures) {
          final dateKey = DateFormat('yyyy-MM-dd').format(fixture.date);
          groupedByDate.putIfAbsent(dateKey, () => []).add(fixture);
        }

        final dateKeys = groupedByDate.keys.toList()..sort();

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
              children: dateKeys.map((dateKey) {
                final dateFixtures = groupedByDate[dateKey]!;
                final date = DateTime.parse(dateKey);
                final isToday = _isToday(date);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 날짜 헤더
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isToday ? const Color(0xFF2563EB).withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatDateHeader(date),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isToday ? const Color(0xFF2563EB) : _textSecondary,
                        ),
                      ),
                    ),
                    // 경기 카드들
                    Container(
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
                    const SizedBox(height: 8),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text('일정을 불러올 수 없습니다', style: TextStyle(color: _textSecondary)),
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
              child: _buildTimeOrStatus(),
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

  Widget _buildTimeOrStatus() {
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
        '종료',
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

    return standingsAsync.when(
      data: (standings) {
        if (standings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 48, color: _textSecondary),
                const SizedBox(height: 16),
                Text('리그 통계 정보가 없습니다', style: TextStyle(color: _textSecondary)),
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text('통계를 불러올 수 없습니다', style: TextStyle(color: _textSecondary)),
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
                '리그 개요',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _OverviewStatBox(icon: Icons.sports_soccer, label: '총 골', value: '$totalGoals', color: _success),
              const SizedBox(width: 12),
              _OverviewStatBox(icon: Icons.speed, label: '경기당 골', value: goalsPerMatch.toStringAsFixed(2), color: _primary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _OverviewStatBox(icon: Icons.home, label: '홈 승리', value: '$totalHomeWins', color: _success),
              const SizedBox(width: 12),
              _OverviewStatBox(icon: Icons.flight, label: '원정 승리', value: '$totalAwayWins', color: _warning),
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
                    Text('홈 승', style: TextStyle(fontSize: 12, color: _success, fontWeight: FontWeight.w600)),
                    Text('무승부', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                    Text('원정 승', style: TextStyle(fontSize: 12, color: _warning, fontWeight: FontWeight.w600)),
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
                    Text('$totalHomeWins경기', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    Text('$totalDraws경기', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    Text('$totalAwayWins경기', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
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
                '팀 순위',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TeamStatRow(icon: Icons.sports_soccer, label: '최다 득점', team: topScorer, value: '${topScorer.goalsFor}골', color: _success),
          _TeamStatRow(icon: Icons.gpp_bad, label: '최다 실점', team: topConceder, value: '${topConceder.goalsAgainst}골', color: _error),
          _TeamStatRow(icon: Icons.military_tech, label: '최다 승리', team: topWinner, value: '${topWinner.win}승', color: _primary),
          _TeamStatRow(icon: Icons.balance, label: '최다 무승부', team: topDrawer, value: '${topDrawer.draw}무', color: _textSecondary),
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
                '골 분석',
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
                        Text('홈 골', style: TextStyle(fontSize: 12, color: _textSecondary)),
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
                        '총 ${totalHomeGoals + totalAwayGoals}골',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textPrimary),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('원정 골', style: TextStyle(fontSize: 12, color: _textSecondary)),
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
            '득실차 상위 5팀',
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
