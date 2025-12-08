import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/sports_db_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/national_team_provider.dart';

class NationalTeamScreen extends ConsumerStatefulWidget {
  const NationalTeamScreen({super.key});

  @override
  ConsumerState<NationalTeamScreen> createState() => _NationalTeamScreenState();
}

class _NationalTeamScreenState extends ConsumerState<NationalTeamScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _background = Color(0xFFF9FAFB);

  // 태극기 색상
  static const _koreaRed = Color(0xFFCD2E3A);
  static const _koreaBlue = Color(0xFF0047A0);

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
    final countdown = ref.watch(worldCupCountdownProvider);

    return Scaffold(
      backgroundColor: _background,
      body: CustomScrollView(
        slivers: [
          // 앱바
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: _koreaRed,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
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
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // 팀 엠블럼
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(8),
                        child: ClipOval(
                          child: Image.network(
                            'https://r2.thesportsdb.com/images/media/team/badge/a8nqfs1589564916.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '대한민국',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Korea Republic',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 월드컵 카운트다운 배너
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700),
                    const Color(0xFFFFA500),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 40)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          countdown.tournamentName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '개막까지',
                          style: TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'D-${countdown.daysRemaining}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _koreaRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 탭바
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: _primary,
                unselectedLabelColor: _textSecondary,
                indicatorColor: _primary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: '일정'),
                  Tab(text: '정보'),
                  Tab(text: '선수단'),
                ],
              ),
            ),
          ),

          // 탭 내용
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ScheduleTab(),
                _InfoTab(),
                _SquadTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 탭바 델리게이트
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

// ============================================================================
// 일정 탭
// ============================================================================
class _ScheduleTab extends ConsumerWidget {
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _primary = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(koreaAllMatchesProvider);

