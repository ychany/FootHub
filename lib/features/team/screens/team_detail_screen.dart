import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/sports_db_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/team_provider.dart';

class TeamDetailScreen extends ConsumerWidget {
  final String teamId;

  const TeamDetailScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamInfoProvider(teamId));

    return Scaffold(
      body: teamAsync.when(
        data: (team) {
          if (team == null) {
            return const Center(child: Text('팀 정보를 찾을 수 없습니다'));
          }
          return _TeamDetailContent(team: team);
        },
        loading: () => const Scaffold(body: LoadingIndicator()),
        error: (e, _) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('오류: $e')),
        ),
      ),
    );
  }
}

class _TeamDetailContent extends ConsumerStatefulWidget {
  final SportsDbTeam team;

  const _TeamDetailContent({required this.team});

  @override
  ConsumerState<_TeamDetailContent> createState() => _TeamDetailContentState();
}

class _TeamDetailContentState extends ConsumerState<_TeamDetailContent>
    with SingleTickerProviderStateMixin {
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
    final team = widget.team;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                team.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (team.banner != null)
                    CachedNetworkImage(
                      imageUrl: team.banner!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.primary,
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // Team Badge
                  Positioned(
                    bottom: 60,
                    left: 16,
                    child: team.badge != null
                        ? CachedNetworkImage(
                            imageUrl: team.badge!,
                            width: 60,
                            height: 60,
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.shield, size: 60, color: Colors.white),
                          )
                        : const Icon(Icons.shield, size: 60, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: '정보'),
                  Tab(text: '일정'),
                  Tab(text: '선수단'),
                ],
              ),
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _InfoTab(team: team),
          _ScheduleTab(teamId: team.id),
          _PlayersTab(teamId: team.id),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
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
  final SportsDbTeam team;

  const _InfoTab({required this.team});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Basic Info Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('기본 정보', style: AppTextStyles.subtitle1),
                const Divider(),
                _InfoRow(label: '리그', value: team.league ?? '-'),
                _InfoRow(label: '국가', value: team.country ?? '-'),
                _InfoRow(label: '경기장', value: team.stadium ?? '-'),
                if (team.stadiumCapacity != null)
                  _InfoRow(label: '수용 인원', value: '${team.stadiumCapacity}명'),
              ],
            ),
          ),
        ),

        // Description
        if (team.description != null) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('소개', style: AppTextStyles.subtitle1),
                  const Divider(),
                  Text(
                    team.description!,
                    style: AppTextStyles.body2,
                    maxLines: 10,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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

// ============ Schedule Tab ============
class _ScheduleTab extends ConsumerWidget {
  final String teamId;

  const _ScheduleTab({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextEventsAsync = ref.watch(teamNextEventsProvider(teamId));
    final pastEventsAsync = ref.watch(teamPastEventsProvider(teamId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Next Matches
        Text('다음 경기', style: AppTextStyles.subtitle1),
        const SizedBox(height: 8),
        nextEventsAsync.when(
          data: (events) {
            if (events.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('예정된 경기가 없습니다', style: TextStyle(color: Colors.grey)),
              );
            }
            return Column(
              children: events.take(5).map((e) => _MatchCard(event: e)).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('오류: $e', style: const TextStyle(color: Colors.red)),
          ),
        ),

        const SizedBox(height: 24),

        // Past Matches
        Text('지난 경기', style: AppTextStyles.subtitle1),
        const SizedBox(height: 8),
        pastEventsAsync.when(
          data: (events) {
            if (events.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('지난 경기가 없습니다', style: TextStyle(color: Colors.grey)),
              );
            }
            return Column(
              children: events.take(5).map((e) => _MatchCard(event: e, isPast: true)).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('오류: $e', style: const TextStyle(color: Colors.red)),
          ),
        ),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final SportsDbEvent event;
  final bool isPast;

  const _MatchCard({required this.event, this.isPast = false});

  @override
  Widget build(BuildContext context) {
    final dateTime = event.dateTime;
    final dateStr = dateTime != null
        ? DateFormat('MM/dd (E)', 'ko').format(dateTime)
        : event.date ?? '-';
    final timeStr = dateTime != null
        ? DateFormat('HH:mm').format(dateTime)
        : event.time ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.push('/match/${event.id}'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Date & League
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$dateStr $timeStr',
                    style: AppTextStyles.caption.copyWith(
                      color: isPast ? Colors.grey : AppColors.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.league ?? '-',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Teams & Score
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.homeTeam ?? '-',
                      style: AppTextStyles.body2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: event.isFinished
                        ? Text(
                            event.scoreDisplay,
                            style: AppTextStyles.subtitle1.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Text(
                            'vs',
                            style: AppTextStyles.body2.copyWith(color: Colors.grey),
                          ),
                  ),
                  Expanded(
                    child: Text(
                      event.awayTeam ?? '-',
                      style: AppTextStyles.body2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
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

// ============ Players Tab ============
class _PlayersTab extends ConsumerWidget {
  final String teamId;

  const _PlayersTab({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(teamPlayersProvider(teamId));

    return playersAsync.when(
      data: (players) {
        if (players.isEmpty) {
          return const Center(
            child: Text('선수 정보가 없습니다', style: TextStyle(color: Colors.grey)),
          );
        }

        // 포지션별 그룹화
        final grouped = <String, List<SportsDbPlayer>>{};
        for (final player in players) {
          final position = player.position ?? '기타';
          grouped.putIfAbsent(position, () => []).add(player);
        }

        final positionOrder = ['Goalkeeper', 'Defender', 'Midfielder', 'Forward'];
        final sortedKeys = grouped.keys.toList()
          ..sort((a, b) {
            final aIndex = positionOrder.indexOf(a);
            final bIndex = positionOrder.indexOf(b);
            if (aIndex == -1 && bIndex == -1) return a.compareTo(b);
            if (aIndex == -1) return 1;
            if (bIndex == -1) return -1;
            return aIndex.compareTo(bIndex);
          });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedKeys.length,
          itemBuilder: (context, index) {
            final position = sortedKeys[index];
            final positionPlayers = grouped[position]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _getPositionKr(position),
                    style: AppTextStyles.subtitle2.copyWith(
                      color: _getPositionColor(position),
                    ),
                  ),
                ),
                ...positionPlayers.map((p) => _PlayerCard(player: p)),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }

  String _getPositionKr(String position) {
    switch (position.toLowerCase()) {
      case 'goalkeeper':
        return '골키퍼';
      case 'defender':
        return '수비수';
      case 'midfielder':
        return '미드필더';
      case 'forward':
        return '공격수';
      default:
        return position;
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

class _PlayerCard extends StatelessWidget {
  final SportsDbPlayer player;

  const _PlayerCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: () => context.push('/player/${player.id}'),
        leading: CircleAvatar(
          radius: 20,
          backgroundImage: player.thumb != null ? NetworkImage(player.thumb!) : null,
          child: player.thumb == null
              ? Text(player.name.isNotEmpty ? player.name[0] : '?')
              : null,
        ),
        title: Text(player.name, style: AppTextStyles.body2),
        subtitle: player.nationality != null
            ? Text(player.nationality!, style: AppTextStyles.caption)
            : null,
        trailing: player.number != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#${player.number}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
