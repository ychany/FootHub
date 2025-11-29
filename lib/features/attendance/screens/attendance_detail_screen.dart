import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/sports_db_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/photo_carousel.dart';
import '../../../shared/widgets/team_logo.dart';
import '../models/attendance_record.dart';
import '../providers/attendance_provider.dart';

// Provider for match stats
final attendanceMatchStatsProvider = FutureProvider.family<SportsDbEventStats?, String>((ref, eventId) async {
  final service = SportsDbService();
  return service.getEventStats(eventId);
});

// Provider for match timeline
final attendanceMatchTimelineProvider = FutureProvider.family<List<SportsDbTimeline>, String>((ref, eventId) async {
  final service = SportsDbService();
  return service.getEventTimeline(eventId);
});

// Provider for match lineup
final attendanceMatchLineupProvider = FutureProvider.family<SportsDbLineup?, String>((ref, eventId) async {
  final service = SportsDbService();
  return service.getEventLineup(eventId);
});

class AttendanceDetailScreen extends ConsumerWidget {
  final String recordId;

  const AttendanceDetailScreen({
    super.key,
    required this.recordId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(attendanceDetailProvider(recordId));

    return Scaffold(
      body: recordAsync.when(
        data: (record) {
          if (record == null) {
            return const Center(child: Text('기록을 찾을 수 없습니다'));
          }
          return _DetailContent(record: record);
        },
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _DetailContent extends ConsumerStatefulWidget {
  final AttendanceRecord record;

  const _DetailContent({required this.record});

  @override
  ConsumerState<_DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends ConsumerState<_DetailContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // matchId가 있으면 4개 탭, 없으면 1개 탭
    _tabController = TabController(
      length: widget.record.matchId != null ? 4 : 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  AttendanceRecord get record => widget.record;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasMatchId = record.matchId != null;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          _buildAppBar(context),
          if (hasMatchId)
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: '일기'),
                    Tab(text: '통계'),
                    Tab(text: '타임라인'),
                    Tab(text: '라인업'),
                  ],
                ),
              ),
            ),
        ];
      },
      body: hasMatchId
          ? TabBarView(
              controller: _tabController,
              children: [
                _DiaryTab(record: record, isDark: isDark),
                _StatsTab(matchId: record.matchId!, record: record),
                _TimelineTab(matchId: record.matchId!),
                _LineupTab(matchId: record.matchId!, record: record),
              ],
            )
          : _DiaryTab(record: record, isDark: isDark),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Teams Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        TeamLogo(
                          logoUrl: record.homeTeamLogo,
                          teamName: record.homeTeamName,
                          size: 56,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          record.homeTeamName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        record.scoreDisplay,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        TeamLogo(
                          logoUrl: record.awayTeamLogo,
                          teamName: record.awayTeamName,
                          size: 56,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          record.awayTeamName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Rating & Mood indicator
                if (record.rating != null || record.mood != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (record.rating != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                record.rating!.toStringAsFixed(1),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (record.rating != null && record.mood != null)
                        const SizedBox(width: 8),
                      if (record.mood != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${record.mood!.emoji} ${record.mood!.label}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            record.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: record.isFavorite ? Colors.red : Colors.white,
          ),
          onPressed: () {
            // TODO: Toggle favorite
          },
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            context.push('/attendance/${record.id}/edit');
          },
        ),
      ],
    );
  }
}

// ============ Tab Bar Delegate ============
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

// ============ Diary Tab (기존 내용) ============
class _DiaryTab extends StatelessWidget {
  final AttendanceRecord record;
  final bool isDark;

  const _DiaryTab({required this.record, required this.isDark});

