import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/api_football_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../favorites/providers/favorites_provider.dart';

// Providers (API-Football 사용)
final playerDetailProvider =
    FutureProvider.family<ApiFootballPlayer?, String>((ref, playerId) async {
  final service = ApiFootballService();
  final id = int.tryParse(playerId);
  if (id == null) return null;
  return service.getPlayerById(id);
});

// 여러 시즌 통계 Provider (최근 5시즌)
final playerMultiSeasonStatsProvider =
    FutureProvider.family<List<ApiFootballPlayer>, String>((ref, playerId) async {
  final service = ApiFootballService();
  final id = int.tryParse(playerId);
  if (id == null) return [];

  final currentYear = DateTime.now().year;
  final seasons = <ApiFootballPlayer>[];

  // 최근 5시즌 데이터 조회
  for (int year = currentYear; year >= currentYear - 4; year--) {
    try {
      final player = await service.getPlayerById(id, season: year);
      if (player != null && player.statistics.isNotEmpty) {
        // 출전 기록이 있는 시즌만 추가
        final hasAppearances = player.statistics.any((s) => (s.appearances ?? 0) > 0);
        if (hasAppearances) {
          seasons.add(player);
        }
      }
    } catch (_) {
      // 해당 시즌 데이터 없으면 무시
    }
  }

  return seasons;
});

final playerTeamProvider =
    FutureProvider.family<ApiFootballTeam?, String?>((ref, teamId) async {
  if (teamId == null || teamId.isEmpty) return null;
  final service = ApiFootballService();
  final id = int.tryParse(teamId);
  if (id == null) return null;
  return service.getTeamById(id);
});

// 이적 기록 Provider
final playerTransfersProvider =
    FutureProvider.family<List<ApiFootballTransfer>, String>((ref, playerId) async {
  final service = ApiFootballService();
  final id = int.tryParse(playerId);
  if (id == null) return [];
  return service.getPlayerTransfers(id);
});

// 트로피 Provider
final playerTrophiesProvider =
    FutureProvider.family<List<ApiFootballTrophy>, String>((ref, playerId) async {
  final service = ApiFootballService();
  final id = int.tryParse(playerId);
  if (id == null) return [];
  return service.getPlayerTrophies(id);
});

class PlayerDetailScreen extends ConsumerWidget {
  final String playerId;

  static const _textSecondary = Color(0xFF6B7280);
  static const _background = Color(0xFFF9FAFB);

