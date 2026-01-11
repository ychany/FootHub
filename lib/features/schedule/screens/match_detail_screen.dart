import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/api_football_service.dart';
import '../../../core/utils/error_helper.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/football_pitch_view.dart';
import '../../../shared/widgets/team_comparison_widget.dart';
import '../../../shared/widgets/standings_table.dart';
import '../../../shared/widgets/banner_ad_widget.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/schedule_provider.dart';
import '../models/match_comment.dart';
import '../services/match_comment_service.dart';
import '../../profile/providers/timezone_provider.dart';
import '../../community/services/community_service.dart';
import '../../community/providers/community_provider.dart';

// Provider for match detail (API-Football)
// 캐시 유지, 화면 재진입 시 invalidate로 새 데이터 로드
final matchDetailProvider =
    FutureProvider.family<ApiFootballFixture?, String>((ref, fixtureId) async {
  final service = ApiFootballService();
  // 타임존 변경 시 자동 갱신
  ref.watch(timezoneProvider);
  final id = int.tryParse(fixtureId);
  if (id == null) return null;
  return service.getFixtureById(id);
});

// Provider for lineup (API-Football)
final matchLineupProvider =
    FutureProvider.family<List<ApiFootballLineup>, String>((ref, fixtureId) async {
  final service = ApiFootballService();
  final id = int.tryParse(fixtureId);
  if (id == null) return [];
  return service.getFixtureLineups(id);
});

// Provider for stats (API-Football)
final matchStatsProvider =
    FutureProvider.family<List<ApiFootballTeamStats>, String>((ref, fixtureId) async {
  final service = ApiFootballService();
  final id = int.tryParse(fixtureId);
  if (id == null) return [];
  return service.getFixtureStatistics(id);
});

// Provider for timeline (API-Football events)
final matchTimelineProvider =
    FutureProvider.family<List<ApiFootballEvent>, String>((ref, fixtureId) async {
  final service = ApiFootballService();
  final id = int.tryParse(fixtureId);
  if (id == null) return [];
  return service.getFixtureEvents(id);
});

// Provider for head to head (API-Football)
final matchH2HProvider =
    FutureProvider.family<List<ApiFootballFixture>, ({int homeTeamId, int awayTeamId})>((ref, params) async {
  final service = ApiFootballService();
  // 타임존 변경 시 자동 갱신
  ref.watch(timezoneProvider);
  return service.getHeadToHead(params.homeTeamId, params.awayTeamId);
});

// Provider for injuries (API-Football)
final matchInjuriesProvider =
    FutureProvider.family<List<ApiFootballInjury>, String>((ref, fixtureId) async {
  final service = ApiFootballService();
  final id = int.tryParse(fixtureId);
  if (id == null) return [];
  return service.getFixtureInjuries(id);
});

// Provider for match prediction (API-Football)
final matchPredictionProvider =
    FutureProvider.family<ApiFootballPrediction?, String>((ref, fixtureId) async {
  final service = ApiFootballService();
  final id = int.tryParse(fixtureId);
  if (id == null) return null;
  return service.getFixturePrediction(id);
});

// Provider for match odds (API-Football)
final matchOddsProvider =
    FutureProvider.family<List<ApiFootballOdds>, String>((ref, fixtureId) async {
  final service = ApiFootballService();
  final id = int.tryParse(fixtureId);
  if (id == null) return [];
  return service.getFixtureOdds(id);
});

// Provider for live odds (API-Football)
final liveOddsProvider =
    FutureProvider.family<ApiFootballLiveOdds?, String>((ref, fixtureId) async {
  final service = ApiFootballService();
  final id = int.tryParse(fixtureId);
  if (id == null) return null;
  return service.getLiveOdds(id);
});

// Provider for player statistics (API-Football)
final matchPlayerStatsProvider =
    FutureProvider.family<List<FixturePlayerStats>, String>((ref, fixtureId) async {
  final service = ApiFootballService();
  final id = int.tryParse(fixtureId);
  if (id == null) return [];
  return service.getFixturePlayers(id);
});

// Provider for team standings (for comparison)
// 조별 리그(컵대회)도 지원: 모든 그룹에서 팀을 찾음
final teamStandingsProvider =
    FutureProvider.family<ApiFootballStanding?, ({int leagueId, int season, int teamId})>((ref, params) async {
  final service = ApiFootballService();

  // 먼저 조별 리그 형태로 모든 그룹에서 팀 찾기
  final groupedStandings = await service.getStandingsGrouped(params.leagueId, params.season);
  for (final group in groupedStandings.values) {
    for (final standing in group) {
      if (standing.teamId == params.teamId) {
        return standing;
      }
    }
  }

  // 조별 리그에서 못 찾으면 일반 순위에서 찾기
  final standings = await service.getStandings(params.leagueId, params.season);
  for (final standing in standings) {
    if (standing.teamId == params.teamId) {
      return standing;
    }
  }
  return null;
});

// Provider for team recent form (last 5 matches)
final teamRecentFormProvider =
    FutureProvider.family<List<ApiFootballFixture>, int>((ref, teamId) async {
  final service = ApiFootballService();
  ref.watch(timezoneProvider);
  return service.getTeamLastFixtures(teamId, count: 5);
});

// Provider for league top scorers (for player comparison)
final leagueTopScorersProvider =
    FutureProvider.family<List<ApiFootballTopScorer>, ({int leagueId, int season})>((ref, params) async {
  final service = ApiFootballService();
  return service.getTopScorers(params.leagueId, params.season);
});

// Provider for league top assists (for player comparison)
final leagueTopAssistsProvider =
    FutureProvider.family<List<ApiFootballTopScorer>, ({int leagueId, int season})>((ref, params) async {
  final service = ApiFootballService();
  return service.getTopAssists(params.leagueId, params.season);
});

// Provider for team season statistics (for radar chart)
final teamSeasonStatsProvider =
    FutureProvider.family<ApiFootballTeamSeasonStats?, ({int teamId, int leagueId, int season})>((ref, params) async {
  final service = ApiFootballService();
  return service.getTeamStatistics(params.teamId, params.leagueId, params.season);
});

class MatchDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const MatchDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> with WidgetsBindingObserver {
  static const _error = Color(0xFFEF4444);
  static const _textSecondary = Color(0xFF6B7280);
  static const _background = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 화면 진입 시 라이브 경기 데이터 자동 갱신 (기존 캐시 먼저 표시 후 새 데이터 로드)
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
        ref.invalidate(matchDetailProvider(widget.eventId));
        ref.invalidate(matchTimelineProvider(widget.eventId));
        ref.invalidate(matchStatsProvider(widget.eventId));
        ref.invalidate(matchLineupProvider(widget.eventId));
        ref.invalidate(matchPlayerStatsProvider(widget.eventId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(matchDetailProvider(widget.eventId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: matchAsync.when(
          data: (match) {
            if (match == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sports_soccer, size: 64, color: _textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.matchInfoNotFound,
                      style: TextStyle(color: _textSecondary, fontSize: 16),
                    ),
                  ],
                ),
              );
            }
            return _MatchDetailContent(match: match);
          },
          loading: () => const LoadingIndicator(),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: _error),
                const SizedBox(height: 16),
                Text(ErrorHelper.getLocalizedErrorMessage(context, e), style: TextStyle(color: _textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchDetailContent extends ConsumerStatefulWidget {
  final ApiFootballFixture match;

  const _MatchDetailContent({required this.match});

  @override
  ConsumerState<_MatchDetailContent> createState() =>
      _MatchDetailContentState();
}

class _MatchDetailContentState extends ConsumerState<_MatchDetailContent>
    with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _background = Color(0xFFF9FAFB);

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshMatchData() {
    final fixtureId = widget.match.id.toString();
    ref.invalidate(matchDetailProvider(fixtureId));
    ref.invalidate(matchLineupProvider(fixtureId));
    ref.invalidate(matchStatsProvider(fixtureId));
    ref.invalidate(matchTimelineProvider(fixtureId));
    ref.invalidate(matchPredictionProvider(fixtureId));
    ref.invalidate(matchOddsProvider(fixtureId));
    ref.invalidate(matchPlayerStatsProvider(fixtureId));
    ref.invalidate(matchInjuriesProvider(fixtureId));
  }

  void _showMatchInfoModal(BuildContext context, ApiFootballFixture match) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 핸들
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 헤더
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.matchInfo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 컨텐츠
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: _InfoTab(match: match),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;

    return Scaffold(
      backgroundColor: _background,
      bottomNavigationBar: const BottomBannerAdWidget(),
      floatingActionButton: _tabController.index == 5
          ? null
          : SizedBox(
              width: 48,
              height: 48,
              child: FloatingActionButton(
                onPressed: () => _addToDiary(context),
                backgroundColor: _primary,
                elevation: 2,
                shape: const CircleBorder(),
                child: const Icon(Icons.edit_note, color: Colors.white, size: 24),
              ),
            ),
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            _buildHeader(context, match),

            // 탭바
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
                  Tab(text: AppLocalizations.of(context)!.tabComparison),
                  Tab(text: AppLocalizations.of(context)!.tabStats),
                  Tab(text: AppLocalizations.of(context)!.tabLineup),
                  Tab(text: AppLocalizations.of(context)!.tabRanking),
                  Tab(text: AppLocalizations.of(context)!.tabPrediction),
                  Tab(text: AppLocalizations.of(context)!.tabComments),
                ],
              ),
            ),

