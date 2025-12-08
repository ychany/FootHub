import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/sports_db_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/schedule_provider.dart';

// Provider for match detail
final matchDetailProvider =
    FutureProvider.family<SportsDbEvent?, String>((ref, eventId) async {
  final service = SportsDbService();
  return service.getEventById(eventId);
});

// Provider for lineup
final matchLineupProvider =
    FutureProvider.family<SportsDbLineup?, String>((ref, eventId) async {
  final service = SportsDbService();
  return service.getEventLineup(eventId);
});

// Provider for stats
final matchStatsProvider =
    FutureProvider.family<SportsDbEventStats?, String>((ref, eventId) async {
  final service = SportsDbService();
  return service.getEventStats(eventId);
});

// Provider for timeline
final matchTimelineProvider =
    FutureProvider.family<List<SportsDbTimeline>, String>((ref, eventId) async {
  final service = SportsDbService();
  return service.getEventTimeline(eventId);
});

// Provider for head to head
final matchH2HProvider =
    FutureProvider.family<List<SportsDbEvent>, ({String homeTeam, String awayTeam})>((ref, params) async {
  final service = SportsDbService();
  return service.getHeadToHead(params.homeTeam, params.awayTeam);
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
  final SportsDbEvent match;

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
    _tabController = TabController(length: 5, vsync: this);
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
      floatingActionButton: FloatingActionButton.extended(
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
                ],
              ),
            ),

            // 탭 컨텐츠
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _InfoTab(match: match),
                  _LineupTab(eventId: match.id, match: match),
                  _StatsTab(eventId: match.id, match: match),
                  _TimelineTab(eventId: match.id),
                  _H2HTab(match: match),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SportsDbEvent match) {
    final dateTime = match.dateTime;
    final dateStr = dateTime != null
        ? DateFormat('yyyy.MM.dd (E) HH:mm', 'ko').format(dateTime)
        : '날짜 미정';

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
                    match.league ?? '경기 상세',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                _NotificationButton(matchId: match.id, match: match),
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
                    onTap: match.homeTeamId != null
                        ? () => context.push('/team/${match.homeTeamId}')
                        : null,
                    child: Column(
                      children: [
                        _buildTeamLogo(match.homeTeamBadge, 56),
                        const SizedBox(height: 8),
                        Text(
                          match.homeTeam ?? '',
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
                  child: match.isFinished
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
                    onTap: match.awayTeamId != null
                        ? () => context.push('/team/${match.awayTeamId}')
                        : null,
                    child: Column(
                      children: [
                        _buildTeamLogo(match.awayTeamBadge, 56),
                        const SizedBox(height: 8),
                        Text(
                          match.awayTeam ?? '',
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
                    match.venue!,
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
  final SportsDbEvent match;

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
              _InfoRow(label: '리그', value: match.league ?? '-'),
              _InfoRow(label: '시즌', value: match.season ?? '-'),
              _InfoRow(
                label: '날짜',
                value: match.dateTime != null
                    ? DateFormat('yyyy년 MM월 dd일 (E)', 'ko')
                        .format(match.dateTime!)
                    : '-',
              ),
              _InfoRow(
                label: '시간',
                value: match.dateTime != null
                    ? DateFormat('HH:mm').format(match.dateTime!)
                    : '-',
              ),
              _InfoRow(label: '경기장', value: match.venue ?? '-'),
              if (match.status != null)
                _InfoRow(label: '상태', value: _getStatusText(match.status)),
            ],
          ),
        ),
      ],
    );
  }

  String _getStatusText(String? status) {
    switch (status?.toUpperCase()) {
      case 'FT':
        return '경기 종료';
      case 'HT':
        return '하프타임';
      case 'LIVE':
      case '1H':
      case '2H':
        return '진행 중';
      case 'PST':
      case 'POSTP':
        return '연기';
      case 'CANC':
        return '취소';
      default:
        return status ?? '예정';
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
  final String eventId;
  final SportsDbEvent match;

  static const _textSecondary = Color(0xFF6B7280);

  const _LineupTab({required this.eventId, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineupAsync = ref.watch(matchLineupProvider(eventId));

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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Home Team
              Expanded(
                child: _TeamLineup(
                  teamName: match.homeTeam ?? '홈',
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
                  teamName: match.awayTeam ?? '원정',
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
      error: (e, _) => Center(
        child: Text('오류: $e', style: const TextStyle(color: _textSecondary)),
      ),
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
  final SportsDbLineupPlayer player;
  final bool isSubstitute;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _PlayerRow({required this.player, this.isSubstitute = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:
          player.id.isNotEmpty ? () => _showPlayerDetail(context, player) : null,
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
                player.number ?? '-',
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
            if (player.position != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPositionColor(player.position!).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getPositionShort(player.position!),
                  style: TextStyle(
                    color: _getPositionColor(player.position!),
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

  void _showPlayerDetail(BuildContext context, SportsDbLineupPlayer player) {
    context.push('/player/${player.id}');
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

// ============ Stats Tab ============
class _StatsTab extends ConsumerWidget {
  final String eventId;
  final SportsDbEvent match;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _StatsTab({required this.eventId, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(matchStatsProvider(eventId));

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
                    color: _textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

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
                            match.homeTeam ?? '',
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
                            match.awayTeam ?? '',
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
  final String eventId;

  static const _textSecondary = Color(0xFF6B7280);

  const _TimelineTab({required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(matchTimelineProvider(eventId));

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
      error: (e, _) => Center(
        child: Text('오류: $e', style: const TextStyle(color: _textSecondary)),
      ),
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
        return Icons.style; // 카드 아이콘
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
        return const Color(0xFF10B981); // 초록색
      case 'card':
        if (event.detail?.toLowerCase().contains('red') == true) {
          return const Color(0xFFEF4444); // 빨간색
        }
        return const Color(0xFFF59E0B); // 노란색
      case 'subst':
        return const Color(0xFF3B82F6); // 파란색
      case 'var':
        return const Color(0xFF8B5CF6); // 보라색
      default:
        return const Color(0xFF6B7280); // 회색
    }
  }
}

// ============ Notification Button ============
class _NotificationButton extends ConsumerWidget {
  final String matchId;
  final SportsDbEvent match;

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
  final SportsDbEvent match;

  const _MatchNotificationDialog({required this.matchId, required this.match});

  @override
  ConsumerState<_MatchNotificationDialog> createState() => _MatchNotificationDialogState();
}

class _MatchNotificationDialogState extends ConsumerState<_MatchNotificationDialog> {
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
            '${widget.match.homeTeam ?? ''} vs ${widget.match.awayTeam ?? ''}',
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
    // 알림이 하나라도 켜져 있으면 저장, 아니면 삭제
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
      // 모든 알림이 꺼져 있으면 기존 설정 삭제
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
  final SportsDbEvent match;

  static const _success = Color(0xFF10B981);
  static const _error = Color(0xFFEF4444);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _H2HTab({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeTeam = match.homeTeam ?? '';
    final awayTeam = match.awayTeam ?? '';

    if (homeTeam.isEmpty || awayTeam.isEmpty) {
      return Center(
        child: Text(
          '팀 정보가 없습니다',
          style: TextStyle(color: _textSecondary),
        ),
      );
    }

    final h2hAsync = ref.watch(matchH2HProvider((homeTeam: homeTeam, awayTeam: awayTeam)));

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

          // 홈팀이 현재 경기의 홈팀인 경우
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
              _buildSummaryCard(homeWins, draws, awayWins, homeGoals, awayGoals, events.length),
              const SizedBox(height: 16),

              // 최근 경기 목록
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
          // 팀 뱃지와 승/무/패
          Row(
            children: [
              // 홈팀
              Expanded(
                child: Column(
                  children: [
                    if (match.homeTeamBadge != null)
                      CachedNetworkImage(
                        imageUrl: match.homeTeamBadge!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => Icon(Icons.shield, size: 48, color: _textSecondary),
                      )
                    else
                      Icon(Icons.shield, size: 48, color: _textSecondary),
                    const SizedBox(height: 8),
                    Text(
                      match.homeTeam ?? '',
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
                    if (match.awayTeamBadge != null)
                      CachedNetworkImage(
                        imageUrl: match.awayTeamBadge!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => Icon(Icons.shield, size: 48, color: _textSecondary),
                      )
                    else
                      Icon(Icons.shield, size: 48, color: _textSecondary),
                    const SizedBox(height: 8),
                    Text(
                      match.awayTeam ?? '',
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

  Widget _buildMatchCard(BuildContext context, SportsDbEvent event) {
    final dateStr = event.dateTime != null
        ? DateFormat('yyyy.MM.dd').format(event.dateTime!)
        : '-';

    final homeScore = event.homeScore ?? 0;
    final awayScore = event.awayScore ?? 0;

    // 현재 경기의 홈팀 기준 결과
    String result;
    Color resultColor;
    if (event.homeTeam?.toLowerCase() == match.homeTeam?.toLowerCase()) {
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
            Icon(Icons.chevron_right, size: 16, color: _textSecondary),
          ],
        ),
      ),
    );
  }
}
