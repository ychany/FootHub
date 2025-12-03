import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/sports_db_service.dart';
import '../../../shared/widgets/loading_indicator.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
                  Tab(text: '통계'),
                  Tab(text: '타임라인'),
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
                const SizedBox(width: 48),
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
                            color: _textPrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            match.scoreDisplay,
                            style: const TextStyle(
                              color: Colors.white,
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: timeline.length,
          itemBuilder: (context, index) {
            return _TimelineItem(event: timeline[index]);
          },
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

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _TimelineItem({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          // Time
          Container(
            width: 40,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              event.time ?? '',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(width: 12),

          // Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getEventColor().withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getEventIcon(),
              size: 16,
              color: _getEventColor(),
            ),
          ),

          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.player ?? event.type ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                  ),
                ),
                if (event.detail != null)
                  Text(
                    event.detail!,
                    style: TextStyle(
                      fontSize: 11,
                      color: _textSecondary,
                    ),
                  ),
                Text(
                  event.team ?? (event.isHome ? '홈' : '원정'),
                  style: TextStyle(
                    fontSize: 11,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEventIcon() {
    switch (event.type?.toLowerCase()) {
      case 'goal':
        return Icons.sports_soccer;
      case 'yellow card':
        return Icons.square;
      case 'red card':
        return Icons.square;
      case 'substitution':
        return Icons.swap_horiz;
      default:
        return Icons.circle;
    }
  }

  Color _getEventColor() {
    switch (event.type?.toLowerCase()) {
      case 'goal':
        return Colors.green;
      case 'yellow card':
        return Colors.amber;
      case 'red card':
        return Colors.red;
      case 'substitution':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
