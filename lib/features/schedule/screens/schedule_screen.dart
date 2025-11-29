import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/sports_db_service.dart';
import '../../../shared/models/match_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/schedule_provider.dart';
import '../../diary/providers/diary_provider.dart';

/// 축구 라이브스코어 Provider
final scheduleLivescoresProvider = FutureProvider<List<SportsDbLiveEvent>>((ref) async {
  final service = SportsDbService();
  return service.getSoccerLivescores();
});

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedLeague = ref.watch(selectedLeagueProvider);
    final schedulesAsync = ref.watch(filteredSchedulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('경기 일정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              ref.read(selectedDateProvider.notifier).state = DateTime.now();
              setState(() => _focusedDay = DateTime.now());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(selectedDate, day),
            onDaySelected: (selectedDay, focusedDay) {
              ref.read(selectedDateProvider.notifier).state = selectedDay;
              setState(() => _focusedDay = focusedDay);
            },
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
            ),
          ),

          // League Filter
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _LeagueChip(
                  label: '전체',
                  isSelected: selectedLeague == null,
                  onTap: () {
                    ref.read(selectedLeagueProvider.notifier).state = null;
                  },
                ),
                ...AppConstants.supportedLeagues.map(
                  (league) => _LeagueChip(
                    label: league,
                    displayLabel: AppConstants.getLeagueDisplayName(league),
                    isSelected: selectedLeague == league,
                    onTap: () {
                      ref.read(selectedLeagueProvider.notifier).state = league;
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Live Scores
          _ScheduleLiveScoresSection(),

          // Match List
          Expanded(
            child: schedulesAsync.when(
              data: (matches) {
                if (matches.isEmpty) {
                  return const EmptyScheduleState();
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(filteredSchedulesProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      return _ScheduleMatchCard(match: matches[index]);
                    },
                  ),
                );
              },
              loading: () => const LoadingIndicator(),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(filteredSchedulesProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeagueChip extends StatelessWidget {
  final String label;
  final String? displayLabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _LeagueChip({
    required this.label,
    this.displayLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          displayLabel ?? label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        checkmarkColor: AppColors.primary,
        backgroundColor: Colors.grey.shade200,
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
        ),
      ),
    );
  }
}

class _ScheduleMatchCard extends ConsumerWidget {
  final Match match;

  const _ScheduleMatchCard({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasNotificationAsync = ref.watch(hasNotificationProvider(match.id));
    final hasDiaryAsync = ref.watch(hasDiaryEntryProvider(match.id));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => context.push('/match/${match.id}'),
        onLongPress: () => _showMatchOptions(context, ref),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Time & League
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('HH:mm').format(match.kickoff),
                    style: AppTextStyles.subtitle1.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppConstants.getLeagueDisplayName(match.league),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      hasNotificationAsync.when(
                        data: (hasNotification) => GestureDetector(
                          onTap: () =>
                              _toggleNotification(ref, hasNotification),
                          child: Icon(
                            hasNotification
                                ? Icons.notifications_active
                                : Icons.notifications_none,
                            size: 20,
                            color: hasNotification
                                ? AppColors.primary
                                : Colors.grey,
                          ),
                        ),
                        loading: () => const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: (_, __) => const Icon(
                          Icons.notifications_none,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Teams
              Row(
                children: [
                  Expanded(
                    child: Text(
                      match.homeTeamName,
                      style: AppTextStyles.subtitle2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: match.isFinished
                        ? Text(
                            match.scoreDisplay,
                            style: AppTextStyles.headline3,
                          )
                        : Text(
                            'vs',
                            style: AppTextStyles.subtitle1.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  Expanded(
                    child: Text(
                      match.awayTeamName,
                      style: AppTextStyles.subtitle2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Stadium & Broadcast
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.stadium_outlined,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      match.stadium,
                      style: AppTextStyles.caption.copyWith(color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (match.broadcast != null) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.tv, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      match.broadcast!,
                      style: AppTextStyles.caption.copyWith(color: Colors.grey),
                    ),
                  ],
                ],
              ),

              // Watched indicator
              hasDiaryAsync.when(
                data: (hasDiary) {
                  if (hasDiary) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '직관 완료',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleNotification(WidgetRef ref, bool currentValue) {
    if (currentValue) {
      ref.read(scheduleNotifierProvider.notifier).removeNotification(match.id);
    } else {
      ref
          .read(scheduleNotifierProvider.notifier)
          .setNotification(matchId: match.id);
    }
  }

  void _showMatchOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('직관 기록하기'),
              onTap: () {
                Navigator.pop(context);
                _addToDiary(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('알림 설정'),
              onTap: () {
                Navigator.pop(context);
                _showNotificationSettings(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addToDiary(BuildContext context, WidgetRef ref) {
    // Navigate to add diary entry for this match
    context.push('/diary/add', extra: match);
  }

  void _showNotificationSettings(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _NotificationSettingsDialog(match: match),
    );
  }
}

class _NotificationSettingsDialog extends ConsumerWidget {
  final Match match;

  const _NotificationSettingsDialog({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingAsync = ref.watch(matchNotificationProvider(match.id));

    return AlertDialog(
      title: const Text('알림 설정'),
      content: settingAsync.when(
        data: (setting) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('킥오프 알림 (30분 전)'),
              value: setting?.notifyKickoff ?? true,
              onChanged: (value) {
                ref
                    .read(scheduleNotifierProvider.notifier)
                    .toggleNotification(
                      matchId: match.id,
                      type: 'kickoff',
                      value: value,
                    );
              },
            ),
            SwitchListTile(
              title: const Text('라인업 발표'),
              value: setting?.notifyLineup ?? false,
              onChanged: (value) {
                ref
                    .read(scheduleNotifierProvider.notifier)
                    .toggleNotification(
                      matchId: match.id,
                      type: 'lineup',
                      value: value,
                    );
              },
            ),
            SwitchListTile(
              title: const Text('경기 결과'),
              value: setting?.notifyResult ?? true,
              onChanged: (value) {
                ref
                    .read(scheduleNotifierProvider.notifier)
                    .toggleNotification(
                      matchId: match.id,
                      type: 'result',
                      value: value,
                    );
              },
            ),
          ],
        ),
        loading: () => const SizedBox(height: 150, child: LoadingIndicator()),
        error: (e, _) => Text('오류: $e'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}

class _ScheduleLiveScoresSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final livescoresAsync = ref.watch(scheduleLivescoresProvider);

    return livescoresAsync.when(
      data: (events) {
        // 진행 중인 경기만 필터링
        final liveEvents = events.where((e) => e.isLive).toList();

        if (liveEvents.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.red.withValues(alpha: 0.05),
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
                      Text(
                        'LIVE (${liveEvents.length})',
                        style: AppTextStyles.subtitle2.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => ref.invalidate(scheduleLivescoresProvider),
                        child: Row(
                          children: [
                            Icon(Icons.refresh, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              '새로고침',
                              style: AppTextStyles.caption.copyWith(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: liveEvents.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final event = liveEvents[index];
                        return _ScheduleLiveCard(event: event);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ScheduleLiveCard extends StatelessWidget {
  final SportsDbLiveEvent event;

  const _ScheduleLiveCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 리그 + 시간
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  event.league ?? '',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  event.statusDisplay,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // 팀 스코어
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  event.homeTeam ?? '',
                  style: const TextStyle(fontSize: 11),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  event.scoreDisplay,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  event.awayTeam ?? '',
                  style: const TextStyle(fontSize: 11),
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