  const PlayerDetailScreen({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(playerDetailProvider(playerId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: playerAsync.when(
          data: (player) {
            if (player == null) {
              return SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(context),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off,
                                size: 64, color: _textSecondary),
                            const SizedBox(height: 16),
                            Text(
                              '선수 정보를 찾을 수 없습니다',
                              style:
                                  TextStyle(color: _textSecondary, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return _PlayerDetailContent(player: player, playerId: playerId);
          },
          loading: () => const LoadingIndicator(),
          error: (e, _) => SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: Center(
                    child: Text('오류: $e',
                        style: const TextStyle(color: _textSecondary)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            color: const Color(0xFF111827),
            onPressed: () => context.pop(),
          ),
          const Expanded(
            child: Text(
              '선수 정보',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _PlayerDetailContent extends ConsumerStatefulWidget {
  final ApiFootballPlayer player;
  final String playerId;

  const _PlayerDetailContent({required this.player, required this.playerId});

  @override
  ConsumerState<_PlayerDetailContent> createState() => _PlayerDetailContentState();
}

class _PlayerDetailContentState extends ConsumerState<_PlayerDetailContent>
    with SingleTickerProviderStateMixin {
  static const _background = Color(0xFFF9FAFB);
  static const _primary = Color(0xFF2563EB);
  static const _textSecondary = Color(0xFF6B7280);

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
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // 헤더
              SliverToBoxAdapter(
                child: _PlayerHeader(player: widget.player, playerId: widget.playerId),
              ),
              // 탭바
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  child: Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: _primary,
                      unselectedLabelColor: _textSecondary,
                      indicatorColor: _primary,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(text: '프로필'),
                        Tab(text: '시즌 통계'),
                        Tab(text: '커리어'),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              // 프로필 탭
              _ProfileTab(player: widget.player, playerId: widget.playerId),
              // 시즌 통계 탭
              _SeasonStatsTab(player: widget.player, playerId: widget.playerId),
              // 커리어 탭 (이적, 트로피)
              _CareerTab(playerId: widget.playerId),
            ],
          ),
        ),
      ),
    );
  }
}

// 탭바 고정용 Delegate
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _TabBarDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

// 프로필 탭
class _ProfileTab extends StatelessWidget {
  final ApiFootballPlayer player;
  final String playerId;

  const _ProfileTab({required this.player, required this.playerId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _BasicInfoCard(player: player),
          const SizedBox(height: 12),
          // 현재 시즌 통계 요약
          if (player.statistics.isNotEmpty)
            _CurrentSeasonSummary(player: player),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// 현재 시즌 요약 카드
class _CurrentSeasonSummary extends StatelessWidget {
  final ApiFootballPlayer player;

  static const _primary = Color(0xFF2563EB);
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);
  static const _error = Color(0xFFEF4444);
  static const _textPrimary = Color(0xFF111827);
  static const _border = Color(0xFFE5E7EB);

  const _CurrentSeasonSummary({required this.player});

  @override
  Widget build(BuildContext context) {
    // 모든 리그 통계 합산
    int totalGoals = 0;
    int totalAssists = 0;
    int totalAppearances = 0;
    int totalMinutes = 0;
    int totalYellowCards = 0;
    int totalRedCards = 0;

    for (final stats in player.statistics) {
      totalGoals += stats.goals ?? 0;
      totalAssists += stats.assists ?? 0;
      totalAppearances += stats.appearances ?? 0;
      totalMinutes += stats.minutes ?? 0;
      totalYellowCards += stats.yellowCards ?? 0;
      totalRedCards += stats.redCards ?? 0;
    }

    if (totalAppearances == 0) return const SizedBox.shrink();

    final season = player.statistics.first.season;
    final seasonText = season != null ? '$season/${season + 1}' : '현재 시즌';

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
                child: Icon(Icons.bar_chart, color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                '$seasonText 통계 요약',
                style: const TextStyle(
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
              _SummaryStatBox(
                icon: Icons.sports_soccer,
                label: '골',
                value: '$totalGoals',
                color: _success,
              ),
              const SizedBox(width: 12),
              _SummaryStatBox(
                icon: Icons.handshake_outlined,
                label: '도움',
                value: '$totalAssists',
                color: _primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SummaryStatBox(
                icon: Icons.timer_outlined,
                label: '출전',
                value: '$totalAppearances경기',
                color: Colors.purple,
              ),
              const SizedBox(width: 12),
              _SummaryStatBox(
                icon: Icons.schedule,
                label: '출전시간',
                value: '$totalMinutes분',
                color: Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 카드 통계
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CardStatItem(
                  color: _warning,
                  value: totalYellowCards,
                  label: '경고',
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: _border,
                ),
                _CardStatItem(
                  color: _error,
                  value: totalRedCards,
                  label: '퇴장',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryStatBox({
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
            Column(
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
          ],
        ),
      ),
    );
  }
}

// 시즌 통계 탭
class _SeasonStatsTab extends ConsumerWidget {
  final ApiFootballPlayer player;
  final String playerId;

  static const _textSecondary = Color(0xFF6B7280);

  const _SeasonStatsTab({required this.player, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final multiSeasonAsync = ref.watch(playerMultiSeasonStatsProvider(playerId));

    return multiSeasonAsync.when(
      data: (seasons) {
        if (seasons.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 64, color: _textSecondary),
                const SizedBox(height: 16),
                Text(
                  '시즌 통계가 없습니다',
                  style: TextStyle(color: _textSecondary, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 시즌별 통계 요약 테이블
              _SeasonStatsTable(seasons: seasons),
              const SizedBox(height: 16),
              // 각 시즌 상세 카드
              ...seasons.map((seasonData) => _SeasonDetailCard(player: seasonData)),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('시즌별 통계를 불러오는 중...'),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Text('오류: $e', style: TextStyle(color: _textSecondary)),
      ),
    );
  }
}

// 시즌별 통계 테이블
class _SeasonStatsTable extends StatelessWidget {
  final List<ApiFootballPlayer> seasons;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _SeasonStatsTable({required this.seasons});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                const Expanded(flex: 2, child: Text('시즌', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                const Expanded(child: Text('경기', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center)),
                const Expanded(child: Text('골', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center)),
                const Expanded(child: Text('도움', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center)),
                const Expanded(child: Text('평점', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center)),
              ],
            ),
          ),
          // 데이터 행
          ...seasons.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;

            // 해당 시즌 통계 합산
            int totalAppearances = 0;
            int totalGoals = 0;
            int totalAssists = 0;
            double avgRating = 0;
            int ratingCount = 0;

            for (final stats in player.statistics) {
              totalAppearances += stats.appearances ?? 0;
              totalGoals += stats.goals ?? 0;
              totalAssists += stats.assists ?? 0;
              if (stats.rating != null) {
                final r = double.tryParse(stats.rating!);
                if (r != null) {
                  avgRating += r;
                  ratingCount++;
                }
              }
            }

            if (ratingCount > 0) avgRating /= ratingCount;

            final season = player.statistics.first.season;
            final seasonText = season != null ? '${season.toString().substring(2)}/${(season + 1).toString().substring(2)}' : '-';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: index.isOdd ? Colors.grey.shade50 : Colors.white,
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      seasonText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  Expanded(child: Text('$totalAppearances', style: const TextStyle(fontSize: 13), textAlign: TextAlign.center)),
                  Expanded(child: Text('$totalGoals', style: TextStyle(fontSize: 13, fontWeight: totalGoals > 0 ? FontWeight.w600 : FontWeight.normal, color: totalGoals > 0 ? const Color(0xFF10B981) : _textPrimary), textAlign: TextAlign.center)),
                  Expanded(child: Text('$totalAssists', style: TextStyle(fontSize: 13, fontWeight: totalAssists > 0 ? FontWeight.w600 : FontWeight.normal, color: totalAssists > 0 ? _primary : _textPrimary), textAlign: TextAlign.center)),
                  Expanded(
                    child: Text(
                      avgRating > 0 ? avgRating.toStringAsFixed(2) : '-',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _getRatingColor(avgRating),
                      ),
                      textAlign: TextAlign.center,
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

  Color _getRatingColor(double rating) {
    if (rating >= 8.0) return const Color(0xFF10B981);
    if (rating >= 7.0) return _primary;
    if (rating >= 6.0) return const Color(0xFFF59E0B);
    if (rating > 0) return const Color(0xFFEF4444);
    return _textSecondary;
  }
}

// 시즌 상세 카드
class _SeasonDetailCard extends StatelessWidget {
  final ApiFootballPlayer player;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _SeasonDetailCard({required this.player});

  @override
  Widget build(BuildContext context) {
    final season = player.statistics.isNotEmpty ? player.statistics.first.season : null;
    final seasonText = season != null ? '$season/${season + 1} 시즌' : '시즌 정보 없음';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            seasonText,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          subtitle: Text(
            '${player.statistics.length}개 대회 참가',
            style: TextStyle(fontSize: 12, color: _textSecondary),
          ),
          children: player.statistics.map((stats) {
            if ((stats.appearances ?? 0) == 0) return const SizedBox.shrink();
            return _LeagueStatsRow(stats: stats);
          }).toList(),
        ),
      ),
    );
  }
}

// 리그별 통계 행
class _LeagueStatsRow extends StatelessWidget {
  final ApiFootballPlayerStats stats;

  static const _primary = Color(0xFF2563EB);
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);
  static const _error = Color(0xFFEF4444);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _LeagueStatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 리그 헤더
          Row(
            children: [
              if (stats.teamLogo != null)
                CachedNetworkImage(
                  imageUrl: stats.teamLogo!,
                  width: 20,
                  height: 20,
                  errorWidget: (_, __, ___) => Icon(Icons.shield, size: 20, color: _textSecondary),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.leagueName ?? '리그',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    if (stats.teamName != null)
                      Text(
                        stats.teamName!,
                        style: TextStyle(fontSize: 11, color: _textSecondary),
                      ),
                  ],
                ),
              ),
              // 평점
              if (stats.rating != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRatingColor(double.tryParse(stats.rating!) ?? 0).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 10, color: _getRatingColor(double.tryParse(stats.rating!) ?? 0)),
                      const SizedBox(width: 4),
                      Text(
                        double.tryParse(stats.rating!)?.toStringAsFixed(2) ?? '-',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _getRatingColor(double.tryParse(stats.rating!) ?? 0),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // 통계 행
          Row(
            children: [
              _MiniStatChip(label: '경기', value: '${stats.appearances ?? 0}'),
              _MiniStatChip(label: '선발', value: '${stats.lineups ?? 0}'),
              _MiniStatChip(label: '골', value: '${stats.goals ?? 0}', highlight: (stats.goals ?? 0) > 0, highlightColor: _success),
              _MiniStatChip(label: '도움', value: '${stats.assists ?? 0}', highlight: (stats.assists ?? 0) > 0, highlightColor: _primary),
              _MiniStatChip(label: '경고', value: '${stats.yellowCards ?? 0}', highlight: (stats.yellowCards ?? 0) > 0, highlightColor: _warning),
              _MiniStatChip(label: '퇴장', value: '${stats.redCards ?? 0}', highlight: (stats.redCards ?? 0) > 0, highlightColor: _error),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 8.0) return _success;
    if (rating >= 7.0) return _primary;
    if (rating >= 6.0) return _warning;
    if (rating > 0) return _error;
    return _textSecondary;
  }
}

class _MiniStatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final Color? highlightColor;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _MiniStatChip({
    required this.label,
    required this.value,
    this.highlight = false,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
              color: highlight && highlightColor != null ? highlightColor : _textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: _textSecondary),
          ),
        ],
      ),
    );
  }
}

// 커리어 탭 (이적, 트로피)
class _CareerTab extends StatelessWidget {
  final String playerId;

  const _CareerTab({required this.playerId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _TransfersSection(playerId: playerId),
          _TrophiesSection(playerId: playerId),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _PlayerHeader extends ConsumerWidget {
  final ApiFootballPlayer player;
  final String playerId;

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _PlayerHeader({required this.player, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = player.statistics.isNotEmpty ? player.statistics.first : null;
    final teamId = stats?.teamId?.toString();
    final teamAsync = ref.watch(playerTeamProvider(teamId));
    final teamLogo = teamAsync.valueOrNull?.logo;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 앱바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  color: _textPrimary,
                  onPressed: () => context.pop(),
                ),
                const Expanded(
                  child: Text(
                    '선수 정보',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                _PlayerFavoriteButton(playerId: playerId),
              ],
            ),
          ),

          // 선수 사진
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _border, width: 3),
              color: Colors.grey.shade100,
            ),
            child: ClipOval(
              child: player.photo != null
                  ? CachedNetworkImage(
                      imageUrl: player.photo!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Icon(
                        Icons.person,
                        size: 50,
                        color: _textSecondary,
                      ),
                      errorWidget: (_, __, ___) => Icon(
                        Icons.person,
                        size: 50,
                        color: _textSecondary,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 50,
                      color: _textSecondary,
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // 선수 이름
          Text(
            player.name,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // 팀 & 포지션
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (teamLogo != null) ...[
                CachedNetworkImage(
                  imageUrl: teamLogo,
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF6B7280)),
                  ),
                  errorWidget: (_, __, ___) =>
                      Icon(Icons.shield, size: 20, color: _textSecondary),
                ),
                const SizedBox(width: 6),
              ] else if (teamAsync.isLoading) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF6B7280)),
                ),
                const SizedBox(width: 6),
              ],
              if (stats?.teamName != null)
                Text(
                  stats!.teamName!,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                  ),
                ),
              if (stats?.teamName != null && stats?.position != null)
                Text(
                  ' · ',
                  style: TextStyle(color: _textSecondary.withValues(alpha: 0.5)),
                ),
              if (stats?.position != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getPositionKorean(stats!.position!),
                    style: TextStyle(
                      color: _primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getPositionKorean(String position) {
    switch (position.toLowerCase()) {
      case 'goalkeeper':
        return '골키퍼';
      case 'defender':
        return '수비수';
      case 'midfielder':
        return '미드필더';
      case 'attacker':
      case 'forward':
        return '공격수';
      default:
        return position;
    }
  }
}

class _BasicInfoCard extends StatelessWidget {
  final ApiFootballPlayer player;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _border = Color(0xFFE5E7EB);

  const _BasicInfoCard({required this.player});

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
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person_outline, color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                '기본 정보',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.flag_outlined, label: '국적', value: player.nationality ?? '-'),
          _InfoRow(icon: Icons.cake_outlined, label: '생년월일', value: player.birthDate ?? '-'),
          if (player.age != null)
            _InfoRow(icon: Icons.calendar_today_outlined, label: '나이', value: '${player.age}세'),
          _InfoRow(icon: Icons.height, label: '키', value: player.height ?? '-'),
          _InfoRow(icon: Icons.fitness_center_outlined, label: '몸무게', value: player.weight ?? '-'),
          if (player.birthPlace != null)
            _InfoRow(icon: Icons.location_on_outlined, label: '출생지', value: player.birthPlace!),
        ],
      ),
    );
  }
}

