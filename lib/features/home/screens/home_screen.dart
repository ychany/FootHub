import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/api_football_service.dart';
import '../../attendance/models/attendance_record.dart';
import '../../attendance/providers/attendance_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../national_team/providers/national_team_provider.dart';

/// 축구 라이브스코어 Provider (API-Football)
final soccerLivescoresProvider =
    FutureProvider<List<ApiFootballFixture>>((ref) async {
  final service = ApiFootballService();
  return service.getLiveFixtures();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);
  static const _error = Color(0xFFEF4444);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _background = Color(0xFFF9FAFB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: RefreshIndicator(
            color: _primary,
            onRefresh: () async {
              ref.invalidate(attendanceListProvider);
              ref.invalidate(favoriteTeamIdsProvider);
              ref.invalidate(soccerLivescoresProvider);
              ref.invalidate(koreaNextMatchesProvider);
              ref.invalidate(koreaPastMatchesProvider);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 헤더
                SliverToBoxAdapter(
                  child: _buildHeader(context, user),
                ),

                // 퀵 액션
                SliverToBoxAdapter(
                  child: _buildQuickActions(context),
                ),

                // 나의 직관 통계
                SliverToBoxAdapter(
                  child: _StatsSection(),
                ),

                // 라이브 스코어
                SliverToBoxAdapter(
                  child: _LiveScoresSection(),
                ),

                // 즐겨찾기 팀 일정
                SliverToBoxAdapter(
                  child: _FavoriteScheduleSection(),
                ),

                // 대한민국 국가대표
                SliverToBoxAdapter(
                  child: _NationalTeamSection(),
                ),

                // 최근 직관 기록
                SliverToBoxAdapter(
                  child: _RecentRecordsSection(),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user) {
    final userName = user?.displayName ?? '축구팬';
    final now = DateTime.now();
    final dateStr = DateFormat('M월 d일 EEEE', 'ko').format(now);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      color: Colors.white,
      child: Row(
        children: [
          // 프로필 아바타
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: _primary.withValues(alpha: 0.2), width: 2),
              ),
              child: user?.photoURL != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: user!.photoURL!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _buildAvatar(userName),
                        errorWidget: (_, __, ___) => _buildAvatar(userName),
                      ),
                    )
                  : _buildAvatar(userName),
            ),
          ),
          const SizedBox(width: 14),
          // 인사말
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '안녕하세요, $userName님',
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // 알림
          _buildIconButton(
            Icons.notifications_outlined,
            onTap: () => context.push('/profile/notifications'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: _primary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Icon(icon, color: _textSecondary, size: 20),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      color: Colors.white,
      child: Row(
        children: [
          _QuickActionButton(
            icon: Icons.add_rounded,
            label: '기록하기',
            color: _primary,
            onTap: () => context.push('/attendance/add'),
          ),
          const SizedBox(width: 8),
          _QuickActionButton(
            icon: Icons.calendar_today_rounded,
            label: '일정',
            color: _success,
            onTap: () => context.go('/schedule'),
          ),
          const SizedBox(width: 8),
          _QuickActionButton(
            icon: Icons.leaderboard_rounded,
            label: '순위',
            color: _warning,
            onTap: () => context.go('/standings'),
          ),
          const SizedBox(width: 8),
          _QuickActionButton(
            icon: Icons.forum_rounded,
            label: '커뮤니티',
            color: const Color(0xFF8B5CF6),
            onTap: () => context.go('/community'),
          ),
          const SizedBox(width: 8),
          _QuickActionButton(
            icon: Icons.favorite_rounded,
            label: '즐겨찾기',
            color: _error,
            onTap: () => context.push('/favorites'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 통계 섹션
// ============================================================================
class _StatsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(attendanceStatsProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '나의 직관 기록',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/attendance'),
                child: Row(
                  children: [
                    Text(
                      '전체보기',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          statsAsync.when(
            data: (stats) => Row(
              children: [
                _StatItem(
                  label: '총 경기',
                  value: '${stats.totalMatches}',
                  unit: '경기',
                  color: const Color(0xFF2563EB),
                ),
                _buildDivider(),
                _StatItem(
                  label: '승리',
                  value: '${stats.wins}',
                  unit: '회',
                  color: const Color(0xFF10B981),
                ),
                _buildDivider(),
                _StatItem(
                  label: '승률',
                  value: stats.winRate.toStringAsFixed(0),
                  unit: '%',
                  color: const Color(0xFFF59E0B),
                ),
                _buildDivider(),
                _StatItem(
                  label: '경기장',
                  value: '${stats.stadiumVisits.length}',
                  unit: '곳',
                  color: const Color(0xFF8B5CF6),
                ),
              ],
            ),
            loading: () => const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox(
              height: 60,
              child: Center(child: Text('통계를 불러올 수 없습니다')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFFE5E7EB),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 2),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 라이브 스코어 섹션
// ============================================================================
class _LiveScoresSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final livescoresAsync = ref.watch(soccerLivescoresProvider);

    return livescoresAsync.when(
      data: (fixtures) {
        final liveFixtures = fixtures.where((f) => f.isLive).toList();
        if (liveFixtures.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.push('/live'),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${liveFixtures.length}경기',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                    Icon(Icons.chevron_right,
                      color: Colors.grey.shade400, size: 18),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => ref.invalidate(soccerLivescoresProvider),
                      child: Icon(Icons.refresh_rounded,
                        color: Colors.grey.shade400, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: liveFixtures.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return _LiveMatchCard(fixture: liveFixtures[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _LiveMatchCard extends StatelessWidget {
  final ApiFootballFixture fixture;

  const _LiveMatchCard({required this.fixture});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/match/${fixture.id}'),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fixture.league.name,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getStatusDisplay(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  fixture.homeTeam.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  fixture.scoreDisplay,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  fixture.awayTeam.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
        ),
      ),
    );
  }

  String _getStatusDisplay() {
    final elapsed = fixture.status.elapsed;
    if (elapsed != null) return "$elapsed'";
    return fixture.status.short;
  }
}

// ============================================================================
// 즐겨찾기 팀 일정
// ============================================================================
final favoriteTeamNextEventsProvider =
    FutureProvider<List<_TeamNextEvent>>((ref) async {
  final teamIdsAsync = ref.watch(favoriteTeamIdsProvider);

  return teamIdsAsync.when(
    data: (teamIds) async {
      if (teamIds.isEmpty) return [];

      final service = ApiFootballService();
      final results = <_TeamNextEvent>[];

      for (final teamId in teamIds) {
        try {
          final apiTeamId = int.tryParse(teamId);
          if (apiTeamId == null) continue;

          final team = await service.getTeamById(apiTeamId);
          final fixtures = await service.getTeamNextFixtures(apiTeamId, count: 2);
          if (team != null && fixtures.isNotEmpty) {
            results.add(_TeamNextEvent(team: team, fixtures: fixtures));
          }
        } catch (e) {
          // 개별 팀 오류는 무시
        }
      }
      return results;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

class _TeamNextEvent {
  final ApiFootballTeam team;
  final List<ApiFootballFixture> fixtures;

  _TeamNextEvent({required this.team, required this.fixtures});
}

class _FavoriteScheduleSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamEventsAsync = ref.watch(favoriteTeamNextEventsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '즐겨찾기 팀 일정',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/favorites'),
                child: Text(
                  '관리',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          teamEventsAsync.when(
            data: (teamEvents) {
              if (teamEvents.isEmpty) {
                return _EmptyCard(
                  icon: Icons.favorite_border_rounded,
                  title: '즐겨찾기 팀을 추가해보세요',
                  subtitle: '팀을 추가하면 다가오는 경기 일정을 확인할 수 있어요',
                  onTap: () => context.push('/favorites'),
                );
              }

              final allMatches = <_MatchWithTeam>[];
              for (final te in teamEvents) {
                for (final fixture in te.fixtures) {
                  allMatches.add(_MatchWithTeam(team: te.team, fixture: fixture));
                }
              }
              allMatches.sort((a, b) {
                return a.fixture.date.compareTo(b.fixture.date);
              });

              return SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: allMatches.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return _ScheduleCard(match: allMatches[index]);
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox(
              height: 150,
              child: Center(child: Text('일정을 불러올 수 없습니다')),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchWithTeam {
  final ApiFootballTeam team;
  final ApiFootballFixture fixture;

  _MatchWithTeam({required this.team, required this.fixture});
}

class _ScheduleCard extends StatelessWidget {
  final _MatchWithTeam match;

  const _ScheduleCard({required this.match});

  // 한국 시간 기준으로 날짜만 비교 (시간 제외)
  int _calculateDaysUntil(DateTime eventDateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(eventDateTime.year, eventDateTime.month, eventDateTime.day);
    return eventDate.difference(today).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final fixture = match.fixture;
    final daysUntil = _calculateDaysUntil(fixture.dateKST);

    return GestureDetector(
      onTap: () => context.push('/match/${fixture.id}'),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatDate(fixture.dateKST),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (daysUntil >= 0 && daysUntil <= 7)
                  Text(
                    daysUntil == 0 ? 'TODAY' : 'D-$daysUntil',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // 팀 정보
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTeamBadge(fixture.homeTeam.logo),
                        const SizedBox(height: 4),
                        Text(
                          fixture.homeTeam.name,
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'VS',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTime(fixture.dateKST),
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTeamBadge(fixture.awayTeam.logo),
                        const SizedBox(height: 4),
                        Text(
                          fixture.awayTeam.name,
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamBadge(String? url) {
    if (url != null) {
      return CachedNetworkImage(
        imageUrl: url,
        width: 32,
        height: 32,
        fit: BoxFit.contain,
        errorWidget: (_, __, ___) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.shield_rounded, color: Colors.grey.shade400, size: 18),
    );
  }

  String _formatDate(DateTime dt) {
    return DateFormat('MM.dd (E)', 'ko').format(dt);
  }

  String _formatTime(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }
}

// ============================================================================
// 최근 직관 기록
// ============================================================================
class _RecentRecordsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(attendanceListProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '최근 직관 기록',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/attendance'),
                child: Text(
                  '전체보기',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          attendanceAsync.when(
            data: (records) {
              if (records.isEmpty) {
                return _EmptyCard(
                  icon: Icons.sports_soccer_rounded,
                  title: '첫 직관 기록을 남겨보세요',
                  subtitle: '경기장에서의 특별한 순간을 기록해보세요',
                  onTap: () => context.push('/attendance/add'),
                );
              }

              final recent = records.take(3).toList();
              return Column(
                children: recent
                    .map((record) => _RecordCard(
                          record: record,
                          onTap: () => context.push('/attendance/${record.id}'),
                        ))
                    .toList(),
              );
            },
            loading: () => const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox(
              height: 150,
              child: Center(child: Text('기록을 불러올 수 없습니다')),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final AttendanceRecord record;
  final VoidCallback onTap;

  const _RecordCard({
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            // 날짜
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('MM/dd').format(record.date),
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (record.mood != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      record.mood!.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 경기 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${record.homeTeamName} ${record.scoreDisplay} ${record.awayTeamName}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (record.rating != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 12, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 2),
                              Text(
                                record.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.diaryTitle?.isNotEmpty == true
                        ? '"${record.diaryTitle}"'
                        : record.stadium,
                    style: TextStyle(
                      color: record.diaryTitle?.isNotEmpty == true
                          ? const Color(0xFF2563EB)
                          : Colors.grey.shade500,
                      fontSize: 12,
                      fontStyle: record.diaryTitle?.isNotEmpty == true
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF2563EB), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.add_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 대한민국 국가대표 섹션
// ============================================================================
class _NationalTeamSection extends ConsumerWidget {
  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  // 태극기 색상
  static const _koreaRed = Color(0xFFCD2E3A);
  static const _koreaBlue = Color(0xFF0047A0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countdown = ref.watch(worldCupCountdownProvider);
    final nextMatchesAsync = ref.watch(koreaNextMatchesProvider);
    final formAsync = ref.watch(koreaFormProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.network(
                    'https://r2.thesportsdb.com/images/media/team/badge/a8nqfs1589564916.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: _koreaRed,
                      child: const Icon(Icons.flag, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '대한민국 국가대표',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/national-team'),
                child: Row(
                  children: [
                    Text(
                      '더보기',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: _textSecondary, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 메인 카드
          GestureDetector(
            onTap: () => context.push('/national-team'),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _koreaRed,
                    _koreaRed.withValues(alpha: 0.9),
                    _koreaBlue.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _koreaRed.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 월드컵 카운트다운
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🏆', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                countdown.tournamentName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'D-${countdown.daysRemaining}',
                                style: TextStyle(
                                  color: _koreaRed,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 다음 경기 정보
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: nextMatchesAsync.when(
                      data: (matches) {
                        if (matches.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                '예정된 경기가 없습니다',
                                style: TextStyle(color: _textSecondary, fontSize: 13),
                              ),
                            ),
                          );
                        }

                        final nextMatch = matches.first;
                        final matchDate = nextMatch.dateKST;
                        final isHome = nextMatch.homeTeam.name.toLowerCase().contains('korea');
                        final opponent = isHome ? nextMatch.awayTeam.name : nextMatch.homeTeam.name;
                        final opponentBadge = isHome ? nextMatch.awayTeam.logo : nextMatch.homeTeam.logo;

                        return Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  '다음 경기',
                                  style: TextStyle(
                                    color: _textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    nextMatch.league.name,
                                    style: TextStyle(
                                      color: _primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                // 대한민국
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: _border),
                                        ),
                                        child: ClipOval(
                                          child: Image.network(
                                            'https://r2.thesportsdb.com/images/media/team/badge/a8nqfs1589564916.png',
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              color: _koreaRed,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Flexible(
                                        child: Text(
                                          '대한민국',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: _textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // VS
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Column(
                                    children: [
                                      Text(
                                        DateFormat('M/d').format(matchDate),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _textPrimary,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('HH:mm').format(matchDate),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // 상대팀
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          opponent,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: _textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: _border),
                                          color: Colors.grey.shade100,
                                        ),
                                        child: opponentBadge != null
                                            ? ClipOval(
                                                child: Image.network(
                                                  opponentBadge,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Icon(
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
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (_, __) => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            '일정을 불러올 수 없습니다',
                            style: TextStyle(color: _textSecondary, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 최근 폼
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Text(
                          '최근 5경기',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 10),
                        formAsync.when(
                          data: (form) => Row(
                            children: form.results.map((r) {
                              Color bgColor;
                              switch (r) {
                                case 'W':
                                  bgColor = const Color(0xFF10B981);
                                  break;
                                case 'L':
                                  bgColor = const Color(0xFFEF4444);
                                  break;
                                default:
                                  bgColor = const Color(0xFF6B7280);
                              }
                              return Container(
                                width: 24,
                                height: 24,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    r,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
