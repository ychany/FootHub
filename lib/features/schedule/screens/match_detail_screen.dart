import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/sports_db_service.dart';
import '../../../shared/widgets/loading_indicator.dart';

// Provider for match detail
final matchDetailProvider = FutureProvider.family<SportsDbEvent?, String>((ref, eventId) async {
  final service = SportsDbService();
  return service.getEventById(eventId);
});

// Provider for lineup
final matchLineupProvider = FutureProvider.family<SportsDbLineup?, String>((ref, eventId) async {
  final service = SportsDbService();
  return service.getEventLineup(eventId);
});

// Provider for stats
final matchStatsProvider = FutureProvider.family<SportsDbEventStats?, String>((ref, eventId) async {
  final service = SportsDbService();
  return service.getEventStats(eventId);
});

// Provider for timeline
final matchTimelineProvider = FutureProvider.family<List<SportsDbTimeline>, String>((ref, eventId) async {
  final service = SportsDbService();
  return service.getEventTimeline(eventId);
});


class MatchDetailScreen extends ConsumerWidget {
  final String eventId;

  const MatchDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchDetailProvider(eventId));

    return Scaffold(
      body: matchAsync.when(
        data: (match) {
          if (match == null) {
            return const Center(child: Text('경기 정보를 찾을 수 없습니다'));
          }
          return _MatchDetailContent(match: match);
        },
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('오류: $e')),
      ),
    );
  }
}

class _MatchDetailContent extends ConsumerStatefulWidget {
  final SportsDbEvent match;

  const _MatchDetailContent({required this.match});

  @override
  ConsumerState<_MatchDetailContent> createState() => _MatchDetailContentState();
}

class _MatchDetailContentState extends ConsumerState<_MatchDetailContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addToDiary(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('직관 기록', style: TextStyle(color: Colors.white)),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: _MatchHeader(match: match),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: '정보'),
                  Tab(text: '라인업'),
                  Tab(text: '통계'),
                  Tab(text: '타임라인'),
                ],
              ),
            ),
          ),
        ];
      },
        body: TabBarView(
          controller: _tabController,
          children: [
            _InfoTab(match: match),
            _LineupTab(eventId: match.id, match: match),
            _StatsTab(eventId: match.id, match: match),
            _TimelineTab(eventId: match.id),
          ],
        ),
      ),
    );
  }

  void _addToDiary(BuildContext context) {
    context.push('/attendance/add?matchId=${widget.match.id}');
  }
}

class _MatchHeader extends StatelessWidget {
  final SportsDbEvent match;

  const _MatchHeader({required this.match});

