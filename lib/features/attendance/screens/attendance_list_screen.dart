import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../models/attendance_record.dart';
import '../providers/attendance_provider.dart';

class AttendanceListScreen extends ConsumerStatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  ConsumerState<AttendanceListScreen> createState() =>
      _AttendanceListScreenState();
}

class _AttendanceListScreenState extends ConsumerState<AttendanceListScreen>
    with SingleTickerProviderStateMixin {
  // 디자인 시스템 색상
  static const _primary = Color(0xFF2563EB);
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);
  static const _error = Color(0xFFEF4444);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _background = Color(0xFFF9FAFB);

  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedDay = DateTime.now();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(attendanceListProvider);
    final statsAsync = ref.watch(attendanceStatsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Column(
            children: [
              // 헤더
              _buildHeader(),

              // 탭바
              _buildTabBar(),

              // 컨텐츠
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildListView(attendanceAsync),
                    _buildCalendarView(attendanceAsync),
                    _buildStatsView(statsAsync),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _navigateToAdd(context),
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text(
            '직관 기록',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: const Text(
        '나의 직관 일기',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: _textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(height: 40, text: '리스트'),
          Tab(height: 40, text: '달력'),
          Tab(height: 40, text: '통계'),
        ],
      ),
    );
  }

  Widget _buildListView(AsyncValue<List<AttendanceRecord>> attendanceAsync) {
    return attendanceAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return EmptyAttendanceState(
            onAdd: () => _navigateToAdd(context),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(attendanceListProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: records.length,
            itemBuilder: (context, index) {
              return _AttendanceCard(
                record: records[index],
                onTap: () => _navigateToDetail(context, records[index].id),
                onLongPress: () => _showOptions(context, ref, records[index]),
              );
            },
          ),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, stack) => ErrorState(
        message: error.toString(),
        onRetry: () => ref.invalidate(attendanceListProvider),
      ),
    );
  }

  Widget _buildCalendarView(
      AsyncValue<List<AttendanceRecord>> attendanceAsync) {
    return attendanceAsync.when(
      data: (records) {
        final Map<DateTime, List<AttendanceRecord>> eventsByDate = {};
        for (final record in records) {
          final date =
              DateTime(record.date.year, record.date.month, record.date.day);
          eventsByDate[date] = [...(eventsByDate[date] ?? []), record];
        }

        final selectedRecords = _selectedDay != null
            ? eventsByDate[DateTime(
                    _selectedDay!.year, _selectedDay!.month, _selectedDay!.day)] ??
                []
            : <AttendanceRecord>[];

        return Column(
          children: [
            const SizedBox(height: 16),
            // 달력
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: TableCalendar<AttendanceRecord>(
                locale: 'ko_KR',
                firstDay: DateTime(2000),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) {
                  final normalizedDay = DateTime(day.year, day.month, day.day);
                  return eventsByDate[normalizedDay] ?? [];
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarStyle: CalendarStyle(
                  markersMaxCount: 3,
                  markerDecoration: const BoxDecoration(
                    color: _primary,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: _primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w600,
                  ),
                  defaultTextStyle: const TextStyle(color: _textPrimary),
                  weekendTextStyle:
                      TextStyle(color: _error.withValues(alpha: 0.8)),
                  outsideTextStyle:
                      TextStyle(color: _textSecondary.withValues(alpha: 0.5)),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                  leftChevronIcon:
                      const Icon(Icons.chevron_left, color: _textSecondary),
                  rightChevronIcon:
                      const Icon(Icons.chevron_right, color: _textSecondary),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  weekendStyle: TextStyle(
                    color: _error,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return null;

                    final record = events.first;
                    Color markerColor = _textSecondary;
                    if (record.myResult == MatchResult.win) {
                      markerColor = _success;
                    } else if (record.myResult == MatchResult.draw) {
                      markerColor = _warning;
                    } else if (record.myResult == MatchResult.loss) {
                      markerColor = _error;
                    }

                    return Positioned(
                      bottom: 1,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: markerColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 선택된 날짜의 기록
            Expanded(
              child: selectedRecords.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_note,
                              size: 48, color: _textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          Text(
                            _selectedDay != null
                                ? '${DateFormat('M월 d일').format(_selectedDay!)}에 기록이 없습니다'
                                : '날짜를 선택해주세요',
                            style: const TextStyle(color: _textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: selectedRecords.length,
                      itemBuilder: (context, index) {
                        return _AttendanceCard(
                          record: selectedRecords[index],
                          onTap: () => _navigateToDetail(
                              context, selectedRecords[index].id),
                          onLongPress: () =>
                              _showOptions(context, ref, selectedRecords[index]),
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, stack) => ErrorState(
        message: error.toString(),
        onRetry: () => ref.invalidate(attendanceListProvider),
      ),
    );
  }

  Widget _buildStatsView(AsyncValue<AttendanceStats> statsAsync) {
    return statsAsync.when(
      data: (stats) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(attendanceStatsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // 승률 카드
            _WinRateCard(
              wins: stats.wins,
              draws: stats.draws,
              losses: stats.losses,
              totalMatches: stats.totalMatches,
            ),
            const SizedBox(height: 16),

            // 요약 통계
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.stadium,
                    iconColor: _primary,
                    label: '총 경기',
                    value: '${stats.totalMatches}',
                    unit: '경기',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.place,
                    iconColor: _success,
                    label: '경기장',
                    value: '${stats.stadiumVisits.length}',
                    unit: '곳',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 리그별 통계
            _buildSectionHeader('리그별 통계', Icons.sports_soccer),
            const SizedBox(height: 12),
            if (stats.leagueCount.isEmpty)
              _buildEmptySection('아직 기록이 없습니다')
            else
              ...stats.leagueCount.entries.map((entry) => _buildStatRow(
                    entry.key,
                    '${entry.value}경기',
                    _primary,
                  )),

            const SizedBox(height: 24),

            // 경기장 방문 현황
            if (stats.stadiumVisits.isNotEmpty) ...[
              _buildSectionHeader('경기장 방문 현황', Icons.stadium_outlined),
              const SizedBox(height: 12),
              ...stats.stadiumVisits.entries.map((entry) => _buildStatRow(
                    entry.key,
                    '${entry.value}회',
                    _success,
                    icon: Icons.stadium_outlined,
                  )),
            ],
          ],
        ),
      ),
      loading: () => const LoadingIndicator(),
      error: (error, stack) => ErrorState(
        message: error.toString(),
        onRetry: () => ref.invalidate(attendanceStatsProvider),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: _primary),
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
    );
  }

  Widget _buildEmptySection(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: _textSecondary),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color,
      {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: _textSecondary),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: _textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAdd(BuildContext context) {
    context.push('/attendance/add');
  }

  void _navigateToDetail(BuildContext context, String id) {
    context.push('/attendance/$id');
  }

  void _showOptions(
      BuildContext context, WidgetRef ref, AttendanceRecord record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: _primary),
                ),
                title: const Text(
                  '수정',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/attendance/${record.id}/edit');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete, color: _error),
                ),
                title: const Text(
                  '삭제',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: _error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, ref, record.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '기록 삭제',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        content: const Text(
          '이 기록을 삭제하시겠습니까?',
          style: TextStyle(color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '취소',
              style: TextStyle(color: _textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(attendanceNotifierProvider.notifier).deleteAttendance(id);
            },
            child: const Text(
              '삭제',
              style: TextStyle(
                color: _error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final AttendanceRecord record;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _AttendanceCard({
    required this.record,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 & 리그 & 평점
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: _textSecondary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          DateFormat('yyyy.MM.dd (E)', 'ko').format(record.date),
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (record.mood != null) ...[
                        const SizedBox(width: 8),
                        Text(record.mood!.emoji,
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (record.rating != null) ...[
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: _warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 12, color: _warning),
                            const SizedBox(width: 2),
                            Text(
                              record.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                color: _warning,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        record.league,
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 팀 & 스코어
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildTeamLogo(record.homeTeamLogo),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          record.homeTeamName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    record.scoreDisplay,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          record.awayTeamName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildTeamLogo(record.awayTeamLogo),
                    ],
                  ),
                ),
              ],
            ),

            // 일기 제목 미리보기
            if (record.diaryTitle != null && record.diaryTitle!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.format_quote,
                        size: 16, color: _primary.withValues(alpha: 0.6)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        record.diaryTitle!,
                        style: const TextStyle(
                          color: _primary,
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // 경기장 & 기타 정보
            Row(
              children: [
                const Icon(Icons.stadium_outlined, size: 14, color: _textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    record.stadium,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (record.photos.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.photo_library_outlined,
                      size: 14, color: _primary),
                  const SizedBox(width: 2),
                  Text(
                    '${record.photos.length}',
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (record.diaryContent != null &&
                    record.diaryContent!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.menu_book, size: 14, color: _success),
                ],
                if (record.mvpPlayerName != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.emoji_events, size: 14, color: _warning),
                ],
              ],
            ),

            // 태그 미리보기
            if (record.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: record.tags
                    .take(4)
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '#$tag',
                            style: const TextStyle(
                              color: _success,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],

            // 좌석 정보
            if (record.seatInfo != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.chair_outlined, size: 14, color: _textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    record.seatInfo!,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamLogo(String? logoUrl) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: logoUrl != null && logoUrl.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: logoUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Icon(
                  Icons.shield_outlined,
                  color: _textSecondary,
                  size: 22,
                ),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.shield_outlined,
                  color: _textSecondary,
                  size: 22,
                ),
              ),
            )
          : const Icon(
              Icons.shield_outlined,
              color: _textSecondary,
              size: 22,
            ),
    );
  }
}

class _WinRateCard extends StatelessWidget {
  final int wins;
  final int draws;
  final int losses;
  final int totalMatches;

  static const _primary = Color(0xFF2563EB);
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);
  static const _error = Color(0xFFEF4444);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _WinRateCard({
    required this.wins,
    required this.draws,
    required this.losses,
    required this.totalMatches,
  });

  @override
  Widget build(BuildContext context) {
    final winRate = totalMatches > 0 ? (wins / totalMatches * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.pie_chart, size: 18, color: _primary),
              ),
              const SizedBox(width: 10),
              const Text(
                '승률',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 160,
            height: 160,
            child: CustomPaint(
              painter: _PieChartPainter(
                wins: wins,
                draws: draws,
                losses: losses,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${winRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      '$totalMatches경기',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: _success, label: '승', count: wins),
              const SizedBox(width: 24),
              _LegendItem(color: _warning, label: '무', count: draws),
              const SizedBox(width: 24),
              _LegendItem(color: _error, label: '패', count: losses),
            ],
          ),
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final int wins;
  final int draws;
  final int losses;

  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);
  static const _error = Color(0xFFEF4444);

  _PieChartPainter({
    required this.wins,
    required this.draws,
    required this.losses,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = wins + draws + losses;
    if (total == 0) {
      final paint = Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24;
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width / 2 - 12,
        paint,
      );
      return;
    }

    final rect = Rect.fromLTWH(12, 12, size.width - 24, size.height - 24);
    const startAngle = -90 * 3.14159 / 180;

    double currentAngle = startAngle;

    if (wins > 0) {
      final sweepAngle = (wins / total) * 2 * 3.14159;
      final paint = Paint()
        ..color = _success
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, currentAngle, sweepAngle, false, paint);
      currentAngle += sweepAngle;
    }

    if (draws > 0) {
      final sweepAngle = (draws / total) * 2 * 3.14159;
      final paint = Paint()
        ..color = _warning
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, currentAngle, sweepAngle, false, paint);
      currentAngle += sweepAngle;
    }

    if (losses > 0) {
      final sweepAngle = (losses / total) * 2 * 3.14159;
      final paint = Paint()
        ..color = _error
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, currentAngle, sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  static const _textPrimary = Color(0xFF111827);

  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label $count',
          style: const TextStyle(
            fontSize: 14,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textSecondary,
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
