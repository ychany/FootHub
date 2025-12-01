import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/sports_db_service.dart';
import '../../attendance/models/attendance_record.dart';
import '../../attendance/providers/attendance_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../favorites/providers/favorites_provider.dart';

/// 축구 라이브스코어 Provider
final soccerLivescoresProvider = FutureProvider<List<SportsDbLiveEvent>>((ref) async {
  final service = SportsDbService();
  return service.getSoccerLivescores();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(attendanceListProvider);
            ref.invalidate(favoriteTeamIdsProvider);
          },
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(context, user),
              ),

              // Live Scores
              SliverToBoxAdapter(
                child: _LiveScoresSection(),
              ),

              // Quick Stats
              SliverToBoxAdapter(
                child: _QuickStatsSection(),
              ),

              // Favorite Team Schedules
              SliverToBoxAdapter(
                child: _FavoriteTeamSchedulesSection(),
              ),

              // Recent Attendance
              SliverToBoxAdapter(
                child: _RecentAttendanceSection(),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user) {
    final greeting = _getGreeting();
    final userName = user?.displayName ?? '축구팬';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$userName님',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '오늘도 좋은 경기 되세요!',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '좋은 아침이에요';
    if (hour < 18) return '좋은 오후예요';
    return '좋은 저녁이에요';
  }
}

