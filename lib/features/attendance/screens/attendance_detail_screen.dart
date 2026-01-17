import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/api_football_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/photo_carousel.dart';
import '../../../shared/widgets/football_pitch_view.dart';
import '../../../shared/widgets/team_comparison_widget.dart';
import '../../../shared/widgets/standings_table.dart';
import '../models/attendance_record.dart';
import '../providers/attendance_provider.dart';

// Provider for match stats (API-Football)
final attendanceMatchStatsProvider =
    FutureProvider.family<List<ApiFootballTeamStats>, String>((ref, fixtureId) async {
  final service = ApiFootballService();
  final id = int.tryParse(fixtureId);
  if (id == null) return [];
  return service.getFixtureStatistics(id);
});

// Provider for match timeline (API-Football events)
final attendanceMatchTimelineProvider =
    FutureProvider.family<List<ApiFootballEvent>, String>((ref, fixtureId) async {
  final service = ApiFootballService();
  final id = int.tryParse(fixtureId);
  if (id == null) return [];
  return service.getFixtureEvents(id);
});

// Provider for match lineup (API-Football)
final attendanceMatchLineupProvider =
    FutureProvider.family<List<ApiFootballLineup>, String>((ref, fixtureId) async {
  final service = ApiFootballService();
  final id = int.tryParse(fixtureId);
  if (id == null) return [];
  return service.getFixtureLineups(id);
});

// Provider for player statistics (API-Football)
final attendancePlayerStatsProvider =
    FutureProvider.family<List<FixturePlayerStats>, String>((ref, fixtureId) async {
  final service = ApiFootballService();
  final id = int.tryParse(fixtureId);
  if (id == null) return [];
  return service.getFixturePlayers(id);
});

// Provider for head to head (API-Football)
final attendanceH2HProvider =
    FutureProvider.family<List<ApiFootballFixture>, ({int homeTeamId, int awayTeamId})>((ref, params) async {
  final service = ApiFootballService();
  return service.getHeadToHead(params.homeTeamId, params.awayTeamId);
});

// Provider for fixture detail (to get leagueId)
final attendanceFixtureProvider =
    FutureProvider.family<ApiFootballFixture?, String>((ref, fixtureId) async {
  final service = ApiFootballService();
  final id = int.tryParse(fixtureId);
  if (id == null) return null;
  return service.getFixtureById(id);
});

// Provider for venue info (API-Football)
final attendanceVenueProvider =
    FutureProvider.family<ApiFootballVenue?, ({String? matchId, String stadiumName})>((ref, params) async {
  final service = ApiFootballService();

  // matchId가 있으면 fixture에서 venue 정보 가져오기
  if (params.matchId != null) {
    final fixtureId = int.tryParse(params.matchId!);
    if (fixtureId != null) {
      final fixture = await service.getFixtureById(fixtureId);
      if (fixture?.venue != null && fixture!.venue!.id != null) {
        // venue id로 상세 정보 조회
        final venue = await service.getVenueById(fixture.venue!.id!);
        if (venue != null) return venue;
        // 상세 정보가 없으면 fixture의 venue 정보 반환
        return fixture.venue;
      }
    }
  }

  // matchId가 없거나 fixture에 venue가 없으면 이름으로 검색
  if (params.stadiumName.isNotEmpty) {
    final venues = await service.searchVenues(params.stadiumName);
    if (venues.isNotEmpty) return venues.first;
  }

  return null;
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
              final l10n = AppLocalizations.of(context)!;
              return Center(child: Text(l10n.recordNotFound));
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
    final l10n = AppLocalizations.of(context)!;
    final hasMatchId = record.matchId != null;

    return Column(
      children: [
        // 헤더 영역 (고정)
        _buildHeader(context),

        // 탭바 (고정)
        if (hasMatchId)
          Container(
            color: Colors.white,
            child: TabBar(
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
              tabs: [
                Tab(text: l10n.diary),
                Tab(text: l10n.tabComparison),
                Tab(text: l10n.tabStats),
                Tab(text: l10n.tabLineup),
                Tab(text: l10n.tabRanking),
              ],
            ),
          ),

        // 탭 컨텐츠 (스크롤)
        Expanded(
          child: hasMatchId
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _DiaryTab(record: record),
                    _ComparisonTab(record: record),
                    _StatsAndTimelineTab(matchId: record.matchId!, record: record),
                    _LineupTab(matchId: record.matchId!, record: record),
                    _StandingsTabWrapper(record: record),
                  ],
                )
              : _DiaryTab(record: record),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단 앱바 영역
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: _textPrimary,
                  onPressed: () => context.pop(),
                ),
                const Spacer(),
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
            ),

            // 리그 배지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          ],
        ),
      ),
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

