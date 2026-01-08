import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/api_football_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/banner_ad_widget.dart';
import '../../attendance/models/attendance_record.dart';
import '../../attendance/providers/attendance_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../national_team/providers/national_team_provider.dart';
import '../../national_team/providers/selected_national_team_provider.dart';

/// 축구 라이브스코어 Provider (API-Football) - 리그 우선순위 정렬
/// 캐시 유지, 화면 재진입 시 invalidate로 새 데이터 로드 (기존 데이터 먼저 표시)
final soccerLivescoresProvider =
    FutureProvider<List<ApiFootballFixture>>((ref) async {
  final service = ApiFootballService();
  final fixtures = await service.getLiveFixtures();

  // 리그 우선순위 정의
  int getLeaguePriority(int leagueId) {
    // 1순위: 5대 리그
    const tier1 = {39, 140, 135, 78, 61}; // EPL, 라리가, 세리에A, 분데스, 리그앙
    // 2순위: 유럽 클럽 대회
    const tier2 = {2, 3, 848}; // UCL, UEL, UECL
    // 3순위: K리그, 국가대항전
    const tier3 = {292, 1, 4, 6, 9, 17}; // K리그1, 월드컵, 유로, AFCON, 코파, AFC

    if (tier1.contains(leagueId)) return 1;
    if (tier2.contains(leagueId)) return 2;
    if (tier3.contains(leagueId)) return 3;
    return 4; // 기타 리그
  }

  // 우선순위로 정렬
  fixtures.sort((a, b) {
    final priorityA = getLeaguePriority(a.league.id);
    final priorityB = getLeaguePriority(b.league.id);
    if (priorityA != priorityB) return priorityA.compareTo(priorityB);
    // 같은 우선순위 내에서는 리그 ID로 그룹화
    return a.league.id.compareTo(b.league.id);
  });

  return fixtures;
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
              ref.invalidate(selectedTeamNextMatchesProvider);
              ref.invalidate(selectedTeamPastMatchesProvider);
              ref.invalidate(selectedTeamFormProvider);
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

                // 배너 광고 (스크롤 중간)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: BannerAdWidget(),
                  ),
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
    final l10n = AppLocalizations.of(context)!;
    final userName = user?.displayName ?? l10n.footballFan;
    final now = DateTime.now();
    final locale = Localizations.localeOf(context);
    final dateStr = DateFormat(l10n.dateFormatHeader, locale.toString()).format(now);

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
                  l10n.hello(userName),
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      color: Colors.white,
      child: Row(
        children: [
          _QuickActionButton(
            icon: Icons.add_rounded,
            label: l10n.record,
            color: _primary,
            onTap: () => context.push('/attendance/add'),
          ),
          const SizedBox(width: 8),
          _QuickActionButton(
            icon: Icons.calendar_today_rounded,
            label: l10n.schedule,
            color: _success,
            onTap: () => context.go('/schedule'),
          ),
          const SizedBox(width: 8),
          _QuickActionButton(
            icon: Icons.leaderboard_rounded,
            label: l10n.standings,
            color: _warning,
            onTap: () => context.go('/standings'),
          ),
          const SizedBox(width: 8),
          _QuickActionButton(
            icon: Icons.forum_rounded,
            label: l10n.community,
            color: const Color(0xFF8B5CF6),
            onTap: () => context.go('/community'),
          ),
          const SizedBox(width: 8),
          _QuickActionButton(
            icon: Icons.favorite_rounded,
            label: l10n.favorites,
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
    final l10n = AppLocalizations.of(context)!;
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
              Text(
                l10n.myAttendanceRecord,
                style: const TextStyle(
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
                      l10n.viewAll,
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
                  label: l10n.totalMatches,
                  value: '${stats.totalMatches}',
                  unit: l10n.matchCount,
                  color: const Color(0xFF2563EB),
                ),
                _buildDivider(),
                _StatItem(
                  label: l10n.win,
                  value: '${stats.wins}',
                  unit: l10n.times,
                  color: const Color(0xFF10B981),
                ),
                _buildDivider(),
                _StatItem(
                  label: l10n.winRate,
                  value: stats.winRate.toStringAsFixed(0),
                  unit: '%',
                  color: const Color(0xFFF59E0B),
                ),
                _buildDivider(),
                _StatItem(
                  label: l10n.stadium,
                  value: '${stats.stadiumVisits.length}',
                  unit: l10n.stadiumCount,
                  color: const Color(0xFF8B5CF6),
                ),
              ],
            ),
            loading: () => const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => SizedBox(
              height: 60,
              child: Center(child: Text(l10n.cannotLoadStats)),
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
class _LiveScoresSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_LiveScoresSection> createState() => _LiveScoresSectionState();
}

class _LiveScoresSectionState extends ConsumerState<_LiveScoresSection> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 라이브 데이터 자동 갱신 (기존 캐시 데이터 먼저 표시 후 새 데이터 로드)
    Future.microtask(() => ref.invalidate(soccerLivescoresProvider));
  }

  @override
  Widget build(BuildContext context) {
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
                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context)!;
                        return Text(
                          l10n.liveMatchCount(liveFixtures.length),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        );
                      },
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
                height: 110,
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

  static const _primary = Color(0xFF2563EB);
  static const _error = Color(0xFFEF4444);

  const _LiveMatchCard({required this.fixture});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/match/${fixture.id}'),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _error.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 리그명 + 시간
            Row(
              children: [
                Expanded(
                  child: Text(
                    fixture.league.name,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusDisplay(),
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 홈팀
            Row(
              children: [
                if (fixture.homeTeam.logo != null)
                  CachedNetworkImage(
                    imageUrl: fixture.homeTeam.logo!,
                    width: 22,
                    height: 22,
                    errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 22, color: Colors.grey),
                  )
                else
                  const Icon(Icons.shield, size: 22, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fixture.homeTeam.name,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${fixture.homeGoals ?? 0}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _primary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // 원정팀
            Row(
              children: [
                if (fixture.awayTeam.logo != null)
                  CachedNetworkImage(
                    imageUrl: fixture.awayTeam.logo!,
                    width: 22,
                    height: 22,
                    errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 22, color: Colors.grey),
                  )
                else
                  const Icon(Icons.shield, size: 22, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fixture.awayTeam.name,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${fixture.awayGoals ?? 0}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusDisplay() {
    // 하프타임
    if (fixture.isHalftime) {
      return 'HT';
    }
    final elapsed = fixture.status.elapsed;
    final extra = fixture.status.extra;
    if (elapsed != null) {
      if (extra != null && extra > 0) {
        return "$elapsed+$extra'";
      }
      return "$elapsed'";
    }
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

      // 병렬로 모든 팀 데이터 요청
      final futures = teamIds.map((teamId) async {
        try {
          final apiTeamId = int.tryParse(teamId);
          if (apiTeamId == null) return null;

          // 팀 정보와 일정을 병렬로 가져오기
          final results = await Future.wait([
            service.getTeamById(apiTeamId),
            service.getTeamNextFixtures(apiTeamId, count: 6),
          ]);

          final team = results[0] as ApiFootballTeam?;
          final fixtures = results[1] as List<ApiFootballFixture>;

          if (team != null && fixtures.isNotEmpty) {
            return _TeamNextEvent(team: team, fixtures: fixtures);
          }
        } catch (e) {
          // 개별 팀 오류는 무시
        }
        return null;
      }).toList();

      final results = await Future.wait(futures);
      return results.whereType<_TeamNextEvent>().toList();
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
    final l10n = AppLocalizations.of(context)!;
    final teamEventsAsync = ref.watch(favoriteTeamNextEventsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.favoriteTeamSchedule,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/favorites'),
                child: Text(
                  l10n.manage,
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
                  title: l10n.addFavoriteTeam,
                  subtitle: l10n.addFavoriteTeamDesc,
                  onTap: () => context.push('/favorites'),
                );
              }

              // 모든 경기를 하나의 리스트로 모으기
              final allMatches = <_MatchWithTeam>[];
              for (final te in teamEvents) {
                for (final fixture in te.fixtures) {
                  allMatches.add(_MatchWithTeam(team: te.team, fixture: fixture));
                }
              }

              // 날짜순 정렬 (빠른 날짜가 먼저)
              allMatches.sort((a, b) {
                return a.fixture.date.compareTo(b.fixture.date);
              });

              // 최대 6개까지만 표시
              final displayMatches = allMatches.take(6).toList();

              return SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: displayMatches.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return _ScheduleCard(match: displayMatches[index]);
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => SizedBox(
              height: 150,
              child: Center(child: Text(l10n.cannotLoadSchedule)),
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
            // 날짜 + D-day
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatDate(context, fixture.dateKST),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                // 모든 경기에 D-day 표시
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: daysUntil == 0
                        ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                        : daysUntil <= 3
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                            : const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    daysUntil == 0 ? 'TODAY' : 'D-$daysUntil',
                    style: TextStyle(
                      color: daysUntil == 0
                          ? const Color(0xFFEF4444)
                          : daysUntil <= 3
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF10B981),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
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

  String _formatDate(BuildContext context, DateTime dt) {
    final l10n = AppLocalizations.of(context)!;
    return DateFormat(l10n.dateFormatShort, Localizations.localeOf(context).toString()).format(dt);
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
    final l10n = AppLocalizations.of(context)!;
    final attendanceAsync = ref.watch(attendanceListProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.recentRecords,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/attendance'),
                child: Text(
                  l10n.viewAll,
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
                  title: l10n.firstRecordPrompt,
                  subtitle: l10n.firstRecordDesc,
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
            error: (_, __) => SizedBox(
              height: 150,
              child: Center(child: Text(l10n.cannotLoadRecords)),
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
// 국가대표 섹션 (동적 선택 지원)
// ============================================================================
class _NationalTeamSection extends ConsumerWidget {
  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  // 월드컵 트로피 테마 - 황금색 그라데이션
  static const _gradientStart = Color(0xFFE6B422);  // 밝은 골드
  static const _gradientMid = Color(0xFFD4A537);    // 골드
  static const _gradientEnd = Color(0xFFC9922E);    // 약간 어두운 골드

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countdown = ref.watch(worldCupCountdownProvider);
    final selectedTeam = ref.watch(selectedNationalTeamProvider);
    final nextMatchesAsync = ref.watch(selectedTeamNextMatchesProvider);
    final formAsync = ref.watch(selectedTeamFormProvider);

    // 팀이 선택되지 않았으면 선택 안내 UI 표시
    if (selectedTeam == null) {
      return _buildNoTeamSelectedUI(context, ref, countdown);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더 (탭하면 국가 선택)
          Row(
            children: [
              GestureDetector(
                onTap: () => _showCountryPicker(context, ref),
                child: Row(
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
                        child: selectedTeam.teamLogo != null
                            ? Image.network(
                                selectedTeam.teamLogo!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Container(
                                  color: _gradientStart,
                                  child: const Icon(Icons.flag, color: Colors.white, size: 16),
                                ),
                              )
                            : Container(
                                color: _gradientStart,
                                child: const Icon(Icons.flag, color: Colors.white, size: 16),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      selectedTeam.teamName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, color: _textSecondary, size: 20),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/national-team'),
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return Row(
                      children: [
                        Text(
                          l10n.more,
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        Icon(Icons.chevron_right, color: _textSecondary, size: 18),
                      ],
                    );
                  },
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
                  begin: Alignment.topCenter,
                  end: Alignment.bottomRight,
                  colors: [
                    _gradientStart,
                    _gradientMid,
                    _gradientEnd,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _gradientStart.withValues(alpha: 0.3),
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
                                AppLocalizations.of(context)!.worldCup2026,
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
                                  color: _gradientStart,
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
                        final l10n = AppLocalizations.of(context)!;
                        if (matches.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                l10n.noScheduledMatches,
                                style: const TextStyle(color: _textSecondary, fontSize: 13),
                              ),
                            ),
                          );
                        }

                        final nextMatch = matches.first;
                        final matchDate = nextMatch.dateKST;
                        final isHome = nextMatch.homeTeam.id == selectedTeam.teamId;
                        final myTeam = isHome ? nextMatch.homeTeam : nextMatch.awayTeam;
                        final opponent = isHome ? nextMatch.awayTeam : nextMatch.homeTeam;

                        return Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  l10n.nextMatch,
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
                                // 선택한 팀
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
                                          child: myTeam.logo != null
                                              ? Image.network(
                                                  myTeam.logo!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Container(
                                                    color: _gradientStart,
                                                  ),
                                                )
                                              : Container(color: _gradientStart),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          myTeam.name,
                                          style: const TextStyle(
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
                                          opponent.name,
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
                                        child: opponent.logo != null
                                            ? ClipOval(
                                                child: Image.network(
                                                  opponent.logo!,
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
                      error: (_, __) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Builder(
                            builder: (context) {
                              final l10n = AppLocalizations.of(context)!;
                              return Text(
                                l10n.cannotLoadSchedule,
                                style: const TextStyle(color: _textSecondary, fontSize: 13),
                              );
                            },
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
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context)!;
                            return Text(
                              l10n.recent5Matches,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        formAsync.when(
                          data: (form) {
                            if (form == null) return const SizedBox.shrink();
                            return Row(
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
                            );
                          },
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

  Widget _buildNoTeamSelectedUI(BuildContext context, WidgetRef ref, WorldCupCountdown countdown) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Row(
            children: [
              GestureDetector(
                onTap: () => _showCountryPicker(context, ref),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.grey.shade200,
                      ),
                      child: const Icon(Icons.flag_outlined, color: Colors.grey, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context)!;
                        return Text(
                          l10n.selectNationalTeam,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, color: _textSecondary, size: 20),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 카운트다운 + 선택 안내 카드
          GestureDetector(
            onTap: () => _showCountryPicker(context, ref),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_gradientStart, _gradientMid, _gradientEnd],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _gradientStart.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              countdown.tournamentName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'D-${countdown.daysRemaining}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context)!;
                            return Text(
                              l10n.selectNationalTeamPrompt,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
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

  void _showCountryPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CountryPickerSheet(),
    );
  }
}

/// 국가 선택 바텀시트
class _CountryPickerSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends ConsumerState<_CountryPickerSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final teamsAsync = ref.watch(worldCupTeamsProvider);
    final selectedTeam = ref.watch(selectedNationalTeamProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  l10n.selectNationalTeam,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.worldCupParticipants,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                // 검색
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: l10n.searchCountry,
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          // 팀 목록
          Expanded(
            child: teamsAsync.when(
              data: (teams) {
                final filtered = _searchQuery.isEmpty
                    ? teams
                    : teams.where((t) =>
                        t.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final team = filtered[index];
                    final isSelected = team.id == selectedTeam?.teamId;

                    return ListTile(
                      onTap: () {
                        ref.read(selectedNationalTeamProvider.notifier).selectTeam(
                          SelectedNationalTeam(
                            teamId: team.id,
                            teamName: team.name,
                            teamLogo: team.logo,
                            countryCode: team.code,
                            countryFlag: team.logo,
                          ),
                        );
                        // 선택 후 관련 providers 새로고침
                        ref.invalidate(selectedTeamNextMatchesProvider);
                        ref.invalidate(selectedTeamPastMatchesProvider);
                        ref.invalidate(selectedTeamFormProvider);
                        Navigator.pop(context);
                      },
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: ClipOval(
                          child: team.logo != null
                              ? Image.network(
                                  team.logo!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.flag,
                                    color: Colors.grey.shade400,
                                  ),
                                )
                              : Icon(Icons.flag, color: Colors.grey.shade400),
                        ),
                      ),
                      title: Text(
                        team.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF111827),
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFF2563EB),
                            )
                          : null,
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      l10n.cannotLoadTeamList,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

