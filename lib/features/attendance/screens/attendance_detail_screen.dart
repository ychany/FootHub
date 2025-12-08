import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/sports_db_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/photo_carousel.dart';
import '../models/attendance_record.dart';
import '../providers/attendance_provider.dart';

// Provider for match stats
final attendanceMatchStatsProvider =
    FutureProvider.family<SportsDbEventStats?, String>((ref, eventId) async {
  final service = SportsDbService();
  return service.getEventStats(eventId);
});

// Provider for match timeline
final attendanceMatchTimelineProvider =
    FutureProvider.family<List<SportsDbTimeline>, String>((ref, eventId) async {
  final service = SportsDbService();
  return service.getEventTimeline(eventId);
});

// Provider for match lineup
final attendanceMatchLineupProvider =
    FutureProvider.family<SportsDbLineup?, String>((ref, eventId) async {
  final service = SportsDbService();
  return service.getEventLineup(eventId);
});

// Provider for head to head
final attendanceH2HProvider =
    FutureProvider.family<List<SportsDbEvent>, ({String homeTeam, String awayTeam})>((ref, params) async {
  final service = SportsDbService();
  return service.getHeadToHead(params.homeTeam, params.awayTeam);
});

class AttendanceDetailScreen extends ConsumerWidget {
  final String recordId;

  static const _background = Color(0xFFF9FAFB);