// ============ Diary Tab ============
class _DiaryTab extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    // Venue 정보 로드
    final venueAsync = ref.watch(attendanceVenueProvider((
      matchId: record.matchId,
      stadiumName: record.stadium,
    )));

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
              child: _buildMvpCard(l10n),
            ),
            const SizedBox(height: 20),
          ],

          // Rating & Mood indicator + Tags (같은 Wrap으로)
          if (record.rating != null || record.mood != null || record.tags.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Rating
                  if (record.rating != null)
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
                          const Icon(Icons.star, color: _warning, size: 16),
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
                  // Mood
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
                        '${record.mood!.emoji} ${record.mood!.getLocalizedLabel(context)}',
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  // Tags
                  ...record.tags.map((tag) => Container(
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
                      )),
                ],
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
                title: l10n.matchDiary,
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
              title: l10n.matchInfo,
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.calendar_today,
                    label: l10n.date,
                    value: DateFormat('yyyy.MM.dd (EEEE)', locale.languageCode).format(record.date),
                  ),
                  _InfoRow(
                    icon: Icons.emoji_events,
                    label: l10n.league,
                    value: record.league,
                  ),
                  _InfoRow(
                    icon: Icons.stadium,
                    label: l10n.stadium,
                    value: record.stadium,
                  ),
                  if (record.seatInfo != null)
                    _InfoRow(
                      icon: Icons.chair,
                      label: l10n.seat,
                      value: record.seatInfo!,
                    ),
                ],
              ),
            ),
          ),

          // Venue Detail Card
          venueAsync.when(
            data: (venue) {
              if (venue == null) return const SizedBox.shrink();
              // 기본 경기장 이름만 있으면 추가 정보가 없으므로 표시하지 않음
              if (venue.capacity == null && venue.address == null && venue.image == null) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                child: _VenueDetailCard(venue: venue),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Additional Info Section
          if (_hasAdditionalInfo()) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSectionCard(
                icon: Icons.info_outline,
                iconColor: _textSecondary,
                title: l10n.additionalInfo,
                child: Column(
                  children: [
                    if (record.weather != null)
                      _InfoRow(
                          icon: Icons.cloud, label: l10n.weather, value: record.weather!),
                    if (record.companion != null)
                      _InfoRow(
                          icon: Icons.people,
                          label: l10n.companions,
                          value: record.companion!),
                    if (record.ticketPrice != null)
                      _InfoRow(
                          icon: Icons.confirmation_number,
                          label: l10n.ticketPrice,
                          value: l10n.currencyWon(NumberFormat('#,###').format(record.ticketPrice))),
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
                title: l10n.stadiumFood,
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
                title: l10n.memo,
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

  Widget _buildMvpCard(AppLocalizations l10n) {
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
                  l10n.mvpToday,
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

// ============ Stats & Timeline Tab (Combined) ============
class _StatsAndTimelineTab extends ConsumerWidget {
  final String matchId;
  final AttendanceRecord record;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _StatsAndTimelineTab({required this.matchId, required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(attendanceMatchStatsProvider(matchId));
    final timelineAsync = ref.watch(attendanceMatchTimelineProvider(matchId));

    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 기록 섹션
        _buildSectionHeader(l10n.sectionStats, Icons.analytics_outlined),
        const SizedBox(height: 12),
        statsAsync.when(
          data: (statsList) => _buildStatsContent(context, statsList),
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => _buildErrorWidget(l10n.noStatsInfo),
        ),

        const SizedBox(height: 24),

        // 중계 섹션
        _buildSectionHeader(l10n.sectionBroadcast, Icons.timeline),
        const SizedBox(height: 12),
        timelineAsync.when(
          data: (events) => _buildTimelineContent(context, events),
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => _buildErrorWidget(l10n.noTimelineInfo),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _textPrimary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: _textSecondary, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildStatsContent(BuildContext context, List<ApiFootballTeamStats> statsList) {
    final l10n = AppLocalizations.of(context)!;
    if (statsList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Center(
          child: Text(
            l10n.noStatsInfo,
            style: const TextStyle(color: _textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    final homeStats = statsList.isNotEmpty ? statsList[0] : null;
    final awayStats = statsList.length > 1 ? statsList[1] : null;

    int? getStat(ApiFootballTeamStats? stats, String type) {
      if (stats == null) return null;
      final value = stats.statistics[type];
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value.replaceAll('%', ''));
      }
      return null;
    }

    final homePossession = getStat(homeStats, 'Ball Possession');
    final awayPossession = getStat(awayStats, 'Ball Possession');
    final homeShots = getStat(homeStats, 'Total Shots');
    final awayShots = getStat(awayStats, 'Total Shots');
    final homeShotsOnTarget = getStat(homeStats, 'Shots on Goal');
    final awayShotsOnTarget = getStat(awayStats, 'Shots on Goal');
    final homeCorners = getStat(homeStats, 'Corner Kicks');
    final awayCorners = getStat(awayStats, 'Corner Kicks');
    final homeFouls = getStat(homeStats, 'Fouls');
    final awayFouls = getStat(awayStats, 'Fouls');
    final homeOffsides = getStat(homeStats, 'Offsides');
    final awayOffsides = getStat(awayStats, 'Offsides');
    final homeYellowCards = getStat(homeStats, 'Yellow Cards');
    final awayYellowCards = getStat(awayStats, 'Yellow Cards');
    final homeRedCards = getStat(homeStats, 'Red Cards');
    final awayRedCards = getStat(awayStats, 'Red Cards');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // Team names header
          Row(
            children: [
              Expanded(
                child: Text(
                  record.homeTeamName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 40),
              Expanded(
                child: Text(
                  record.awayTeamName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Stats rows
          if (homePossession != null && awayPossession != null)
            _StatBar(
              label: l10n.possession,
              homeValue: homePossession,
              awayValue: awayPossession,
              isPercentage: true,
            ),
          if (homeShots != null && awayShots != null)
            _StatBar(
              label: l10n.shots,
              homeValue: homeShots,
              awayValue: awayShots,
            ),
          if (homeShotsOnTarget != null && awayShotsOnTarget != null)
            _StatBar(
              label: l10n.shotsOnTarget,
              homeValue: homeShotsOnTarget,
              awayValue: awayShotsOnTarget,
            ),
          if (homeCorners != null && awayCorners != null)
            _StatBar(
              label: l10n.corners,
              homeValue: homeCorners,
              awayValue: awayCorners,
            ),
          if (homeFouls != null && awayFouls != null)
            _StatBar(
              label: l10n.fouls,
              homeValue: homeFouls,
              awayValue: awayFouls,
            ),
          if (homeOffsides != null && awayOffsides != null)
            _StatBar(
              label: l10n.offsidesLabel,
              homeValue: homeOffsides,
              awayValue: awayOffsides,
            ),
          if (homeYellowCards != null && awayYellowCards != null)
            _StatBar(
              label: l10n.warningsLabel,
              homeValue: homeYellowCards,
              awayValue: awayYellowCards,
              color: Colors.amber,
            ),
          if (homeRedCards != null && awayRedCards != null)
            _StatBar(
              label: l10n.sendOffsLabel,
              homeValue: homeRedCards,
              awayValue: awayRedCards,
              color: Colors.red,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineContent(BuildContext context, List<ApiFootballEvent> events) {
    final l10n = AppLocalizations.of(context)!;
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Center(
          child: Text(
            l10n.noTimelineInfo,
            style: const TextStyle(color: _textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    // 시간순 정렬
    final sortedEvents = List<ApiFootballEvent>.from(events)
      ..sort((a, b) {
        final aTime = a.elapsed ?? 0;
        final bTime = b.elapsed ?? 0;
        return aTime.compareTo(bTime);
      });

    final homeTeamId = int.tryParse(record.homeTeamId);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: List.generate(sortedEvents.length, (index) {
          final event = sortedEvents[index];
          final isFirst = index == 0;
          final isLast = index == sortedEvents.length - 1;
          final isHome = event.teamId == homeTeamId;
          return _TimelineItem(
            event: event,
            isFirst: isFirst,
            isLast: isLast,
            isHome: isHome,
          );
        }),
      ),
    );
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
    final playerStatsAsync = ref.watch(attendancePlayerStatsProvider(matchId));
    final eventsAsync = ref.watch(attendanceMatchTimelineProvider(matchId));

    return lineupAsync.when(
      data: (lineupList) {
        if (lineupList.isEmpty) {
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
                Text(
                  AppLocalizations.of(context)!.noLineupInfo,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.updatedAfterMatch,
                  style: const TextStyle(color: _textSecondary, fontSize: 13),
                ),
              ],
            ),
          );
        }

        // API-Football returns List<ApiFootballLineup> - index 0 = home, index 1 = away
        final homeLineup = lineupList.isNotEmpty ? lineupList[0] : null;
        final awayLineup = lineupList.length > 1 ? lineupList[1] : null;

        // 선수 통계 매핑
        final playerStats = playerStatsAsync.valueOrNull;
        final homePlayerStats = playerStats?.isNotEmpty == true ? playerStats!.first : null;
        final awayPlayerStats = playerStats != null && playerStats.length > 1 ? playerStats[1] : null;

        // 이벤트 가져오기
        final allEvents = eventsAsync.valueOrNull ?? [];
        final substitutions = allEvents.where((e) => e.isSubstitution).toList();

        // 선수별 이벤트 매핑 (playerId -> events)
        final playerEvents = <int, List<ApiFootballEvent>>{};
        for (final event in allEvents) {
          if (event.playerId != null) {
            playerEvents.putIfAbsent(event.playerId!, () => []).add(event);
          }
          // 어시스트 선수도 추가
          if (event.assistId != null && event.type == 'Goal') {
            playerEvents.putIfAbsent(event.assistId!, () => []).add(
              ApiFootballEvent(
                elapsed: event.elapsed,
                extra: event.extra,
                teamId: event.teamId,
                teamName: event.teamName,
                playerId: event.assistId,
                playerName: event.assistName,
                assistId: null,
                assistName: null,
                type: 'Assist',
                detail: 'Assist',
              ),
            );
          }
        }

        // FootballPitchView에 필요한 팀 정보 생성
        final homeTeam = ApiFootballFixtureTeam(
          id: int.tryParse(record.homeTeamId) ?? 0,
          name: record.homeTeamName,
          logo: record.homeTeamLogo,
        );
        final awayTeam = ApiFootballFixtureTeam(
          id: int.tryParse(record.awayTeamId) ?? 0,
          name: record.awayTeamName,
          logo: record.awayTeamLogo,
        );

        // FootballPitchView 공통 위젯 사용
        return Padding(
          padding: const EdgeInsets.all(16),
          child: FootballPitchView(
            homeLineup: homeLineup,
            awayLineup: awayLineup,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            homePlayerStats: homePlayerStats,
            awayPlayerStats: awayPlayerStats,
            substitutions: substitutions,
            playerEvents: playerEvents,
          ),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// ============ Comparison Tab ============
class _ComparisonTab extends ConsumerWidget {
  final AttendanceRecord record;

  const _ComparisonTab({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final homeTeamId = int.tryParse(record.homeTeamId) ?? 0;
    final awayTeamId = int.tryParse(record.awayTeamId) ?? 0;

    if (homeTeamId == 0 || awayTeamId == 0) {
      return Center(
        child: Text(
          l10n.noDataAvailable,
          style: const TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }

    // matchId가 없으면 비교 탭 표시 불가
    if (record.matchId == null) {
      return Center(
        child: Text(
          l10n.noDataAvailable,
          style: const TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }

    // fixture에서 leagueId와 season 가져오기
    final fixtureAsync = ref.watch(attendanceFixtureProvider(record.matchId!));

    return fixtureAsync.when(
      data: (fixture) {
        if (fixture == null) {
          return Center(
            child: Text(
              l10n.noDataAvailable,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          );
        }

        final leagueId = fixture.league.id;
        final season = fixture.league.season ?? record.date.year;

        return TeamComparisonTab(
          homeTeamId: homeTeamId,
          awayTeamId: awayTeamId,
          homeTeamName: record.homeTeamName,
          awayTeamName: record.awayTeamName,
          homeTeamLogo: record.homeTeamLogo,
          awayTeamLogo: record.awayTeamLogo,
          leagueId: leagueId,
          season: season,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(
          l10n.noDataAvailable,
          style: const TextStyle(color: Color(0xFF6B7280)),
        ),
      ),
    );
  }
}

// ============ Standings Tab Wrapper ============
class _StandingsTabWrapper extends ConsumerWidget {
  final AttendanceRecord record;

  const _StandingsTabWrapper({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final homeTeamId = int.tryParse(record.homeTeamId) ?? 0;
    final awayTeamId = int.tryParse(record.awayTeamId) ?? 0;

    if (homeTeamId == 0 || awayTeamId == 0) {
      return Center(
        child: Text(
          l10n.noStandingsInfo,
          style: const TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }

    // matchId가 없으면 순위 탭 표시 불가
    if (record.matchId == null) {
      return Center(
        child: Text(
          l10n.noStandingsInfo,
          style: const TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }

    // fixture에서 leagueId와 season 가져오기
    final fixtureAsync = ref.watch(attendanceFixtureProvider(record.matchId!));

    return fixtureAsync.when(
      data: (fixture) {
        if (fixture == null) {
          return Center(
            child: Text(
              l10n.noStandingsInfo,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          );
        }

        final leagueId = fixture.league.id;
        final season = fixture.league.season ?? record.date.year;

        return StandingsTab(
          leagueId: leagueId,
          season: season,
          homeTeamId: homeTeamId,
          awayTeamId: awayTeamId,
          leagueName: fixture.league.name,
          leagueLogo: fixture.league.logo,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(
          l10n.noStandingsInfo,
          style: const TextStyle(color: Color(0xFF6B7280)),
        ),
      ),
    );
  }
}

// ============ Venue Detail Card ============
class _VenueDetailCard extends StatelessWidget {
  final ApiFootballVenue venue;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _VenueDetailCard({required this.venue});

  bool get _hasImage => venue.image != null && venue.image!.isNotEmpty;

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
          // 경기장 이미지 (있는 경우만)
          if (_hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              child: CachedNetworkImage(
                imageUrl: venue.image!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 140,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.stadium, size: 48, color: Colors.grey),
                  ),
                ),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),

          // 경기장 정보
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.stadium, size: 18, color: _primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            venue.name ?? AppLocalizations.of(context)!.stadium,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                          ),
                          if (venue.city != null)
                            Text(
                              venue.city!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 수용인원/잔디 정보 (가로 배치)
                if (venue.capacity != null || venue.surface != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (venue.capacity != null)
                        Expanded(
                          child: _VenueStatChip(
                            icon: Icons.people_outline,
                            label: AppLocalizations.of(context)!.capacity,
                            value: NumberFormat('#,###').format(venue.capacity),
                          ),
                        ),
                      if (venue.capacity != null && venue.surface != null)
                        const SizedBox(width: 12),
                      if (venue.surface != null)
                        Expanded(
                          child: _VenueStatChip(
                            icon: Icons.grass,
                            label: AppLocalizations.of(context)!.grass,
                            value: venue.surface!,
                          ),
                        ),
                    ],
                  ),
                ],

                // 주소 (있는 경우)
                if (venue.address != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: _textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          venue.address!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _textSecondary,
                          ),
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
    );
  }
}

class _VenueStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _VenueStatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: _primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============ Stat Bar Widget ============
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

    // 숫자가 큰 쪽이 진한 색
    final homeWins = homeValue > awayValue;
    final awayWins = awayValue > homeValue;
    final isDraw = homeValue == awayValue;

    final baseColor = color ?? _primary;
    final homeColor = isDraw ? baseColor.withValues(alpha: 0.6) : (homeWins ? baseColor : baseColor.withValues(alpha: 0.3));
    final awayColor = isDraw ? baseColor.withValues(alpha: 0.6) : (awayWins ? baseColor : baseColor.withValues(alpha: 0.3));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPercentage ? '$homeValue%' : '$homeValue',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: homeWins ? FontWeight.w700 : FontWeight.w500,
                  color: homeWins ? _textPrimary : _textSecondary,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: _textSecondary,
                ),
              ),
              Text(
                isPercentage ? '$awayValue%' : '$awayValue',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: awayWins ? FontWeight.w700 : FontWeight.w500,
                  color: awayWins ? _textPrimary : _textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                flex: (homeRatio * 100).round().clamp(1, 99),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: homeColor,
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
                    color: awayColor,
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

// ============ Timeline Item Widget ============
class _TimelineItem extends StatelessWidget {
  final ApiFootballEvent event;
  final bool isFirst;
  final bool isLast;
  final bool isHome;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _TimelineItem({
    required this.event,
    this.isFirst = false,
    this.isLast = false,
    required this.isHome,
  });

  @override
  Widget build(BuildContext context) {
    final isGoal = event.isGoal;
    final isCard = event.isCard;
    final isSubst = event.isSubstitution;

    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 12 : 0),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // 홈팀 영역 (왼쪽)
            Expanded(
              child: isHome
                  ? _buildEventContent(context, isGoal, isCard, isSubst, true)
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
            child: !isHome
                ? _buildEventContent(context, isGoal, isCard, isSubst, false)
                : const SizedBox(),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildEventContent(BuildContext context, bool isGoal, bool isCard, bool isSubst, bool isHome) {
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
                _getEventTypeText(context),
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
            event.playerName ?? '',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
            textAlign: isHome ? TextAlign.right : TextAlign.left,
          ),

          // 어시스트 또는 세부 정보
          if (isGoal && event.assistName != null && event.assistName!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              AppLocalizations.of(context)!.assistLabel(event.assistName!),
              style: TextStyle(
                fontSize: 11,
                color: _textSecondary,
              ),
              textAlign: isHome ? TextAlign.right : TextAlign.left,
            ),
          ] else if (isSubst && event.assistName != null && event.assistName!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_upward, size: 10, color: Colors.green),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    event.assistName!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
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
            event.teamName,
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

  String _getEventTypeText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (event.type.toLowerCase()) {
      case 'goal':
        if (event.detail?.toLowerCase().contains('penalty') == true) {
          return l10n.penaltyGoal;
        } else if (event.detail?.toLowerCase().contains('own') == true) {
          return l10n.ownGoal;
        }
        return l10n.goalLabel;
      case 'card':
        if (event.detail?.toLowerCase().contains('yellow') == true) {
          return l10n.warningCard;
        } else if (event.detail?.toLowerCase().contains('red') == true) {
          return l10n.sendOffCard;
        }
        return l10n.cardLabel;
      case 'subst':
        return l10n.substitutionLabel;
      case 'var':
        return 'VAR';
      default:
        return event.type;
    }
  }

  IconData _getEventIcon() {
    switch (event.type.toLowerCase()) {
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
    switch (event.type.toLowerCase()) {
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
