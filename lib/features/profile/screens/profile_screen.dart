import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../auth/providers/auth_provider.dart';
import '../../attendance/providers/attendance_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/banner_ad_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _background = Color(0xFFF9FAFB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(attendanceStatsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _background,
        bottomNavigationBar: const BottomBannerAdWidget(),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // 헤더
                _buildHeader(context, user),

                // 프로필 카드
                _ProfileCard(user: user),

                // 통계 카드
                statsAsync.when(
                  data: (stats) => _StatsCard(stats: stats),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // 즐겨찾기 섹션
                _FavoritesSection(),

                // 메뉴 섹션
                _MenuSection(),

                // 로그인/로그아웃 버튼
                const _AuthButton(),

                // 앱 정보
                _AppInfo(),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Text(
            l10n.profile,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/profile/edit'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, color: _primary, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    l10n.edit,
                    style: TextStyle(
                      color: _primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

// ============================================================================
// 프로필 카드
// ============================================================================
class _ProfileCard extends StatelessWidget {
  final dynamic user;

  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userId = user?.uid;

    // 비로그인 상태일 때 로그인 유도 카드
    if (userId == null) {
      return _buildLoginPromptCard(context, l10n);
    }

    // 로그인 상태일 때 프로필 카드
    return _buildProfileCard(context, l10n);
  }

  Widget _buildLoginPromptCard(BuildContext context, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => context.push('/login'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            // 아이콘
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.person_add_rounded,
                  color: Color(0xFF2563EB),
                  size: 32,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.loginPromptTitle,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.loginPromptSubtitle,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // 화살표 아이콘
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AppLocalizations l10n) {
    final displayName = user?.displayName ?? l10n.userDefault;
    final email = user?.email ?? '';
    final photoUrl = user?.photoURL;
    final userId = user?.uid;

    return GestureDetector(
      onTap: () {
        if (userId != null) {
          context.push('/user/$userId?name=${Uri.encodeComponent(displayName)}');
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            // 프로필 이미지
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
              child: photoUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _buildAvatar(displayName),
                        errorWidget: (_, __, ___) => _buildAvatar(displayName),
                      ),
                    )
                  : _buildAvatar(displayName),
            ),
            const SizedBox(width: 16),
            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.activeMember,
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 화살표 아이콘
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Color(0xFF2563EB),
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================================
// 통계 카드
// ============================================================================
class _StatsCard extends StatelessWidget {
  final dynamic stats;

  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.stadium_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.myAttendanceRecord,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
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
          // 승/무/패 통계
          Row(
            children: [
              _ResultCircle(value: stats.wins, label: l10n.winShort, color: const Color(0xFF10B981)),
              const SizedBox(width: 16),
              _ResultCircle(value: stats.draws, label: l10n.drawShort, color: Colors.grey),
              const SizedBox(width: 16),
              _ResultCircle(value: stats.losses, label: l10n.lossShort, color: const Color(0xFFEF4444)),
              const Spacer(),
              // 총 경기 수
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${stats.totalMatches}',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    l10n.totalMatches,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 승률 바
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.winRate,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${stats.winRate.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (stats.winRate / 100).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 경기장 방문
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.place_rounded, color: const Color(0xFF8B5CF6), size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.visitedStadiums,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  '${stats.stadiumVisits.length} ${l10n.stadiumCount}',
                  style: const TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCircle extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _ResultCircle({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 즐겨찾기 섹션
// ============================================================================
class _FavoritesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final teamsAsync = ref.watch(favoriteTeamsProvider);
    final playersAsync = ref.watch(favoritePlayersProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.favorites,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/favorites'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add, color: Colors.grey.shade600, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        l10n.manage,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 팀
          Row(
            children: [
              Icon(Icons.shield_rounded, color: Colors.grey.shade400, size: 14),
              const SizedBox(width: 4),
              Text(
                l10n.team,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          teamsAsync.when(
            data: (teams) {
              if (teams.isEmpty) {
                return _buildEmptyState(l10n.addFavoriteTeamPrompt, () => context.push('/favorites'));
              }
              return SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: teams.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final team = teams[index];
                    return GestureDetector(
                      onTap: () => context.push('/team/${team.id}'),
                      child: Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: team.logoUrl != null
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: team.logoUrl!,
                                      fit: BoxFit.contain,
                                      placeholder: (_, __) => const Icon(Icons.shield, color: Colors.grey),
                                      errorWidget: (_, __, ___) => const Icon(Icons.shield, color: Colors.grey),
                                    ),
                                  )
                                : const Icon(Icons.shield, color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 56,
                            child: Text(
                              team.shortName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, __) => Text(l10n.loadFailed),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          // 선수
          Row(
            children: [
              Icon(Icons.person_rounded, color: Colors.grey.shade400, size: 14),
              const SizedBox(width: 4),
              Text(
                l10n.player,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          playersAsync.when(
            data: (players) {
              if (players.isEmpty) {
                return _buildEmptyState(l10n.addFavoritePlayerPrompt, () => context.push('/favorites'));
              }
              return SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: players.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final player = players[index];
                    return GestureDetector(
                      onTap: () => context.push('/player/${player.id}'),
                      child: Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: player.photoUrl != null
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: player.photoUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Center(
                                        child: Text(
                                          player.name.isNotEmpty ? player.name[0] : '?',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => Center(
                                        child: Text(
                                          player.name.isNotEmpty ? player.name[0] : '?',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      player.name.isNotEmpty ? player.name[0] : '?',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 56,
                            child: Text(
                              player.nameKr,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, __) => Text(l10n.loadFailed),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Colors.grey.shade400, size: 18),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 메뉴 섹션
// ============================================================================
class _MenuSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _MenuItem(
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFF6366F1),
            title: l10n.attendanceDiary,
            subtitle: l10n.myRecords,
            onTap: () => context.go('/attendance'),
          ),
          Container(height: 1, margin: const EdgeInsets.only(left: 72), color: const Color(0xFFE5E7EB)),
          _MenuItem(
            icon: Icons.leaderboard_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: l10n.leagueStandings,
            subtitle: l10n.checkLeagueStandings,
            onTap: () => context.go('/standings'),
          ),
          Container(height: 1, margin: const EdgeInsets.only(left: 72), color: const Color(0xFFE5E7EB)),
          _MenuItem(
            icon: Icons.calendar_month_rounded,
            iconColor: const Color(0xFF14B8A6),
            title: l10n.matchSchedule,
            subtitle: l10n.upcomingMatches,
            onTap: () => context.go('/schedule'),
          ),
          Container(height: 1, margin: const EdgeInsets.only(left: 72), color: const Color(0xFFE5E7EB)),
          _MenuItem(
            icon: Icons.notifications_outlined,
            iconColor: const Color(0xFFEC4899),
            title: l10n.notificationSettings,
            subtitle: l10n.matchAlertsPush,
            onTap: () => context.push('/profile/notifications'),
          ),
          Container(height: 1, margin: const EdgeInsets.only(left: 72), color: const Color(0xFFE5E7EB)),
          _MenuItem(
            icon: Icons.block_rounded,
            iconColor: const Color(0xFFEF4444),
            title: l10n.blockedUsersManagement,
            subtitle: l10n.blockUserDesc,
            onTap: () => context.push('/profile/blocked-users'),
          ),
          Container(height: 1, margin: const EdgeInsets.only(left: 72), color: const Color(0xFFE5E7EB)),
          _MenuItem(
            icon: Icons.schedule_rounded,
            iconColor: const Color(0xFF0EA5E9),
            title: l10n.timezoneSettings,
            subtitle: l10n.matchTimeDisplay,
            onTap: () => context.push('/profile/timezone'),
          ),
          Container(height: 1, margin: const EdgeInsets.only(left: 72), color: const Color(0xFFE5E7EB)),
          _MenuItem(
            icon: Icons.language_rounded,
            iconColor: const Color(0xFF06B6D4),
            title: l10n.languageSettings,
            subtitle: l10n.languageSubtitle,
            onTap: () => context.push('/profile/language'),
          ),
          Container(height: 1, margin: const EdgeInsets.only(left: 72), color: const Color(0xFFE5E7EB)),
          _MenuItem(
            icon: Icons.forum_outlined,
            iconColor: const Color(0xFF8B5CF6),
            title: l10n.communityTitle,
            subtitle: l10n.communityDesc,
            onTap: () => context.push('/community'),
          ),
          Container(height: 1, margin: const EdgeInsets.only(left: 72), color: const Color(0xFFE5E7EB)),
          _MenuItem(
            icon: Icons.help_outline_rounded,
            iconColor: const Color(0xFF3B82F6),
            title: l10n.helpAndSupport,
            subtitle: l10n.faqContact,
            onTap: () => context.push('/profile/help'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
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
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 로그인/로그아웃 버튼
// ============================================================================
class _AuthButton extends ConsumerWidget {
  const _AuthButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isLoggedIn = ref.watch(isLoggedInProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => isLoggedIn ? _showLogoutDialog(context, ref) : context.push('/login'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLoggedIn
                  ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                  : const Color(0xFF2563EB).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isLoggedIn ? Icons.logout_rounded : Icons.login_rounded,
                color: isLoggedIn ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isLoggedIn ? l10n.logout : l10n.loginAction,
                style: TextStyle(
                  color: isLoggedIn ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).signOut();
            },
            child: Text(l10n.logout, style: const TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 앱 정보
// ============================================================================
class _AppInfo extends StatefulWidget {
  @override
  State<_AppInfo> createState() => _AppInfoState();
}

class _AppInfoState extends State<_AppInfo> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = info.version);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          Text(
            l10n.appVersion(_version.isEmpty ? '...' : _version),
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '© 2025 FootHub. All rights reserved.',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