  bool _hasAdditionalInfo() {
    return record.weather != null || record.companion != null || record.ticketPrice != null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photos
          if (record.photos.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PhotoCarousel(
                photos: record.photos,
                height: 220,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Diary Title (한 줄 요약)
          if (record.diaryTitle != null && record.diaryTitle!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.format_quote, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        record.diaryTitle!,
                        style: AppTextStyles.subtitle1.copyWith(
                          color: AppColors.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // MVP Section
          if (record.mvpPlayerName != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMvpCard(),
            ),
            const SizedBox(height: 24),
          ],

          // Tags
          if (record.tags.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: record.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '#$tag',
                    style: AppTextStyles.caption.copyWith(color: AppColors.secondary),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Diary Content
          if (record.diaryContent != null && record.diaryContent!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.menu_book, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('직관 일기', style: AppTextStyles.subtitle1),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      record.diaryContent!,
                      style: AppTextStyles.body1.copyWith(height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Match Info Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sports_soccer, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('경기 정보', style: AppTextStyles.subtitle1),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoTile(
                  icon: Icons.calendar_today,
                  label: '날짜',
                  value: DateFormat('yyyy.MM.dd (EEEE)', 'ko').format(record.date),
                ),
                _InfoTile(
                  icon: Icons.emoji_events,
                  label: '리그',
                  value: record.league,
                ),
                _InfoTile(
                  icon: Icons.stadium,
                  label: '경기장',
                  value: record.stadium,
                ),
                if (record.seatInfo != null)
                  _InfoTile(
                    icon: Icons.chair,
                    label: '좌석',
                    value: record.seatInfo!,
                  ),
              ],
            ),
          ),

          // Additional Info Section
          if (_hasAdditionalInfo()) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('추가 정보', style: AppTextStyles.subtitle1),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (record.weather != null)
                    _InfoTile(icon: Icons.cloud, label: '날씨', value: record.weather!),
                  if (record.companion != null)
                    _InfoTile(icon: Icons.people, label: '함께 간 사람', value: record.companion!),
                  if (record.ticketPrice != null)
                    _InfoTile(icon: Icons.confirmation_number, label: '티켓 가격', value: '${NumberFormat('#,###').format(record.ticketPrice)}원'),
                ],
              ),
            ),
          ],

          // Food Review
          if (record.foodReview != null && record.foodReview!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.restaurant, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('경기장 음식', style: AppTextStyles.subtitle1),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      record.foodReview!,
                      style: AppTextStyles.body2,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Old Memo (for backwards compatibility)
          if (record.memo != null && record.memo!.isNotEmpty && (record.diaryContent == null || record.diaryContent!.isEmpty)) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('메모', style: AppTextStyles.subtitle1),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(record.memo!, style: AppTextStyles.body2),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMvpCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade100, Colors.amber.shade50],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.emoji_events, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('오늘의 MVP', style: AppTextStyles.caption.copyWith(color: Colors.amber.shade800)),
                const SizedBox(height: 4),
                Text(
                  record.mvpPlayerName!,
                  style: AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
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

// ============ Stats Tab ============
class _StatsTab extends ConsumerWidget {
  final String matchId;
  final AttendanceRecord record;

  const _StatsTab({required this.matchId, required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(attendanceMatchStatsProvider(matchId));

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
                SizedBox(height: 8),
                Text(
                  '경기 종료 후 업데이트됩니다',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
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
                      record.homeTeamName,
                      style: AppTextStyles.subtitle2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 60),
                  Expanded(
                    child: Text(
                      record.awayTeamName,
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
                flex: (homeRatio * 100).round().clamp(1, 99),
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
                flex: (awayRatio * 100).round().clamp(1, 99),
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
  final String matchId;

  const _TimelineTab({required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(attendanceMatchTimelineProvider(matchId));

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
                SizedBox(height: 8),
                Text(
                  '경기 종료 후 업데이트됩니다',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
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

// ============ Lineup Tab ============
class _LineupTab extends ConsumerWidget {
  final String matchId;
  final AttendanceRecord record;

  const _LineupTab({required this.matchId, required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineupAsync = ref.watch(attendanceMatchLineupProvider(matchId));

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
                  teamName: record.homeTeamName,
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
                  teamName: record.awayTeamName,
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
      onTap: player.id.isNotEmpty ? () => context.push('/player/${player.id}') : null,
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

// ============ Info Tile ============
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
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
