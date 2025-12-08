import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/sports_db_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/team_provider.dart';
import '../../favorites/providers/favorites_provider.dart';

class TeamDetailScreen extends ConsumerWidget {
  final String teamId;

  static const _textSecondary = Color(0xFF6B7280);
  static const _background = Color(0xFFF9FAFB);

  const TeamDetailScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamInfoProvider(teamId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: teamAsync.when(
          data: (team) {
            if (team == null) {
              return SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(context),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined,
                                size: 64, color: _textSecondary),
                            const SizedBox(height: 16),
                            Text(
                              '팀 정보를 찾을 수 없습니다',
                              style:
                                  TextStyle(color: _textSecondary, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return _TeamDetailContent(team: team);
          },
          loading: () => const LoadingIndicator(),
          error: (e, _) => SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: Center(
                    child: Text('오류: $e',
                        style: const TextStyle(color: _textSecondary)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            color: const Color(0xFF111827),
            onPressed: () => context.pop(),
          ),
          const Expanded(
            child: Text(
              '팀 정보',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _TeamDetailContent extends ConsumerStatefulWidget {
  final SportsDbTeam team;

  const _TeamDetailContent({required this.team});

  @override
  ConsumerState<_TeamDetailContent> createState() => _TeamDetailContentState();
}

class _TeamDetailContentState extends ConsumerState<_TeamDetailContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _background = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final team = widget.team;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            _buildHeader(context, team),

            // 탭바
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: _primary,
                unselectedLabelColor: _textSecondary,
                indicatorColor: _primary,
                indicatorWeight: 2,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: '정보'),
                  Tab(text: '일정'),
                  Tab(text: '선수단'),
                ],
              ),
            ),

            // 탭 내용
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _InfoTab(team: team),
                  _ScheduleTab(teamId: team.id),
                  _PlayersTab(teamId: team.id),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SportsDbTeam team) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 앱바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  color: _textPrimary,
                  onPressed: () => context.pop(),
                ),
                const Expanded(
                  child: Text(
                    '팀 정보',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                _FavoriteButton(teamId: team.id),
              ],
            ),
          ),

