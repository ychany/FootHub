import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/team_logo.dart';
import '../models/attendance_record.dart';
import '../providers/attendance_provider.dart';

class AttendanceListScreen extends ConsumerStatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  ConsumerState<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends ConsumerState<AttendanceListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // 달력 탭에서 기본으로 오늘 날짜 선택
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 직관 일기'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: TabBar(
            controller: _tabController,
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            tabs: const [
              Tab(height: 36, text: '리스트'),
              Tab(height: 36, text: '달력'),
              Tab(height: 36, text: '통계'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 리스트 뷰
          _buildListView(attendanceAsync),
          // 달력 뷰
          _buildCalendarView(attendanceAsync),
          // 통계 뷰
          _buildStatsView(statsAsync),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAdd(context),
        icon: const Icon(Icons.add),
        label: const Text('직관 기록'),
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
            padding: const EdgeInsets.only(bottom: 80),
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

  Widget _buildCalendarView(AsyncValue<List<AttendanceRecord>> attendanceAsync) {
    return attendanceAsync.when(
      data: (records) {
        // 날짜별 기록 맵 생성
        final Map<DateTime, List<AttendanceRecord>> eventsByDate = {};
        for (final record in records) {
          final date = DateTime(record.date.year, record.date.month, record.date.day);
          eventsByDate[date] = [...(eventsByDate[date] ?? []), record];
        }

        // 선택된 날짜의 기록
        final selectedRecords = _selectedDay != null
            ? eventsByDate[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)] ?? []
            : <AttendanceRecord>[];

        return Column(
          children: [
            TableCalendar<AttendanceRecord>(
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
                markerDecoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: AppTextStyles.subtitle1,
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return null;

                  // 승무패 결과에 따른 마커 색상
                  final record = events.first;
                  Color markerColor = Colors.grey;
                  if (record.myResult == MatchResult.win) {
                    markerColor = Colors.green;
                  } else if (record.myResult == MatchResult.draw) {
                    markerColor = Colors.orange;
                  } else if (record.myResult == MatchResult.loss) {
                    markerColor = Colors.red;
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
            const Divider(height: 1),
            Expanded(
              child: selectedRecords.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_note, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            _selectedDay != null
                                ? '${DateFormat('M월 d일').format(_selectedDay!)}에 기록이 없습니다'
                                : '날짜를 선택해주세요',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: selectedRecords.length,
                      itemBuilder: (context, index) {
                        return _AttendanceCard(
                          record: selectedRecords[index],
                          onTap: () => _navigateToDetail(context, selectedRecords[index].id),
                          onLongPress: () => _showOptions(context, ref, selectedRecords[index]),
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

  void _navigateToAdd(BuildContext context) {
    context.push('/attendance/add');
  }

  void _navigateToDetail(BuildContext context, String id) {
    context.push('/attendance/$id');
  }

  void _showOptions(BuildContext context, WidgetRef ref, AttendanceRecord record) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('수정'),
              onTap: () {
                Navigator.pop(context);
                context.push('/attendance/${record.id}/edit');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('삭제', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, ref, record.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록 삭제'),
        content: const Text('이 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(attendanceNotifierProvider.notifier).deleteAttendance(id);
            },
            child: const Text('삭제', style: TextStyle(color: AppColors.error)),
          ),
        ],
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
          padding: const EdgeInsets.all(16),
          children: [
            // 승무패 원형 그래프
            _WinRateChart(
              wins: stats.wins,
              draws: stats.draws,
              losses: stats.losses,
              totalMatches: stats.totalMatches,
            ),
            const SizedBox(height: 24),

            // 요약 카드들
            Row(
              children: [
                Expanded(
                  child: _MiniStatCard(
                    title: '총 경기',
                    value: '${stats.totalMatches}',
                    icon: Icons.stadium,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStatCard(
                    title: '경기장',
                    value: '${stats.stadiumVisits.length}',
                    icon: Icons.place,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 리그별 통계
            Text(
              '리그별 통계',
              style: AppTextStyles.subtitle1,
            ),
            const SizedBox(height: 12),
            if (stats.leagueCount.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '아직 기록이 없습니다',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ...stats.leagueCount.entries.map((entry) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: AppTextStyles.body1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${entry.value}경기',
                      style: AppTextStyles.subtitle2.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              )),

            const SizedBox(height: 24),

            // 경기장 방문 현황
            if (stats.stadiumVisits.isNotEmpty) ...[
              Text(
                '경기장 방문 현황',
                style: AppTextStyles.subtitle1,
              ),
              const SizedBox(height: 12),
              ...stats.stadiumVisits.entries.map((entry) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.stadium_outlined, size: 18, color: AppColors.secondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: AppTextStyles.body1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${entry.value}회',
                      style: AppTextStyles.subtitle2.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              )),
            ],

            const SizedBox(height: 80), // FAB 공간
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
}

class _AttendanceCard extends StatelessWidget {
  final AttendanceRecord record;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _AttendanceCard({
    required this.record,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date, League & Mood/Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            DateFormat('yyyy.MM.dd (E)', 'ko').format(record.date),
                            style: AppTextStyles.caption.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (record.mood != null) ...[
                          const SizedBox(width: 8),
                          Text(record.mood!.emoji, style: const TextStyle(fontSize: 14)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 12, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                record.rating!.toStringAsFixed(1),
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.amber.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      _LeagueBadge(league: record.league),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Teams & Score
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        TeamLogo(
                          logoUrl: record.homeTeamLogo,
                          teamName: record.homeTeamName,
                          size: 40,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            record.homeTeamName,
                            style: AppTextStyles.subtitle2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      record.scoreDisplay,
                      style: AppTextStyles.headline3,
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            record.awayTeamName,
                            style: AppTextStyles.subtitle2,
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TeamLogo(
                          logoUrl: record.awayTeamLogo,
                          teamName: record.awayTeamName,
                          size: 40,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Diary Title Preview
              if (record.diaryTitle != null && record.diaryTitle!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.format_quote, size: 16, color: AppColors.primary.withValues(alpha: 0.6)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          record.diaryTitle!,
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.primary,
                            fontStyle: FontStyle.italic,
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

              // Stadium, Photos & Tags indicator
              Row(
                children: [
                  Icon(
                    Icons.stadium_outlined,
                    size: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      record.stadium,
                      style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (record.photos.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.photo_library_outlined,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${record.photos.length}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                  if (record.diaryContent != null && record.diaryContent!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.menu_book,
                      size: 14,
                      color: AppColors.secondary,
                    ),
                  ],
                  if (record.mvpPlayerName != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.emoji_events,
                      size: 14,
                      color: Colors.amber,
                    ),
                  ],
                ],
              ),

              // Tags Preview
              if (record.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: record.tags.take(4).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '#$tag',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondary,
                        fontSize: 11,
                      ),
                    ),
                  )).toList(),
                ),
              ],

              if (record.seatInfo != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.chair_outlined,
                      size: 14,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      record.seatInfo!,
                      style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LeagueBadge extends StatelessWidget {
  final String league;

  const _LeagueBadge({required this.league});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        league,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _WinRateChart extends StatelessWidget {
  final int wins;
  final int draws;
  final int losses;
  final int totalMatches;

  const _WinRateChart({
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
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Text('승률', style: AppTextStyles.subtitle1),
          const SizedBox(height: 16),
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
                      style: AppTextStyles.headline2.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$totalMatches경기',
                      style: AppTextStyles.caption,
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
              _LegendItem(color: Colors.green, label: '승', count: wins),
              const SizedBox(width: 24),
              _LegendItem(color: Colors.orange, label: '무', count: draws),
              const SizedBox(width: 24),
              _LegendItem(color: Colors.red, label: '패', count: losses),
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

  _PieChartPainter({
    required this.wins,
    required this.draws,
    required this.losses,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = wins + draws + losses;
    if (total == 0) {
      // 기록이 없을 때 회색 원
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
    const startAngle = -90 * 3.14159 / 180; // 12시 방향에서 시작

    double currentAngle = startAngle;

    // 승 (녹색)
    if (wins > 0) {
      final sweepAngle = (wins / total) * 2 * 3.14159;
      final paint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, currentAngle, sweepAngle, false, paint);
      currentAngle += sweepAngle;
    }

    // 무 (주황색)
    if (draws > 0) {
      final sweepAngle = (draws / total) * 2 * 3.14159;
      final paint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, currentAngle, sweepAngle, false, paint);
      currentAngle += sweepAngle;
    }

    // 패 (빨간색)
    if (losses > 0) {
      final sweepAngle = (losses / total) * 2 * 3.14159;
      final paint = Paint()
        ..color = Colors.red
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
          style: AppTextStyles.body2,
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.icon,
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
          Text(value, style: AppTextStyles.headline3),
          Text(title, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
