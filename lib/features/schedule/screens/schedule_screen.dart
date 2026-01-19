import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/error_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/match_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/schedule_provider.dart';
import '../../diary/providers/diary_provider.dart';
import '../../league/screens/league_list_screen.dart' show userLocalLeagueIdsProvider, userCountryCodeProvider, getLocalizedCountryName;

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> with WidgetsBindingObserver {
  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _success = Color(0xFF10B981);
  static const _error = Color(0xFFEF4444);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _background = Color(0xFFF9FAFB);

  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 화면 진입 시 일정 데이터 자동 갱신 (기존 캐시 먼저 표시 후 새 데이터 로드)
    _refreshData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 다시 포그라운드로 돌아올 때 데이터 갱신
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  @override
  void activate() {
    super.activate();
    // 화면이 다시 활성화될 때 (뒤로가기로 돌아올 때) 데이터 갱신
    _refreshData();
  }

  void _refreshData() {
    Future.microtask(() {
      if (mounted) {
        ref.invalidate(filteredSchedulesProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedLeague = ref.watch(selectedLeagueProvider);
    final schedulesAsync = ref.watch(filteredSchedulesProvider);

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

              Expanded(
                child: RefreshIndicator(
                  color: _primary,
                  displacement: 20,
                  onRefresh: () async {
                    ref.invalidate(filteredSchedulesProvider);
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            children: [
                              // 캘린더
                              _buildCalendar(selectedDate),

                              const SizedBox(height: 12),

                              // 리그 필터
                              _buildLeagueFilter(selectedLeague),

                              const SizedBox(height: 16),

                              // 경기 목록
                              _buildMatchList(schedulesAsync),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              l10n.matchSchedule,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              // 새로고침 버튼
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ref.invalidate(filteredSchedulesProvider);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: Icon(Icons.refresh, size: 20, color: _primary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 달력 선택 버튼
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showDatePicker,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: Icon(Icons.calendar_month, size: 20, color: _primary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 오늘 버튼
              GestureDetector(
                onTap: () {
                  ref.read(selectedDateProvider.notifier).state = DateTime.now();
                  setState(() => _focusedDay = DateTime.now());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.today, size: 18, color: _primary),
                      const SizedBox(width: 6),
                      Text(
                        l10n.today,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDatePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _DatePickerBottomSheet(
        initialDate: ref.read(selectedDateProvider),
        onDateSelected: (date) {
          ref.read(selectedDateProvider.notifier).state = date;
          setState(() => _focusedDay = date);
        },
      ),
    );
  }

  Widget _buildCalendar(DateTime selectedDate) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: TableCalendar(
        locale: Localizations.localeOf(context).toString(),
        firstDay: DateTime(2020, 1, 1),
        lastDay: DateTime(2030, 12, 31),
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
          weekendTextStyle: TextStyle(color: _error.withValues(alpha: 0.8)),
          outsideTextStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.5)),
          markerDecoration: const BoxDecoration(
            color: _success,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          titleTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
          formatButtonDecoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(8),
          ),
          formatButtonTextStyle: const TextStyle(
            color: _textSecondary,
            fontSize: 12,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left, color: _textSecondary),
          rightChevronIcon:
              const Icon(Icons.chevron_right, color: _textSecondary),
        ),
        availableCalendarFormats: {
          CalendarFormat.month: AppLocalizations.of(context)!.monthly,
          CalendarFormat.twoWeeks: AppLocalizations.of(context)!.twoWeeks,
          CalendarFormat.week: AppLocalizations.of(context)!.weekly,
        },
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
      ),
    );
  }

  Widget _buildLeagueFilter(String? selectedLeague) {
    final l10n = AppLocalizations.of(context)!;
    final localLeagueIds = ref.watch(userLocalLeagueIdsProvider);

    // 자국 리그 이름 목록 생성
    final localLeagueNames = localLeagueIds
        .map((id) => AppConstants.getLeagueNameById(id))
        .whereType<String>()
        .toList();

    // 전체 리그 목록: 기본 리그 + 자국 리그
    final allLeagues = [
      ...AppConstants.supportedLeagues,
      ...localLeagueNames,
    ];

    // 자국 이름 가져오기 (로컬라이징)
    final userCountryCode = ref.watch(userCountryCodeProvider);
    final languageCode = Localizations.localeOf(context).languageCode;
    final userCountryName = getLocalizedCountryName(userCountryCode, languageCode);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // 주요 (5대 리그 + 대륙컵 + 국제대회)
          _LeagueChip(
            label: l10n.major,
            isSelected: selectedLeague == 'major',
            onTap: () {
              ref.read(selectedLeagueProvider.notifier).state = 'major';
            },
          ),
          // 전체
          _LeagueChip(
            label: l10n.all,
            isSelected: selectedLeague == null,
            onTap: () {
              ref.read(selectedLeagueProvider.notifier).state = null;
            },
          ),
          // 자국 (국가대표 + 연령별 경기) - 전체 다음
          if (userCountryName != null)
            _LeagueChip(
              label: 'myCountry',
              displayLabel: userCountryName,
              isSelected: selectedLeague == 'myCountry',
              onTap: () {
                ref.read(selectedLeagueProvider.notifier).state = 'myCountry';
              },
            ),
          // 개별 리그들 (기본 + 자국 리그)
          ...allLeagues.map(
            (league) => _LeagueChip(
              label: league,
              displayLabel: AppConstants.getLocalizedLeagueName(context, league),
              isSelected: selectedLeague == league,
              onTap: () {
                ref.read(selectedLeagueProvider.notifier).state = league;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchList(AsyncValue<List<Match>> schedulesAsync) {
    return schedulesAsync.when(
      data: (matches) {
        if (matches.isEmpty) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: const EmptyScheduleState(),
          );
        }

        // 리그별로 그룹화
        final groupedMatches = <String, List<Match>>{};
        for (final match in matches) {
          final leagueName = match.league;
          groupedMatches.putIfAbsent(leagueName, () => []).add(match);
        }

        // 리그 순서 정렬 (5대 리그 우선, 그 다음 가나다순)
        final leagueOrder = [
          'Premier League', 'La Liga', 'Serie A', 'Bundesliga', 'Ligue 1',
          'K League 1', 'K League 2', 'UEFA Champions League', 'UEFA Europa League', 'UEFA Conference League',
        ];
        final sortedLeagues = groupedMatches.keys.toList()
          ..sort((a, b) {
            final aIndex = leagueOrder.indexWhere((l) => a.contains(l));
            final bIndex = leagueOrder.indexWhere((l) => b.contains(l));
            if (aIndex != -1 && bIndex != -1) return aIndex.compareTo(bIndex);
            if (aIndex != -1) return -1;
            if (bIndex != -1) return 1;
            return a.compareTo(b);
          });

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: sortedLeagues.map((league) {
              final leagueMatches = groupedMatches[league]!;
              return _LeagueMatchGroup(
                leagueName: league,
                matches: leagueMatches,
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(40),
        child: LoadingIndicator(),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorState(
          message: ErrorHelper.getLocalizedErrorMessage(context, e),
          onRetry: () => ref.invalidate(filteredSchedulesProvider),
        ),
      ),
    );
  }
}

class _LeagueMatchGroup extends StatelessWidget {
  final String leagueName;
  final List<Match> matches;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _LeagueMatchGroup({
    required this.leagueName,
    required this.matches,
  });

  int? get _leagueId => matches.isNotEmpty ? matches.first.leagueId : null;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 리그 헤더 (탭하면 리그 상세로 이동)
          GestureDetector(
            onTap: () {
              if (_leagueId != null) {
                context.push('/league/$_leagueId');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  // 리그 로고 (첫 번째 경기에서 가져옴)
                  if (matches.isNotEmpty && matches.first.homeTeamLogo != null)
                    _buildLeagueLogo(matches.first),
                  Expanded(
                    child: Text(
                      AppConstants.getLocalizedLeagueName(context, leagueName),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.nMatches(matches.length),
                    style: TextStyle(
                      fontSize: 11,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16, color: _textSecondary),
                ],
              ),
            ),
          ),
          // 경기 목록
          ...matches.asMap().entries.map((entry) {
            final index = entry.key;
            final match = entry.value;
            return Column(
              children: [
                if (index > 0)
                  Divider(height: 1, color: _border, indent: 14, endIndent: 14),
                _ScheduleMatchCard(match: match, showLeague: false),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLeagueLogo(Match match) {
    // 리그 ID로 로고 URL 생성
    if (match.leagueId != null) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            'https://media.api-sports.io/football/leagues/${match.leagueId}.png',
            width: 20,
            height: 20,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

}

class _LeagueChip extends StatelessWidget {
  final String label;
  final String? displayLabel;
  final bool isSelected;
  final VoidCallback onTap;

  static const _primary = Color(0xFF2563EB);
  static const _border = Color(0xFFE5E7EB);

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
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? _primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? _primary : _border,
            ),
          ),
          child: Text(
            displayLabel ?? label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleMatchCard extends ConsumerWidget {
  final Match match;
  final bool showLeague;

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _success = Color(0xFF10B981);
  static const _error = Color(0xFFEF4444);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _ScheduleMatchCard({required this.match, this.showLeague = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasNotificationAsync = ref.watch(hasNotificationProvider(match.id));
    final hasDiaryAsync = ref.watch(hasDiaryEntryProvider(match.id));

    return GestureDetector(
      onTap: () => context.push('/match/${match.id}'),
      onLongPress: () => _showMatchOptions(context, ref),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: showLeague ? 12 : 14,
          vertical: showLeague ? 12 : 10,
        ),
        decoration: showLeague
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              )
            : null,
        child: Column(
          children: [
            // 리그 & 시간 & 알림
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (showLeague) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          // A매치는 원래 리그명 그대로, 그 외는 축약 표시
                          AppConstants.isInternationalMatch(match.league)
                              ? match.league
                              : AppConstants.getLocalizedLeagueName(context, match.league),
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    // 킥오프 시간 (항상 표시, 라이브면 빨간색)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: match.isLive
                            ? _error.withValues(alpha: 0.1)
                            : _primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        DateFormat('HH:mm').format(match.kickoff),
                        style: TextStyle(
                          color: match.isLive ? _error : _primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    // 라이브 경기면 경과 시간 추가 표시
                    if (match.isLive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              match.isHalftime
                                  ? 'HT'
                                  : match.elapsed != null
                                      ? (match.extra != null && match.extra! > 0
                                          ? "${match.elapsed}+${match.extra}'"
                                          : "${match.elapsed}'")
                                      : 'LIVE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // 경기 종료 시 "종료" 배지 추가
                    if (match.isFinished) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _textSecondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.finished,
                          style: const TextStyle(
                            color: _textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                hasNotificationAsync.when(
                  data: (hasNotification) => GestureDetector(
                    onTap: () => _toggleNotification(ref, hasNotification),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: hasNotification
                            ? _primary.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hasNotification
                            ? Icons.notifications_active
                            : Icons.notifications_none_outlined,
                        size: 16,
                        color: hasNotification ? _primary : _textSecondary,
                      ),
                    ),
                  ),
                  loading: () => const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => Icon(
                    Icons.notifications_none_outlined,
                    size: 16,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 팀 정보
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildTeamLogo(match.homeTeamLogo),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          match.homeTeamName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: match.isFinished || match.isLive
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: match.isLive ? _error.withValues(alpha: 0.1) : _primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                match.scoreDisplay,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: match.isLive ? _error : _primary,
                                ),
                              ),
                              // 승부차기 점수 표시
                              if (match.penaltyScoreDisplay != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: Text(
                                    match.penaltyScoreDisplay!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: match.isLive ? _error : _primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : const Text(
                          'VS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _textSecondary,
                          ),
                        ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          match.awayTeamName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildTeamLogo(match.awayTeamLogo),
                    ],
                  ),
                ),
              ],
            ),

            // 직관 완료 표시
            hasDiaryAsync.when(
              data: (hasDiary) {
                if (hasDiary) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: _success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.attendanceComplete,
                            style: TextStyle(
                              color: _success,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
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
    );
  }

  void _toggleNotification(WidgetRef ref, bool currentValue) {
    if (currentValue) {
      ref.read(scheduleNotifierProvider.notifier).removeNotification(match.id);
    } else {
      // 기본값: 경기 시작 알림만 설정
      ref.read(scheduleNotifierProvider.notifier).setNotification(
        matchId: match.id,
        notifyKickoff: true,
        notifyLineup: false,
        notifyResult: false,
      );
    }
  }

  Widget _buildTeamLogo(String? logoUrl) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: logoUrl != null && logoUrl.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: logoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Icon(
                  Icons.shield_outlined,
                  color: _textSecondary,
                  size: 20,
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.shield_outlined,
                  color: _textSecondary,
                  size: 20,
                ),
              ),
            )
          : Icon(
              Icons.shield_outlined,
              color: _textSecondary,
              size: 20,
            ),
    );
  }

  void _showMatchOptions(BuildContext context, WidgetRef ref) {
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
                  child: const Icon(Icons.visibility, color: _primary),
                ),
                title: Text(
                  AppLocalizations.of(context)!.recordAttendance,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _addToDiary(context, ref);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications, color: Colors.orange),
                ),
                title: Text(
                  AppLocalizations.of(context)!.notificationSettings,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showNotificationSettings(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addToDiary(BuildContext context, WidgetRef ref) {
    context.push('/diary/add', extra: match);
  }

  void _showNotificationSettings(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _NotificationSettingsDialog(match: match),
    );
  }
}

class _NotificationSettingsDialog extends ConsumerStatefulWidget {
  final Match match;

  const _NotificationSettingsDialog({required this.match});

  @override
  ConsumerState<_NotificationSettingsDialog> createState() => _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState extends ConsumerState<_NotificationSettingsDialog> {
  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  // 로컬 상태로 알림 설정 관리 (기본값: 경기 시작 알림만)
  bool _notifyKickoff = true;
  bool _notifyLineup = false;
  bool _notifyResult = false;
  bool _isInitialized = false;
  bool _hasExistingSetting = false;

  @override
  Widget build(BuildContext context) {
    final settingAsync = ref.watch(matchNotificationProvider(widget.match.id));

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_active, color: _primary, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.matchNotification,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.match.homeTeamName} vs ${widget.match.awayTeamName}',
            style: TextStyle(
              fontSize: 13,
              color: _textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: settingAsync.when(
        data: (setting) {
          // 기존 설정이 있으면 로컬 상태 초기화
          if (!_isInitialized) {
            _isInitialized = true;
            if (setting != null) {
              _hasExistingSetting = true;
              _notifyKickoff = setting.notifyKickoff;
              _notifyLineup = setting.notifyLineup;
              _notifyResult = setting.notifyResult;
            }
          }

          final l10n = AppLocalizations.of(context)!;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNotificationTile(
                icon: Icons.sports_soccer,
                iconColor: Colors.green,
                title: l10n.kickoffNotification,
                subtitle: l10n.kickoffNotificationDesc,
                value: _notifyKickoff,
                onChanged: (value) {
                  setState(() => _notifyKickoff = value);
                },
              ),
              const Divider(height: 1, color: _border),
              _buildNotificationTile(
                icon: Icons.people_outline,
                iconColor: Colors.blue,
                title: l10n.lineupNotification,
                subtitle: l10n.lineupNotificationDesc,
                value: _notifyLineup,
                onChanged: (value) {
                  setState(() => _notifyLineup = value);
                },
              ),
              const Divider(height: 1, color: _border),
              _buildNotificationTile(
                icon: Icons.emoji_events_outlined,
                iconColor: Colors.amber,
                title: l10n.resultNotification,
                subtitle: l10n.resultNotificationDesc,
                value: _notifyResult,
                onChanged: (value) {
                  setState(() => _notifyResult = value);
                },
              ),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => SizedBox(
          height: 100,
          child: Center(
            child: Text(
              ErrorHelper.getLocalizedErrorMessage(context, e),
              style: TextStyle(color: _textSecondary),
            ),
          ),
        ),
      ),
      actions: [
        if (_hasExistingSetting)
          TextButton(
            onPressed: () {
              ref.read(scheduleNotifierProvider.notifier).removeNotification(widget.match.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.notificationRemoved),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              AppLocalizations.of(context)!.notificationOff,
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.cancel,
            style: TextStyle(color: _textSecondary),
          ),
        ),
        TextButton(
          onPressed: _saveNotification,
          style: TextButton.styleFrom(
            foregroundColor: _primary,
          ),
          child: Text(
            AppLocalizations.of(context)!.save,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _primary,
          ),
        ],
      ),
    );
  }

  void _saveNotification() {
    final l10n = AppLocalizations.of(context)!;
    // 알림이 하나라도 켜져 있으면 저장, 아니면 삭제
    if (_notifyKickoff || _notifyLineup || _notifyResult) {
      ref.read(scheduleNotifierProvider.notifier).setNotification(
        matchId: widget.match.id,
        notifyKickoff: _notifyKickoff,
        notifyLineup: _notifyLineup,
        notifyResult: _notifyResult,
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.notificationSet),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // 모든 알림이 꺼져 있으면 기존 설정 삭제
      if (_hasExistingSetting) {
        ref.read(scheduleNotifierProvider.notifier).removeNotification(widget.match.id);
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.notificationRemoved),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class _DatePickerBottomSheet extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateSelected;

  const _DatePickerBottomSheet({
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<_DatePickerBottomSheet> createState() => _DatePickerBottomSheetState();
}

enum _PickerMode { year, month, day }

class _DatePickerBottomSheetState extends State<_DatePickerBottomSheet> {
  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;
  _PickerMode _mode = _PickerMode.day;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
    _selectedDay = widget.initialDate.day;
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  String _getMonthName(BuildContext context, int month) {
    final l10n = AppLocalizations.of(context)!;
    final months = [
      l10n.monthJan, l10n.monthFeb, l10n.monthMar, l10n.monthApr,
      l10n.monthMay, l10n.monthJun, l10n.monthJul, l10n.monthAug,
      l10n.monthSep, l10n.monthOct, l10n.monthNov, l10n.monthDec,
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 드래그 핸들
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // 헤더 (현재 선택된 날짜 표시 + 모드 전환)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _mode = _PickerMode.year;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.yearMonthFormat(_selectedYear, _selectedMonth),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _mode == _PickerMode.day ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: _textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 1,
                color: _border,
                margin: const EdgeInsets.symmetric(vertical: 12),
              ),
              // 그리드 선택 영역
              SizedBox(
                height: 280,
                child: _buildPickerContent(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: _border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: const TextStyle(
                          color: _textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onSelect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.select,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _buildPickerContent() {
    switch (_mode) {
      case _PickerMode.year:
        return _buildYearPicker();
      case _PickerMode.month:
        return _buildMonthPicker();
      case _PickerMode.day:
        return _buildDayPicker();
    }
  }

  Widget _buildYearPicker() {
    final years = List.generate(17, (i) => 2025 - i); // 2025 ~ 2009 (최신순)
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: years.length,
      itemBuilder: (context, index) {
        final year = years[index];
        final isSelected = year == _selectedYear;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedYear = year;
              _mode = _PickerMode.month;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? _primary : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: Text(
              '$year',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : _textPrimary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthPicker() {
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final isSelected = month == _selectedMonth;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedMonth = month;
              // 선택된 일자가 해당 월의 최대 일수보다 크면 조정
              final maxDay = _getDaysInMonth(_selectedYear, _selectedMonth);
              if (_selectedDay > maxDay) _selectedDay = maxDay;
              _mode = _PickerMode.day;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? _primary : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: Text(
              _getMonthName(context, month),
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : _textPrimary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayPicker() {
    final daysInMonth = _getDaysInMonth(_selectedYear, _selectedMonth);
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: daysInMonth,
      itemBuilder: (context, index) {
        final day = index + 1;
        final isSelected = day == _selectedDay;
        final isToday = _selectedYear == DateTime.now().year &&
            _selectedMonth == DateTime.now().month &&
            day == DateTime.now().day;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = day;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? _primary
                  : isToday
                      ? _primary.withValues(alpha: 0.2)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : _textPrimary,
              ),
            ),
          ),
        );
      },
    );
  }

  void _onSelect() {
    final selected = DateTime(_selectedYear, _selectedMonth, _selectedDay);
    Navigator.pop(context);
    widget.onDateSelected(selected);
  }
}