          // 팀 뱃지
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _border, width: 3),
              color: Colors.grey.shade100,
            ),
            child: ClipOval(
              child: team.badge != null
                  ? CachedNetworkImage(
                      imageUrl: team.badge!,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => Icon(
                        Icons.shield,
                        size: 40,
                        color: _textSecondary,
                      ),
                      errorWidget: (_, __, ___) => Icon(
                        Icons.shield,
                        size: 40,
                        color: _textSecondary,
                      ),
                    )
                  : Icon(
                      Icons.shield,
                      size: 40,
                      color: _textSecondary,
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // 팀 이름
          Text(
            team.name,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // 리그 & 국가 (국가대표 팀은 리그 표시 안함)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (team.league != null && team.league != 'FIFA World Cup') ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    team.league!,
                    style: TextStyle(
                      color: _primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (team.country != null) const SizedBox(width: 8),
              ],
              if (team.country != null)
                Text(
                  team.country!,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ============ Info Tab ============
class _InfoTab extends StatelessWidget {
  final SportsDbTeam team;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _InfoTab({required this.team});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Basic Info Card
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
                    '기본 정보',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 국가대표 팀은 리그 표시 안함
              if (team.league != null && team.league != 'FIFA World Cup')
                _InfoRow(
                    icon: Icons.sports_soccer_outlined,
                    label: '리그',
                    value: team.league!),
              _InfoRow(
                  icon: Icons.flag_outlined,
                  label: '국가',
                  value: team.country ?? '-'),
              _InfoRow(
                  icon: Icons.stadium_outlined,
                  label: '경기장',
                  value: team.stadium ?? '-'),
              if (team.stadiumCapacity != null)
                _InfoRow(
                    icon: Icons.people_outline,
                    label: '수용 인원',
                    value: '${team.stadiumCapacity}명'),
            ],
          ),
        ),

        // Description
        if (team.description != null) ...[
          const SizedBox(height: 12),
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
                      child: Icon(Icons.description_outlined,
                          color: _primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '소개',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  team.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _textSecondary,
                    height: 1.6,
                  ),
                  maxLines: 15,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
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

// ============ Schedule Tab ============
class _ScheduleTab extends ConsumerWidget {
  final String teamId;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _ScheduleTab({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(teamFullScheduleProvider(teamId));

    return scheduleAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 48, color: _textSecondary),
                const SizedBox(height: 12),
                Text(
                  '일정이 없습니다',
                  style: TextStyle(color: _textSecondary, fontSize: 14),
                ),
              ],
            ),
          );
        }

        // 날짜순 정렬 (최신순)
        final sortedEvents = List<SportsDbEvent>.from(events)
          ..sort((a, b) {
            final aDate = a.dateTime ?? DateTime(1900);
            final bDate = b.dateTime ?? DateTime(1900);
            return bDate.compareTo(aDate); // 최신순
          });

        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);

        // 지난 경기, 예정된 경기 분리
        final pastEvents = sortedEvents.where((e) {
          final dt = e.dateTime;
          return dt != null && dt.isBefore(todayStart);
        }).toList();

        final upcomingEvents = sortedEvents.where((e) {
          final dt = e.dateTime;
          return dt != null && !dt.isBefore(todayStart);
        }).toList()
          ..sort((a, b) {
            // 예정된 경기는 가까운 순서로
            final aDate = a.dateTime ?? DateTime(2100);
            final bDate = b.dateTime ?? DateTime(2100);
            return aDate.compareTo(bDate);
          });

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Upcoming Matches
            if (upcomingEvents.isNotEmpty) ...[
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
                          child: Icon(Icons.event_outlined, color: _primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '예정된 경기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${upcomingEvents.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...upcomingEvents.map((e) => _MatchCard(event: e)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Past Matches
            if (pastEvents.isNotEmpty)
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
                            color: _textSecondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.history, color: _textSecondary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '지난 경기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _textSecondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${pastEvents.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...pastEvents.map((e) => _MatchCard(event: e, isPast: true)),
                  ],
                ),
              ),
          ],
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: _textSecondary),
            const SizedBox(height: 12),
            Text('오류: $e', style: TextStyle(color: _textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final SportsDbEvent event;
  final bool isPast;

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _MatchCard({required this.event, this.isPast = false});

  @override
  Widget build(BuildContext context) {
    final dateTime = event.dateTime;
    final dateStr = dateTime != null
        ? DateFormat('MM/dd (E)', 'ko').format(dateTime)
        : event.date ?? '-';
    final timeStr = dateTime != null
        ? DateFormat('HH:mm').format(dateTime)
        : event.time ?? '-';

    return GestureDetector(
      onTap: () => context.push('/match/${event.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPast ? Colors.grey.shade50 : _primaryLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isPast ? _border : _primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            // Date & League
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$dateStr $timeStr',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isPast ? _textSecondary : _primary,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPast
                        ? Colors.grey.shade200
                        : _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    event.league ?? '-',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isPast ? _textSecondary : _primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Teams & Score
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildTeamBadge(event.homeTeamBadge, 28),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.homeTeam ?? '-',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: event.isFinished
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _textPrimary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.scoreDisplay,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'VS',
                          style: TextStyle(
                            fontSize: 13,
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
                          event.awayTeam ?? '-',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _textPrimary,
                          ),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildTeamBadge(event.awayTeamBadge, 28),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamBadge(String? badgeUrl, double size) {
    if (badgeUrl != null && badgeUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: badgeUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholder: (_, __) =>
            Icon(Icons.shield, size: size, color: _textSecondary),
        errorWidget: (_, __, ___) =>
            Icon(Icons.shield, size: size, color: _textSecondary),
      );
    }
    return Icon(Icons.shield, size: size, color: _textSecondary);
  }
}

// ============ Players Tab ============
class _PlayersTab extends ConsumerWidget {
  final String teamId;

  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _PlayersTab({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(teamPlayersProvider(teamId));

    return playersAsync.when(
      data: (players) {
        if (players.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 48, color: _textSecondary),
                const SizedBox(height: 12),
                Text(
                  '선수 정보가 없습니다',
                  style: TextStyle(color: _textSecondary, fontSize: 14),
                ),
              ],
            ),
          );
        }

        // 포지션별 그룹화
        final grouped = <String, List<SportsDbPlayer>>{};
        for (final player in players) {
          final position = player.position ?? '기타';
          grouped.putIfAbsent(position, () => []).add(player);
        }

        final positionOrder = ['Goalkeeper', 'Defender', 'Midfielder', 'Forward'];
        final sortedKeys = grouped.keys.toList()
          ..sort((a, b) {
            final aIndex = positionOrder.indexOf(a);
            final bIndex = positionOrder.indexOf(b);
            if (aIndex == -1 && bIndex == -1) return a.compareTo(b);
            if (aIndex == -1) return 1;
            if (bIndex == -1) return -1;
            return aIndex.compareTo(bIndex);
          });

        return ListView(
          padding: const EdgeInsets.all(16),
          children: sortedKeys.map((position) {
            final positionPlayers = grouped[position]!;
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
                  // Position Header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getPositionColor(position).withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(11)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _getPositionColor(position),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _getPositionKr(position),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getPositionColor(position),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPositionColor(position)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${positionPlayers.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getPositionColor(position),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Players List
                  ...positionPlayers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final player = entry.value;
                    return Column(
                      children: [
                        if (index > 0)
                          Divider(height: 1, color: _border, indent: 16, endIndent: 16),
                        _PlayerCard(player: player),
                      ],
                    );
                  }),
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(
        child: Text('오류: $e', style: TextStyle(color: _textSecondary)),
      ),
    );
  }

  String _getPositionKr(String position) {
    switch (position.toLowerCase()) {
      case 'goalkeeper':
        return '골키퍼';
      case 'defender':
        return '수비수';
      case 'midfielder':
        return '미드필더';
      case 'forward':
        return '공격수';
      default:
        return position;
    }
  }

  Color _getPositionColor(String position) {
    switch (position.toLowerCase()) {
      case 'goalkeeper':
        return const Color(0xFFF59E0B); // warning/orange
      case 'defender':
        return const Color(0xFF2563EB); // primary/blue
      case 'midfielder':
        return const Color(0xFF10B981); // success/green
      case 'forward':
        return const Color(0xFFEF4444); // error/red
      default:
        return const Color(0xFF6B7280); // secondary/grey
    }
  }
}

class _PlayerCard extends StatelessWidget {
  final SportsDbPlayer player;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _PlayerCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/player/${player.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Player Photo
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipOval(
                child: player.thumb != null
                    ? CachedNetworkImage(
                        imageUrl: player.thumb!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Center(
                          child: Text(
                            player.name.isNotEmpty ? player.name[0] : '?',
                            style: TextStyle(
                              color: _textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Center(
                          child: Text(
                            player.name.isNotEmpty ? player.name[0] : '?',
                            style: TextStyle(
                              color: _textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          player.name.isNotEmpty ? player.name[0] : '?',
                          style: TextStyle(
                            color: _textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Player Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary,
                    ),
                  ),
                  if (player.nationality != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      player.nationality!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Number
            if (player.number != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            Icon(Icons.chevron_right, color: _textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  final String teamId;

  static const _error = Color(0xFFEF4444);

  const _FavoriteButton({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowedAsync = ref.watch(isTeamFollowedProvider(teamId));

    return isFollowedAsync.when(
      data: (isFollowed) => IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isFollowed
                ? _error.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isFollowed ? Icons.favorite : Icons.favorite_border,
            color: isFollowed ? _error : Colors.grey,
            size: 20,
          ),
        ),
        onPressed: () async {
          await ref
              .read(favoritesNotifierProvider.notifier)
              .toggleTeamFollow(teamId);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(isFollowed ? '즐겨찾기에서 제거되었습니다' : '즐겨찾기에 추가되었습니다'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
      ),
      loading: () => Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.grey.shade400),
        ),
      ),
      error: (_, __) => IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.favorite_border,
            color: Colors.grey,
            size: 20,
          ),
        ),
        onPressed: () async {
          await ref
              .read(favoritesNotifierProvider.notifier)
              .toggleTeamFollow(teamId);
        },
      ),
    );
  }
}