class _CardStatItem extends StatelessWidget {
  final Color color;
  final int value;
  final String label;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _CardStatItem({
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: _textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransfersSection extends ConsumerWidget {
  final String playerId;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _TransfersSection({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfersAsync = ref.watch(playerTransfersProvider(playerId));

    return transfersAsync.when(
      data: (transfers) {
        if (transfers.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                    child: Icon(Icons.swap_horiz, color: _primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '이적 기록',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...transfers.take(5).map((transfer) => _TransferItem(transfer: transfer)),
              if (transfers.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '외 ${transfers.length - 5}건의 이적 기록',
                    style: TextStyle(fontSize: 12, color: _textSecondary),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _TransferItem extends StatelessWidget {
  final ApiFootballTransfer transfer;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _TransferItem({required this.transfer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          // From Team
          Expanded(
            child: Row(
              children: [
                if (transfer.teamOutLogo != null)
                  CachedNetworkImage(
                    imageUrl: transfer.teamOutLogo!,
                    width: 24,
                    height: 24,
                    errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 24),
                  )
                else
                  const Icon(Icons.shield, size: 24, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    transfer.teamOutName ?? '-',
                    style: const TextStyle(fontSize: 11, color: _textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Arrow
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, size: 16, color: _textSecondary),
          ),
          // To Team
          Expanded(
            child: Row(
              children: [
                if (transfer.teamInLogo != null)
                  CachedNetworkImage(
                    imageUrl: transfer.teamInLogo!,
                    width: 24,
                    height: 24,
                    errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 24),
                  )
                else
                  const Icon(Icons.shield, size: 24, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    transfer.teamInName ?? '-',
                    style: const TextStyle(fontSize: 11, color: _textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrophiesSection extends ConsumerWidget {
  final String playerId;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _warning = Color(0xFFF59E0B);

  const _TrophiesSection({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trophiesAsync = ref.watch(playerTrophiesProvider(playerId));

    return trophiesAsync.when(
      data: (trophies) {
        if (trophies.isEmpty) return const SizedBox.shrink();

        // Winner만 필터링
        final winnerTrophies = trophies.where((t) => t.place == 'Winner').toList();
        if (winnerTrophies.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                    child: Icon(Icons.emoji_events, color: _warning, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '수상 경력',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${winnerTrophies.length}개',
                      style: TextStyle(
                        color: _warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...winnerTrophies.take(10).map((trophy) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.star, size: 14, color: _warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trophy.league ?? '-',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                    if (trophy.season != null)
                      Text(
                        trophy.season!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _textSecondary,
                        ),
                      ),
                  ],
                ),
              )),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PlayerFavoriteButton extends ConsumerWidget {
  final String playerId;

  static const _error = Color(0xFFEF4444);

  const _PlayerFavoriteButton({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowedAsync = ref.watch(isPlayerFollowedProvider(playerId));

    return isFollowedAsync.when(
      data: (isFollowed) => IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isFollowed
                ? _error.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isFollowed ? Icons.favorite : Icons.favorite_border,
            color: isFollowed ? _error : Colors.grey,
            size: 20,
          ),
        ),
        onPressed: () async {
          await ref
              .read(favoritesNotifierProvider.notifier)
              .togglePlayerFollow(playerId);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    isFollowed ? '즐겨찾기에서 제거되었습니다' : '즐겨찾기에 추가되었습니다'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
      ),
      loading: () => Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.grey.shade400),
        ),
      ),
      error: (_, __) => IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.favorite_border,
            color: Colors.grey,
            size: 20,
          ),
        ),
        onPressed: () async {
          await ref
              .read(favoritesNotifierProvider.notifier)
              .togglePlayerFollow(playerId);
        },
      ),
    );
  }
}