  @override
  Widget build(BuildContext context) {
    final dateTime = match.dateTime;
    final dateStr = dateTime != null
        ? DateFormat('yyyy.MM.dd (E) HH:mm', 'ko').format(dateTime)
        : '날짜 미정';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // League & Date
              Text(
                match.league ?? '',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),

              // Teams & Score
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        if (match.homeTeamBadge != null)
                          CachedNetworkImage(
                            imageUrl: match.homeTeamBadge!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Icon(Icons.shield, size: 48, color: Colors.white54),
                            errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 48, color: Colors.white54),
                          )
                        else
                          const Icon(Icons.shield, size: 48, color: Colors.white54),
                        const SizedBox(height: 8),
                        Text(
                          match.homeTeam ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: match.isFinished
                        ? Text(
                            match.scoreDisplay,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'VS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        if (match.awayTeamBadge != null)
                          CachedNetworkImage(
                            imageUrl: match.awayTeamBadge!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Icon(Icons.shield, size: 48, color: Colors.white54),
                            errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 48, color: Colors.white54),
                          )
                        else
                          const Icon(Icons.shield, size: 48, color: Colors.white54),
                        const SizedBox(height: 8),
                        Text(
                          match.awayTeam ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Venue
              if (match.venue != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stadium, color: Colors.white54, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      match.venue!,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

// ============ Info Tab ============
class _InfoTab extends StatelessWidget {
  final SportsDbEvent match;

  const _InfoTab({required this.match});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Match Info Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('경기 정보', style: AppTextStyles.subtitle1),
                const SizedBox(height: 16),
                _InfoRow(label: '리그', value: match.league ?? '-'),
                _InfoRow(label: '시즌', value: match.season ?? '-'),
                _InfoRow(
                  label: '날짜',
                  value: match.dateTime != null
                      ? DateFormat('yyyy년 MM월 dd일 (E)', 'ko').format(match.dateTime!)
                      : '-',
                ),
                _InfoRow(
                  label: '시간',
                  value: match.dateTime != null
                      ? DateFormat('HH:mm').format(match.dateTime!)
                      : '-',
                ),
                _InfoRow(label: '경기장', value: match.venue ?? '-'),
                if (match.status != null)
                  _InfoRow(label: '상태', value: _getStatusText(match.status)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusText(String? status) {
    switch (status?.toUpperCase()) {
      case 'FT':
        return '경기 종료';
      case 'HT':
        return '하프타임';
      case 'LIVE':
      case '1H':
      case '2H':
        return '진행 중';
      case 'PST':
      case 'POSTP':
        return '연기';
      case 'CANC':
        return '취소';
      default:
        return status ?? '예정';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.body2.copyWith(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.body2),
          ),
        ],
      ),
    );
  }
}

// ============ Lineup Tab ============
class _LineupTab extends ConsumerWidget {
  final String eventId;
  final SportsDbEvent match;

  const _LineupTab({required this.eventId, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineupAsync = ref.watch(matchLineupProvider(eventId));

    return lineupAsync.when(
      data: (lineup) {
        if (lineup == null || lineup.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('라인업 정보가 없습니다', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 8),
                Text(
                  '경기 종료 후 업데이트됩니다',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Home Team
              Expanded(
                child: _TeamLineup(
                  teamName: match.homeTeam ?? '홈',
                  formation: lineup.homeFormation,
                  players: lineup.homePlayers,
                  substitutes: lineup.homeSubstitutes,
                  isHome: true,
                ),
              ),
              const SizedBox(width: 12),
              // Away Team
              Expanded(
                child: _TeamLineup(
                  teamName: match.awayTeam ?? '원정',
                  formation: lineup.awayFormation,
                  players: lineup.awayPlayers,
                  substitutes: lineup.awaySubstitutes,
                  isHome: false,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }
}

class _TeamLineup extends StatelessWidget {
  final String teamName;
  final String? formation;
  final List<SportsDbLineupPlayer> players;
  final List<SportsDbLineupPlayer> substitutes;
  final bool isHome;

  const _TeamLineup({
    required this.teamName,
    this.formation,
    required this.players,
    required this.substitutes,
    required this.isHome,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team Name Header
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isHome ? AppColors.primary : AppColors.secondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    teamName,
                    style: AppTextStyles.subtitle2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (formation != null) ...[
              const SizedBox(height: 4),
              Text(
                formation!,
                style: AppTextStyles.caption.copyWith(color: Colors.grey),
              ),
            ],
            const Divider(height: 16),

            // Starting XI
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports_soccer, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '선발 (${players.length})',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (players.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '선발 정보 없음',
                  style: AppTextStyles.caption.copyWith(color: Colors.grey),
                ),
              )
            else
              ...players.map((p) => _PlayerRow(player: p)),

            // Substitutes
            if (substitutes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '교체 (${substitutes.length})',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...substitutes.map((p) => _PlayerRow(player: p, isSubstitute: true)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final SportsDbLineupPlayer player;
  final bool isSubstitute;

  const _PlayerRow({required this.player, this.isSubstitute = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: player.id.isNotEmpty ? () => _showPlayerDetail(context, player) : null,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            // Squad Number
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSubstitute
                    ? Colors.grey.shade200
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                player.number ?? '-',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSubstitute ? Colors.grey.shade600 : AppColors.primary,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Player Name
            Expanded(
              child: Text(
                player.name,
                style: AppTextStyles.body2.copyWith(
                  color: isSubstitute ? Colors.grey.shade700 : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Position Badge
            if (player.position != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPositionColor(player.position!).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getPositionShort(player.position!),
                  style: AppTextStyles.caption.copyWith(
                    color: _getPositionColor(player.position!),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPlayerDetail(BuildContext context, SportsDbLineupPlayer player) {
    context.push('/player/${player.id}');
  }

  String _getPositionShort(String position) {
    switch (position.toLowerCase()) {
      case 'goalkeeper':
        return 'GK';
      case 'defender':
        return 'DF';
      case 'midfielder':
        return 'MF';
      case 'forward':
        return 'FW';
      default:
        return position.substring(0, position.length > 3 ? 3 : position.length).toUpperCase();
    }
  }

  Color _getPositionColor(String position) {
    switch (position.toLowerCase()) {
      case 'goalkeeper':
        return Colors.orange;
      case 'defender':
        return Colors.blue;
      case 'midfielder':
        return Colors.green;
      case 'forward':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// ============ Stats Tab ============
class _StatsTab extends ConsumerWidget {
  final String eventId;
  final SportsDbEvent match;

  const _StatsTab({required this.eventId, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(matchStatsProvider(eventId));

    return statsAsync.when(
      data: (stats) {
        if (stats == null || stats.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('통계 정보가 없습니다', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Team names header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      match.homeTeam ?? '',
                      style: AppTextStyles.subtitle2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 60),
                  Expanded(
                    child: Text(
                      match.awayTeam ?? '',
                      style: AppTextStyles.subtitle2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Stats rows
            if (stats.homePossession != null)
              _StatBar(
                label: '점유율',
                homeValue: stats.homePossession!,
                awayValue: stats.awayPossession ?? 0,
                isPercentage: true,
              ),
            if (stats.homeShots != null)
              _StatBar(
                label: '슈팅',
                homeValue: stats.homeShots!,
                awayValue: stats.awayShots ?? 0,
              ),
            if (stats.homeShotsOnTarget != null)
              _StatBar(
                label: '유효 슈팅',
                homeValue: stats.homeShotsOnTarget!,
                awayValue: stats.awayShotsOnTarget ?? 0,
              ),
            if (stats.homeCorners != null)
              _StatBar(
                label: '코너킥',
                homeValue: stats.homeCorners!,
                awayValue: stats.awayCorners ?? 0,
              ),
            if (stats.homeFouls != null)
              _StatBar(
                label: '파울',
                homeValue: stats.homeFouls!,
                awayValue: stats.awayFouls ?? 0,
              ),
            if (stats.homeOffsides != null)
              _StatBar(
                label: '오프사이드',
                homeValue: stats.homeOffsides!,
                awayValue: stats.awayOffsides ?? 0,
              ),
            if (stats.homeYellowCards != null)
              _StatBar(
                label: '경고',
                homeValue: stats.homeYellowCards!,
                awayValue: stats.awayYellowCards ?? 0,
                color: Colors.amber,
              ),
            if (stats.homeRedCards != null)
              _StatBar(
                label: '퇴장',
                homeValue: stats.homeRedCards!,
                awayValue: stats.awayRedCards ?? 0,
                color: Colors.red,
              ),
          ],
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final int homeValue;
  final int awayValue;
  final bool isPercentage;
  final Color? color;

  const _StatBar({
    required this.label,
    required this.homeValue,
    required this.awayValue,
    this.isPercentage = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final total = homeValue + awayValue;
    final homeRatio = total > 0 ? homeValue / total : 0.5;
    final awayRatio = total > 0 ? awayValue / total : 0.5;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPercentage ? '$homeValue%' : '$homeValue',
                style: AppTextStyles.subtitle2,
              ),
              Text(label, style: AppTextStyles.caption),
              Text(
                isPercentage ? '$awayValue%' : '$awayValue',
                style: AppTextStyles.subtitle2,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                flex: (homeRatio * 100).round(),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color ?? AppColors.primary,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: (awayRatio * 100).round(),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: (color ?? AppColors.primary).withValues(alpha: 0.4),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============ Timeline Tab ============
class _TimelineTab extends ConsumerWidget {
  final String eventId;

  const _TimelineTab({required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(matchTimelineProvider(eventId));

    return timelineAsync.when(
      data: (timeline) {
        if (timeline.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timeline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('타임라인 정보가 없습니다', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: timeline.length,
          itemBuilder: (context, index) {
            return _TimelineItem(event: timeline[index]);
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final SportsDbTimeline event;

  const _TimelineItem({required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 40,
            child: Text(
              event.time ?? '',
              style: AppTextStyles.subtitle2.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),

          // Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getEventColor().withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getEventIcon(),
              size: 16,
              color: _getEventColor(),
            ),
          ),

          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.player ?? event.type ?? '',
                  style: AppTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (event.detail != null)
                  Text(
                    event.detail!,
                    style: AppTextStyles.caption.copyWith(color: Colors.grey),
                  ),
                Text(
                  event.team ?? (event.isHome ? '홈' : '원정'),
                  style: AppTextStyles.caption.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEventIcon() {
    switch (event.type?.toLowerCase()) {
      case 'goal':
        return Icons.sports_soccer;
      case 'yellow card':
        return Icons.square;
      case 'red card':
        return Icons.square;
      case 'substitution':
        return Icons.swap_horiz;
      default:
        return Icons.circle;
    }
  }

  Color _getEventColor() {
    switch (event.type?.toLowerCase()) {
      case 'goal':
        return Colors.green;
      case 'yellow card':
        return Colors.amber;
      case 'red card':
        return Colors.red;
      case 'substitution':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