class _QuickStatsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(attendanceStatsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('나의 직관 통계', style: AppTextStyles.subtitle1),
              TextButton(
                onPressed: () => context.go('/attendance'),
                child: const Text('전체 보기'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          statsAsync.when(
            data: (stats) => Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.stadium,
                    label: '총 직관',
                    value: '${stats.totalMatches}경기',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.emoji_events,
                    label: '승률',
                    value: '${stats.winRate.toStringAsFixed(0)}%',
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.place,
                    label: '경기장',
                    value: '${stats.stadiumVisits.length}곳',
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox(
              height: 100,
              child: Center(child: Text('통계를 불러올 수 없습니다')),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.subtitle1.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _LiveScoresSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final livescoresAsync = ref.watch(soccerLivescoresProvider);

    return livescoresAsync.when(
      data: (events) {
        // 진행 중인 경기만 필터링
        final liveEvents = events.where((e) => e.isLive).toList();

        if (liveEvents.isEmpty) {
          return const SizedBox.shrink(); // 진행 중인 경기 없으면 숨김
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('LIVE', style: AppTextStyles.subtitle1.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  )),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: () => ref.invalidate(soccerLivescoresProvider),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: liveEvents.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final event = liveEvents[index];
                    return _LiveMatchCard(event: event);
                  },
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

class _LiveMatchCard extends StatelessWidget {
  final SportsDbLiveEvent event;

  const _LiveMatchCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 리그명 + 진행 시간
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  event.league ?? '',
                  style: AppTextStyles.caption.copyWith(color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  event.statusDisplay,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // 팀 vs 팀 + 스코어
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  event.homeTeam ?? '',
                  style: AppTextStyles.body2,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  event.scoreDisplay,
                  style: AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  event.awayTeam ?? '',
                  style: AppTextStyles.body2,
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

/// 즐겨찾기 팀별 다음 경기 Provider
final favoriteTeamNextEventsProvider = FutureProvider<List<_TeamNextEvent>>((ref) async {
  final teamIdsAsync = ref.watch(favoriteTeamIdsProvider);

  return teamIdsAsync.when(
    data: (teamIds) async {
      if (teamIds.isEmpty) return [];

      final service = SportsDbService();
      final results = <_TeamNextEvent>[];

      for (final teamId in teamIds) {
        try {
          final team = await service.getTeamById(teamId);
          final events = await service.getNextTeamEvents(teamId);
          if (team != null && events.isNotEmpty) {
            results.add(_TeamNextEvent(team: team, events: events.take(2).toList()));
          }
        } catch (e) {
          // 개별 팀 오류는 무시
        }
      }
      return results;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

class _TeamNextEvent {
  final SportsDbTeam team;
  final List<SportsDbEvent> events;

  _TeamNextEvent({required this.team, required this.events});
}

class _FavoriteTeamSchedulesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamEventsAsync = ref.watch(favoriteTeamNextEventsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('즐겨찾기 팀 일정', style: AppTextStyles.subtitle1),
              TextButton(
                onPressed: () => context.push('/favorites'),
                child: const Text('관리'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          teamEventsAsync.when(
            data: (teamEvents) {
              if (teamEvents.isEmpty) {
                return _EmptyFavoriteTeamsCard();
              }

              // 모든 경기를 하나의 리스트로 플래튼
              final allMatches = <_MatchWithTeam>[];
              for (final te in teamEvents) {
                for (final event in te.events) {
                  allMatches.add(_MatchWithTeam(team: te.team, event: event));
                }
              }

              // 날짜순 정렬
              allMatches.sort((a, b) {
                final aDate = a.event.dateTime ?? DateTime.now();
                final bDate = b.event.dateTime ?? DateTime.now();
                return aDate.compareTo(bDate);
              });

              return SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: allMatches.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final match = allMatches[index];
                    return _MatchCard(
                      team: match.team,
                      event: match.event,
                      onTap: () => context.push('/team/${match.team.id}'),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Container(
              height: 180,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Center(
                child: Text(
                  '일정을 불러올 수 없습니다',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchWithTeam {
  final SportsDbTeam team;
  final SportsDbEvent event;

  _MatchWithTeam({required this.team, required this.event});
}

class _EmptyFavoriteTeamsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/favorites'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.favorite_border,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                '즐겨찾기한 팀이 없습니다',
                style: AppTextStyles.subtitle2.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '팀을 추가하여 경기 일정을 확인하세요',
                style: AppTextStyles.caption.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final SportsDbTeam team;
  final SportsDbEvent event;
  final VoidCallback onTap;

  const _MatchCard({
    required this.team,
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 내 팀 표시 + 날짜
              Row(
                children: [
                  if (team.badge != null)
                    CachedNetworkImage(
                      imageUrl: team.badge!,
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 24),
                    )
                  else
                    const Icon(Icons.shield, size: 24, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      team.name,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDate(event.dateTime),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 경기 정보 (팀 vs 팀)
              Expanded(
                child: Row(
                  children: [
                    // 홈팀
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (event.homeTeamBadge != null)
                            CachedNetworkImage(
                              imageUrl: event.homeTeamBadge!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.contain,
                              errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 44),
                            )
                          else
                            const Icon(Icons.shield, size: 44, color: Colors.grey),
                          const SizedBox(height: 6),
                          Text(
                            event.homeTeam ?? '-',
                            style: AppTextStyles.caption,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    // VS
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'VS',
                            style: AppTextStyles.subtitle2.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(event.dateTime),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 원정팀
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (event.awayTeamBadge != null)
                            CachedNetworkImage(
                              imageUrl: event.awayTeamBadge!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.contain,
                              errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 44),
                            )
                          else
                            const Icon(Icons.shield, size: 44, color: Colors.grey),
                          const SizedBox(height: 6),
                          Text(
                            event.awayTeam ?? '-',
                            style: AppTextStyles.caption,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 리그명
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_soccer, size: 12, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    event.league ?? '',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('MM/dd (E)', 'ko').format(dt);
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('HH:mm').format(dt);
  }
}

class _RecentAttendanceSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(attendanceListProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('최근 직관 기록', style: AppTextStyles.subtitle1),
              TextButton(
                onPressed: () => context.go('/attendance'),
                child: const Text('전체 보기'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          attendanceAsync.when(
            data: (records) {
              if (records.isEmpty) {
                return _EmptyAttendanceCard();
              }

              final recent = records.take(3).toList();
              return Column(
                children: recent.map((record) => _RecentAttendanceCard(
                  record: record,
                  onTap: () => context.push('/attendance/${record.id}'),
                )).toList(),
              );
            },
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Center(
                child: Text(
                  '직관 기록을 불러올 수 없습니다',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAttendanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/attendance/add'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                '첫 직관 기록을 남겨보세요!',
                style: AppTextStyles.subtitle2.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '경기를 직접 보고 온 추억을 기록해보세요',
                style: AppTextStyles.caption.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentAttendanceCard extends StatelessWidget {
  final AttendanceRecord record;
  final VoidCallback onTap;

  const _RecentAttendanceCard({
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Date & Mood
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('MM/dd').format(record.date),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (record.mood != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        record.mood!.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Teams & Score
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${record.homeTeamName} ${record.scoreDisplay} ${record.awayTeamName}',
                            style: AppTextStyles.subtitle2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (record.rating != null) ...[
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 14, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                record.rating!.toStringAsFixed(1),
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (record.diaryTitle != null && record.diaryTitle!.isNotEmpty)
                      Text(
                        '"${record.diaryTitle}"',
                        style: AppTextStyles.caption.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        record.stadium,
                        style: AppTextStyles.caption.copyWith(color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
