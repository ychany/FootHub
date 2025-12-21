import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/services/api_football_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/schedule_provider.dart';
import '../models/match_comment.dart';
import '../services/match_comment_service.dart';
import '../../profile/providers/timezone_provider.dart';

// Provider for match detail (API-Football)
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
final teamStandingsProvider =
    FutureProvider.family<ApiFootballStanding?, ({int leagueId, int season, int teamId})>((ref, params) async {
  final service = ApiFootballService();
  final standings = await service.getStandings(params.leagueId, params.season);
  // Find the team in standings
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

class MatchDetailScreen extends ConsumerWidget {
  final String eventId;

  static const _error = Color(0xFFEF4444);
  static const _textSecondary = Color(0xFF6B7280);
  static const _background = Color(0xFFF9FAFB);

  const MatchDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchDetailProvider(eventId));

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
                      '경기 정보를 찾을 수 없습니다',
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
                Text('오류: $e', style: TextStyle(color: _textSecondary)),
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
                    const Text(
                      '경기 정보',
                      style: TextStyle(
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
      floatingActionButton: _tabController.index == 5
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _addToDiary(context),
              backgroundColor: _primary,
              elevation: 2,
              icon: const Icon(Icons.edit_note, color: Colors.white),
              label: const Text(
                '직관 기록',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
                tabs: const [
                  Tab(text: '비교'),
                  Tab(text: '전적'),
                  Tab(text: '기록'),
                  Tab(text: '라인업'),
                  Tab(text: '예측'),
                  Tab(text: '댓글'),
                ],
              ),
            ),

            // 탭 컨텐츠
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ComparisonTab(match: match),
                  _H2HTab(match: match),
                  _StatsAndTimelineTab(fixtureId: match.id.toString(), match: match),
                  _LineupTab(fixtureId: match.id.toString(), match: match),
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
    final dateStr = DateFormat('yyyy.MM.dd (E) HH:mm', 'ko').format(dateTime);

    // 골 & 레드카드 이벤트 가져오기
    final eventsAsync = ref.watch(matchTimelineProvider(match.id.toString()));
    final allEvents = eventsAsync.valueOrNull ?? [];
    final goalEvents = allEvents.where((e) => e.type == 'Goal').toList();
    final redCardEvents = allEvents.where((e) => e.type == 'Card' && e.detail == 'Red Card').toList();
    final homeGoals = goalEvents.where((e) => e.teamId == match.homeTeam.id).toList();
    final awayGoals = goalEvents.where((e) => e.teamId == match.awayTeam.id).toList();
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
                  child: Text(
                    match.league.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                    textAlign: TextAlign.center,
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
                    match.status.elapsed != null ? "${match.status.elapsed}'" : 'LIVE',
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
                  child: Text(
                    '경기 종료',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
                          child: Text(
                            match.scoreDisplay,
                            style: TextStyle(
                              color: match.isLive ? const Color(0xFFEF4444) : _primary,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
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
      if (isOwnGoal) label += ' (자책)';
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
              const Text(
                '경기 정보',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(label: '리그', value: match.league.name),
          _InfoRow(label: '시즌', value: '${match.league.season ?? '-'}'),
          if (match.league.round != null && match.league.round!.isNotEmpty)
            _InfoRow(label: '라운드', value: match.league.round!),
          _InfoRow(
            label: '날짜',
            value: DateFormat('yyyy년 MM월 dd일 (E)', 'ko')
                .format(match.dateKST),
          ),
          _InfoRow(
            label: '시간',
            value: DateFormat('HH:mm').format(match.dateKST),
          ),
          _InfoRow(label: '경기장', value: match.venue?.name ?? '-'),
          _InfoRow(label: '상태', value: _getStatusText(match.status.short)),
          if (match.referee != null)
            _InfoRow(label: '주심', value: match.referee!),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'FT':
        return '경기 종료';
      case 'HT':
        return '하프타임';
      case '1H':
      case '2H':
        return '진행 중';
      case 'NS':
        return '예정';
      case 'TBD':
        return '시간 미정';
      case 'PST':
      case 'POSTP':
        return '연기';
      case 'CANC':
        return '취소';
      case 'AET':
        return '연장 종료';
      case 'PEN':
        return '승부차기 종료';
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
              return _buildEmptyCard(
                icon: Icons.analytics_outlined,
                message: '예측 정보가 없습니다',
              );
            }
            return _buildPredictionCard(prediction);
          },
          loading: () => _buildLoadingCard(),
          error: (e, _) => _buildEmptyCard(
            icon: Icons.error_outline,
            message: '예측 정보를 불러올 수 없습니다',
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
              Text(
                '배당률',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
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
                child: _buildQuickOddBox(
                  label: '무승부',
                  odd: drawOdd ?? '-',
                  color: _textSecondary,
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
              const Text(
                '실시간 배당률',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
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
                      Text(
                        '전체',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _primary,
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
                child: _buildLiveOddBox(
                  label: '무승부',
                  odd: drawOdd ?? '-',
                  initialOdd: initDrawOdd,
                  color: _textSecondary,
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
        const SnackBar(content: Text('배팅 정보가 없습니다')),
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
        getBetKoreanName: _getBetKoreanName,
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
    final orderedCategories = ['주요 배팅', '골 관련', '핸디캡', '전/후반', '팀 관련', '기타'];
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

  /// 배팅 이름으로 카테고리 결정
  String _getBetCategory(String name) {
    final nameLower = name.toLowerCase();

    // 주요 배팅
    if (nameLower.contains('winner') ||
        nameLower.contains('1x2') ||
        nameLower == 'home/away' ||
        nameLower.contains('double chance')) {
      return '주요 배팅';
    }

    // 골 관련
    if (nameLower.contains('goal') ||
        nameLower.contains('score') ||
        nameLower.contains('over') ||
        nameLower.contains('under') ||
        nameLower.contains('total') ||
        nameLower.contains('btts') ||
        nameLower.contains('both teams')) {
      return '골 관련';
    }

    // 핸디캡
    if (nameLower.contains('handicap') ||
        nameLower.contains('spread')) {
      return '핸디캡';
    }

    // 전후반
    if (nameLower.contains('half') ||
        nameLower.contains('1st') ||
        nameLower.contains('2nd')) {
      return '전/후반';
    }

    // 팀 관련
    if (nameLower.contains('home') ||
        nameLower.contains('away') ||
        nameLower.contains('team') ||
        nameLower.contains('clean sheet') ||
        nameLower.contains('win to nil')) {
      return '팀 관련';
    }

    return '기타';
  }

  /// 카테고리 정보 (아이콘, 색상)
  Map<String, dynamic> _getCategoryInfo(String category) {
    switch (category) {
      case '주요 배팅':
        return {'icon': Icons.star, 'color': const Color(0xFF2563EB)};
      case '골 관련':
        return {'icon': Icons.sports_soccer, 'color': const Color(0xFF10B981)};
      case '핸디캡':
        return {'icon': Icons.balance, 'color': const Color(0xFF8B5CF6)};
      case '전/후반':
        return {'icon': Icons.timelapse, 'color': const Color(0xFFF59E0B)};
      case '팀 관련':
        return {'icon': Icons.shield_outlined, 'color': const Color(0xFF06B6D4)};
      default:
        return {'icon': Icons.more_horiz, 'color': const Color(0xFF6B7280)};
    }
  }

  /// 배팅 이름 한글화
  String _getBetKoreanName(String name) {
    final Map<String, String> translations = {
      'Match Winner': '승무패',
      '1X2': '승무패',
      'Home/Away': '홈/원정',
      'Double Chance': '더블찬스',
      'Both Teams Score': '양팀 모두 득점',
      'Exact Score': '정확한 스코어',
      'Goals Over/Under': '총 골 수',
      'Over/Under': '오버/언더',
      'Asian Handicap': '아시안 핸디캡',
      'Handicap': '핸디캡',
      'First Half Winner': '전반전 승자',
      'Second Half Winner': '후반전 승자',
      'Half Time / Full Time': '전반/후반 결과',
      'Odd/Even': '홀/짝',
      'Total - Home': '홈팀 총 골',
      'Total - Away': '원정팀 총 골',
      'Clean Sheet - Home': '홈팀 무실점',
      'Clean Sheet - Away': '원정팀 무실점',
      'Win to Nil - Home': '홈팀 완봉승',
      'Win to Nil - Away': '원정팀 완봉승',
      'Corners Over Under': '코너킥 수',
      'Cards Over Under': '카드 수',
      'First Team To Score': '선제골 팀',
      'Last Team To Score': '마지막 득점 팀',
      'Highest Scoring Half': '최다 득점 반',
      'To Score In Both Halves': '양 반전 득점',
      'Home Win Both Halves': '홈팀 양 반전 승리',
      'Away Win Both Halves': '원정팀 양 반전 승리',
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
            Text(
              '초기 $initialOdd',
              style: TextStyle(
                fontSize: 10,
                color: _textSecondary.withValues(alpha: 0.7),
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
              const Text(
                '승부 예측',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
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
                  Text(
                    '예상 승자',
                    style: TextStyle(
                      fontSize: 12,
                      color: _textSecondary,
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
                    Text(
                      '무승부',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _textSecondary,
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
            Text(
              '상세 분석',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (prediction.comparison!.form != null)
              _buildComparisonRow('폼', prediction.comparison!.form!),
            if (prediction.comparison!.att != null)
              _buildComparisonRow('공격력', prediction.comparison!.att!),
            if (prediction.comparison!.def != null)
              _buildComparisonRow('수비력', prediction.comparison!.def!),
            if (prediction.comparison!.h2h != null)
              _buildComparisonRow('상대전적', prediction.comparison!.h2h!),
            if (prediction.comparison!.goals != null)
              _buildComparisonRow('득점력', prediction.comparison!.goals!),
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

              return _FootballPitchView(
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
            error: (e, _) => Container(
              padding: const EdgeInsets.all(16),
              child: Text('라인업 로딩 오류: $e', style: TextStyle(color: _textSecondary)),
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
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 40, color: _textSecondary),
            const SizedBox(height: 12),
            const Text(
              '라인업 정보가 없습니다',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '경기 시작 전 업데이트됩니다',
              style: TextStyle(
                color: _textSecondary.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ Football Pitch View ============
class _FootballPitchView extends StatelessWidget {
  final ApiFootballLineup? homeLineup;
  final ApiFootballLineup? awayLineup;
  final ApiFootballFixtureTeam homeTeam;
  final ApiFootballFixtureTeam awayTeam;
  final FixturePlayerStats? homePlayerStats;
  final FixturePlayerStats? awayPlayerStats;
  final List<ApiFootballEvent> substitutions;
  final Map<int, List<ApiFootballEvent>> playerEvents;

  static const _pitchGreen = Color(0xFF2E7D32);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _FootballPitchView({
    required this.homeLineup,
    required this.awayLineup,
    required this.homeTeam,
    required this.awayTeam,
    this.homePlayerStats,
    this.awayPlayerStats,
    this.substitutions = const [],
    this.playerEvents = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 포메이션 헤더
        _buildFormationHeader(),
        const SizedBox(height: 12),

        // 축구 피치
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 0.7,
              child: CustomPaint(
                painter: _FootballPitchPainter(),
                child: Stack(
                  children: [
                    // 홈팀 (위쪽 절반)
                    if (homeLineup != null)
                      ..._buildTeamPlayers(
                        homeLineup!,
                        homePlayerStats,
                        isHome: true,
                      ),
                    // 어웨이팀 (아래쪽 절반)
                    if (awayLineup != null)
                      ..._buildTeamPlayers(
                        awayLineup!,
                        awayPlayerStats,
                        isHome: false,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 교체 선수 섹션
        _buildSubstitutesSection(),
      ],
    );
  }

  Widget _buildFormationHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // 홈팀
          Expanded(
            child: Row(
              children: [
                if (homeTeam.logo != null)
                  CachedNetworkImage(
                    imageUrl: homeTeam.logo!,
                    width: 24,
                    height: 24,
                    errorWidget: (_, __, ___) => const Icon(Icons.sports_soccer, size: 24),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        homeTeam.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (homeLineup?.formation != null)
                        Text(
                          homeLineup!.formation!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _pitchGreen,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // VS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
          ),

          // 어웨이팀
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        awayTeam.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                      if (awayLineup?.formation != null)
                        Text(
                          awayLineup!.formation!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _pitchGreen,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (awayTeam.logo != null)
                  CachedNetworkImage(
                    imageUrl: awayTeam.logo!,
                    width: 24,
                    height: 24,
                    errorWidget: (_, __, ___) => const Icon(Icons.sports_soccer, size: 24),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTeamPlayers(
    ApiFootballLineup lineup,
    FixturePlayerStats? playerStats, {
    required bool isHome,
  }) {
    final players = lineup.startXI;
    final formation = lineup.formation;

    if (formation == null || players.isEmpty) return [];

    // 포메이션 파싱 (예: "4-3-3" -> [4, 3, 3])
    final lines = formation.split('-').map((e) => int.tryParse(e) ?? 0).toList();
    if (lines.isEmpty) return [];

    // 골키퍼 + 필드 플레이어 라인 구성
    final allLines = [1, ...lines]; // 골키퍼 1명 추가
    final totalLines = allLines.length;

    final widgets = <Widget>[];
    int playerIndex = 0;

    // 각 라인의 Y 위치를 미리 계산 (골키퍼부터 공격수까지 균등 분배)
    // 홈팀: 상단(골키퍼) -> 하단(공격수), 어웨이팀: 하단(골키퍼) -> 상단(공격수)
    final lineYPositions = <double>[];
    for (int i = 0; i < totalLines; i++) {
      if (isHome) {
        // 홈팀: 5% ~ 45% 범위 (상단 절반)
        lineYPositions.add(0.05 + (i / (totalLines - 1)) * 0.40);
      } else {
        // 어웨이팀: 95% ~ 55% 범위 (하단 절반)
        lineYPositions.add(0.95 - (i / (totalLines - 1)) * 0.40);
      }
    }

    for (int lineIndex = 0; lineIndex < allLines.length; lineIndex++) {
      final playersInLine = allLines[lineIndex];

      for (int posIndex = 0; posIndex < playersInLine; posIndex++) {
        if (playerIndex >= players.length) break;

        final player = players[playerIndex];
        final stats = _findPlayerStats(player.id, playerStats);

        // Y 위치
        final yPercent = lineYPositions[lineIndex];

        // X 위치 계산 (선수 분포) - 더 넓게 분포
        double xPercent;
        if (playersInLine == 1) {
          xPercent = 0.5;
        } else if (playersInLine == 2) {
          // 2명: 30%, 70%
          xPercent = 0.30 + posIndex * 0.40;
        } else if (playersInLine == 3) {
          // 3명: 20%, 50%, 80%
          xPercent = 0.20 + posIndex * 0.30;
        } else if (playersInLine == 4) {
          // 4명: 12%, 37%, 63%, 88%
          xPercent = 0.12 + posIndex * 0.25;
        } else if (playersInLine == 5) {
          // 5명: 10%, 30%, 50%, 70%, 90%
          xPercent = 0.10 + posIndex * 0.20;
        } else {
          // 그 외
          final spacing = 0.80 / (playersInLine - 1);
          xPercent = 0.10 + posIndex * spacing;
        }

        widgets.add(
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 마커 중심 위치 계산 (마커 크기 약 36x50 정도)
                final markerCenterX = constraints.maxWidth * xPercent;
                final markerCenterY = constraints.maxHeight * yPercent;

                return Stack(
                  children: [
                    Positioned(
                      left: markerCenterX - 28, // 마커 너비/2 + 여유
                      top: markerCenterY - 25,  // 마커 높이 고려
                      child: _PlayerMarker(
                        player: player,
                        stats: stats,
                        isHome: isHome,
                        events: playerEvents[player.id] ?? [],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );

        playerIndex++;
      }
    }

    return widgets;
  }

  PlayerMatchStats? _findPlayerStats(int playerId, FixturePlayerStats? teamStats) {
    if (teamStats == null) return null;
    try {
      return teamStats.players.firstWhere((p) => p.id == playerId);
    } catch (_) {
      return null;
    }
  }

  Widget _buildSubstitutesSection() {
    final homeSubs = homeLineup?.substitutes ?? [];
    final awaySubs = awayLineup?.substitutes ?? [];

    if (homeSubs.isEmpty && awaySubs.isEmpty) return const SizedBox.shrink();

    // 홈팀/어웨이팀 교체 이벤트 분리
    final homeSubEvents = substitutions.where((e) => e.teamId == homeTeam.id).toList();
    final awaySubEvents = substitutions.where((e) => e.teamId == awayTeam.id).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Icon(Icons.swap_horiz, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                '교체 선수',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const Spacer(),
              // 교체 횟수
              if (substitutions.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${substitutions.length}회',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
            ],
          ),

          // 실제 교체 이벤트 (발생한 경우)
          if (substitutions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              '교체 기록',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            // 홈팀 교체
            if (homeSubEvents.isNotEmpty) ...[
              _buildTeamSubstitutions(homeTeam.name, homeSubEvents, true),
              if (awaySubEvents.isNotEmpty) const SizedBox(height: 12),
            ],
            // 어웨이팀 교체
            if (awaySubEvents.isNotEmpty)
              _buildTeamSubstitutions(awayTeam.name, awaySubEvents, false),
          ],

          // 벤치 선수 (아직 투입되지 않은 선수)
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            '벤치',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 홈팀 벤치
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: homeSubs.take(7).map((p) {
                    final stats = _findPlayerStats(p.id, homePlayerStats);
                    final subEvent = _findSubstitutionEvent(p.id, homeSubEvents);
                    return _SubstituteRow(
                      player: p,
                      stats: stats,
                      substitutionEvent: subEvent,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 16),
              // 어웨이팀 벤치
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: awaySubs.take(7).map((p) {
                    final stats = _findPlayerStats(p.id, awayPlayerStats);
                    final subEvent = _findSubstitutionEvent(p.id, awaySubEvents);
                    return _SubstituteRow(
                      player: p,
                      stats: stats,
                      substitutionEvent: subEvent,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSubstitutions(String teamName, List<ApiFootballEvent> events, bool isHome) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          teamName,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isHome ? const Color(0xFF1E40AF) : const Color(0xFFDC2626),
          ),
        ),
        const SizedBox(height: 6),
        ...events.map((event) => _buildSubstitutionEventRow(event)),
      ],
    );
  }

  Widget _buildSubstitutionEventRow(ApiFootballEvent event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // 시간
          Container(
            width: 36,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              event.timeDisplay,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          // IN 선수
          Expanded(
            child: Row(
              children: [
                Icon(Icons.arrow_upward, size: 12, color: Colors.green.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.assistName ?? '-', // assistName이 IN 선수
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // OUT 선수
          Expanded(
            child: Row(
              children: [
                Icon(Icons.arrow_downward, size: 12, color: Colors.red.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.playerName ?? '-', // playerName이 OUT 선수
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ApiFootballEvent? _findSubstitutionEvent(int playerId, List<ApiFootballEvent> events) {
    // 해당 선수가 IN된 이벤트 찾기 (assistId가 IN 선수)
    try {
      return events.firstWhere((e) => e.assistId == playerId);
    } catch (_) {
      return null;
    }
  }
}

// 축구장 배경 페인터
class _FootballPitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // 잔디 배경 (줄무늬)
    final stripeCount = 12;
    final stripeHeight = size.height / stripeCount;
    for (int i = 0; i < stripeCount; i++) {
      paint.color = i % 2 == 0 ? const Color(0xFF2E7D32) : const Color(0xFF388E3C);
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight),
        paint,
      );
    }

    // 외곽선
    canvas.drawRect(
      Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
      linePaint,
    );

    // 중앙선
    canvas.drawLine(
      Offset(4, size.height / 2),
      Offset(size.width - 4, size.height / 2),
      linePaint,
    );

    // 센터 서클
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.15,
      linePaint,
    );

    // 센터 점
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      4,
      dotPaint,
    );

    // 페널티 박스 (위)
    _drawPenaltyBox(canvas, size, linePaint, isTop: true);
    // 페널티 박스 (아래)
    _drawPenaltyBox(canvas, size, linePaint, isTop: false);

    // 골 에어리어 (위)
    _drawGoalArea(canvas, size, linePaint, isTop: true);
    // 골 에어리어 (아래)
    _drawGoalArea(canvas, size, linePaint, isTop: false);
  }

  void _drawPenaltyBox(Canvas canvas, Size size, Paint paint, {required bool isTop}) {
    final boxWidth = size.width * 0.6;
    final boxHeight = size.height * 0.14;
    final left = (size.width - boxWidth) / 2;

    if (isTop) {
      canvas.drawRect(
        Rect.fromLTWH(left, 4, boxWidth, boxHeight),
        paint,
      );
      // 페널티 아크
      final arcRect = Rect.fromCircle(
        center: Offset(size.width / 2, boxHeight + 4),
        radius: size.width * 0.12,
      );
      canvas.drawArc(arcRect, 0.2, 2.74, false, paint);
    } else {
      canvas.drawRect(
        Rect.fromLTWH(left, size.height - boxHeight - 4, boxWidth, boxHeight),
        paint,
      );
      // 페널티 아크
      final arcRect = Rect.fromCircle(
        center: Offset(size.width / 2, size.height - boxHeight - 4),
        radius: size.width * 0.12,
      );
      canvas.drawArc(arcRect, 3.34, 2.74, false, paint);
    }
  }

  void _drawGoalArea(Canvas canvas, Size size, Paint paint, {required bool isTop}) {
    final boxWidth = size.width * 0.3;
    final boxHeight = size.height * 0.05;
    final left = (size.width - boxWidth) / 2;

    if (isTop) {
      canvas.drawRect(
        Rect.fromLTWH(left, 4, boxWidth, boxHeight),
        paint,
      );
    } else {
      canvas.drawRect(
        Rect.fromLTWH(left, size.height - boxHeight - 4, boxWidth, boxHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 선수 마커 위젯
class _PlayerMarker extends StatelessWidget {
  final ApiFootballLineupPlayer player;
  final PlayerMatchStats? stats;
  final bool isHome;
  final List<ApiFootballEvent> events;

  const _PlayerMarker({
    required this.player,
    this.stats,
    required this.isHome,
    this.events = const [],
  });

  @override
  Widget build(BuildContext context) {
    final rating = stats?.ratingValue;
    final ratingColor = _getRatingColor(rating);
    final hasPhoto = stats?.photo != null;

    return GestureDetector(
      onTap: () => _showPlayerDetail(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 선수 얼굴/등번호
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasPhoto
                      ? Colors.white
                      : (isHome ? const Color(0xFF1E40AF) : const Color(0xFFDC2626)),
                  border: Border.all(
                    color: isHome ? const Color(0xFF1E40AF) : const Color(0xFFDC2626),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: hasPhoto
                      ? CachedNetworkImage(
                          imageUrl: stats!.photo!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Center(
                            child: Text(
                              player.number?.toString() ?? '-',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            player.number?.toString() ?? '-',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
              // 평점 뱃지 (우측 하단)
              if (rating != null)
                Positioned(
                  right: -4,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: ratingColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              // 이벤트 아이콘들 (좌측 상단)
              if (events.isNotEmpty)
                Positioned(
                  left: -6,
                  top: -6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildEventIcons(),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 2),

          // 선수 이름
          Container(
            constraints: const BoxConstraints(maxWidth: 56),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              _getShortName(player.name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _getShortName(String fullName) {
    final parts = fullName.split(' ');
    if (parts.length <= 1) return fullName;
    // 성만 반환 (또는 마지막 단어)
    return parts.last.length <= 8 ? parts.last : parts.last.substring(0, 8);
  }

  Color _getRatingColor(double? rating) {
    if (rating == null) return Colors.grey;
    if (rating >= 7.5) return const Color(0xFF22C55E);
    if (rating >= 7.0) return const Color(0xFF84CC16);
    if (rating >= 6.5) return const Color(0xFFF59E0B);
    if (rating >= 6.0) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  List<Widget> _buildEventIcons() {
    final icons = <Widget>[];

    final goals = events.where((e) => e.type == 'Goal' && e.detail != 'Own Goal').length;
    final ownGoals = events.where((e) => e.type == 'Goal' && e.detail == 'Own Goal').length;
    final assists = events.where((e) => e.type == 'Assist').length;
    final yellowCards = events.where((e) => e.type == 'Card' && e.detail == 'Yellow Card').length;
    final redCards = events.where((e) => e.type == 'Card' && e.detail == 'Red Card').length;

    // 골 아이콘
    for (int i = 0; i < goals; i++) {
      icons.add(Container(
        width: 16,
        height: 16,
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: const Icon(Icons.sports_soccer, size: 11, color: Colors.black),
      ));
    }

    // 자책골 아이콘
    for (int i = 0; i < ownGoals; i++) {
      icons.add(Container(
        width: 16,
        height: 16,
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.red, width: 1),
        ),
        child: const Icon(Icons.sports_soccer, size: 11, color: Colors.red),
      ));
    }

    // 어시스트 아이콘 (축구화)
    for (int i = 0; i < assists; i++) {
      icons.add(Container(
        width: 16,
        height: 16,
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.green, width: 1),
        ),
        child: const Center(child: Text('👟', style: TextStyle(fontSize: 10))),
      ));
    }

    // 옐로카드 아이콘
    for (int i = 0; i < yellowCards; i++) {
      icons.add(Container(
        width: 10,
        height: 12,
        margin: const EdgeInsets.only(right: 1),
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(1),
          border: Border.all(color: Colors.white, width: 0.5),
        ),
      ));
    }

    // 레드카드 아이콘
    for (int i = 0; i < redCards; i++) {
      icons.add(Container(
        width: 10,
        height: 12,
        margin: const EdgeInsets.only(right: 1),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(1),
          border: Border.all(color: Colors.white, width: 0.5),
        ),
      ));
    }

    return icons;
  }

  void _showPlayerDetail(BuildContext context) {
    if (player.id <= 0) return;
    _showPlayerStatsModal(context, player, stats);
  }
}

// 선수 경기 스탯 모달
void _showPlayerStatsModal(
  BuildContext context,
  ApiFootballLineupPlayer player,
  PlayerMatchStats? stats,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _PlayerStatsModal(player: player, stats: stats),
  );
}

class _PlayerStatsModal extends StatelessWidget {
  final ApiFootballLineupPlayer player;
  final PlayerMatchStats? stats;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _success = Color(0xFF22C55E);

  const _PlayerStatsModal({required this.player, this.stats});

  @override
  Widget build(BuildContext context) {
    final rating = stats?.ratingValue;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더 영역 (선수 정보)
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // 핸들
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // 선수 프로필
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    children: [
                      // 선수 사진 + 평점
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: _border, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: stats?.photo != null
                                  ? CachedNetworkImage(
                                      imageUrl: stats!.photo!,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Icon(
                                        Icons.person,
                                        size: 36,
                                        color: _textSecondary,
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 36,
                                      color: _textSecondary,
                                    ),
                            ),
                          ),
                          // 평점 뱃지
                          if (rating != null)
                            Positioned(
                              right: -8,
                              bottom: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRatingColor(rating),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getRatingColor(rating).withValues(alpha: 0.4),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),

                      // 이름 + 포지션 + 등번호
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 이름 (탭하면 상세 페이지로)
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                if (player.id > 0) {
                                  context.push('/player/${player.id}');
                                }
                              },
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      player.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: _primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 10,
                                      color: _primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (player.number != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '#${player.number}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (stats?.position != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getPositionColor(stats!.position!).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getPositionName(stats!.position!),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _getPositionColor(stats!.position!),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 주요 스탯 요약 (출전/골/어시스트)
                if (stats != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildKeyStatItem(
                          icon: Icons.timer_outlined,
                          label: '출전',
                          value: stats!.minutesPlayed != null ? "${stats!.minutesPlayed}'" : '-',
                        ),
                        _buildVerticalDivider(),
                        _buildKeyStatItem(
                          icon: Icons.sports_soccer,
                          label: '골',
                          value: '${stats!.goals ?? 0}',
                          highlight: (stats!.goals ?? 0) > 0,
                        ),
                        _buildVerticalDivider(),
                        _buildKeyStatItem(
                          icon: Icons.assistant_outlined,
                          label: '어시스트',
                          value: '${stats!.assists ?? 0}',
                          highlight: (stats!.assists ?? 0) > 0,
                        ),
                        _buildVerticalDivider(),
                        _buildKeyStatItem(
                          icon: Icons.check_circle_outline,
                          label: '패스 성공률',
                          value: stats!.passAccuracyText,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // 스탯 상세 영역
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: stats != null
                  ? _buildStatsContent(context)
                  : _buildNoStatsContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyStatItem({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 18,
            color: highlight ? _success : _textSecondary,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: highlight ? _success : _textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 36,
      color: _border,
    );
  }

  Widget _buildNoStatsContent() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.sports_soccer, size: 48, color: _textSecondary),
          const SizedBox(height: 16),
          const Text(
            '경기 통계가 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '경기 중 또는 경기 후에 업데이트됩니다',
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 공격 카드
        _buildStatCard(
          title: '공격',
          icon: Icons.sports_soccer,
          iconColor: const Color(0xFFEF4444),
          stats: [
            _StatRow(label: '슈팅', value: '${stats!.shotsTotal ?? 0}'),
            _StatRow(label: '유효 슈팅', value: '${stats!.shotsOn ?? 0}'),
            _StatRow(label: '오프사이드', value: '${stats!.offsides ?? 0}'),
          ],
        ),

        // 패스 카드
        _buildStatCard(
          title: '패스',
          icon: Icons.swap_calls,
          iconColor: const Color(0xFF3B82F6),
          stats: [
            _StatRow(label: '총 패스', value: '${stats!.passesTotal ?? 0}'),
            _StatRow(label: '키 패스', value: '${stats!.passesKey ?? 0}'),
          ],
        ),

        // 수비 카드
        _buildStatCard(
          title: '수비',
          icon: Icons.shield_outlined,
          iconColor: const Color(0xFF22C55E),
          stats: [
            _StatRow(label: '태클', value: '${stats!.tacklesTotal ?? 0}'),
            _StatRow(label: '인터셉트', value: '${stats!.tacklesInterceptions ?? 0}'),
            _StatRow(label: '블록', value: '${stats!.tacklesBlocks ?? 0}'),
          ],
        ),

        // 듀얼 & 드리블 카드
        _buildStatCard(
          title: '듀얼 & 드리블',
          icon: Icons.directions_run,
          iconColor: const Color(0xFF8B5CF6),
          stats: [
            _StatRow(
              label: '듀얼',
              value: '${stats!.duelsWon ?? 0}/${stats!.duelsTotal ?? 0}',
              subValue: stats!.duelWinRateText,
            ),
            _StatRow(
              label: '드리블',
              value: '${stats!.dribblesSuccess ?? 0}/${stats!.dribblesAttempts ?? 0}',
            ),
          ],
        ),

        // 파울 & 카드
        _buildStatCard(
          title: '파울 & 카드',
          icon: Icons.warning_amber_outlined,
          iconColor: const Color(0xFFF59E0B),
          stats: [
            _StatRow(label: '파울', value: '${stats!.foulsCommitted ?? 0}'),
            _StatRow(label: '피파울', value: '${stats!.foulsDrawn ?? 0}'),
            if ((stats!.yellowCards ?? 0) > 0 || (stats!.redCards ?? 0) > 0)
              _StatRow(
                label: '카드',
                value: '',
                customWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if ((stats!.yellowCards ?? 0) > 0)
                      Container(
                        width: 14,
                        height: 18,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Center(
                          child: Text(
                            '${stats!.yellowCards}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    if ((stats!.redCards ?? 0) > 0)
                      Container(
                        width: 14,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Center(
                          child: Text(
                            '${stats!.redCards}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),

        // 골키퍼 전용
        if (stats!.position == 'G')
          _buildStatCard(
            title: '골키퍼',
            icon: Icons.sports_handball,
            iconColor: Colors.orange,
            stats: [
              _StatRow(label: '선방', value: '${stats!.saves ?? 0}'),
              _StatRow(label: '실점', value: '${stats!.goalsConceded ?? 0}'),
            ],
          ),

        const SizedBox(height: 8),

        // 선수 상세 페이지 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              if (player.id > 0) {
                context.push('/player/${player.id}');
              }
            },
            icon: const Icon(Icons.person_outline, size: 18),
            label: const Text('선수 상세 정보 보기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<_StatRow> stats,
  }) {
    // 값이 모두 0이거나 없으면 표시하지 않음
    final hasValue = stats.any((stat) =>
        stat.value != '0' && stat.value != '-' && stat.value != '0/0' && stat.value.isNotEmpty ||
        stat.customWidget != null);
    if (!hasValue) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _border),
          // 스탯 목록
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              children: stats.map((stat) {
                if (stat.value == '0' && stat.customWidget == null) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        stat.label,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                        ),
                      ),
                      stat.customWidget ??
                          Row(
                            children: [
                              Text(
                                stat.value,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _textPrimary,
                                ),
                              ),
                              if (stat.subValue != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    stat.subValue!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getPositionName(String pos) {
    switch (pos.toUpperCase()) {
      case 'G':
        return '골키퍼';
      case 'D':
        return '수비수';
      case 'M':
        return '미드필더';
      case 'F':
        return '공격수';
      default:
        return pos;
    }
  }

  Color _getRatingColor(double rating) {
    if (rating >= 7.5) return const Color(0xFF22C55E);
    if (rating >= 7.0) return const Color(0xFF84CC16);
    if (rating >= 6.5) return const Color(0xFFF59E0B);
    if (rating >= 6.0) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  Color _getPositionColor(String position) {
    switch (position.toUpperCase()) {
      case 'G':
        return Colors.orange;
      case 'D':
        return Colors.blue;
      case 'M':
        return Colors.green;
      case 'F':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _StatRow {
  final String label;
  final String value;
  final String? subValue;
  final Widget? customWidget;

  const _StatRow({
    required this.label,
    required this.value,
    this.subValue,
    this.customWidget,
  });
}

// 교체 선수 행
class _SubstituteRow extends StatelessWidget {
  final ApiFootballLineupPlayer player;
  final PlayerMatchStats? stats;
  final ApiFootballEvent? substitutionEvent;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _SubstituteRow({
    required this.player,
    this.stats,
    this.substitutionEvent,
  });

  bool get isSubbedIn => substitutionEvent != null;

  @override
  Widget build(BuildContext context) {
    final rating = stats?.ratingValue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () {
          _showPlayerStatsModal(context, player, stats);
        },
        child: Row(
          children: [
            // 투입 표시 (IN 뱃지)
            if (isSubbedIn) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_upward, size: 8, color: Colors.green.shade700),
                    Text(
                      substitutionEvent!.timeDisplay,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
            ],
            // 등번호
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSubbedIn ? Colors.green.shade50 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
                border: isSubbedIn
                    ? Border.all(color: Colors.green.shade300, width: 1)
                    : null,
              ),
              child: Center(
                child: Text(
                  player.number?.toString() ?? '-',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSubbedIn ? Colors.green.shade700 : _textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // 이름
            Expanded(
              child: Text(
                player.name,
                style: TextStyle(
                  fontSize: 11,
                  color: isSubbedIn ? Colors.green.shade800 : _textPrimary,
                  fontWeight: isSubbedIn ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 평점
            if (rating != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _getRatingColor(rating).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _getRatingColor(rating),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 7.5) return const Color(0xFF22C55E);
    if (rating >= 7.0) return const Color(0xFF84CC16);
    if (rating >= 6.5) return const Color(0xFFF59E0B);
    if (rating >= 6.0) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
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
                    '결장 선수',
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
                      '${injuries.length}명',
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
            Text('결장 정보 확인 중...', style: TextStyle(color: _textSecondary, fontSize: 13)),
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
                      _getReasonText(injury),
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

  String _getReasonText(ApiFootballInjury injury) {
    final reason = injury.reason ?? '';
    if (injury.isSuspended) return '정지';
    if (reason.toLowerCase().contains('knee')) return '무릎 부상';
    if (reason.toLowerCase().contains('hamstring')) return '햄스트링';
    if (reason.toLowerCase().contains('ankle')) return '발목 부상';
    if (reason.toLowerCase().contains('muscle')) return '근육 부상';
    if (reason.toLowerCase().contains('back')) return '허리 부상';
    if (reason.toLowerCase().contains('illness')) return '질병';
    if (injury.isInjury) return '부상';
    if (injury.isDoubtful) return '불투명';
    return '결장';
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 기록 섹션
        _buildSectionHeader('기록', Icons.analytics_outlined),
        const SizedBox(height: 12),
        statsAsync.when(
          data: (statsList) => _buildStatsContent(statsList),
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => _buildErrorWidget('통계를 불러올 수 없습니다'),
        ),

        const SizedBox(height: 24),

        // 중계 섹션
        _buildSectionHeader('중계', Icons.timeline),
        const SizedBox(height: 12),
        timelineAsync.when(
          data: (events) => _buildTimelineContent(events),
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => _buildErrorWidget('타임라인을 불러올 수 없습니다'),
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

  Widget _buildStatsContent(List<ApiFootballTeamStats> statsList) {
    if (statsList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: const Center(
          child: Text(
            '통계 정보가 없습니다',
            style: TextStyle(color: _textSecondary, fontSize: 14),
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
              label: '점유율',
              homeValue: _parsePercent(homeStats?.possession),
              awayValue: _parsePercent(awayStats?.possession),
              isPercentage: true,
            ),
          if (homeStats?.shotsTotal != null)
            _StatBar(
              label: '슈팅',
              homeValue: homeStats?.shotsTotal ?? 0,
              awayValue: awayStats?.shotsTotal ?? 0,
            ),
          if (homeStats?.shotsOnTarget != null)
            _StatBar(
              label: '유효 슈팅',
              homeValue: homeStats?.shotsOnTarget ?? 0,
              awayValue: awayStats?.shotsOnTarget ?? 0,
            ),
          if (homeStats?.corners != null)
            _StatBar(
              label: '코너킥',
              homeValue: homeStats?.corners ?? 0,
              awayValue: awayStats?.corners ?? 0,
            ),
          if (homeStats?.fouls != null)
            _StatBar(
              label: '파울',
              homeValue: homeStats?.fouls ?? 0,
              awayValue: awayStats?.fouls ?? 0,
            ),
          if (homeStats?.offsides != null)
            _StatBar(
              label: '오프사이드',
              homeValue: homeStats?.offsides ?? 0,
              awayValue: awayStats?.offsides ?? 0,
            ),
          if (homeStats?.yellowCards != null)
            _StatBar(
              label: '경고',
              homeValue: homeStats?.yellowCards ?? 0,
              awayValue: awayStats?.yellowCards ?? 0,
              color: Colors.amber,
            ),
          if (homeStats?.redCards != null)
            _StatBar(
              label: '퇴장',
              homeValue: homeStats?.redCards ?? 0,
              awayValue: awayStats?.redCards ?? 0,
              color: Colors.red,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineContent(List<ApiFootballEvent> events) {
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: const Center(
          child: Text(
            '타임라인 정보가 없습니다',
            style: TextStyle(color: _textSecondary, fontSize: 14),
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

    return IntrinsicHeight(
      child: Row(
        children: [
          // 홈팀 영역 (왼쪽)
          Expanded(
            child: isHome
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
            child: !isHome
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
              '어시스트: ${event.assistName}',
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
                Text(
                  event.assistName!,
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

  String _getEventTypeText() {
    switch (event.type.toLowerCase()) {
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
          const Text(
            '경기 알림 설정',
            style: TextStyle(
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

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNotificationTile(
                icon: Icons.sports_soccer,
                iconColor: Colors.green,
                title: '경기 시작 알림',
                subtitle: '킥오프 30분 전에 알림',
                value: _notifyKickoff,
                onChanged: (value) {
                  setState(() => _notifyKickoff = value);
                },
              ),
              const Divider(height: 1, color: _border),
              _buildNotificationTile(
                icon: Icons.people_outline,
                iconColor: Colors.blue,
                title: '라인업 발표',
                subtitle: '선발 명단 공개 시 알림',
                value: _notifyLineup,
                onChanged: (value) {
                  setState(() => _notifyLineup = value);
                },
              ),
              const Divider(height: 1, color: _border),
              _buildNotificationTile(
                icon: Icons.emoji_events_outlined,
                iconColor: Colors.amber,
                title: '경기 결과',
                subtitle: '경기 종료 후 결과 알림',
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
            child: Text('오류: $e', style: TextStyle(color: _textSecondary)),
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
                const SnackBar(
                  content: Text('알림이 해제되었습니다'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              '알림 해제',
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            '취소',
            style: TextStyle(color: _textSecondary),
          ),
        ),
        TextButton(
          onPressed: _saveNotification,
          style: TextButton.styleFrom(
            foregroundColor: _primary,
          ),
          child: const Text(
            '저장',
            style: TextStyle(fontWeight: FontWeight.w600),
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
    if (_notifyKickoff || _notifyLineup || _notifyResult) {
      ref.read(scheduleNotifierProvider.notifier).setNotification(
        matchId: widget.matchId,
        notifyKickoff: _notifyKickoff,
        notifyLineup: _notifyLineup,
        notifyResult: _notifyResult,
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('알림이 설정되었습니다'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      if (_hasExistingSetting) {
        ref.read(scheduleNotifierProvider.notifier).removeNotification(widget.matchId);
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('알림이 해제되었습니다'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

// ============ Comparison Tab ============
class _ComparisonTab extends ConsumerWidget {
  final ApiFootballFixture match;

  static const _primary = Color(0xFF2563EB);
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);
  static const _error = Color(0xFFEF4444);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _ComparisonTab({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leagueId = match.league.id;
    final season = match.league.season ?? DateTime.now().year;
    final homeTeamId = match.homeTeam.id;
    final awayTeamId = match.awayTeam.id;

    // Providers
    final homeStandingAsync = ref.watch(teamStandingsProvider((
      leagueId: leagueId,
      season: season,
      teamId: homeTeamId,
    )));
    final awayStandingAsync = ref.watch(teamStandingsProvider((
      leagueId: leagueId,
      season: season,
      teamId: awayTeamId,
    )));
    final homeFormAsync = ref.watch(teamRecentFormProvider(homeTeamId));
    final awayFormAsync = ref.watch(teamRecentFormProvider(awayTeamId));
    final h2hAsync = ref.watch(matchH2HProvider((
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
    )));
    final topScorersAsync = ref.watch(leagueTopScorersProvider((
      leagueId: leagueId,
      season: season,
    )));
    final topAssistsAsync = ref.watch(leagueTopAssistsProvider((
      leagueId: leagueId,
      season: season,
    )));
    final homeSeasonStatsAsync = ref.watch(teamSeasonStatsProvider((
      teamId: homeTeamId,
      leagueId: leagueId,
      season: season,
    )));
    final awaySeasonStatsAsync = ref.watch(teamSeasonStatsProvider((
      teamId: awayTeamId,
      leagueId: leagueId,
      season: season,
    )));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. 리그 순위 비교
        _buildSectionHeader('리그 순위', Icons.emoji_events_outlined),
        const SizedBox(height: 12),
        _buildStandingsComparison(homeStandingAsync, awayStandingAsync),

        const SizedBox(height: 24),

        // 2. 홈/원정 성적 비교
        _buildSectionHeader('홈/원정 성적', Icons.home_outlined),
        const SizedBox(height: 12),
        _buildHomeAwayComparison(homeStandingAsync, awayStandingAsync),

        const SizedBox(height: 24),

        // 3. 최근 폼 비교
        _buildSectionHeader('최근 5경기', Icons.trending_up),
        const SizedBox(height: 12),
        _buildFormComparison(homeFormAsync, awayFormAsync, homeTeamId, awayTeamId),

        const SizedBox(height: 24),

        // 4. 득점/실점 통계
        _buildSectionHeader('득점/실점 통계', Icons.sports_soccer),
        const SizedBox(height: 12),
        _buildGoalStatsComparison(homeStandingAsync, awayStandingAsync),

        const SizedBox(height: 24),

        // 5. 팀 스타일 비교 (레이더 차트)
        _buildSectionHeader('팀 스타일 비교', Icons.radar),
        const SizedBox(height: 12),
        _buildRadarChartComparison(homeSeasonStatsAsync, awaySeasonStatsAsync),

        const SizedBox(height: 24),

        // 6. 주요 선수 비교
        _buildSectionHeader('주요 선수', Icons.person_outline),
        const SizedBox(height: 12),
        _buildTopPlayersComparison(topScorersAsync, topAssistsAsync, homeTeamId, awayTeamId),

        const SizedBox(height: 24),

        // 7. 상대전적 요약
        _buildSectionHeader('상대전적 요약', Icons.compare_arrows),
        const SizedBox(height: 12),
        _buildH2HSummary(h2hAsync, homeTeamId, awayTeamId),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _primary),
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

  // 1. 리그 순위 비교
  Widget _buildStandingsComparison(
    AsyncValue<ApiFootballStanding?> homeAsync,
    AsyncValue<ApiFootballStanding?> awayAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // 팀 이름 헤더
          Row(
            children: [
              Expanded(
                child: _buildTeamHeader(match.homeTeam.name, match.homeTeam.logo),
              ),
              const SizedBox(width: 16),
              const Text('VS', style: TextStyle(color: _textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTeamHeader(match.awayTeam.name, match.awayTeam.logo, isAway: true),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // 순위 비교 행들
          homeAsync.when(
            data: (homeSt) => awayAsync.when(
              data: (awaySt) {
                if (homeSt == null && awaySt == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('순위 정보가 없습니다', style: TextStyle(color: _textSecondary)),
                    ),
                  );
                }
                return Column(
                  children: [
                    _buildCompareRow('순위', '${homeSt?.rank ?? '-'}위', '${awaySt?.rank ?? '-'}위',
                        homeBetter: (homeSt?.rank ?? 99) < (awaySt?.rank ?? 99)),
                    _buildCompareRow('승점', '${homeSt?.points ?? '-'}', '${awaySt?.points ?? '-'}',
                        homeBetter: (homeSt?.points ?? 0) > (awaySt?.points ?? 0)),
                    _buildCompareRow('경기', '${homeSt?.played ?? '-'}', '${awaySt?.played ?? '-'}'),
                    _buildCompareRow(
                      '승-무-패',
                      '${homeSt?.win ?? 0}-${homeSt?.draw ?? 0}-${homeSt?.lose ?? 0}',
                      '${awaySt?.win ?? 0}-${awaySt?.draw ?? 0}-${awaySt?.lose ?? 0}',
                    ),
                    _buildCompareRow('득점', '${homeSt?.goalsFor ?? '-'}', '${awaySt?.goalsFor ?? '-'}',
                        homeBetter: (homeSt?.goalsFor ?? 0) > (awaySt?.goalsFor ?? 0)),
                    _buildCompareRow('실점', '${homeSt?.goalsAgainst ?? '-'}', '${awaySt?.goalsAgainst ?? '-'}',
                        homeBetter: (homeSt?.goalsAgainst ?? 99) < (awaySt?.goalsAgainst ?? 99)),
                    _buildCompareRow('득실차', _formatGoalDiff(homeSt?.goalsDiff), _formatGoalDiff(awaySt?.goalsDiff),
                        homeBetter: (homeSt?.goalsDiff ?? -99) > (awaySt?.goalsDiff ?? -99)),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('데이터 로드 실패', style: TextStyle(color: _textSecondary)),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('데이터 로드 실패', style: TextStyle(color: _textSecondary)),
          ),
        ],
      ),
    );
  }

  String _formatGoalDiff(int? diff) {
    if (diff == null) return '-';
    return diff > 0 ? '+$diff' : '$diff';
  }

  Widget _buildTeamHeader(String name, String? logo, {bool isAway = false}) {
    return Row(
      mainAxisAlignment: isAway ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isAway && logo != null) ...[
          CachedNetworkImage(
            imageUrl: logo,
            width: 28,
            height: 28,
            placeholder: (_, __) => const SizedBox(width: 28, height: 28),
            errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 28),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: isAway ? TextAlign.end : TextAlign.start,
          ),
        ),
        if (isAway && logo != null) ...[
          const SizedBox(width: 8),
          CachedNetworkImage(
            imageUrl: logo,
            width: 28,
            height: 28,
            placeholder: (_, __) => const SizedBox(width: 28, height: 28),
            errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 28),
          ),
        ],
      ],
    );
  }

  Widget _buildCompareRow(String label, String homeValue, String awayValue, {bool? homeBetter}) {
    Color homeColor = _textPrimary;
    Color awayColor = _textPrimary;

    if (homeBetter != null) {
      homeColor = homeBetter ? _success : _textSecondary;
      awayColor = homeBetter ? _textSecondary : _success;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              homeValue,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: homeColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: _textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              awayValue,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: awayColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // 2. 홈/원정 성적 비교
  Widget _buildHomeAwayComparison(
    AsyncValue<ApiFootballStanding?> homeAsync,
    AsyncValue<ApiFootballStanding?> awayAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: homeAsync.when(
        data: (homeSt) => awayAsync.when(
          data: (awaySt) {
            if (homeSt == null && awaySt == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('성적 정보가 없습니다', style: TextStyle(color: _textSecondary)),
                ),
              );
            }
            return Column(
              children: [
                // 홈팀의 홈 성적 vs 원정팀의 원정 성적
                Row(
                  children: [
                    Expanded(
                      child: _buildRecordCard(
                        '${match.homeTeam.name}\n홈 성적',
                        homeSt?.homeWin ?? 0,
                        homeSt?.homeDraw ?? 0,
                        homeSt?.homeLose ?? 0,
                        homeSt?.homeGoalsFor ?? 0,
                        homeSt?.homeGoalsAgainst ?? 0,
                        _primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRecordCard(
                        '${match.awayTeam.name}\n원정 성적',
                        awaySt?.awayWin ?? 0,
                        awaySt?.awayDraw ?? 0,
                        awaySt?.awayLose ?? 0,
                        awaySt?.awayGoalsFor ?? 0,
                        awaySt?.awayGoalsAgainst ?? 0,
                        _warning,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('데이터 로드 실패'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Text('데이터 로드 실패'),
      ),
    );
  }

  Widget _buildRecordCard(String title, int win, int draw, int lose, int gf, int ga, Color accentColor) {
    final played = win + draw + lose;
    final avgGf = played > 0 ? (gf / played).toStringAsFixed(1) : '0.0';
    final avgGa = played > 0 ? (ga / played).toStringAsFixed(1) : '0.0';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '$win승 $draw무 $lose패',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatMini('평균 득점', avgGf),
              _buildStatMini('평균 실점', avgGa),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMini(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: _textSecondary,
          ),
        ),
      ],
    );
  }

  // 3. 최근 폼 비교
  Widget _buildFormComparison(
    AsyncValue<List<ApiFootballFixture>> homeFormAsync,
    AsyncValue<List<ApiFootballFixture>> awayFormAsync,
    int homeTeamId,
    int awayTeamId,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // 홈팀 폼
          homeFormAsync.when(
            data: (fixtures) => _buildFormRow(match.homeTeam.name, fixtures, homeTeamId),
            loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const Text('로드 실패'),
          ),
          const SizedBox(height: 16),
          // 원정팀 폼
          awayFormAsync.when(
            data: (fixtures) => _buildFormRow(match.awayTeam.name, fixtures, awayTeamId),
            loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const Text('로드 실패'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormRow(String teamName, List<ApiFootballFixture> fixtures, int teamId) {
    final results = <String>[];
    int wins = 0, draws = 0, losses = 0;

    for (final f in fixtures.take(5)) {
      final isHome = f.homeTeam.id == teamId;
      final teamGoals = isHome ? (f.homeGoals ?? 0) : (f.awayGoals ?? 0);
      final oppGoals = isHome ? (f.awayGoals ?? 0) : (f.homeGoals ?? 0);

      if (teamGoals > oppGoals) {
        results.add('W');
        wins++;
      } else if (teamGoals < oppGoals) {
        results.add('L');
        losses++;
      } else {
        results.add('D');
        draws++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              teamName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            Text(
              '$wins승 $draws무 $losses패',
              style: const TextStyle(
                fontSize: 12,
                color: _textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: results.map((r) => _buildFormBadge(r)).toList(),
        ),
      ],
    );
  }

  Widget _buildFormBadge(String result) {
    Color bgColor;
    Color textColor = Colors.white;

    switch (result) {
      case 'W':
        bgColor = _success;
        break;
      case 'L':
        bgColor = _error;
        break;
      default:
        bgColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(right: 6),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          result,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 4. 득점/실점 통계
  Widget _buildGoalStatsComparison(
    AsyncValue<ApiFootballStanding?> homeAsync,
    AsyncValue<ApiFootballStanding?> awayAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: homeAsync.when(
        data: (homeSt) => awayAsync.when(
          data: (awaySt) {
            if (homeSt == null && awaySt == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('통계 정보가 없습니다', style: TextStyle(color: _textSecondary)),
                ),
              );
            }

            final homePlayed = homeSt?.played ?? 1;
            final awayPlayed = awaySt?.played ?? 1;
            final homeAvgGf = ((homeSt?.goalsFor ?? 0) / homePlayed).toStringAsFixed(1);
            final homeAvgGa = ((homeSt?.goalsAgainst ?? 0) / homePlayed).toStringAsFixed(1);
            final awayAvgGf = ((awaySt?.goalsFor ?? 0) / awayPlayed).toStringAsFixed(1);
            final awayAvgGa = ((awaySt?.goalsAgainst ?? 0) / awayPlayed).toStringAsFixed(1);

            return Column(
              children: [
                _buildCompareRow('총 득점', '${homeSt?.goalsFor ?? 0}', '${awaySt?.goalsFor ?? 0}',
                    homeBetter: (homeSt?.goalsFor ?? 0) > (awaySt?.goalsFor ?? 0)),
                _buildCompareRow('총 실점', '${homeSt?.goalsAgainst ?? 0}', '${awaySt?.goalsAgainst ?? 0}',
                    homeBetter: (homeSt?.goalsAgainst ?? 99) < (awaySt?.goalsAgainst ?? 99)),
                _buildCompareRow('경기당 득점', homeAvgGf, awayAvgGf,
                    homeBetter: double.parse(homeAvgGf) > double.parse(awayAvgGf)),
                _buildCompareRow('경기당 실점', homeAvgGa, awayAvgGa,
                    homeBetter: double.parse(homeAvgGa) < double.parse(awayAvgGa)),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('데이터 로드 실패'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Text('데이터 로드 실패'),
      ),
    );
  }

  // 5. 주요 선수 비교
  Widget _buildTopPlayersComparison(
    AsyncValue<List<ApiFootballTopScorer>> scorersAsync,
    AsyncValue<List<ApiFootballTopScorer>> assistsAsync,
    int homeTeamId,
    int awayTeamId,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: scorersAsync.when(
        data: (scorers) {
          final homeScorer = scorers.where((s) => s.teamId == homeTeamId).toList();
          final awayScorer = scorers.where((s) => s.teamId == awayTeamId).toList();

          return assistsAsync.when(
            data: (assists) {
              final homeAssist = assists.where((a) => a.teamId == homeTeamId).toList();
              final awayAssist = assists.where((a) => a.teamId == awayTeamId).toList();

              if (homeScorer.isEmpty && awayScorer.isEmpty && homeAssist.isEmpty && awayAssist.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('선수 통계 정보가 없습니다', style: TextStyle(color: _textSecondary)),
                  ),
                );
              }

              return Column(
                children: [
                  // 득점 리더
                  _buildPlayerCompareSection(
                    '득점 리더',
                    Icons.sports_soccer,
                    homeScorer.isNotEmpty ? homeScorer.first : null,
                    awayScorer.isNotEmpty ? awayScorer.first : null,
                    (p) => '${p.goals ?? 0}골',
                  ),
                  const SizedBox(height: 16),
                  // 도움 리더
                  _buildPlayerCompareSection(
                    '도움 리더',
                    Icons.handshake_outlined,
                    homeAssist.isNotEmpty ? homeAssist.first : null,
                    awayAssist.isNotEmpty ? awayAssist.first : null,
                    (p) => '${p.assists ?? 0}도움',
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('도움 데이터 로드 실패'),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('선수 통계를 불러올 수 없습니다', style: TextStyle(color: _textSecondary)),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCompareSection(
    String title,
    IconData icon,
    ApiFootballTopScorer? homePlayer,
    ApiFootballTopScorer? awayPlayer,
    String Function(ApiFootballTopScorer) statBuilder,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: _primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildPlayerCard(homePlayer, statBuilder)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('vs', style: TextStyle(color: _textSecondary)),
            ),
            Expanded(child: _buildPlayerCard(awayPlayer, statBuilder, isAway: true)),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayerCard(ApiFootballTopScorer? player, String Function(ApiFootballTopScorer) statBuilder, {bool isAway = false}) {
    if (player == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('-', style: TextStyle(color: _textSecondary)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: isAway ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isAway && player.playerPhoto != null)
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: player.playerPhoto!,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 36,
                  height: 36,
                  color: Colors.grey.shade200,
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 36,
                  height: 36,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.person, size: 20),
                ),
              ),
            ),
          if (!isAway) const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: isAway ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  player.playerName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  statBuilder(player),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
              ],
            ),
          ),
          if (isAway) const SizedBox(width: 8),
          if (isAway && player.playerPhoto != null)
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: player.playerPhoto!,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 36,
                  height: 36,
                  color: Colors.grey.shade200,
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 36,
                  height: 36,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.person, size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 5. 팀 스타일 비교 (레이더 차트)
  Widget _buildRadarChartComparison(
    AsyncValue<ApiFootballTeamSeasonStats?> homeStatsAsync,
    AsyncValue<ApiFootballTeamSeasonStats?> awayStatsAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: homeStatsAsync.when(
        data: (homeStats) => awayStatsAsync.when(
          data: (awayStats) {
            if (homeStats == null && awayStats == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('시즌 통계 정보가 없습니다', style: TextStyle(color: _textSecondary)),
                ),
              );
            }

            // 레이더 차트 데이터 계산 (0-100 스케일로 정규화)
            final homeData = _calculateRadarData(homeStats);
            final awayData = _calculateRadarData(awayStats);

            return Column(
              children: [
                // 범례
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(match.homeTeam.name, const Color(0xFF2563EB)),
                    const SizedBox(width: 24),
                    _buildLegendItem(match.awayTeam.name, const Color(0xFFEF4444)),
                  ],
                ),
                const SizedBox(height: 16),
                // 레이더 차트
                SizedBox(
                  height: 280,
                  child: RadarChart(
                    RadarChartData(
                      dataSets: [
                        RadarDataSet(
                          dataEntries: homeData.map((e) => RadarEntry(value: e)).toList(),
                          fillColor: const Color(0xFF2563EB).withOpacity(0.2),
                          borderColor: const Color(0xFF2563EB),
                          borderWidth: 2,
                          entryRadius: 3,
                        ),
                        RadarDataSet(
                          dataEntries: awayData.map((e) => RadarEntry(value: e)).toList(),
                          fillColor: const Color(0xFFEF4444).withOpacity(0.2),
                          borderColor: const Color(0xFFEF4444),
                          borderWidth: 2,
                          entryRadius: 3,
                        ),
                      ],
                      radarBackgroundColor: Colors.transparent,
                      borderData: FlBorderData(show: false),
                      radarBorderData: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                      titlePositionPercentageOffset: 0.2,
                      titleTextStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                      ),
                      getTitle: (index, angle) {
                        const titles = ['승률', '공격력', '수비력', '클린시트', '홈 성적'];
                        return RadarChartTitle(
                          text: titles[index],
                          angle: 0,
                        );
                      },
                      tickCount: 4,
                      ticksTextStyle: const TextStyle(
                        fontSize: 10,
                        color: _textSecondary,
                      ),
                      tickBorderData: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
                      gridBorderData: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 상세 수치
                _buildRadarStatsDetail(homeStats, awayStats),
              ],
            );
          },
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          )),
          error: (_, __) => const Text('데이터 로드 실패', style: TextStyle(color: _textSecondary)),
        ),
        loading: () => const Center(child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        )),
        error: (_, __) => const Text('데이터 로드 실패', style: TextStyle(color: _textSecondary)),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label.length > 10 ? '${label.substring(0, 10)}...' : label,
          style: const TextStyle(fontSize: 12, color: _textPrimary),
        ),
      ],
    );
  }

  List<double> _calculateRadarData(ApiFootballTeamSeasonStats? stats) {
    if (stats == null) return [0, 0, 0, 0, 0];

    final totalPlayed = stats.fixtures.played.total;
    if (totalPlayed == 0) return [0, 0, 0, 0, 0];

    // 1. 승률 (0-100)
    final winRate = (stats.fixtures.wins.total / totalPlayed) * 100;

    // 2. 공격력 (평균 득점 * 33, 최대 100) - 경기당 3골 이상이면 100
    final avgGoals = stats.goals.goalsFor.total / totalPlayed;
    final attackPower = math.min(avgGoals * 33, 100.0);

    // 3. 수비력 (100 - 평균 실점 * 33) - 실점이 적을수록 높음
    final avgConceded = stats.goals.goalsAgainst.total / totalPlayed;
    final defensePower = math.max(100 - (avgConceded * 33), 0.0);

    // 4. 클린시트 비율 (0-100)
    final cleanSheetRate = (stats.cleanSheet.total / totalPlayed) * 100;

    // 5. 홈 성적 (홈 승률 0-100)
    final homePlayed = stats.fixtures.played.home;
    final homeWinRate = homePlayed > 0
        ? (stats.fixtures.wins.home / homePlayed) * 100
        : 0.0;

    return [winRate, attackPower, defensePower, cleanSheetRate, homeWinRate];
  }

  Widget _buildRadarStatsDetail(
    ApiFootballTeamSeasonStats? homeStats,
    ApiFootballTeamSeasonStats? awayStats,
  ) {
    final homePlayed = homeStats?.fixtures.played.total ?? 0;
    final awayPlayed = awayStats?.fixtures.played.total ?? 0;

    return Column(
      children: [
        const Divider(height: 24),
        _buildCompareRow(
          '승률',
          homePlayed > 0
              ? '${((homeStats!.fixtures.wins.total / homePlayed) * 100).toStringAsFixed(1)}%'
              : '-',
          awayPlayed > 0
              ? '${((awayStats!.fixtures.wins.total / awayPlayed) * 100).toStringAsFixed(1)}%'
              : '-',
          homeBetter: homePlayed > 0 && awayPlayed > 0
              ? (homeStats!.fixtures.wins.total / homePlayed) > (awayStats!.fixtures.wins.total / awayPlayed)
              : null,
        ),
        _buildCompareRow(
          '평균 득점',
          homePlayed > 0
              ? (homeStats!.goals.goalsFor.total / homePlayed).toStringAsFixed(2)
              : '-',
          awayPlayed > 0
              ? (awayStats!.goals.goalsFor.total / awayPlayed).toStringAsFixed(2)
              : '-',
          homeBetter: homePlayed > 0 && awayPlayed > 0
              ? (homeStats!.goals.goalsFor.total / homePlayed) > (awayStats!.goals.goalsFor.total / awayPlayed)
              : null,
        ),
        _buildCompareRow(
          '평균 실점',
          homePlayed > 0
              ? (homeStats!.goals.goalsAgainst.total / homePlayed).toStringAsFixed(2)
              : '-',
          awayPlayed > 0
              ? (awayStats!.goals.goalsAgainst.total / awayPlayed).toStringAsFixed(2)
              : '-',
          homeBetter: homePlayed > 0 && awayPlayed > 0
              ? (homeStats!.goals.goalsAgainst.total / homePlayed) < (awayStats!.goals.goalsAgainst.total / awayPlayed)
              : null,
        ),
        _buildCompareRow(
          '클린시트',
          '${homeStats?.cleanSheet.total ?? 0}회',
          '${awayStats?.cleanSheet.total ?? 0}회',
          homeBetter: (homeStats?.cleanSheet.total ?? 0) > (awayStats?.cleanSheet.total ?? 0),
        ),
        _buildCompareRow(
          '무득점 경기',
          '${homeStats?.failedToScore.total ?? 0}회',
          '${awayStats?.failedToScore.total ?? 0}회',
          homeBetter: (homeStats?.failedToScore.total ?? 0) < (awayStats?.failedToScore.total ?? 0),
        ),
      ],
    );
  }

  // 7. 상대전적 요약
  Widget _buildH2HSummary(
    AsyncValue<List<ApiFootballFixture>> h2hAsync,
    int homeTeamId,
    int awayTeamId,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: h2hAsync.when(
        data: (fixtures) {
          if (fixtures.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('상대전적 정보가 없습니다', style: TextStyle(color: _textSecondary)),
              ),
            );
          }

          int homeWins = 0, draws = 0, awayWins = 0;

          // 최근 10경기만 사용
          final recentFixtures = fixtures.take(10).toList();

          for (final f in recentFixtures) {
            final hGoals = f.homeGoals ?? 0;
            final aGoals = f.awayGoals ?? 0;
            final isHomeTeamHome = f.homeTeam.id == homeTeamId;

            if (hGoals == aGoals) {
              draws++;
            } else if (hGoals > aGoals) {
              if (isHomeTeamHome) {
                homeWins++;
              } else {
                awayWins++;
              }
            } else {
              if (isHomeTeamHome) {
                awayWins++;
              } else {
                homeWins++;
              }
            }
          }

          final total = recentFixtures.length;

          return Column(
            children: [
              Text(
                '최근 $total경기 상대전적',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              // 승리 바
              _buildH2HBar(homeWins, draws, awayWins, total),
              const SizedBox(height: 16),
              // 숫자 표시
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildH2HStat(match.homeTeam.name, homeWins, _primary),
                  _buildH2HStat('무승부', draws, Colors.grey),
                  _buildH2HStat(match.awayTeam.name, awayWins, _warning),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Text('상대전적 로드 실패', style: TextStyle(color: _textSecondary)),
      ),
    );
  }

  Widget _buildH2HBar(int homeWins, int draws, int awayWins, int total) {
    if (total == 0) return const SizedBox.shrink();

    return Container(
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade200,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            if (homeWins > 0)
              Expanded(
                flex: homeWins,
                child: Container(
                  color: _primary,
                  child: Center(
                    child: Text(
                      '$homeWins',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            if (draws > 0)
              Expanded(
                flex: draws,
                child: Container(
                  color: Colors.grey.shade400,
                  child: Center(
                    child: Text(
                      '$draws',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            if (awayWins > 0)
              Expanded(
                flex: awayWins,
                child: Container(
                  color: _warning,
                  child: Center(
                    child: Text(
                      '$awayWins',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildH2HStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value승',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ============ H2H Tab ============
class _H2HTab extends ConsumerWidget {
  final ApiFootballFixture match;

  static const _success = Color(0xFF10B981);
  static const _error = Color(0xFFEF4444);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _H2HTab({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeTeamId = match.homeTeam.id;
    final awayTeamId = match.awayTeam.id;

    final h2hAsync = ref.watch(matchH2HProvider((homeTeamId: homeTeamId, awayTeamId: awayTeamId)));

    return h2hAsync.when(
      data: (fixtures) {
        if (fixtures.isEmpty) {
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

        // 최근 10경기로 제한하여 통계 계산
        final recentFixtures = fixtures.take(10).toList();
        int homeWins = 0;
        int awayWins = 0;
        int draws = 0;
        int homeGoals = 0;
        int awayGoals = 0;

        for (final fixture in recentFixtures) {
          final hScore = fixture.homeGoals ?? 0;
          final aScore = fixture.awayGoals ?? 0;

          // 홈팀이 현재 경기의 홈팀인 경우
          if (fixture.homeTeam.id == homeTeamId) {
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
            // 홈팀이 현재 경기의 원정팀인 경우
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
              // 상대전적 요약
              _buildSummaryCard(homeWins, draws, awayWins, homeGoals, awayGoals, recentFixtures.length),
              const SizedBox(height: 16),

              // 최근 경기 목록
              Text(
                '최근 ${recentFixtures.length}경기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...recentFixtures.map((fixture) => _buildMatchCard(context, fixture)),
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
          // 팀 뱃지와 승/무/패
          Row(
            children: [
              // 홈팀
              Expanded(
                child: Column(
                  children: [
                    if (match.homeTeam.logo != null)
                      CachedNetworkImage(
                        imageUrl: match.homeTeam.logo!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => Icon(Icons.shield, size: 48, color: _textSecondary),
                      )
                    else
                      Icon(Icons.shield, size: 48, color: _textSecondary),
                    const SizedBox(height: 8),
                    Text(
                      match.homeTeam.name,
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

              // 전적
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

              // 원정팀
              Expanded(
                child: Column(
                  children: [
                    if (match.awayTeam.logo != null)
                      CachedNetworkImage(
                        imageUrl: match.awayTeam.logo!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => Icon(Icons.shield, size: 48, color: _textSecondary),
                      )
                    else
                      Icon(Icons.shield, size: 48, color: _textSecondary),
                    const SizedBox(height: 8),
                    Text(
                      match.awayTeam.name,
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

          // 승률 바
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

          // 승률 퍼센트
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

  Widget _buildMatchCard(BuildContext context, ApiFootballFixture fixture) {
    final dateStr = DateFormat('yyyy.MM.dd').format(fixture.dateKST);

    final homeScore = fixture.homeGoals ?? 0;
    final awayScore = fixture.awayGoals ?? 0;

    // 현재 경기의 홈팀 기준 결과
    String result;
    Color resultColor;
    if (fixture.homeTeam.id == match.homeTeam.id) {
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
      onTap: () => context.push('/match/${fixture.id}'),
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
            // 결과 뱃지
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

            // 경기 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${fixture.homeTeam.name} $homeScore - $awayScore ${fixture.awayTeam.name}',
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
                    '$dateStr · ${fixture.league.name}',
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
            Icon(Icons.chevron_right, size: 16, color: _textSecondary),
          ],
        ),
      ),
    );
  }
}

// ============ Comments Tab ============
class _CommentsTab extends StatefulWidget {
  final String matchId;

  const _CommentsTab({required this.matchId});

  @override
  State<_CommentsTab> createState() => _CommentsTabState();
}

class _CommentsTabState extends State<_CommentsTab> {
  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  final MatchCommentService _commentService = MatchCommentService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;

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
          SnackBar(content: Text('댓글 작성 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _deleteComment(MatchComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('이 댓글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _commentService.deleteComment(comment.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('댓글이 삭제되었습니다')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제 실패: $e')),
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
              const Text(
                '실시간 댓글',
                style: TextStyle(
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
                    const SnackBar(
                      content: Text('댓글을 새로고침했습니다'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('새로고침'),
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
                        '댓글을 불러올 수 없습니다',
                        style: TextStyle(color: _textSecondary),
                      ),
                    ],
                  ),
                );
              }

              final comments = snapshot.data ?? [];

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
                      const Text(
                        '아직 댓글이 없습니다',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '첫 댓글을 남겨보세요!',
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
                  return _CommentItem(
                    comment: comment,
                    onDelete: () => _deleteComment(comment),
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
                    hintText: '댓글을 입력하세요...',
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

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _CommentItem({
    required this.comment,
    required this.onDelete,
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
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('삭제', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                onDelete();
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
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
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
  final String Function(String) getBetKoreanName;

  const _AllBetsModalContent({
    required this.allBets,
    required this.groupedBets,
    required this.getCategoryInfo,
    required this.getBetKoreanName,
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
    _categories = ['전체', ...widget.groupedBets.keys];
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
                  const Text(
                    '실시간 배당률',
                    style: TextStyle(
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
                  final info = cat == '전체'
                      ? {'icon': Icons.grid_view_rounded, 'color': _primary}
                      : widget.getCategoryInfo(cat);
                  final count = cat == '전체'
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
                              cat,
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
    final bets = cat == '전체'
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
              '해당 카테고리에 배팅이 없습니다',
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
        return _buildBetCard(bet, index);
      },
    );
  }

  Widget _buildBetCard(ApiFootballLiveOddsBet bet, int index) {
    final koreanName = widget.getBetKoreanName(bet.name);
    final cat = _categories[_selectedIndex];
    final info = cat == '전체'
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
                        koreanName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      if (koreanName != bet.name)
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
