import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_football_service.dart';
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
            return _TeamDetailContent(team: team, teamId: teamId);
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
  final ApiFootballTeam team;
  final String teamId;

  const _TeamDetailContent({required this.team, required this.teamId});

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
    _tabController = TabController(length: 5, vsync: this);
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
                  Tab(text: '통계'),
                  Tab(text: '일정'),
                  Tab(text: '선수단'),
                  Tab(text: '이적'),
                ],
              ),
            ),

            // 탭 내용
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _InfoTab(team: team),
                  _StatisticsTab(teamId: widget.teamId),
                  _ScheduleTab(teamId: widget.teamId),
                  _PlayersTab(teamId: widget.teamId),
                  _TransfersTab(teamId: widget.teamId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ApiFootballTeam team) {
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
                _FavoriteButton(teamId: widget.teamId),
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
              child: team.logo != null
                  ? CachedNetworkImage(
                      imageUrl: team.logo!,
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

          // 국가 정보
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (team.country != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    team.country!,
                    style: TextStyle(
                      color: _primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (team.founded != null) ...[
                const SizedBox(width: 8),
                Text(
                  '창단 ${team.founded}',
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
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
  final ApiFootballTeam team;

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
              _InfoRow(
                  icon: Icons.flag_outlined,
                  label: '국가',
                  value: team.country ?? '-'),
              if (team.founded != null)
                _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: '창단',
                    value: '${team.founded}년'),
              if (team.national)
                _InfoRow(
                    icon: Icons.public_outlined,
                    label: '유형',
                    value: '국가대표팀'),
              if (team.code != null)
                _InfoRow(
                    icon: Icons.tag,
                    label: '코드',
                    value: team.code!),
            ],
          ),
        ),

        // Venue Info Card
        if (team.venue != null) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 경기장 이미지
                if (team.venue!.image != null && team.venue!.image!.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    child: CachedNetworkImage(
                      imageUrl: team.venue!.image!,
                      fit: BoxFit.cover,
                      height: 160,
                      width: double.infinity,
                      placeholder: (_, __) => Container(
                        height: 160,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.stadium, size: 48, color: _textSecondary),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 160,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.stadium, size: 48, color: _textSecondary),
                        ),
                      ),
                    ),
                  ),
                // 경기장 정보
                Padding(
                  padding: const EdgeInsets.all(16),
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
                            child: Icon(Icons.stadium_outlined,
                                color: _primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  team.venue!.name ?? '홈 경기장',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _textPrimary,
                                  ),
                                ),
                                if (team.venue!.city != null)
                                  Text(
                                    team.venue!.city!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 핵심 정보를 가로로 배치
                      Row(
                        children: [
                          if (team.venue!.capacity != null)
                            Expanded(
                              child: _VenueStatChip(
                                icon: Icons.people_outline,
                                label: '수용인원',
                                value: NumberFormat('#,###').format(team.venue!.capacity),
                              ),
                            ),
                          if (team.venue!.surface != null) ...[
                            if (team.venue!.capacity != null) const SizedBox(width: 12),
                            Expanded(
                              child: _VenueStatChip(
                                icon: Icons.grass_outlined,
                                label: '잔디',
                                value: team.venue!.surface!,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (team.venue!.address != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.place_outlined, size: 16, color: _textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                team.venue!.address!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
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

class _VenueStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _VenueStatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: _primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============ Statistics Tab ============
class _StatisticsTab extends ConsumerWidget {
  final String teamId;

  static const _textSecondary = Color(0xFF6B7280);

  const _StatisticsTab({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(teamStatisticsProvider(teamId));

    return statsAsync.when(
      data: (statsList) {
        if (statsList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 48, color: _textSecondary),
                const SizedBox(height: 12),
                Text(
                  '통계 정보가 없습니다',
                  style: TextStyle(color: _textSecondary, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: statsList.length,
          itemBuilder: (context, index) {
            final stats = statsList[index];
            return _LeagueStatsCard(stats: stats);
          },
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

class _LeagueStatsCard extends StatelessWidget {
  final ApiFootballTeamSeasonStats stats;

  static const _primary = Color(0xFF2563EB);
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);
  static const _error = Color(0xFFEF4444);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _LeagueStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 리그 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                if (stats.leagueLogo != null)
                  CachedNetworkImage(
                    imageUrl: stats.leagueLogo!,
                    width: 28,
                    height: 28,
                    placeholder: (_, __) => Icon(Icons.emoji_events, size: 28, color: _primary),
                    errorWidget: (_, __, ___) => Icon(Icons.emoji_events, size: 28, color: _primary),
                  )
                else
                  Icon(Icons.emoji_events, size: 28, color: _primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stats.leagueName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                      Text(
                        '${stats.season}/${stats.season + 1} 시즌',
                        style: TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 폼 (최근 경기)
          if (stats.form != null && stats.form!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '최근 폼',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: stats.form!.split('').take(10).map((result) {
                      Color bgColor;
                      switch (result.toUpperCase()) {
                        case 'W':
                          bgColor = _success;
                          break;
                        case 'D':
                          bgColor = _warning;
                          break;
                        case 'L':
                          bgColor = _error;
                          break;
                        default:
                          bgColor = _textSecondary;
                      }
                      return Container(
                        margin: const EdgeInsets.only(right: 4),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            result.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // 시즌 요약
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '시즌 성적',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // 승/무/패
                Row(
                  children: [
                    _StatBox(
                      label: '경기',
                      value: '${stats.fixtures.played.total}',
                      color: _primary,
                    ),
                    const SizedBox(width: 8),
                    _StatBox(
                      label: '승',
                      value: '${stats.fixtures.wins.total}',
                      color: _success,
                    ),
                    const SizedBox(width: 8),
                    _StatBox(
                      label: '무',
                      value: '${stats.fixtures.draws.total}',
                      color: _warning,
                    ),
                    const SizedBox(width: 8),
                    _StatBox(
                      label: '패',
                      value: '${stats.fixtures.loses.total}',
                      color: _error,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 승률
                _buildProgressBar(
                  '승률',
                  stats.winRate,
                  '${stats.winRate.toStringAsFixed(1)}%',
                  _success,
                ),
                const SizedBox(height: 16),

                // 득점/실점
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.sports_soccer,
                        label: '득점',
                        value: '${stats.goals.goalsFor.total}',
                        subValue: '평균 ${stats.goals.goalsFor.avgTotal?.toStringAsFixed(1) ?? '-'}',
                        color: _success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.sports_soccer_outlined,
                        label: '실점',
                        value: '${stats.goals.goalsAgainst.total}',
                        subValue: '평균 ${stats.goals.goalsAgainst.avgTotal?.toStringAsFixed(1) ?? '-'}',
                        color: _error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 클린시트 / 무득점
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.shield,
                        label: '클린시트',
                        value: '${stats.cleanSheet.total}',
                        subValue: '홈 ${stats.cleanSheet.home} / 원정 ${stats.cleanSheet.away}',
                        color: _primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.block,
                        label: '무득점',
                        value: '${stats.failedToScore.total}',
                        subValue: '홈 ${stats.failedToScore.home} / 원정 ${stats.failedToScore.away}',
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 홈/어웨이 비교
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '홈/원정 비교',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                _HomeAwayCompareRow(
                  label: '경기',
                  home: stats.fixtures.played.home,
                  away: stats.fixtures.played.away,
                ),
                _HomeAwayCompareRow(
                  label: '승리',
                  home: stats.fixtures.wins.home,
                  away: stats.fixtures.wins.away,
                  homeColor: _success,
                  awayColor: _success,
                ),
                _HomeAwayCompareRow(
                  label: '무승부',
                  home: stats.fixtures.draws.home,
                  away: stats.fixtures.draws.away,
                  homeColor: _warning,
                  awayColor: _warning,
                ),
                _HomeAwayCompareRow(
                  label: '패배',
                  home: stats.fixtures.loses.home,
                  away: stats.fixtures.loses.away,
                  homeColor: _error,
                  awayColor: _error,
                ),
                const Divider(height: 24),
                _HomeAwayCompareRow(
                  label: '득점',
                  home: stats.goals.goalsFor.home,
                  away: stats.goals.goalsFor.away,
                  homeColor: _success,
                  awayColor: _success,
                ),
                _HomeAwayCompareRow(
                  label: '실점',
                  home: stats.goals.goalsAgainst.home,
                  away: stats.goals.goalsAgainst.away,
                  homeColor: _error,
                  awayColor: _error,
                ),

                // 페널티 통계
                if (stats.penalty != null && stats.penalty!.total > 0) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Icon(Icons.sports, size: 16, color: _textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        '페널티킥',
                        style: TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${stats.penalty!.scored}/${stats.penalty!.total} (${stats.penalty!.percentage?.toStringAsFixed(0) ?? '-'}%)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],

                // 카드 통계
                if (stats.cards != null) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _warning,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${stats.cards!.totalYellow}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _error,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${stats.cards!.totalRed}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double percentage, String valueText, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: _textSecondary,
              ),
            ),
            Text(
              valueText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subValue;
  final Color color;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          Text(
            subValue,
            style: TextStyle(
              fontSize: 11,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeAwayCompareRow extends StatelessWidget {
  final String label;
  final int home;
  final int away;
  final Color? homeColor;
  final Color? awayColor;

  static const _textSecondary = Color(0xFF6B7280);
  static const _primary = Color(0xFF2563EB);

  const _HomeAwayCompareRow({
    required this.label,
    required this.home,
    required this.away,
    this.homeColor,
    this.awayColor,
  });

  @override
  Widget build(BuildContext context) {
    final total = home + away;
    final homePercent = total > 0 ? home / total : 0.5;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  '$home',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: homeColor ?? _primary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: _textSecondary,
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '$away',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: awayColor ?? _textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                flex: (homePercent * 100).round(),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: homeColor ?? _primary,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(3)),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: ((1 - homePercent) * 100).round().clamp(1, 100),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: (awayColor ?? _textSecondary).withValues(alpha: 0.5),
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
      data: (fixtures) {
        if (fixtures.isEmpty) {
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
        final sortedFixtures = List<ApiFootballFixture>.from(fixtures)
          ..sort((a, b) {
            return b.date.compareTo(a.date); // 최신순
          });

        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);

        // 지난 경기, 예정된 경기 분리
        final pastFixtures = sortedFixtures.where((f) {
          return f.date.isBefore(todayStart);
        }).toList();

        final upcomingFixtures = sortedFixtures.where((f) {
          return !f.date.isBefore(todayStart);
        }).toList()
          ..sort((a, b) {
            // 예정된 경기는 가까운 순서로
            return a.date.compareTo(b.date);
          });

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Upcoming Matches
            if (upcomingFixtures.isNotEmpty) ...[
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
                            '${upcomingFixtures.length}',
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
                    ...upcomingFixtures.map((f) => _MatchCard(fixture: f)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Past Matches
            if (pastFixtures.isNotEmpty)
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
                            '${pastFixtures.length}',
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
                    ...pastFixtures.map((f) => _MatchCard(fixture: f, isPast: true)),
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
  final ApiFootballFixture fixture;
  final bool isPast;

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _MatchCard({required this.fixture, this.isPast = false});

  @override
  Widget build(BuildContext context) {
    final dateTime = fixture.dateKST;
    final dateStr = DateFormat('MM/dd (E)', 'ko').format(dateTime);
    final timeStr = DateFormat('HH:mm').format(dateTime);

    return GestureDetector(
      onTap: () => context.push('/match/${fixture.id}'),
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
                    fixture.league.name,
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
                      _buildTeamBadge(fixture.homeTeam.logo, 28),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fixture.homeTeam.name,
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
                  child: fixture.isFinished
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _textPrimary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            fixture.scoreDisplay,
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
                          fixture.awayTeam.name,
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
                      _buildTeamBadge(fixture.awayTeam.logo, 28),
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
  static const _error = Color(0xFFEF4444);
  static const _warning = Color(0xFFF59E0B);
  static const _textPrimary = Color(0xFF111827);

  const _PlayersTab({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(teamPlayersProvider(teamId));
    final injuriesAsync = ref.watch(teamInjuriesProvider(teamId));

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

        // 부상 선수 ID 목록 (부상 표시용)
        final injuredPlayerIds = injuriesAsync.whenOrNull(
          data: (injuries) => injuries.map((i) => i.playerId).toSet(),
        ) ?? <int>{};

        // 부상 선수 상세 정보 맵
        final injuryMap = injuriesAsync.whenOrNull(
          data: (injuries) => {for (var i in injuries) i.playerId: i},
        ) ?? <int, ApiFootballInjury>{};

        // 포지션별 그룹화
        final grouped = <String, List<ApiFootballSquadPlayer>>{};
        for (final player in players) {
          final position = player.position ?? '기타';
          grouped.putIfAbsent(position, () => []).add(player);
        }

        final positionOrder = ['Goalkeeper', 'Defender', 'Midfielder', 'Attacker'];
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
          children: [
            // 부상/결장 선수 섹션 (상단에 표시)
            _buildInjuriesSection(injuriesAsync),
            // 포지션별 선수 목록
            ...sortedKeys.map((position) {
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
                      final isInjured = injuredPlayerIds.contains(player.id);
                      final injury = injuryMap[player.id];
                      return Column(
                        children: [
                          if (index > 0)
                            Divider(height: 1, color: _border, indent: 16, endIndent: 16),
                          _PlayerCard(
                            player: player,
                            isInjured: isInjured,
                            injury: injury,
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(
        child: Text('오류: $e', style: TextStyle(color: _textSecondary)),
      ),
    );
  }

  Widget _buildInjuriesSection(AsyncValue<List<ApiFootballInjury>> injuriesAsync) {
    return injuriesAsync.when(
      data: (injuries) {
        if (injuries.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _error.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _error.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    '부상/결장 선수',
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
              const SizedBox(height: 12),
              ...injuries.map((injury) => _buildInjuryPlayerRow(injury)),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildInjuryPlayerRow(ApiFootballInjury injury) {
    return Builder(
      builder: (context) => InkWell(
        onTap: () => context.push('/player/${injury.playerId}'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              // 선수 사진
              if (injury.playerPhoto != null)
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: injury.playerPhoto!,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 32,
                      height: 32,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.person, size: 18, color: _textSecondary),
                    ),
                  ),
                )
              else
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, size: 18, color: _textSecondary),
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
                  color: _getInjuryColor(injury).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getInjuryText(injury),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _getInjuryColor(injury),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getInjuryColor(ApiFootballInjury injury) {
    if (injury.isSuspended) return _error;
    if (injury.isInjury) return _warning;
    if (injury.isDoubtful) return Colors.orange;
    return _textSecondary;
  }

  String _getInjuryText(ApiFootballInjury injury) {
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

  String _getPositionKr(String position) {
    switch (position.toLowerCase()) {
      case 'goalkeeper':
        return '골키퍼';
      case 'defender':
        return '수비수';
      case 'midfielder':
        return '미드필더';
      case 'attacker':
        return '공격수';
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
      case 'attacker':
      case 'forward':
        return const Color(0xFFEF4444); // error/red
      default:
        return const Color(0xFF6B7280); // secondary/grey
    }
  }
}

class _PlayerCard extends StatelessWidget {
  final ApiFootballSquadPlayer player;
  final bool isInjured;
  final ApiFootballInjury? injury;

  static const _primary = Color(0xFF2563EB);
  static const _error = Color(0xFFEF4444);
  static const _warning = Color(0xFFF59E0B);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _PlayerCard({
    required this.player,
    this.isInjured = false,
    this.injury,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/player/${player.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Player Photo with injury indicator
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade100,
                    border: Border.all(
                      color: isInjured ? _warning.withValues(alpha: 0.5) : Colors.grey.shade200,
                      width: isInjured ? 2 : 1,
                    ),
                  ),
                  child: ClipOval(
                    child: player.photo != null
                        ? CachedNetworkImage(
                            imageUrl: player.photo!,
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
                // 부상 아이콘
                if (isInjured)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: injury?.isSuspended == true ? _error : _warning,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Icon(
                        injury?.isSuspended == true ? Icons.block : Icons.personal_injury,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Player Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          player.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isInjured ? _textSecondary : _textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isInjured && injury != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (injury!.isSuspended ? _error : _warning).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getInjuryShortText(injury!),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: injury!.isSuspended ? _error : _warning,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (player.age != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${player.age}세',
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

  String _getInjuryShortText(ApiFootballInjury injury) {
    if (injury.isSuspended) return '정지';
    if (injury.isInjury) return '부상';
    if (injury.isDoubtful) return '불투명';
    return '결장';
  }
}

// ============ Transfers Tab ============
class _TransfersTab extends ConsumerStatefulWidget {
  final String teamId;

  const _TransfersTab({required this.teamId});

  @override
  ConsumerState<_TransfersTab> createState() => _TransfersTabState();
}

class _TransfersTabState extends ConsumerState<_TransfersTab> {
  static const _primary = Color(0xFF2563EB);
  static const _success = Color(0xFF10B981);
  static const _error = Color(0xFFEF4444);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  String? _selectedYear; // null이면 전체

  @override
  Widget build(BuildContext context) {
    final transfersAsync = ref.watch(teamTransfersProvider(widget.teamId));

    return transfersAsync.when(
      data: (transfers) {
        if (transfers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swap_horiz, size: 48, color: _textSecondary),
                const SizedBox(height: 12),
                Text(
                  '이적 정보가 없습니다',
                  style: TextStyle(color: _textSecondary, fontSize: 14),
                ),
              ],
            ),
          );
        }

        // API-Football ID로 변환
        final apiTeamId = int.tryParse(widget.teamId);

        // 시즌별로 그룹화하고 영입/방출 분류
        final transfersByYear = <String, List<_TransferInfo>>{};
        // 중복 제거용 Set (playerId + year + isIn 조합)
        final seenTransfers = <String>{};

        for (final transfer in transfers) {
          // 선수의 모든 이적 기록을 날짜순으로 정렬 (최신 → 과거)
          final sortedTransfers = transfer.transfers.toList()
            ..sort((a, b) => (b.date ?? '').compareTo(a.date ?? ''));

          for (int i = 0; i < sortedTransfers.length; i++) {
            final t = sortedTransfers[i];
            if (t.date == null) continue;

            final year = t.date!.substring(0, 4);
            final isIn = apiTeamId != null && t.teamInId == apiTeamId;
            final isOut = apiTeamId != null && t.teamOutId == apiTeamId;

            if (!isIn && !isOut) continue;

            // 같은 날에 N/A IN과 실제 OUT이 동시에 있으면 N/A IN은 무시
            // (API 데이터 오류로 완전 이적인데 N/A IN이 함께 기록되는 경우)
            if (isIn && (t.type == null || t.type == 'N/A' || t.type!.isEmpty)) {
              bool hasSameDayOut = false;
              for (final otherT in sortedTransfers) {
                if (otherT.date == t.date &&
                    otherT.teamOutId == apiTeamId &&
                    otherT.type != null &&
                    otherT.type != 'N/A' &&
                    otherT.type!.isNotEmpty) {
                  hasSameDayOut = true;
                  break;
                }
              }
              if (hasSameDayOut) continue;
            }

            // 중복 체크: 같은 선수 + 같은 연도 + 같은 방향은 한 번만 표시
            final uniqueKey = '${transfer.playerId}_${year}_$isIn';
            if (seenTransfers.contains(uniqueKey)) continue;
            seenTransfers.add(uniqueKey);

            // 임대 복귀인지 확인
            final typeLower = (t.type ?? '').toLowerCase();
            bool isLoanReturn = typeLower.contains('loan') &&
                (typeLower.contains('end') || typeLower.contains('back') || typeLower.contains('return'));

            // 타입이 N/A나 빈 값인데 영입인 경우, 이전 기록 확인
            // 이전에 같은 팀으로 임대를 보냈다가 돌아온 건지 체크
            if (!isLoanReturn && isIn && (t.type == null || t.type == 'N/A' || t.type!.isEmpty)) {
              // 이후 기록(과거)에서 같은 팀으로 임대 보낸 기록이 있는지 확인
              for (int j = i + 1; j < sortedTransfers.length; j++) {
                final prevT = sortedTransfers[j];
                if (prevT.teamInId == t.teamOutId && // 이전에 그 팀으로 갔었고
                    prevT.teamOutId == apiTeamId && // 우리 팀에서 보냈고
                    (prevT.type?.toLowerCase().contains('loan') ?? false)) { // 임대였다면
                  isLoanReturn = true; // 이건 임대 복귀
                  break;
                }
              }

              // API 데이터에 특정 팀으로의 임대 기록이 누락될 수 있음
              // 선수에게 어떤 팀으로든 Loan OUT 기록이 있으면 임대 복귀로 간주
              // (빅클럽 유스 선수들은 여러 팀으로 임대를 다니는 경우가 많음)
              if (!isLoanReturn) {
                for (int j = 0; j < sortedTransfers.length; j++) {
                  if (j == i) continue;
                  final otherT = sortedTransfers[j];
                  // 우리 팀(apiTeamId)에서 임대로 보낸 기록이 있으면 복귀
                  if (otherT.teamOutId == apiTeamId &&
                      (otherT.type?.toLowerCase().contains('loan') ?? false)) {
                    isLoanReturn = true;
                    break;
                  }
                }
              }
            }

            transfersByYear.putIfAbsent(year, () => []).add(_TransferInfo(
              playerName: transfer.playerName,
              playerId: transfer.playerId,
              date: t.date!,
              type: t.type ?? 'N/A',
              isIn: isIn,
              isLoanReturn: isLoanReturn,
              fromTeamName: t.teamOutName,
              fromTeamLogo: t.teamOutLogo,
              toTeamName: t.teamInName,
              toTeamLogo: t.teamInLogo,
            ));
          }
        }

        // 연도별 정렬 (최신순)
        final sortedYears = transfersByYear.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        // 선택된 연도가 없거나 유효하지 않으면 최신 연도로 설정
        final effectiveYear = (_selectedYear != null && sortedYears.contains(_selectedYear))
            ? _selectedYear
            : null;

        // 필터링된 연도 목록
        final displayYears = effectiveYear != null
            ? [effectiveYear]
            : sortedYears;

        return Column(
          children: [
            // 연도 선택 필터
            Container(
              height: 48,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: sortedYears.length + 1, // +1 for "전체"
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // 전체 버튼
                    final isSelected = _selectedYear == null;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('전체'),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedYear = null),
                        backgroundColor: Colors.white,
                        selectedColor: _primary.withValues(alpha: 0.15),
                        checkmarkColor: _primary,
                        labelStyle: TextStyle(
                          color: isSelected ? _primary : _textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                        side: BorderSide(
                          color: isSelected ? _primary : _border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    );
                  }
                  final year = sortedYears[index - 1];
                  final isSelected = _selectedYear == year;
                  final yearData = transfersByYear[year]!;
                  final totalCount = yearData.length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('$year ($totalCount)'),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedYear = year),
                      backgroundColor: Colors.white,
                      selectedColor: _primary.withValues(alpha: 0.15),
                      checkmarkColor: _primary,
                      labelStyle: TextStyle(
                        color: isSelected ? _primary : _textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: isSelected ? _primary : _border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 이적 목록
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: displayYears.length,
                itemBuilder: (context, index) {
                  final year = displayYears[index];
                  final yearTransfers = transfersByYear[year]!;

            // 영입/방출/복귀 분리
            final inTransfers = yearTransfers.where((t) => t.isIn && !t.isLoanReturn).toList();
            final returnTransfers = yearTransfers.where((t) => t.isIn && t.isLoanReturn).toList();
            final outTransfers = yearTransfers.where((t) => !t.isIn).toList();

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 연도 헤더
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.05),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 20, color: _primary),
                        const SizedBox(width: 10),
                        Text(
                          '$year년',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                        const Spacer(),
                        // 영입 카운트
                        if (inTransfers.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_downward, size: 12, color: _success),
                                const SizedBox(width: 4),
                                Text(
                                  '${inTransfers.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // 복귀 카운트
                        if (returnTransfers.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.replay, size: 12, color: const Color(0xFF8B5CF6)),
                                const SizedBox(width: 4),
                                Text(
                                  '${returnTransfers.length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // 방출 카운트
                        if (outTransfers.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_upward, size: 12, color: _error),
                                const SizedBox(width: 4),
                                Text(
                                  '${outTransfers.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 영입
                  if (inTransfers.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _success,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '영입',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...inTransfers.map((t) => _TransferCard(transfer: t)),
                  ],

                  // 임대 복귀
                  if (returnTransfers.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6), // 보라색
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '임대 복귀',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...returnTransfers.map((t) => _TransferCard(transfer: t)),
                  ],

                  // 방출
                  if (outTransfers.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _error,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '방출',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...outTransfers.map((t) => _TransferCard(transfer: t)),
                  ],

                  const SizedBox(height: 8),
                ],
              ),
            );
          },
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

class _TransferInfo {
  final String playerName;
  final int playerId;
  final String date;
  final String type;
  final bool isIn;
  final bool isLoanReturn; // 임대 복귀 여부
  final String? fromTeamName;
  final String? fromTeamLogo;
  final String? toTeamName;
  final String? toTeamLogo;

  _TransferInfo({
    required this.playerName,
    required this.playerId,
    required this.date,
    required this.type,
    required this.isIn,
    this.isLoanReturn = false,
    this.fromTeamName,
    this.fromTeamLogo,
    this.toTeamName,
    this.toTeamLogo,
  });
}

class _TransferCard extends StatelessWidget {
  final _TransferInfo transfer;

  static const _success = Color(0xFF10B981);
  static const _error = Color(0xFFEF4444);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _TransferCard({required this.transfer});

  @override
  Widget build(BuildContext context) {
    // 임대 복귀면 보라색, 아니면 영입=초록/방출=빨강
    final Color color;
    final IconData icon;
    if (transfer.isLoanReturn) {
      color = const Color(0xFF8B5CF6); // 보라색
      icon = Icons.replay;
    } else if (transfer.isIn) {
      color = _success;
      icon = Icons.arrow_downward;
    } else {
      color = _error;
      icon = Icons.arrow_upward;
    }
    final otherTeamName = transfer.isIn ? transfer.fromTeamName : transfer.toTeamName;
    final otherTeamLogo = transfer.isIn ? transfer.fromTeamLogo : transfer.toTeamLogo;

    return InkWell(
      onTap: () => context.push('/player/${transfer.playerId}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            // 이적 방향 아이콘
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // 선수 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transfer.playerName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // 상대 팀 로고
                      if (otherTeamLogo != null) ...[
                        CachedNetworkImage(
                          imageUrl: otherTeamLogo,
                          width: 16,
                          height: 16,
                          placeholder: (_, __) => Icon(Icons.shield, size: 16, color: _textSecondary),
                          errorWidget: (_, __, ___) => Icon(Icons.shield, size: 16, color: _textSecondary),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          transfer.isIn
                              ? '← ${otherTeamName ?? '알 수 없음'}'
                              : '→ ${otherTeamName ?? '알 수 없음'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 이적 유형 및 날짜
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getTypeColor(transfer.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getTypeLabel(transfer.type),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _getTypeColor(transfer.type),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(transfer.date),
                  style: TextStyle(
                    fontSize: 11,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: _textSecondary),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'free':
        return '자유 이적';
      case 'loan':
        return '임대';
      case 'loan end':
      case 'end of loan':
      case 'back from loan':
        return '임대 복귀';
      case 'transfer':
        return '이적';
      case 'n/a':
      case '':
        return '-';
      default:
        // 이적료가 있는 경우 (예: "€50M")
        if (type.contains('€') || type.contains('\$') || type.contains('£')) {
          return type;
        }
        return type;
    }
  }

  Color _getTypeColor(String type) {
    final typeLower = type.toLowerCase();
    if (typeLower == 'free') {
      return const Color(0xFF10B981); // 초록 - 자유 이적
    } else if (typeLower == 'loan') {
      return const Color(0xFFF59E0B); // 노란색 - 임대
    } else if (typeLower.contains('loan')) {
      return const Color(0xFF8B5CF6); // 보라색 - 임대 복귀
    } else if (typeLower == 'transfer') {
      return const Color(0xFF6366F1); // 인디고 - 일반 이적
    } else if (type.contains('€') || type.contains('\$') || type.contains('£')) {
      return const Color(0xFF2563EB); // 파란색 - 유료 이적
    }
    return const Color(0xFF6B7280); // 회색 - 기타
  }

  String _formatDate(String date) {
    try {
      final parts = date.split('-');
      if (parts.length >= 2) {
        return '${parts[0]}.${parts[1]}';
      }
      return date;
    } catch (_) {
      return date;
    }
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