    return matchesAsync.when(
      data: (matches) {
        if (matches.isEmpty) {
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

        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);

        final upcomingMatches = matches.where((m) {
          final dt = m.dateTime;
          return dt != null && !dt.isBefore(todayStart);
        }).toList()
          ..sort((a, b) {
            final aDate = a.dateTime ?? DateTime(2100);
            final bDate = b.dateTime ?? DateTime(2100);
            return aDate.compareTo(bDate);
          });

        final pastMatches = matches.where((m) {
          final dt = m.dateTime;
          return dt != null && dt.isBefore(todayStart);
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 예정된 경기
            if (upcomingMatches.isNotEmpty) ...[
              _buildSectionHeader('예정된 경기', Icons.event_outlined, _primary, upcomingMatches.length),
              const SizedBox(height: 12),
              ...upcomingMatches.map((m) => _MatchCard(match: m, isPast: false)),
              const SizedBox(height: 24),
            ],

            // 지난 경기
            if (pastMatches.isNotEmpty) ...[
              _buildSectionHeader('지난 경기', Icons.history, _textSecondary, pastMatches.length),
              const SizedBox(height: 12),
              ...pastMatches.map((m) => _MatchCard(match: m, isPast: true)),
            ],
          ],
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(
        child: Text('오류: $e', style: TextStyle(color: _textSecondary)),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, int count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
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
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final SportsDbEvent match;
  final bool isPast;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _primary = Color(0xFF2563EB);
  static const _koreaRed = Color(0xFFCD2E3A);

  const _MatchCard({required this.match, required this.isPast});

  @override
  Widget build(BuildContext context) {
    final matchDate = match.dateTime;
    final isKoreaHome = match.homeTeam?.toLowerCase().contains('korea') ?? false;

    return GestureDetector(
      onTap: () => context.push('/match/${match.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            // 리그 & 날짜
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    match.league ?? 'A매치',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (matchDate != null)
                  Text(
                    DateFormat('yyyy.MM.dd (E)', 'ko').format(matchDate),
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // 팀 vs 팀
            Row(
              children: [
                // 홈팀
                Expanded(
                  child: Column(
                    children: [
                      _buildTeamBadge(
                        isKoreaHome
                            ? 'https://r2.thesportsdb.com/images/media/team/badge/a8nqfs1589564916.png'
                            : match.homeTeamBadge,
                        isKorea: isKoreaHome,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isKoreaHome ? '대한민국' : (match.homeTeam ?? '-'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isKoreaHome ? _koreaRed : _textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 스코어 or 시간
                SizedBox(
                  width: 80,
                  child: Column(
                    children: [
                      if (isPast && match.homeScore != null && match.awayScore != null)
                        Text(
                          '${match.homeScore} - ${match.awayScore}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                          ),
                        )
                      else if (matchDate != null)
                        Text(
                          DateFormat('HH:mm').format(matchDate),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        )
                      else
                        const Text(
                          'VS',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _textSecondary,
                          ),
                        ),
                      if (match.venue != null && match.venue!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          match.venue!,
                          style: TextStyle(
                            fontSize: 10,
                            color: _textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // 원정팀
                Expanded(
                  child: Column(
                    children: [
                      _buildTeamBadge(
                        !isKoreaHome
                            ? 'https://r2.thesportsdb.com/images/media/team/badge/a8nqfs1589564916.png'
                            : match.awayTeamBadge,
                        isKorea: !isKoreaHome,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        !isKoreaHome ? '대한민국' : (match.awayTeam ?? '-'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: !isKoreaHome ? _koreaRed : _textPrimary,
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
          ],
        ),
      ),
    );
  }

  Widget _buildTeamBadge(String? badgeUrl, {bool isKorea = false}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isKorea ? _koreaRed.withValues(alpha: 0.3) : _border,
          width: isKorea ? 2 : 1,
        ),
        color: Colors.white,
      ),
      child: ClipOval(
        child: badgeUrl != null
            ? CachedNetworkImage(
                imageUrl: badgeUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey.shade100),
                errorWidget: (_, __, ___) => Icon(
                  Icons.shield_outlined,
                  color: _textSecondary,
                  size: 24,
                ),
              )
            : Icon(
                Icons.shield_outlined,
                color: _textSecondary,
                size: 24,
              ),
      ),
    );
  }
}

// ============================================================================
// 정보 탭
// ============================================================================
class _InfoTab extends ConsumerWidget {
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(koreaTeamProvider);
    final formAsync = ref.watch(koreaFormProvider);

    return teamAsync.when(
      data: (team) {
        if (team == null) {
          return const Center(child: Text('팀 정보를 불러올 수 없습니다'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 기본 정보
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
                  const Text(
                    '기본 정보',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(icon: Icons.flag_outlined, label: '국가', value: team.country ?? '-'),
                  _InfoRow(icon: Icons.stadium_outlined, label: '홈 경기장', value: team.stadium ?? '-'),
                  if (team.stadiumCapacity != null)
                    _InfoRow(icon: Icons.people_outline, label: '수용 인원', value: '${team.stadiumCapacity}명'),
                  _InfoRow(icon: Icons.calendar_today_outlined, label: '창단', value: team.formedYear ?? '-'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 최근 폼
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
                  const Text(
                    '최근 5경기 폼',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  formAsync.when(
                    data: (form) => Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  r,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatItem(label: '승', value: '${form.wins}', color: const Color(0xFF10B981)),
                            _StatItem(label: '무', value: '${form.draws}', color: const Color(0xFF6B7280)),
                            _StatItem(label: '패', value: '${form.losses}', color: const Color(0xFFEF4444)),
                          ],
                        ),
                      ],
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Text('폼 정보를 불러올 수 없습니다'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 주요 대회
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
                  const Text(
                    '참가 대회',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _CompetitionItem(name: 'FIFA 월드컵', icon: '🏆'),
                  _CompetitionItem(name: '월드컵 예선 (AFC)', icon: '⚽'),
                  _CompetitionItem(name: 'AFC 아시안컵', icon: '🏅'),
                  _CompetitionItem(name: '친선경기', icon: '🤝'),
                ],
              ),
            ),

            // 팀 설명
            if (team.description != null) ...[
              const SizedBox(height: 16),
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
                    const Text(
                      '소개',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      team.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: _textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

class _CompetitionItem extends StatelessWidget {
  final String name;
  final String icon;

  const _CompetitionItem({required this.name, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 선수단 탭
// ============================================================================
class _SquadTab extends ConsumerWidget {
  static const _textSecondary = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 국가대표 팀은 API에서 선수 정보를 제공하지 않음
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 48, color: _textSecondary),
          const SizedBox(height: 16),
          Text(
            '국가대표 선수단 정보는\n대회별로 소집됩니다',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _ManagerRow(
                  name: '홍명보',
                  role: '감독',
                  since: '2024~',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagerRow extends StatelessWidget {
  final String name;
  final String role;
  final String since;

  const _ManagerRow({required this.name, required this.role, required this.since});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade100,
          ),
          child: const Icon(Icons.person, color: Color(0xFF6B7280)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                '$role · $since',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