            // 탭 컨텐츠
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ComparisonTab(match: match),
                  _StatsAndTimelineTab(fixtureId: match.id.toString(), match: match),
                  _LineupTab(fixtureId: match.id.toString(), match: match),
                  _StandingsTab(match: match),
                  _PredictionTab(fixtureId: match.id.toString(), match: match),
                  _CommentsTab(matchId: match.id.toString()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ApiFootballFixture match) {
    final dateTime = match.dateKST;
    final dateStr = DateFormat(AppLocalizations.of(context)!.dateFormatWithTime, Localizations.localeOf(context).toString()).format(dateTime);

    // 골 & 레드카드 이벤트 가져오기
    final eventsAsync = ref.watch(matchTimelineProvider(match.id.toString()));
    final allEvents = eventsAsync.valueOrNull ?? [];
    final goalEvents = allEvents.where((e) => e.type == 'Goal').toList();
    final redCardEvents = allEvents.where((e) => e.type == 'Card' && e.detail == 'Red Card').toList();
    final homeGoalEvents = goalEvents.where((e) => e.teamId == match.homeTeam.id).toList();
    final awayGoalEvents = goalEvents.where((e) => e.teamId == match.awayTeam.id).toList();

    // API-Football에서 자책골은 득점한 팀(수혜 팀)의 이벤트로 기록됨.
    // 따라서 자책골 보정 없이 그냥 팀별 이벤트 수를 세면 됨.
    final actualHomeGoals = homeGoalEvents.length;
    final actualAwayGoals = awayGoalEvents.length;

    // 기존 변수명 호환
    final homeGoals = homeGoalEvents;
    final awayGoals = awayGoalEvents;
    final homeRedCards = redCardEvents.where((e) => e.teamId == match.homeTeam.id).toList();
    final awayRedCards = redCardEvents.where((e) => e.teamId == match.awayTeam.id).toList();

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 상단 바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  color: _textPrimary,
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/league/${match.league.id}'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (match.league.logo != null && match.league.logo!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CachedNetworkImage(
                              imageUrl: match.league.logo!,
                              width: 24,
                              height: 24,
                              placeholder: (context, url) => const SizedBox(width: 24, height: 24),
                              errorWidget: (context, url, error) => const Icon(Icons.sports_soccer, size: 24),
                            ),
                          ),
                        Flexible(
                          child: Text(
                            match.league.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: _textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 22),
                  color: _textSecondary,
                  onPressed: () => _refreshMatchData(),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 22),
                  color: _textSecondary,
                  onPressed: () => _showMatchInfoModal(context, match),
                ),
                _NotificationButton(matchId: match.id.toString(), match: match),
              ],
            ),
          ),

          // 날짜 또는 라이브/종료 상태
          if (match.isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(16),
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
                  const SizedBox(width: 6),
                  Text(
                    match.isHalftime
                        ? 'HT'
                        : match.status.elapsed != null
                            ? (match.status.extra != null && match.status.extra! > 0
                                ? "${match.status.elapsed}+${match.status.extra}'"
                                : "${match.status.elapsed}'")
                            : 'LIVE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else if (match.isFinished)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _textSecondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Builder(
                    builder: (context) => Text(
                      AppLocalizations.of(context)!.matchEnded,
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _primaryLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    dateStr,
                    style: TextStyle(
                      color: _primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                dateStr,
                style: TextStyle(
                  color: _primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // 팀 정보
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // 홈팀
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/team/${match.homeTeam.id}'),
                    child: Column(
                      children: [
                        _buildTeamLogo(match.homeTeam.logo, 56),
                        const SizedBox(height: 8),
                        Text(
                          match.homeTeam.name,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 13,
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

                // 스코어
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: match.isFinished || match.isLive
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: match.isLive
                                ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                                : _primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 스코어 표시 (연장전/승부차기는 이벤트 기반, 그 외는 API 값)
                              Text(
                                (match.status.short == 'AET' || match.status.short == 'PEN') && goalEvents.isNotEmpty
                                    ? '$actualHomeGoals - $actualAwayGoals'
                                    : match.scoreDisplay,
                                style: TextStyle(
                                  color: match.isLive ? const Color(0xFFEF4444) : _primary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              // 승부차기인 경우 PK 스코어 표시
                              if (match.isPenaltyShootout && match.score.penaltyHome != null && match.score.penaltyAway != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '(${match.score.penaltyHome} - ${match.score.penaltyAway})',
                                    style: TextStyle(
                                      color: _textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _border,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'VS',
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),

                // 원정팀
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/team/${match.awayTeam.id}'),
                    child: Column(
                      children: [
                        _buildTeamLogo(match.awayTeam.logo, 56),
                        const SizedBox(height: 8),
                        Text(
                          match.awayTeam.name,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 13,
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

          // 골 득점자 & 레드카드 표시 (경기 중이거나 종료된 경우)
          if ((match.isLive || match.isFinished) && (goalEvents.isNotEmpty || redCardEvents.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 20, right: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 홈팀 이벤트
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...homeGoals.map((goal) => _buildEventRow(goal, isHome: true, isGoal: true)),
                        ...homeRedCards.map((card) => _buildEventRow(card, isHome: true, isGoal: false)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 60), // 스코어 영역 공간
                  // 원정팀 이벤트
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ...awayGoals.map((goal) => _buildEventRow(goal, isHome: false, isGoal: true)),
                        ...awayRedCards.map((card) => _buildEventRow(card, isHome: false, isGoal: false)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEventRow(ApiFootballEvent event, {required bool isHome, required bool isGoal}) {
    final timeStr = event.extra != null
        ? "${event.elapsed}+${event.extra}'"
        : "${event.elapsed}'";
    final isPenalty = event.detail == 'Penalty';
    final isOwnGoal = event.detail == 'Own Goal';

    // 아이콘 및 색상 설정
    IconData icon;
    Color iconColor;
    if (isGoal) {
      icon = Icons.sports_soccer;
      iconColor = isOwnGoal ? Colors.red : _textSecondary;
    } else {
      // 레드카드
      icon = Icons.square_rounded;
      iconColor = Colors.red;
    }

    // 라벨 설정
    String label = event.playerName ?? '';
    if (isGoal) {
      if (isPenalty) label += ' (P)';
      if (isOwnGoal) label += ' (${AppLocalizations.of(context)!.ownGoal})';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: isHome ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isHome) ...[
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 11,
                color: _textSecondary,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Icon(
            icon,
            size: 12,
            color: iconColor,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: _textPrimary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isHome) ...[
            const SizedBox(width: 4),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 11,
                color: _textSecondary,
              ),
            ),
          ],
        ],
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
      ),
      child: logoUrl != null && logoUrl.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: logoUrl,
                fit: BoxFit.cover,
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

  void _addToDiary(BuildContext context) {
    context.push('/attendance/add?matchId=${widget.match.id}');
  }
}

// ============ Info Tab ============
class _InfoTab extends StatelessWidget {
  final ApiFootballFixture match;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _border = Color(0xFFE5E7EB);

  const _InfoTab({required this.match});

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  /// 모달에서도 사용할 수 있도록 내부 컨텐츠를 별도 메서드로 분리
  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.info_outline, color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              Builder(
                builder: (context) => Text(
                  AppLocalizations.of(context)!.matchInfo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Column(
                children: [
                  _InfoRow(label: l10n.leagueLabel, value: match.league.name),
                  _InfoRow(label: l10n.seasonLabel, value: '${match.league.season ?? '-'}'),
                  if (match.league.round != null && match.league.round!.isNotEmpty)
                    _InfoRow(label: l10n.roundLabel, value: match.league.round!),
                  _InfoRow(
                    label: l10n.dateLabel,
                    value: DateFormat(l10n.dateFormatSlash, Localizations.localeOf(context).toString())
                        .format(match.dateKST),
                  ),
                  _InfoRow(
                    label: l10n.timeLabel,
                    value: DateFormat('HH:mm').format(match.dateKST),
                  ),
                  _InfoRow(label: l10n.venueLabel, value: match.venue?.name ?? '-'),
                  _InfoRow(label: l10n.statusLabel, value: _getStatusText(context, match.status.short)),
                  if (match.referee != null)
                    _InfoRow(label: l10n.refereeLabel, value: match.referee!),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _getStatusText(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toUpperCase()) {
      case 'FT':
        return l10n.statusFinished;
      case 'HT':
        return l10n.statusHalftime;
      case '1H':
      case '2H':
        return l10n.statusLive;
      case 'NS':
        return l10n.statusScheduled;
      case 'TBD':
        return l10n.statusTBD;
      case 'PST':
      case 'POSTP':
        return l10n.statusPostponed;
      case 'CANC':
        return l10n.statusCancelled;
      case 'AET':
        return l10n.statusAET;
      case 'PEN':
        return l10n.statusPEN;
      default:
        return status;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

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
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ Prediction Tab ============
class _PredictionTab extends ConsumerWidget {
  final String fixtureId;
  final ApiFootballFixture match;

  static const _primary = Color(0xFF2563EB);
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);
  static const _error = Color(0xFFEF4444);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _PredictionTab({required this.fixtureId, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionAsync = ref.watch(matchPredictionProvider(fixtureId));
    final oddsAsync = ref.watch(matchOddsProvider(fixtureId));
    final isLive = match.status.short == '1H' ||
                   match.status.short == '2H' ||
                   match.status.short == 'HT' ||
                   match.status.short == 'ET' ||
                   match.status.short == 'P' ||
                   match.status.short == 'BT' ||
                   match.status.short == 'LIVE';
    final isFinished = match.status.short == 'FT' ||
                       match.status.short == 'AET' ||
                       match.status.short == 'PEN';
    final liveOddsAsync = isLive ? ref.watch(liveOddsProvider(fixtureId)) : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 라이브 경기일 때 실시간 배당률 섹션 (초기 배당값 포함)
        if (isLive && liveOddsAsync != null) ...[
          liveOddsAsync.when(
            data: (liveOdds) {
              // bookmakers 또는 directOdds가 있으면 실시간 배당률 사용
              final hasLiveOdds = liveOdds != null &&
                  (liveOdds.bookmakers.isNotEmpty || liveOdds.directOdds.isNotEmpty);

              if (!hasLiveOdds) {
                // 실시간 배당이 없으면 일반 배당률을 LIVE 뱃지와 함께 표시
                return oddsAsync.when(
                  data: (oddsList) {
                    if (oddsList.isEmpty) return const SizedBox.shrink();
                    return _buildQuickOddsCard(oddsList, isLive: true);
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                );
              }
              // 초기 배당값도 함께 전달
              return oddsAsync.when(
                data: (oddsList) => _buildLiveOddsCard(context, liveOdds, initialOdds: oddsList),
                loading: () => _buildLiveOddsCard(context, liveOdds),
                error: (_, __) => _buildLiveOddsCard(context, liveOdds),
              );
            },
            loading: () => _buildLoadingCard(),
            error: (e, _) => oddsAsync.when(
              data: (oddsList) {
                if (oddsList.isEmpty) return const SizedBox.shrink();
                return _buildQuickOddsCard(oddsList, isLive: true);
              },
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 경기 전/종료 후: 배당률 요약 카드
        if (!isLive) ...[
          oddsAsync.when(
            data: (oddsList) {
              if (oddsList.isEmpty) return const SizedBox.shrink();
              return _buildQuickOddsCard(oddsList, isFinished: isFinished);
            },
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
        ],

        // 승부 예측 섹션
        predictionAsync.when(
          data: (prediction) {
            if (prediction == null) {
              return Builder(
                builder: (context) => _buildEmptyCard(
                  icon: Icons.analytics_outlined,
                  message: AppLocalizations.of(context)!.noPredictionInfo,
                ),
              );
            }
            return _buildPredictionCard(prediction);
          },
          loading: () => _buildLoadingCard(),
          error: (e, _) => Builder(
            builder: (context) => _buildEmptyCard(
              icon: Icons.error_outline,
              message: AppLocalizations.of(context)!.cannotLoadPrediction,
            ),
          ),
        ),
      ],
    );
  }

  /// 경기 전/종료 후 배당률 요약 카드
  Widget _buildQuickOddsCard(List<ApiFootballOdds> oddsList, {bool isFinished = false, bool isLive = false}) {
    // 첫 번째 북메이커에서 1X2 배당 찾기
    String? homeOdd, drawOdd, awayOdd;
    String? bookmakerName;

    for (final bookmaker in oddsList) {
      for (final bet in bookmaker.bets) {
        if (bet.name.toLowerCase() == 'match winner' ||
            bet.name.toLowerCase() == '1x2' ||
            bet.name.toLowerCase().contains('winner')) {
          bookmakerName = bookmaker.bookmakerName;
          for (final value in bet.values) {
            if (value.value.toLowerCase() == 'home') {
              homeOdd = value.odd;
            } else if (value.value.toLowerCase() == 'draw') {
              drawOdd = value.odd;
            } else if (value.value.toLowerCase() == 'away') {
              awayOdd = value.odd;
            }
          }
          break;
        }
      }
      if (homeOdd != null) break;
    }

    if (homeOdd == null && drawOdd == null && awayOdd == null) {
      return const SizedBox.shrink();
    }

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
          // 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isLive ? _error.withValues(alpha: 0.1) : _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.monetization_on_outlined,
                  color: isLive ? _error : _primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Builder(
                builder: (context) => Text(
                  AppLocalizations.of(context)!.odds,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ),
              if (isLive) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (bookmakerName != null)
                Text(
                  bookmakerName,
                  style: TextStyle(
                    fontSize: 11,
                    color: _textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 배당률 표시
          Row(
            children: [
              // 홈팀 배당
              Expanded(
                child: _buildQuickOddBox(
                  label: match.homeTeam.name,
                  odd: homeOdd ?? '-',
                  color: _primary,
                ),
              ),
              const SizedBox(width: 8),
              // 무승부 배당
              Expanded(
                child: Builder(
                  builder: (context) => _buildQuickOddBox(
                    label: AppLocalizations.of(context)!.drawLabel,
                    odd: drawOdd ?? '-',
                    color: _textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 원정팀 배당
              Expanded(
                child: _buildQuickOddBox(
                  label: match.awayTeam.name,
                  odd: awayOdd ?? '-',
                  color: _success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOddBox({
    required String label,
    required String odd,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: _textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            odd,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveOddsCard(BuildContext context, ApiFootballLiveOdds liveOdds, {List<ApiFootballOdds>? initialOdds}) {
    // 승무패 배당 찾기
    final matchWinnerBet = liveOdds.findMatchWinnerBet();

    if (matchWinnerBet == null) {
      return const SizedBox.shrink();
    }

    String? homeOdd, drawOdd, awayOdd;
    for (final value in matchWinnerBet.values) {
      if (value.value.toLowerCase() == 'home' || value.value == '1') {
        homeOdd = value.odd;
      } else if (value.value.toLowerCase() == 'draw' || value.value == 'x' || value.value == 'X') {
        drawOdd = value.odd;
      } else if (value.value.toLowerCase() == 'away' || value.value == '2') {
        awayOdd = value.odd;
      }
    }

    // 초기 배당값 추출
    String? initHomeOdd, initDrawOdd, initAwayOdd;
    if (initialOdds != null && initialOdds.isNotEmpty) {
      for (final bookmaker in initialOdds) {
        for (final bet in bookmaker.bets) {
          if (bet.name.toLowerCase() == 'match winner' ||
              bet.name.toLowerCase() == '1x2' ||
              bet.name.toLowerCase().contains('winner')) {
            for (final value in bet.values) {
              if (value.value.toLowerCase() == 'home') {
                initHomeOdd = value.odd;
              } else if (value.value.toLowerCase() == 'draw') {
                initDrawOdd = value.odd;
              } else if (value.value.toLowerCase() == 'away') {
                initAwayOdd = value.odd;
              }
            }
            break;
          }
        }
        if (initHomeOdd != null) break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _error.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: _error.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 - 라이브 배지
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Builder(
                builder: (context) => Text(
                  AppLocalizations.of(context)!.liveOdds,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ),
              const Spacer(),
              // 전체 배팅 종류 버튼
              GestureDetector(
                onTap: () => _showAllBetsModal(context, liveOdds),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.list_alt, size: 12, color: _primary),
                      const SizedBox(width: 4),
                      Builder(
                        builder: (context) => Text(
                          AppLocalizations.of(context)!.allCategory,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('HH:mm:ss').format(liveOdds.updateAt.toLocal()),
                style: TextStyle(
                  fontSize: 11,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 배당률 표시
          Row(
            children: [
              // 홈팀 배당
              Expanded(
                child: _buildLiveOddBox(
                  label: match.homeTeam.name,
                  odd: homeOdd ?? '-',
                  initialOdd: initHomeOdd,
                  color: _primary,
                ),
              ),
              const SizedBox(width: 8),
              // 무승부 배당
              Expanded(
                child: Builder(
                  builder: (context) => _buildLiveOddBox(
                    label: AppLocalizations.of(context)!.drawLabel,
                    odd: drawOdd ?? '-',
                    initialOdd: initDrawOdd,
                    color: _textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 원정팀 배당
              Expanded(
                child: _buildLiveOddBox(
                  label: match.awayTeam.name,
                  odd: awayOdd ?? '-',
                  initialOdd: initAwayOdd,
                  color: _success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 전체 배팅 종류 모달 표시
  void _showAllBetsModal(BuildContext context, ApiFootballLiveOdds liveOdds) {
    // 모든 배팅 종류 수집
    List<ApiFootballLiveOddsBet> allBets = [];

    if (liveOdds.directOdds.isNotEmpty) {
      allBets = liveOdds.directOdds;
    } else if (liveOdds.bookmakers.isNotEmpty) {
      allBets = liveOdds.bookmakers.first.bets;
    }

    if (allBets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noBettingInfo)),
      );
      return;
    }

    // 카테고리별로 그룹화
    final groupedBets = _groupBetsByCategory(allBets);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AllBetsModalContent(
        allBets: allBets,
        groupedBets: groupedBets,
        getCategoryInfo: _getCategoryInfo,
        getBetLocalizedName: _getBetLocalizedName,
        getCategoryLocalizedName: _getCategoryLocalizedName,
      ),
    );
  }

  /// 배팅을 카테고리별로 그룹화
  Map<String, List<ApiFootballLiveOddsBet>> _groupBetsByCategory(List<ApiFootballLiveOddsBet> bets) {
    final Map<String, List<ApiFootballLiveOddsBet>> grouped = {};

    for (final bet in bets) {
      final category = _getBetCategory(bet.name);
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(bet);
    }

    // 카테고리 정렬 (주요 → 골 → 핸디캡 → 기타)
    final orderedCategories = ['main', 'goal', 'handicap', 'half', 'team', 'other'];
    final sortedGrouped = <String, List<ApiFootballLiveOddsBet>>{};

    for (final cat in orderedCategories) {
      if (grouped.containsKey(cat)) {
        sortedGrouped[cat] = grouped[cat]!;
      }
    }
    // 정의되지 않은 카테고리 추가
    for (final entry in grouped.entries) {
      if (!sortedGrouped.containsKey(entry.key)) {
        sortedGrouped[entry.key] = entry.value;
      }
    }

    return sortedGrouped;
  }

  /// 배팅 이름으로 카테고리 결정 (내부 키 반환)
  String _getBetCategory(String name) {
    final nameLower = name.toLowerCase();

    // 주요 배팅
    if (nameLower.contains('winner') ||
        nameLower.contains('1x2') ||
        nameLower == 'home/away' ||
        nameLower.contains('double chance')) {
      return 'main';
    }

    // 골 관련
    if (nameLower.contains('goal') ||
        nameLower.contains('score') ||
        nameLower.contains('over') ||
        nameLower.contains('under') ||
        nameLower.contains('total') ||
        nameLower.contains('btts') ||
        nameLower.contains('both teams')) {
      return 'goal';
    }

    // 핸디캡
    if (nameLower.contains('handicap') ||
        nameLower.contains('spread')) {
      return 'handicap';
    }

    // 전후반
    if (nameLower.contains('half') ||
        nameLower.contains('1st') ||
        nameLower.contains('2nd')) {
      return 'half';
    }

    // 팀 관련
    if (nameLower.contains('home') ||
        nameLower.contains('away') ||
        nameLower.contains('team') ||
        nameLower.contains('clean sheet') ||
        nameLower.contains('win to nil')) {
      return 'team';
    }

    return 'other';
  }

  /// 카테고리 키를 로컬라이즈된 이름으로 변환
  String _getCategoryLocalizedName(BuildContext context, String categoryKey) {
    final l10n = AppLocalizations.of(context)!;
    switch (categoryKey) {
      case 'main': return l10n.betCategoryMain;
      case 'goal': return l10n.betCategoryGoal;
      case 'handicap': return l10n.betCategoryHandicap;
      case 'half': return l10n.betCategoryHalf;
      case 'team': return l10n.betCategoryTeam;
      default: return l10n.betCategoryOther;
    }
  }

  /// 카테고리 정보 (아이콘, 색상)
  Map<String, dynamic> _getCategoryInfo(String category) {
    switch (category) {
      case 'main':
        return {'icon': Icons.star, 'color': const Color(0xFF2563EB)};
      case 'goal':
        return {'icon': Icons.sports_soccer, 'color': const Color(0xFF10B981)};
      case 'handicap':
        return {'icon': Icons.balance, 'color': const Color(0xFF8B5CF6)};
      case 'half':
        return {'icon': Icons.timelapse, 'color': const Color(0xFFF59E0B)};
      case 'team':
        return {'icon': Icons.shield_outlined, 'color': const Color(0xFF06B6D4)};
      default:
        return {'icon': Icons.more_horiz, 'color': const Color(0xFF6B7280)};
    }
  }

  /// 배팅 이름 로컬라이제이션
  String _getBetLocalizedName(BuildContext context, String name) {
    final l10n = AppLocalizations.of(context)!;
    final Map<String, String> translations = {
      'Match Winner': l10n.betMatchWinner,
      '1X2': l10n.betMatchWinner,
      'Home/Away': l10n.betHomeAway,
      'Double Chance': l10n.betDoubleChance,
      'Both Teams Score': l10n.betBothTeamsScore,
      'Exact Score': l10n.betExactScore,
      'Goals Over/Under': l10n.betGoalsOverUnder,
      'Over/Under': l10n.betOverUnder,
      'Asian Handicap': l10n.betAsianHandicap,
      'Handicap': l10n.betHandicap,
      'First Half Winner': l10n.betFirstHalfWinner,
      'Second Half Winner': l10n.betSecondHalfWinner,
      'Half Time / Full Time': l10n.betHalfTimeFullTime,
      'Odd/Even': l10n.betOddEven,
      'Total - Home': l10n.betTotalHome,
      'Total - Away': l10n.betTotalAway,
      'Clean Sheet - Home': l10n.betCleanSheetHome,
      'Clean Sheet - Away': l10n.betCleanSheetAway,
      'Win to Nil - Home': l10n.betWinToNilHome,
      'Win to Nil - Away': l10n.betWinToNilAway,
      'Corners Over Under': l10n.betCornersOverUnder,
      'Cards Over Under': l10n.betCardsOverUnder,
      'First Team To Score': l10n.betFirstTeamToScore,
      'Last Team To Score': l10n.betLastTeamToScore,
      'Highest Scoring Half': l10n.betHighestScoringHalf,
      'To Score In Both Halves': l10n.betToScoreInBothHalves,
      'Home Win Both Halves': l10n.betHomeWinBothHalves,
      'Away Win Both Halves': l10n.betAwayWinBothHalves,
    };

    // 정확히 일치하는 경우
    if (translations.containsKey(name)) {
      return translations[name]!;
    }

    // 부분 일치 검색
    for (final entry in translations.entries) {
      if (name.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    return name;
  }

  Widget _buildLiveOddBox({
    required String label,
    required String odd,
    String? initialOdd,
    required Color color,
  }) {
    // 배당 변화 계산
    double? currentOddValue = double.tryParse(odd);
    double? initialOddValue = initialOdd != null ? double.tryParse(initialOdd) : null;
    int? direction; // 1: 상승, -1: 하락, 0: 동일
    if (currentOddValue != null && initialOddValue != null) {
      if (currentOddValue > initialOddValue) {
        direction = 1;
      } else if (currentOddValue < initialOddValue) {
        direction = -1;
      } else {
        direction = 0;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: _textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                odd,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              if (direction != null && direction != 0) ...[
                const SizedBox(width: 4),
                Icon(
                  direction == 1 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: direction == 1 ? _success : _error,
                  size: 20,
                ),
              ],
            ],
          ),
          // 초기 배당값 표시
          if (initialOdd != null) ...[
            const SizedBox(height: 4),
            Builder(
              builder: (context) => Text(
                AppLocalizations.of(context)!.initialOdd(initialOdd),
                style: TextStyle(
                  fontSize: 10,
                  color: _textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyCard({required IconData icon, required String message}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: _textSecondary),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: _textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(ApiFootballPrediction prediction) {
    final homePercent = prediction.percent.homePercent;
    final drawPercent = prediction.percent.drawPercent;
    final awayPercent = prediction.percent.awayPercent;

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
          // 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.analytics_outlined, color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              Builder(
                builder: (context) => Text(
                  AppLocalizations.of(context)!.matchPrediction,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 예측 결과
          if (prediction.winner != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _success.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.emoji_events, color: _success, size: 32),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) => Text(
                      AppLocalizations.of(context)!.expectedWinner,
                      style: TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    prediction.winner!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _success,
                    ),
                  ),
                  if (prediction.winnerComment != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      prediction.winnerComment!,
                      style: TextStyle(
                        fontSize: 11,
                        color: _textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 승률 바
          Row(
            children: [
              // 홈팀
              Expanded(
                child: Column(
                  children: [
                    Text(
                      match.homeTeam.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${homePercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
              ),

              // 무승부
              Expanded(
                child: Column(
                  children: [
                    Builder(
                      builder: (context) => Text(
                        AppLocalizations.of(context)!.drawPrediction,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${drawPercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _warning,
                      ),
                    ),
                  ],
                ),
              ),

              // 원정팀
              Expanded(
                child: Column(
                  children: [
                    Text(
                      match.awayTeam.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${awayPercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 승률 프로그레스 바
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(
                  flex: homePercent.round().clamp(1, 100),
                  child: Container(height: 8, color: _primary),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: drawPercent.round().clamp(1, 100),
                  child: Container(height: 8, color: _warning),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: awayPercent.round().clamp(1, 100),
                  child: Container(height: 8, color: _error),
                ),
              ],
            ),
          ),

          // 비교 분석
          if (prediction.comparison != null) ...[
            const Divider(height: 32),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.detailedAnalysis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (prediction.comparison!.form != null)
                      _buildComparisonRow(l10n.comparisonForm, prediction.comparison!.form!),
                    if (prediction.comparison!.att != null)
                      _buildComparisonRow(l10n.comparisonAttack, prediction.comparison!.att!),
                    if (prediction.comparison!.def != null)
                      _buildComparisonRow(l10n.comparisonDefense, prediction.comparison!.def!),
                    if (prediction.comparison!.h2h != null)
                      _buildComparisonRow(l10n.comparisonH2H, prediction.comparison!.h2h!),
                    if (prediction.comparison!.goals != null)
                      _buildComparisonRow(l10n.comparisonGoals, prediction.comparison!.goals!),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, ApiFootballComparisonItem item) {
    final homePercent = item.homePercent;
    final awayPercent = item.awayPercent;
    final total = homePercent + awayPercent;
    final homeRatio = total > 0 ? homePercent / total : 0.5;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${homePercent.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _primary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: _textSecondary,
                ),
              ),
              Text(
                '${awayPercent.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _error,
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
                    color: _primary,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(3)),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: ((1 - homeRatio) * 100).round().clamp(1, 99),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: _error,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
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

// ============ Lineup Tab ============
class _LineupTab extends ConsumerStatefulWidget {
  final String fixtureId;
  final ApiFootballFixture match;

  const _LineupTab({required this.fixtureId, required this.match});

  @override
  ConsumerState<_LineupTab> createState() => _LineupTabState();
}

class _LineupTabState extends ConsumerState<_LineupTab> {
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final lineupAsync = ref.watch(matchLineupProvider(widget.fixtureId));
    final injuriesAsync = ref.watch(matchInjuriesProvider(widget.fixtureId));
    final playerStatsAsync = ref.watch(matchPlayerStatsProvider(widget.fixtureId));
    final eventsAsync = ref.watch(matchTimelineProvider(widget.fixtureId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 라인업 섹션
          lineupAsync.when(
            data: (lineups) {
              if (lineups.isEmpty) {
                return _buildEmptyLineup();
              }

              final homeLineup = lineups.isNotEmpty ? lineups.first : null;
              final awayLineup = lineups.length > 1 ? lineups[1] : null;

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

              return FootballPitchView(
                homeLineup: homeLineup,
                awayLineup: awayLineup,
                homeTeam: widget.match.homeTeam,
                awayTeam: widget.match.awayTeam,
                homePlayerStats: homePlayerStats,
                awayPlayerStats: awayPlayerStats,
                substitutions: substitutions,
                playerEvents: playerEvents,
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Builder(
              builder: (context) => Container(
                padding: const EdgeInsets.all(16),
                child: Text(AppLocalizations.of(context)!.lineupLoadError(ErrorHelper.getLocalizedErrorMessage(context, e)), style: TextStyle(color: _textSecondary)),
              ),
            ),
          ),

          // 결장 선수 섹션
          const SizedBox(height: 16),
          _InjuriesSection(
            injuriesAsync: injuriesAsync,
            homeTeamId: widget.match.homeTeam.id,
            homeTeamName: widget.match.homeTeam.name,
            awayTeamId: widget.match.awayTeam.id,
            awayTeamName: widget.match.awayTeam.name,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLineup() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Center(
        child: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Column(
              children: [
                Icon(Icons.people_outline, size: 40, color: _textSecondary),
                const SizedBox(height: 12),
                Text(
                  l10n.noLineupInfo,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.lineupUpdateBeforeMatch,
                  style: TextStyle(
                    color: _textSecondary.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// 결장 선수 섹션 위젯
class _InjuriesSection extends StatelessWidget {
  final AsyncValue<List<ApiFootballInjury>> injuriesAsync;
  final int homeTeamId;
  final String homeTeamName;
  final int awayTeamId;
  final String awayTeamName;

  static const _error = Color(0xFFEF4444);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _InjuriesSection({
    required this.injuriesAsync,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.awayTeamId,
    required this.awayTeamName,
  });

  @override
  Widget build(BuildContext context) {
    return injuriesAsync.when(
      data: (injuries) {
        if (injuries.isEmpty) {
          return const SizedBox.shrink(); // 결장 선수 없으면 표시 안함
        }

        // 홈/어웨이 팀별로 분류
        final homeInjuries = injuries.where((i) => i.teamId == homeTeamId).toList();
        final awayInjuries = injuries.where((i) => i.teamId == awayTeamId).toList();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _error.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _error.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 섹션 헤더
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.personal_injury, size: 18, color: _error),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(context)!.missingPlayers,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.nPlayers(injuries.length),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 홈팀 결장 선수
              if (homeInjuries.isNotEmpty) ...[
                _TeamInjuriesList(
                  teamName: homeTeamName,
                  injuries: homeInjuries,
                  isHome: true,
                ),
              ],

              // 어웨이팀 결장 선수
              if (awayInjuries.isNotEmpty) ...[
                if (homeInjuries.isNotEmpty) const SizedBox(height: 12),
                _TeamInjuriesList(
                  teamName: awayTeamName,
                  injuries: awayInjuries,
                  isHome: false,
                ),
              ],
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: _textSecondary),
            ),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.checkingMissingInfo, style: TextStyle(color: _textSecondary, fontSize: 13)),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(), // 오류시 표시 안함
    );
  }
}

// 팀별 결장 선수 목록
class _TeamInjuriesList extends StatelessWidget {
  final String teamName;
  final List<ApiFootballInjury> injuries;
  final bool isHome;

  static const _primary = Color(0xFF2563EB);
  static const _secondary = Color(0xFF8B5CF6);
  static const _error = Color(0xFFEF4444);
  static const _warning = Color(0xFFF59E0B);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _TeamInjuriesList({
    required this.teamName,
    required this.injuries,
    required this.isHome,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 팀 이름
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: isHome ? _primary : _secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              teamName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 선수 목록
        ...injuries.map((injury) => Padding(
          padding: const EdgeInsets.only(left: 11, bottom: 6),
          child: InkWell(
            onTap: () => context.push('/player/${injury.playerId}'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                children: [
                  // 선수 사진
                  if (injury.playerPhoto != null)
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: injury.playerPhoto!,
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 28,
                          height: 28,
                          color: Colors.grey.shade200,
                          child: Icon(Icons.person, size: 16, color: _textSecondary),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 28,
                          height: 28,
                          color: Colors.grey.shade200,
                          child: Icon(Icons.person, size: 16, color: _textSecondary),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person, size: 16, color: _textSecondary),
                    ),
                  const SizedBox(width: 10),
                  // 선수 이름
                  Expanded(
                    child: Text(
                      injury.playerName,
                      style: TextStyle(
                        fontSize: 13,
                        color: _textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 상태 배지
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getReasonColor(injury).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getReasonText(context, injury),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _getReasonColor(injury),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )),
      ],
    );
  }

  Color _getReasonColor(ApiFootballInjury injury) {
    if (injury.isSuspended) return _error;
    if (injury.isInjury) return _warning;
    if (injury.isDoubtful) return Colors.orange;
    return _textSecondary;
  }

  String _getReasonText(BuildContext context, ApiFootballInjury injury) {
    final l10n = AppLocalizations.of(context)!;
    final reason = injury.reason ?? '';
    if (injury.isSuspended) return l10n.injurySuspension;
    if (reason.toLowerCase().contains('knee')) return l10n.injuryKnee;
    if (reason.toLowerCase().contains('hamstring')) return l10n.injuryHamstring;
    if (reason.toLowerCase().contains('ankle')) return l10n.injuryAnkle;
    if (reason.toLowerCase().contains('muscle')) return l10n.injuryMuscle;
    if (reason.toLowerCase().contains('back')) return l10n.injuryBack;
    if (reason.toLowerCase().contains('illness')) return l10n.injuryIllness;
    if (injury.isInjury) return l10n.injuryGeneral;
    if (injury.isDoubtful) return l10n.injuryDoubtful;
    return l10n.injuryOut;
  }
}

// ============ Stats Tab ============
/// 기록 + 중계 통합 탭
class _StatsAndTimelineTab extends ConsumerWidget {
  final String fixtureId;
  final ApiFootballFixture match;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _StatsAndTimelineTab({required this.fixtureId, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(matchStatsProvider(fixtureId));
    final timelineAsync = ref.watch(matchTimelineProvider(fixtureId));

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
          error: (e, _) => _buildErrorWidget(l10n.cannotLoadStats),
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
          error: (e, _) => _buildErrorWidget(l10n.cannotLoadTimeline),
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

    final homeStats = statsList.isNotEmpty ? statsList.first : null;
    final awayStats = statsList.length > 1 ? statsList[1] : null;

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
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    match.homeTeam.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 60),
                Expanded(
                  child: Text(
                    match.awayTeam.name,
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
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Stats rows
          if (homeStats?.possession != null)
            _StatBar(
              label: l10n.possessionLabel,
              homeValue: _parsePercent(homeStats?.possession),
              awayValue: _parsePercent(awayStats?.possession),
              isPercentage: true,
            ),
          if (homeStats?.shotsTotal != null)
            _StatBar(
              label: l10n.shotsLabel,
              homeValue: homeStats?.shotsTotal ?? 0,
              awayValue: awayStats?.shotsTotal ?? 0,
            ),
          if (homeStats?.shotsOnTarget != null)
            _StatBar(
              label: l10n.shotsOnLabel,
              homeValue: homeStats?.shotsOnTarget ?? 0,
              awayValue: awayStats?.shotsOnTarget ?? 0,
            ),
          if (homeStats?.corners != null)
            _StatBar(
              label: l10n.cornersLabel,
              homeValue: homeStats?.corners ?? 0,
              awayValue: awayStats?.corners ?? 0,
            ),
          if (homeStats?.fouls != null)
            _StatBar(
              label: l10n.foulsLabel,
              homeValue: homeStats?.fouls ?? 0,
              awayValue: awayStats?.fouls ?? 0,
            ),
          if (homeStats?.offsides != null)
            _StatBar(
              label: l10n.offsidesLabel,
              homeValue: homeStats?.offsides ?? 0,
              awayValue: awayStats?.offsides ?? 0,
            ),
          if (homeStats?.yellowCards != null)
            _StatBar(
              label: l10n.warningsLabel,
              homeValue: homeStats?.yellowCards ?? 0,
              awayValue: awayStats?.yellowCards ?? 0,
              color: Colors.amber,
            ),
          if (homeStats?.redCards != null)
            _StatBar(
              label: l10n.sendOffsLabel,
              homeValue: homeStats?.redCards ?? 0,
              awayValue: awayStats?.redCards ?? 0,
              color: Colors.red,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineContent(BuildContext context, List<ApiFootballEvent> events) {
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
            AppLocalizations.of(context)!.noTimelineInfo,
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
          final isHome = event.teamId == match.homeTeam.id;
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

  int _parsePercent(String? value) {
    if (value == null) return 0;
    return int.tryParse(value.replaceAll('%', '')) ?? 0;
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
                  fontSize: 12,
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
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                flex: (homeRatio * 100).round().clamp(1, 99),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color ?? _primary,
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
                    color: (color ?? _primary).withValues(alpha: 0.3),
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

// ============ Notification Button ============
class _NotificationButton extends ConsumerWidget {
  final String matchId;
  final ApiFootballFixture match;

  static const _primary = Color(0xFF2563EB);
  static const _textSecondary = Color(0xFF6B7280);

  const _NotificationButton({required this.matchId, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasNotificationAsync = ref.watch(hasNotificationProvider(matchId));

    return hasNotificationAsync.when(
      data: (hasNotification) => IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
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
            size: 20,
            color: hasNotification ? _primary : _textSecondary,
          ),
        ),
        onPressed: () => _showNotificationSettings(context, ref, hasNotification),
      ),
      loading: () => const SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => IconButton(
        icon: Icon(
          Icons.notifications_none_outlined,
          size: 20,
          color: _textSecondary,
        ),
        onPressed: () => _showNotificationSettings(context, ref, false),
      ),
    );
  }

  void _showNotificationSettings(BuildContext context, WidgetRef ref, bool hasNotification) {
    showDialog(
      context: context,
      builder: (context) => _MatchNotificationDialog(
        matchId: matchId,
        match: match,
      ),
    );
  }
}

// ============ Match Notification Dialog ============
class _MatchNotificationDialog extends ConsumerStatefulWidget {
  final String matchId;
  final ApiFootballFixture match;

  const _MatchNotificationDialog({required this.matchId, required this.match});

  @override
  ConsumerState<_MatchNotificationDialog> createState() => _MatchNotificationDialogState();
}

class _MatchNotificationDialogState extends ConsumerState<_MatchNotificationDialog> {
  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  bool _notifyKickoff = true;
  bool _notifyLineup = false;
  bool _notifyResult = false;
  bool _isInitialized = false;
  bool _hasExistingSetting = false;

  @override
  Widget build(BuildContext context) {
    final settingAsync = ref.watch(matchNotificationProvider(widget.matchId));

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
            AppLocalizations.of(context)!.matchNotificationSettings,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.match.homeTeam.name} vs ${widget.match.awayTeam.name}',
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
            child: Text(ErrorHelper.getLocalizedErrorMessage(context, e), style: TextStyle(color: _textSecondary)),
          ),
        ),
      ),
      actions: [
        if (_hasExistingSetting)
          TextButton(
            onPressed: () {
              ref.read(scheduleNotifierProvider.notifier).removeNotification(widget.matchId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.notificationRemoved),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              AppLocalizations.of(context)!.turnOffNotification,
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.cancelLabel,
            style: TextStyle(color: _textSecondary),
          ),
        ),
        TextButton(
          onPressed: _saveNotification,
          style: TextButton.styleFrom(
            foregroundColor: _primary,
          ),
          child: Text(
            AppLocalizations.of(context)!.saveLabel,
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
    if (_notifyKickoff || _notifyLineup || _notifyResult) {
      ref.read(scheduleNotifierProvider.notifier).setNotification(
        matchId: widget.matchId,
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
      if (_hasExistingSetting) {
        ref.read(scheduleNotifierProvider.notifier).removeNotification(widget.matchId);
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

// ============ Comparison Tab ============
class _ComparisonTab extends StatelessWidget {
  final ApiFootballFixture match;

  const _ComparisonTab({required this.match});

  @override
  Widget build(BuildContext context) {
    final leagueId = match.league.id;
    final season = match.league.season ?? DateTime.now().year;

    return TeamComparisonTab(
      homeTeamId: match.homeTeam.id,
      awayTeamId: match.awayTeam.id,
      homeTeamName: match.homeTeam.name,
      awayTeamName: match.awayTeam.name,
      homeTeamLogo: match.homeTeam.logo,
      awayTeamLogo: match.awayTeam.logo,
      leagueId: leagueId,
      season: season,
    );
  }
}

// ============ Standings Tab ============
class _StandingsTab extends StatelessWidget {
  final ApiFootballFixture match;

  const _StandingsTab({required this.match});

  @override
  Widget build(BuildContext context) {
    final season = match.league.season ?? DateTime.now().year;

    return StandingsTab(
      leagueId: match.league.id,
      season: season,
      homeTeamId: match.homeTeam.id,
      awayTeamId: match.awayTeam.id,
      leagueName: match.league.name,
      leagueLogo: match.league.logo,
    );
  }
}

// ============ Comments Tab ============
class _CommentsTab extends ConsumerStatefulWidget {
  final String matchId;

  const _CommentsTab({required this.matchId});

  @override
  ConsumerState<_CommentsTab> createState() => _CommentsTabState();
}

class _CommentsTabState extends ConsumerState<_CommentsTab> {
  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  final MatchCommentService _commentService = MatchCommentService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;
  List<String> _blockedUserIds = [];

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    try {
      final service = CommunityService();
      final blockedIds = await service.getBlockedUserIds();
      if (mounted) {
        setState(() {
          _blockedUserIds = blockedIds;
        });
      }
    } catch (_) {
      // 무시
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await _commentService.createComment(
        matchId: widget.matchId,
        content: content,
      );
      _commentController.clear();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.commentWriteFailed(ErrorHelper.getLocalizedErrorMessage(context, e)))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _deleteComment(MatchComment comment) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteComment),
        content: Text(l10n.deleteCommentConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _commentService.deleteComment(comment.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.commentDeleted)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.deleteFailed(ErrorHelper.getLocalizedErrorMessage(context, e)))),
          );
        }
      }
    }
  }

  void _showReportDialog(MatchComment comment) {
    final l10n = AppLocalizations.of(context)!;
    String? selectedReason;
    final additionalController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.report_outlined, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    l10n.reportComment,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                l10n.reportReason,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              ...[
                ('spam', l10n.reportReasonSpam),
                ('harassment', l10n.reportReasonHarassment),
                ('inappropriate', l10n.reportReasonInappropriate),
                ('false_info', l10n.reportReasonFalseInfo),
                ('other', l10n.reportReasonOther),
              ].map((item) => RadioListTile<String>(
                value: item.$1,
                groupValue: selectedReason,
                onChanged: (value) => setModalState(() => selectedReason = value),
                title: Text(item.$2),
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
              const SizedBox(height: 12),
              TextField(
                controller: additionalController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.reportAdditionalInfo,
                  hintText: l10n.reportAdditionalInfoHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: selectedReason == null
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await _submitReport(
                            comment: comment,
                            reason: selectedReason!,
                            additionalInfo: additionalController.text.trim(),
                          );
                        },
                  child: Text(l10n.reportSubmit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitReport({
    required MatchComment comment,
    required String reason,
    String? additionalInfo,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final service = CommunityService();
      await service.reportContent(
        contentType: 'match_comment',
        contentId: comment.id,
        reason: reason,
        additionalInfo: additionalInfo,
        reportedUserId: comment.authorId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reportSubmitted)),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().contains('ALREADY_REPORTED')
            ? l10n.reportAlreadySubmitted
            : l10n.reportFailed(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _blockUser(MatchComment comment) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.blockUser),
        content: Text(l10n.blockUserConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.blockUser),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // blockedUsersNotifierProvider를 통해 차단 (관리 페이지 및 커뮤니티와 연동)
        await ref
            .read(blockedUsersNotifierProvider.notifier)
            .block(comment.authorId, comment.authorName);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.userBlocked)),
          );
          // 차단 목록 새로고침
          await _loadBlockedUsers();
          // 커뮤니티 게시글 목록도 새로고침
          ref.read(postsNotifierProvider.notifier).refresh();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 헤더
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: _border)),
          ),
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline, size: 18, color: _primary),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.liveComments,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.commentsRefreshed),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(AppLocalizations.of(context)!.refreshButton),
                style: TextButton.styleFrom(
                  foregroundColor: _textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ),

        // 댓글 목록
        Expanded(
          child: StreamBuilder<List<MatchComment>>(
            stream: _commentService.getCommentsStream(widget.matchId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingIndicator();
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: _textSecondary),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.cannotLoadComments,
                        style: TextStyle(color: _textSecondary),
                      ),
                    ],
                  ),
                );
              }

              final allComments = snapshot.data ?? [];
              final comments = allComments
                  .where((c) => !_blockedUserIds.contains(c.authorId))
                  .toList();

              if (comments.isEmpty) {
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
                        child: Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: _textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.noCommentsYet,
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.beFirstToComment,
                        style: TextStyle(
                          color: _textSecondary.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  final isOwner = _currentUserId == comment.authorId;
                  return _CommentItem(
                    comment: comment,
                    onDelete: () => _deleteComment(comment),
                    onReport: () => _showReportDialog(comment),
                    onBlock: () => _blockUser(comment),
                    isOwner: isOwner,
                  );
                },
              );
            },
          ),
        ),

        // 댓글 입력창
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: _border)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.commentInputHint,
                    hintStyle: TextStyle(color: _textSecondary, fontSize: 14),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitComment(),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: _primary,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: _isSubmitting ? null : _submitComment,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentItem extends StatelessWidget {
  final MatchComment comment;
  final VoidCallback onDelete;
  final VoidCallback onReport;
  final VoidCallback onBlock;
  final bool isOwner;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _CommentItem({
    required this.comment,
    required this.onDelete,
    required this.onReport,
    required this.onBlock,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final timeAgo = _getTimeAgo(comment.createdAt);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: comment.authorProfileUrl != null
                ? NetworkImage(comment.authorProfileUrl!)
                : null,
            child: comment.authorProfileUrl == null
                ? Icon(Icons.person, size: 20, color: _textSecondary)
                : null,
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 16, color: _textSecondary),
            padding: EdgeInsets.zero,
            itemBuilder: (menuContext) {
              final l10n = AppLocalizations.of(menuContext)!;
              if (isOwner) {
                return [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(l10n.deleteAction, style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ];
              } else {
                return [
                  PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        const Icon(Icons.report_outlined, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(l10n.report),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        const Icon(Icons.block, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(l10n.blockUser, style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ];
              }
            },
            onSelected: (value) {
              if (value == 'delete') {
                onDelete();
              } else if (value == 'report') {
                onReport();
              } else if (value == 'block') {
                onBlock();
              }
            },
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now'; // Used in comment item, context not available here
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('MM/dd').format(dateTime);
    }
  }
}

/// 전체 배팅 모달 컨텐츠 (탭 지원)
class _AllBetsModalContent extends StatefulWidget {
  final List<ApiFootballLiveOddsBet> allBets;
  final Map<String, List<ApiFootballLiveOddsBet>> groupedBets;
  final Map<String, dynamic> Function(String) getCategoryInfo;
  final String Function(BuildContext, String) getBetLocalizedName;
  final String Function(BuildContext, String) getCategoryLocalizedName;

  const _AllBetsModalContent({
    required this.allBets,
    required this.groupedBets,
    required this.getCategoryInfo,
    required this.getBetLocalizedName,
    required this.getCategoryLocalizedName,
  });

  @override
  State<_AllBetsModalContent> createState() => _AllBetsModalContentState();
}

class _AllBetsModalContentState extends State<_AllBetsModalContent> {
  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  int _selectedIndex = 0;
  late List<String> _categories;

  @override
  void initState() {
    super.initState();
    _categories = ['all', ...widget.groupedBets.keys];
  }

  String _getLocalizedCategoryName(BuildContext context, String categoryKey) {
    if (categoryKey == 'all') {
      return AppLocalizations.of(context)!.all;
    }
    return widget.getCategoryLocalizedName(context, categoryKey);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // 핸들바
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  // LIVE 뱃지 with 애니메이션 효과
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                        const SizedBox(width: 5),
                        const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.liveOdds,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.allBets.length}개',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 카테고리 필터 칩
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedIndex == index;
                  final info = cat == 'all'
                      ? {'icon': Icons.grid_view_rounded, 'color': _primary}
                      : widget.getCategoryInfo(cat);
                  final count = cat == 'all'
                      ? widget.allBets.length
                      : widget.groupedBets[cat]?.length ?? 0;
                  final color = info['color'] as Color;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? color : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? color : Colors.grey.shade200,
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              info['icon'] as IconData,
                              size: 15,
                              color: isSelected ? Colors.white : color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getLocalizedCategoryName(context, cat),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : _textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // 배팅 목록
            Expanded(
              child: Container(
                color: Colors.grey.shade50,
                child: _buildBetsList(scrollController),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBetsList(ScrollController scrollController) {
    final cat = _categories[_selectedIndex];
    final bets = cat == 'all'
        ? widget.allBets
        : widget.groupedBets[cat] ?? [];

    if (bets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.sports_soccer, size: 40, color: _textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noBettingInCategory,
              style: TextStyle(color: _textSecondary, fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: bets.length,
      itemBuilder: (context, index) {
        final bet = bets[index];
        return _buildBetCard(context, bet, index);
      },
    );
  }

  Widget _buildBetCard(BuildContext context, ApiFootballLiveOddsBet bet, int index) {
    final localizedName = widget.getBetLocalizedName(context, bet.name);
    final cat = _categories[_selectedIndex];
    final info = cat == 'all'
        ? {'color': _primary}
        : widget.getCategoryInfo(cat);
    final accentColor = info['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 배팅 헤더
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizedName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      if (localizedName != bet.name)
                        Text(
                          bet.name,
                          style: TextStyle(
                            fontSize: 11,
                            color: _textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${bet.values.length}개',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 배당값들
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bet.values.map((value) => _buildOddChip(value, accentColor)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOddChip(ApiFootballLiveOddsValue value, Color accentColor) {
    final isSuspended = value.suspended;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSuspended ? Colors.grey.shade100 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSuspended ? Colors.grey.shade300 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.handicap != null && value.handicap!.isNotEmpty
                ? '${value.value} (${value.handicap})'
                : value.value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSuspended ? Colors.grey : _textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: isSuspended
                  ? null
                  : LinearGradient(
                      colors: [accentColor, accentColor.withValues(alpha: 0.85)],
                    ),
              color: isSuspended ? Colors.grey.shade300 : null,
              borderRadius: BorderRadius.circular(8),
              boxShadow: isSuspended
                  ? null
                  : [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Text(
              isSuspended ? '-' : value.odd,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isSuspended ? Colors.grey.shade500 : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
