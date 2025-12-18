import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/api_football_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/schedule_provider.dart';
import '../models/match_comment.dart';
import '../services/match_comment_service.dart';

// Provider for match detail (API-Football)
final matchDetailProvider =
    FutureProvider.family<ApiFootballFixture?, String>((ref, fixtureId) async {
  final service = ApiFootballService();
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
  return service.getHeadToHead(params.homeTeamId, params.awayTeamId);
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
                  Tab(text: '정보'),
                  Tab(text: '라인업'),
                  Tab(text: '기록'),
                  Tab(text: '중계'),
                  Tab(text: '전적'),
                  Tab(text: '댓글'),
                ],
              ),
            ),

            // 탭 컨텐츠
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _InfoTab(match: match),
                  _LineupTab(fixtureId: match.id.toString(), match: match),
                  _StatsTab(fixtureId: match.id.toString(), match: match),
                  _TimelineTab(fixtureId: match.id.toString(), match: match),
                  _H2HTab(match: match),
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
                _NotificationButton(matchId: match.id.toString(), match: match),
              ],
            ),
          ),

          // 날짜
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
                            color: _primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            match.scoreDisplay,
                            style: const TextStyle(
                              color: _primary,
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

          // 경기장
          if (match.venue != null)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stadium_outlined, size: 14, color: _textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    match.venue!.name ?? '',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 16),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Match Info Card
        Container(
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
        ),
      ],
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

// ============ Lineup Tab ============
class _LineupTab extends ConsumerWidget {
  final String fixtureId;
  final ApiFootballFixture match;

  static const _textSecondary = Color(0xFF6B7280);

  const _LineupTab({required this.fixtureId, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineupAsync = ref.watch(matchLineupProvider(fixtureId));

    return lineupAsync.when(
      data: (lineups) {
        if (lineups.isEmpty) {
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
                      Icon(Icons.people_outline, size: 48, color: _textSecondary),
                ),
                const SizedBox(height: 16),
                const Text(
                  '라인업 정보가 없습니다',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '경기 종료 후 업데이트됩니다',
                  style: TextStyle(
                    color: _textSecondary.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        // API-Football returns list of lineups (home, away)
        final homeLineup = lineups.isNotEmpty ? lineups.first : null;
        final awayLineup = lineups.length > 1 ? lineups[1] : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Home Team
              Expanded(
                child: _TeamLineup(
                  teamName: homeLineup?.teamName ?? match.homeTeam.name,
                  formation: homeLineup?.formation,
                  players: homeLineup?.startXI ?? [],
                  substitutes: homeLineup?.substitutes ?? [],
                  isHome: true,
                ),
              ),
              const SizedBox(width: 12),
              // Away Team
              Expanded(
                child: _TeamLineup(
                  teamName: awayLineup?.teamName ?? match.awayTeam.name,
                  formation: awayLineup?.formation,
                  players: awayLineup?.startXI ?? [],
                  substitutes: awayLineup?.substitutes ?? [],
                  isHome: false,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(
        child: Text('오류: $e', style: const TextStyle(color: _textSecondary)),
      ),
    );
  }
}

class _TeamLineup extends StatelessWidget {
  final String teamName;
  final String? formation;
  final List<ApiFootballLineupPlayer> players;
  final List<ApiFootballLineupPlayer> substitutes;
  final bool isHome;

  static const _primary = Color(0xFF2563EB);
  static const _secondary = Color(0xFF8B5CF6);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
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
                  color: isHome ? _primary : _secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  teamName,
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
          if (formation != null) ...[
            const SizedBox(height: 4),
            Text(
              formation!,
              style: const TextStyle(
                fontSize: 12,
                color: _textSecondary,
              ),
            ),
          ],
          const Divider(height: 16),

          // Starting XI
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_soccer, size: 12, color: _primary),
                const SizedBox(width: 4),
                Text(
                  '선발 (${players.length})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _primary,
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz, size: 12, color: _textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '교체 (${substitutes.length})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary,
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
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final ApiFootballLineupPlayer player;
  final bool isSubstitute;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _PlayerRow({required this.player, this.isSubstitute = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: player.id > 0 ? () => _showPlayerDetail(context, player) : null,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            // Squad Number
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSubstitute
                    ? Colors.grey.shade200
                    : _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                player.number?.toString() ?? '-',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSubstitute ? _textSecondary : _primary,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Player Name
            Expanded(
              child: Text(
                player.name,
                style: TextStyle(
                  color: isSubstitute ? _textSecondary : _textPrimary,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Position Badge
            if (player.pos != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPositionColor(player.pos!).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  player.pos!,
                  style: TextStyle(
                    color: _getPositionColor(player.pos!),
                    fontWeight: FontWeight.w600,
                    fontSize: 9,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPlayerDetail(BuildContext context, ApiFootballLineupPlayer player) {
    context.push('/player/${player.id}');
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

// ============ Stats Tab ============
class _StatsTab extends ConsumerWidget {
  final String fixtureId;
  final ApiFootballFixture match;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _StatsTab({required this.fixtureId, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(matchStatsProvider(fixtureId));

    return statsAsync.when(
      data: (statsList) {
        if (statsList.isEmpty) {
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
                    color: _textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        // API-Football returns stats per team
        final homeStats = statsList.isNotEmpty ? statsList.first : null;
        final awayStats = statsList.length > 1 ? statsList[1] : null;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
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

                  // Stats rows using API-Football format
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
            ),
          ],
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(
        child: Text('오류: $e', style: const TextStyle(color: _textSecondary)),
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

// ============ Timeline Tab ============
class _TimelineTab extends ConsumerWidget {
  final String fixtureId;
  final ApiFootballFixture match;

  static const _textSecondary = Color(0xFF6B7280);

  const _TimelineTab({required this.fixtureId, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(matchTimelineProvider(fixtureId));

    return timelineAsync.when(
      data: (events) {
        if (events.isEmpty) {
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
                  child: Icon(Icons.timeline, size: 48, color: _textSecondary),
                ),
                const SizedBox(height: 16),
                const Text(
                  '타임라인 정보가 없습니다',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
          color: Colors.white,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: sortedEvents.length,
            itemBuilder: (context, index) {
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
            },
          ),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(
        child: Text('오류: $e', style: const TextStyle(color: _textSecondary)),
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