  const AttendanceDetailScreen({
    super.key,
    required this.recordId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(attendanceDetailProvider(recordId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _background,
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

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _background = Color(0xFFF9FAFB);
  static const _warning = Color(0xFFF59E0B);
  static const _error = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.record.matchId != null ? 5 : 1,
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
                  labelColor: _primary,
                  unselectedLabelColor: _textSecondary,
                  indicatorColor: _primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: '일기'),
                    Tab(text: '기록'),
                    Tab(text: '중계'),
                    Tab(text: '라인업'),
                    Tab(text: '전적'),
                  ],
                ),
                _background,
              ),
            ),
        ];
      },
      body: hasMatchId
          ? TabBarView(
              controller: _tabController,
              children: [
                _DiaryTab(record: record),
                _StatsTab(matchId: record.matchId!, record: record),
                _TimelineTab(matchId: record.matchId!),
                _LineupTab(matchId: record.matchId!, record: record),
                _H2HTab(record: record),
              ],
            )
          : _DiaryTab(record: record),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: _textPrimary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Colors.white,
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                // 리그 배지
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _primaryLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    record.league,
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Teams Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // 홈팀
                      Expanded(
                        child: GestureDetector(
                          onTap: record.homeTeamId.isNotEmpty
                              ? () => context.push('/team/${record.homeTeamId}')
                              : null,
                          child: Column(
                            children: [
                              _buildTeamLogo(record.homeTeamLogo, 56),
                              const SizedBox(height: 8),
                              Text(
                                record.homeTeamName,
                                style: const TextStyle(
                                  color: _textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 스코어 (고정 너비)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: _primaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          record.scoreDisplay,
                          style: const TextStyle(
                            color: _primary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // 어웨이팀
                      Expanded(
                        child: GestureDetector(
                          onTap: record.awayTeamId.isNotEmpty
                              ? () => context.push('/team/${record.awayTeamId}')
                              : null,
                          child: Column(
                            children: [
                              _buildTeamLogo(record.awayTeamLogo, 56),
                              const SizedBox(height: 8),
                              Text(
                                record.awayTeamName,
                                style: const TextStyle(
                                  color: _textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Rating & Mood indicator
                if (record.rating != null || record.mood != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (record.rating != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: _warning.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  color: _warning, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                record.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: _warning,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (record.rating != null && record.mood != null)
                        const SizedBox(width: 8),
                      if (record.mood != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _primaryLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: _primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${record.mood!.emoji} ${record.mood!.label}',
                            style: const TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
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
            color: record.isFavorite ? _error : _textSecondary,
          ),
          onPressed: () {
            // TODO: Toggle favorite
          },
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          color: _textSecondary,
          onPressed: () {
            context.push('/attendance/${record.id}/edit');
          },
        ),
      ],
    );
  }

  Widget _buildTeamLogo(String? logoUrl, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
        border: Border.all(color: _border, width: 2),
      ),
      child: logoUrl != null && logoUrl.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: logoUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => Icon(
                  Icons.shield_outlined,
                  color: _textSecondary,
                  size: size * 0.5,
                ),
                errorWidget: (_, __, ___) => Icon(
                  Icons.shield_outlined,
                  color: _textSecondary,
                  size: size * 0.5,
                ),
              ),
            )
          : Icon(
              Icons.shield_outlined,
              color: _textSecondary,
              size: size * 0.5,
            ),
    );
  }
}

// ============ Tab Bar Delegate ============
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _TabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(
      color: backgroundColor,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
        ),
        child: tabBar,
      ),
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

// ============ Diary Tab ============
class _DiaryTab extends StatelessWidget {
  final AttendanceRecord record;

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _warning = Color(0xFFF59E0B);
  static const _success = Color(0xFF10B981);

  const _DiaryTab({required this.record});

  bool _hasAdditionalInfo() {
    return record.weather != null ||
        record.companion != null ||
        record.ticketPrice != null;
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

          const SizedBox(height: 20),

          // Diary Title (한 줄 요약)
          if (record.diaryTitle != null && record.diaryTitle!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.format_quote, color: _primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        record.diaryTitle!,
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // MVP Section
          if (record.mvpPlayerName != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMvpCard(),
            ),
            const SizedBox(height: 20),
          ],

          // Tags
          if (record.tags.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: record.tags
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: _success.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '#$tag',
                            style: const TextStyle(
                              color: _success,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Diary Content
          if (record.diaryContent != null &&
              record.diaryContent!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSectionCard(
                icon: Icons.menu_book,
                iconColor: _primary,
                title: '직관 일기',
                child: Text(
                  record.diaryContent!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _textPrimary,
                    height: 1.7,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Match Info Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSectionCard(
              icon: Icons.sports_soccer,
              iconColor: _success,
              title: '경기 정보',
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.calendar_today,
                    label: '날짜',
                    value:
                        DateFormat('yyyy.MM.dd (EEEE)', 'ko').format(record.date),
                  ),
                  _InfoRow(
                    icon: Icons.emoji_events,
                    label: '리그',
                    value: record.league,
                  ),
                  _InfoRow(
                    icon: Icons.stadium,
                    label: '경기장',
                    value: record.stadium,
                  ),
                  if (record.seatInfo != null)
                    _InfoRow(
                      icon: Icons.chair,
                      label: '좌석',
                      value: record.seatInfo!,
                    ),
                ],
              ),
            ),
          ),

          // Additional Info Section
          if (_hasAdditionalInfo()) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSectionCard(
                icon: Icons.info_outline,
                iconColor: _textSecondary,
                title: '추가 정보',
                child: Column(
                  children: [
                    if (record.weather != null)
                      _InfoRow(
                          icon: Icons.cloud, label: '날씨', value: record.weather!),
                    if (record.companion != null)
                      _InfoRow(
                          icon: Icons.people,
                          label: '함께 간 사람',
                          value: record.companion!),
                    if (record.ticketPrice != null)
                      _InfoRow(
                          icon: Icons.confirmation_number,
                          label: '티켓 가격',
                          value:
                              '${NumberFormat('#,###').format(record.ticketPrice)}원'),
                  ],
                ),
              ),
            ),
          ],

          // Food Review
          if (record.foodReview != null && record.foodReview!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSectionCard(
                icon: Icons.restaurant,
                iconColor: _warning,
                title: '경기장 음식',
                child: Text(
                  record.foodReview!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _textPrimary,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],

          // Old Memo (for backwards compatibility)
          if (record.memo != null &&
              record.memo!.isNotEmpty &&
              (record.diaryContent == null ||
                  record.diaryContent!.isEmpty)) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSectionCard(
                icon: Icons.note,
                iconColor: _textSecondary,
                title: '메모',
                child: Text(
                  record.memo!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _textPrimary,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
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
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildMvpCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _warning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _warning,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _warning.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child:
                const Icon(Icons.emoji_events, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오늘의 MVP',
                  style: TextStyle(
                    fontSize: 12,
                    color: _warning.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  record.mvpPlayerName!,
                  style: TextStyle(
                    fontSize: 18,
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

// ============ Info Row ============
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  static const _primary = Color(0xFF2563EB);
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: _textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: _textPrimary,
                fontWeight: FontWeight.w500,
              ),
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

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _warning = Color(0xFFF59E0B);
  static const _error = Color(0xFFEF4444);

  const _StatsTab({required this.matchId, required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(attendanceMatchStatsProvider(matchId));

    return statsAsync.when(
      data: (stats) {
        if (stats == null || stats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.analytics_outlined,
                      size: 48, color: _textSecondary),
                ),
                const SizedBox(height: 16),
                const Text(
                  '통계 정보가 없습니다',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '경기 종료 후 업데이트됩니다',
                  style: TextStyle(color: _textSecondary, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Team names header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      record.homeTeamName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      record.awayTeamName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Stats rows
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
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
                      color: _warning,
                    ),
                  if (stats.homeRedCards != null)
                    _StatBar(
                      label: '퇴장',
                      homeValue: stats.homeRedCards!,
                      awayValue: stats.awayRedCards ?? 0,
                      color: _error,
                    ),
                ],
              ),
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

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

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
    final barColor = color ?? _primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPercentage ? '$homeValue%' : '$homeValue',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: _textSecondary,
                ),
              ),
              Text(
                isPercentage ? '$awayValue%' : '$awayValue',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: (homeRatio * 100).round().clamp(1, 99),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: (awayRatio * 100).round().clamp(1, 99),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(4),
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

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _TimelineTab({required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(attendanceMatchTimelineProvider(matchId));

    return timelineAsync.when(
      data: (timeline) {
        if (timeline.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.timeline, size: 48, color: _textSecondary),
                ),
                const SizedBox(height: 16),
                const Text(
                  '타임라인 정보가 없습니다',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '경기 종료 후 업데이트됩니다',
                  style: TextStyle(color: _textSecondary, fontSize: 13),
                ),
              ],
            ),
          );
        }

        // 시간순 정렬
        final sortedTimeline = List<SportsDbTimeline>.from(timeline)
          ..sort((a, b) {
            final aTime = int.tryParse(a.time ?? '0') ?? 0;
            final bTime = int.tryParse(b.time ?? '0') ?? 0;
            return aTime.compareTo(bTime);
          });

        return Container(
          color: Colors.white,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: sortedTimeline.length,
            itemBuilder: (context, index) {
              final event = sortedTimeline[index];
              final isFirst = index == 0;
              final isLast = index == sortedTimeline.length - 1;
              return _TimelineItem(
                event: event,
                isFirst: isFirst,
                isLast: isLast,
              );
            },
          ),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final SportsDbTimeline event;
  final bool isFirst;
  final bool isLast;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _TimelineItem({
    required this.event,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isGoal = event.type?.toLowerCase() == 'goal';
    final isCard = event.type?.toLowerCase() == 'card';
    final isSubst = event.type?.toLowerCase() == 'subst';

    return IntrinsicHeight(
      child: Row(
        children: [
          // 홈팀 영역 (왼쪽)
          Expanded(
            child: event.isHome
                ? _buildEventContent(isGoal, isCard, isSubst, true)
                : const SizedBox(),
          ),

          // 중앙 타임라인
          SizedBox(
            width: 60,
            child: Column(
              children: [
                // 상단 연결선
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 8,
                    color: Colors.grey.shade300,
                  ),
                // 시간 원
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getEventColor().withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getEventColor(),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        event.timeDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _getEventColor(),
                        ),
                      ),
                    ],
                  ),
                ),
                // 하단 연결선
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),

          // 원정팀 영역 (오른쪽)
          Expanded(
            child: !event.isHome
                ? _buildEventContent(isGoal, isCard, isSubst, false)
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventContent(bool isGoal, bool isCard, bool isSubst, bool isHome) {
    return Container(
      margin: EdgeInsets.only(
        left: isHome ? 16 : 8,
        right: isHome ? 8 : 16,
        bottom: 12,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getEventColor().withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getEventColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: isHome ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 이벤트 타입 뱃지
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getEventIcon(),
                size: 14,
                color: _getEventColor(),
              ),
              const SizedBox(width: 4),
              Text(
                _getEventTypeText(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _getEventColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 선수 이름
          Text(
            event.player ?? '',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
            textAlign: isHome ? TextAlign.right : TextAlign.left,
          ),

          // 어시스트 또는 세부 정보
          if (isGoal && event.assist != null && event.assist!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '어시스트: ${event.assist}',
              style: TextStyle(
                fontSize: 11,
                color: _textSecondary,
              ),
              textAlign: isHome ? TextAlign.right : TextAlign.left,
            ),
          ] else if (isSubst && event.detail != null && event.detail!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_upward, size: 10, color: Colors.green),
                const SizedBox(width: 2),
                Text(
                  event.detail!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ] else if (event.detail != null && event.detail!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              event.detail!,
              style: TextStyle(
                fontSize: 11,
                color: _textSecondary,
              ),
              textAlign: isHome ? TextAlign.right : TextAlign.left,
            ),
          ],

          // 팀 이름
          const SizedBox(height: 4),
          Text(
            event.team ?? '',
            style: TextStyle(
              fontSize: 10,
              color: _textSecondary,
            ),
            textAlign: isHome ? TextAlign.right : TextAlign.left,
          ),
        ],
      ),
    );
  }

  String _getEventTypeText() {
    switch (event.type?.toLowerCase()) {
      case 'goal':
        if (event.detail?.toLowerCase().contains('penalty') == true) {
          return '페널티골';
        } else if (event.detail?.toLowerCase().contains('own') == true) {
          return '자책골';
        }
        return '골';
      case 'card':
        if (event.detail?.toLowerCase().contains('yellow') == true) {
          return '경고';
        } else if (event.detail?.toLowerCase().contains('red') == true) {
          return '퇴장';
        }
        return '카드';
      case 'subst':
        return '교체';
      case 'var':
        return 'VAR';
      default:
        return event.type ?? '';
    }
  }

  IconData _getEventIcon() {
    switch (event.type?.toLowerCase()) {
      case 'goal':
        return Icons.sports_soccer;
      case 'card':
        return Icons.style;
      case 'subst':
        return Icons.swap_horiz;
      case 'var':
        return Icons.tv;
      default:
        return Icons.circle;
    }
  }

  Color _getEventColor() {
    switch (event.type?.toLowerCase()) {
      case 'goal':
        return const Color(0xFF10B981);
      case 'card':
        if (event.detail?.toLowerCase().contains('red') == true) {
          return const Color(0xFFEF4444);
        }
        return const Color(0xFFF59E0B);
      case 'subst':
        return const Color(0xFF3B82F6);
      case 'var':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

// ============ Lineup Tab ============
class _LineupTab extends ConsumerWidget {
  final String matchId;
  final AttendanceRecord record;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _LineupTab({required this.matchId, required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineupAsync = ref.watch(attendanceMatchLineupProvider(matchId));

    return lineupAsync.when(
      data: (lineup) {
        if (lineup == null || lineup.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.people_outline,
                      size: 48, color: _textSecondary),
                ),
                const SizedBox(height: 16),
                const Text(
                  '라인업 정보가 없습니다',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '경기 종료 후 업데이트됩니다',
                  style: TextStyle(color: _textSecondary, fontSize: 13),
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

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _success = Color(0xFF10B981);

  const _TeamLineup({
    required this.teamName,
    this.formation,
    required this.players,
    required this.substitutes,
    required this.isHome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team Name Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isHome ? _primaryLight : _success.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isHome ? _primary : _success,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    teamName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isHome ? _primary : _success,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (formation != null) ...[
                  Text(
                    formation!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Starting XI
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sports_soccer,
                          size: 12, color: _primary),
                      const SizedBox(width: 4),
                      Text(
                        '선발 (${players.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _primary,
                          fontSize: 11,
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
                      style: TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                  )
                else
                  ...players.map((p) => _PlayerRow(player: p)),

                // Substitutes
                if (substitutes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz,
                            size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '교체 (${substitutes.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...substitutes
                      .map((p) => _PlayerRow(player: p, isSubstitute: true)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final SportsDbLineupPlayer player;
  final bool isSubstitute;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _PlayerRow({required this.player, this.isSubstitute = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: player.id.isNotEmpty
          ? () => context.push('/player/${player.id}')
          : null,
      borderRadius: BorderRadius.circular(6),
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
                    ? Colors.grey.shade100
                    : _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                player.number ?? '-',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSubstitute ? _textSecondary : _primary,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Player Name
            Expanded(
              child: Text(
                player.name,
                style: TextStyle(
                  fontSize: 13,
                  color: isSubstitute ? _textSecondary : _textPrimary,
                  fontWeight: isSubstitute ? FontWeight.normal : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Position Badge
            if (player.position != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPositionColor(player.position!).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getPositionShort(player.position!),
                  style: TextStyle(
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
        return position
            .substring(0, position.length > 3 ? 3 : position.length)
            .toUpperCase();
    }
  }

  Color _getPositionColor(String position) {
    switch (position.toLowerCase()) {
      case 'goalkeeper':
        return Colors.orange;
      case 'defender':
        return const Color(0xFF2563EB);
      case 'midfielder':
        return const Color(0xFF10B981);
      case 'forward':
        return const Color(0xFFEF4444);
      default:
        return _textSecondary;
    }
  }
}

// ============ H2H Tab ============
class _H2HTab extends ConsumerWidget {
  final AttendanceRecord record;

  static const _success = Color(0xFF10B981);
  static const _error = Color(0xFFEF4444);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _H2HTab({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeTeam = record.homeTeamName;
    final awayTeam = record.awayTeamName;

    if (homeTeam.isEmpty || awayTeam.isEmpty) {
      return Center(
        child: Text(
          '팀 정보가 없습니다',
          style: TextStyle(color: _textSecondary),
        ),
      );
    }

    final h2hAsync = ref.watch(attendanceH2HProvider((homeTeam: homeTeam, awayTeam: awayTeam)));

    return h2hAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 48, color: _textSecondary),
                const SizedBox(height: 12),
                Text(
                  '상대전적 기록이 없습니다',
                  style: TextStyle(color: _textSecondary, fontSize: 14),
                ),
              ],
            ),
          );
        }

        // 통계 계산
        int homeWins = 0;
        int awayWins = 0;
        int draws = 0;
        int homeGoals = 0;
        int awayGoals = 0;

        for (final event in events) {
          final hScore = event.homeScore ?? 0;
          final aScore = event.awayScore ?? 0;

          if (event.homeTeam?.toLowerCase() == homeTeam.toLowerCase()) {
            homeGoals += hScore;
            awayGoals += aScore;
            if (hScore > aScore) {
              homeWins++;
            } else if (hScore < aScore) {
              awayWins++;
            } else {
              draws++;
            }
          } else {
            homeGoals += aScore;
            awayGoals += hScore;
            if (aScore > hScore) {
              homeWins++;
            } else if (aScore < hScore) {
              awayWins++;
            } else {
              draws++;
            }
          }
        }

        return Container(
          color: Colors.white,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(homeWins, draws, awayWins, homeGoals, awayGoals, events.length),
              const SizedBox(height: 16),
              Text(
                '최근 경기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...events.take(10).map((event) => _buildMatchCard(context, event)),
            ],
          ),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(
        child: Text('오류: $e', style: TextStyle(color: _textSecondary)),
      ),
    );
  }

  Widget _buildSummaryCard(int homeWins, int draws, int awayWins, int homeGoals, int awayGoals, int totalMatches) {
    final total = homeWins + draws + awayWins;
    final homePercent = total > 0 ? homeWins / total : 0.0;
    final drawPercent = total > 0 ? draws / total : 0.0;
    final awayPercent = total > 0 ? awayWins / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    if (record.homeTeamLogo != null)
                      CachedNetworkImage(
                        imageUrl: record.homeTeamLogo!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => Icon(Icons.shield, size: 48, color: _textSecondary),
                      )
                    else
                      Icon(Icons.shield, size: 48, color: _textSecondary),
                    const SizedBox(height: 8),
                    Text(
                      record.homeTeamName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      '$totalMatches경기',
                      style: TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildWinStat('$homeWins', '승', _success),
                        Container(
                          width: 1,
                          height: 30,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          color: _border,
                        ),
                        _buildWinStat('$draws', '무', _textSecondary),
                        Container(
                          width: 1,
                          height: 30,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          color: _border,
                        ),
                        _buildWinStat('$awayWins', '승', _error),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '득점 $homeGoals : $awayGoals',
                      style: TextStyle(
                        fontSize: 11,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    if (record.awayTeamLogo != null)
                      CachedNetworkImage(
                        imageUrl: record.awayTeamLogo!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => Icon(Icons.shield, size: 48, color: _textSecondary),
                      )
                    else
                      Icon(Icons.shield, size: 48, color: _textSecondary),
                    const SizedBox(height: 8),
                    Text(
                      record.awayTeamName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
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
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(
                  flex: (homePercent * 100).round().clamp(1, 100),
                  child: Container(
                    height: 8,
                    color: _success,
                  ),
                ),
                if (drawPercent > 0)
                  Expanded(
                    flex: (drawPercent * 100).round().clamp(1, 100),
                    child: Container(
                      height: 8,
                      color: _textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                Expanded(
                  flex: (awayPercent * 100).round().clamp(1, 100),
                  child: Container(
                    height: 8,
                    color: _error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(homePercent * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _success,
                ),
              ),
              Text(
                '${(drawPercent * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: _textSecondary,
                ),
              ),
              Text(
                '${(awayPercent * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWinStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: _textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchCard(BuildContext context, SportsDbEvent event) {
    final dateStr = event.dateTime != null
        ? DateFormat('yyyy.MM.dd').format(event.dateTime!)
        : '-';

    final homeScore = event.homeScore ?? 0;
    final awayScore = event.awayScore ?? 0;

    String result;
    Color resultColor;
    if (event.homeTeam?.toLowerCase() == record.homeTeamName.toLowerCase()) {
      if (homeScore > awayScore) {
        result = '승';
        resultColor = _success;
      } else if (homeScore < awayScore) {
        result = '패';
        resultColor = _error;
      } else {
        result = '무';
        resultColor = _textSecondary;
      }
    } else {
      if (awayScore > homeScore) {
        result = '승';
        resultColor = _success;
      } else if (awayScore < homeScore) {
        result = '패';
        resultColor = _error;
      } else {
        result = '무';
        resultColor = _textSecondary;
      }
    }

    return GestureDetector(
      onTap: () => context.push('/match/${event.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  result,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: resultColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${event.homeTeam} $homeScore - $awayScore ${event.awayTeam}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dateStr · ${event.league ?? ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: _textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: _textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
