import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../attendance/providers/attendance_provider.dart';
import '../../favorites/providers/favorites_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(attendanceStatsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          // 커스텀 앱바 + 프로필 헤더
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHeader(user: user),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () => _showSettingsDialog(context, ref),
              ),
            ],
          ),
          // 컨텐츠
          SliverToBoxAdapter(
            child: Column(
              children: [
                // 통계 카드
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: statsAsync.when(
                      data: (stats) => _StatsCard(stats: stats),
                      loading: () => const Card(
                        child: SizedBox(
                          height: 120,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                // 메뉴 섹션
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _FavoritesSection(),
                      const SizedBox(height: 16),
                      _QuickMenuSection(),
                      const SizedBox(height: 24),
                      // 로그아웃 버튼
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showLogoutDialog(context, ref),
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: const Text('로그아웃', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'MatchLog v1.0.0',
                        style: AppTextStyles.caption.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '축구 직관 기록 앱',
                        style: AppTextStyles.caption.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit, color: AppColors.primary),
              ),
              title: const Text('프로필 수정'),
              subtitle: const Text('내 정보 변경'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                context.push('/profile/edit');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notifications_outlined, color: Colors.orange),
              ),
              title: const Text('알림 설정'),
              subtitle: const Text('경기 알림, 푸시 알림'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('알림 설정 기능 준비 중')),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.help_outline, color: Colors.blue),
              ),
              title: const Text('도움말 및 지원'),
              subtitle: const Text('FAQ, 문의하기'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('도움말 기능 준비 중')),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline, color: Colors.grey),
              ),
              title: const Text('앱 정보'),
              subtitle: const Text('버전 1.0.0'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _showAppInfoDialog(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.sports_soccer, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            const Text('MatchLog'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('버전: 1.0.0'),
            SizedBox(height: 8),
            Text('축구 직관 기록을 위한 앱입니다.'),
            SizedBox(height: 8),
            Text('좋아하는 팀의 경기를 기록하고,\n추억을 간직하세요!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).signOut();
            },
            child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final dynamic user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final displayName = user?.displayName ?? '사용자';
    final email = user?.email ?? '';
    final photoUrl = user?.photoURL;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 프로필 이미지
            GestureDetector(
              onTap: () => context.push('/profile/edit'),
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null
                          ? Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: AppColors.primary,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 이름
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            // 이메일
            Text(
              email,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20), // 통계 카드가 겹칠 공간
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final dynamic stats;

  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 상단 헤더
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.stadium, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  '나의 직관 기록',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '총 ${stats.totalMatches}경기',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 승/무/패 통계
            Row(
              children: [
                Expanded(child: _StatCircle(value: stats.wins, label: '승', color: AppColors.success)),
                Expanded(child: _StatCircle(value: stats.draws, label: '무', color: Colors.grey)),
                Expanded(child: _StatCircle(value: stats.losses, label: '패', color: AppColors.error)),
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
                    Text('승률', style: AppTextStyles.caption.copyWith(color: Colors.grey.shade600)),
                    Text(
                      '${stats.winRate.toStringAsFixed(1)}%',
                      style: AppTextStyles.subtitle2.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: stats.winRate / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCircle extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _StatCircle({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _QuickMenuSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _MenuItem(
            icon: Icons.menu_book,
            iconColor: Colors.indigo,
            title: '직관 일기',
            subtitle: '나의 직관 기록들',
            onTap: () => context.go('/attendance'),
          ),
          const Divider(height: 1, indent: 72),
          _MenuItem(
            icon: Icons.leaderboard,
            iconColor: Colors.orange,
            title: '리그 순위',
            subtitle: '각 리그 순위표 확인',
            onTap: () => context.go('/standings'),
          ),
          const Divider(height: 1, indent: 72),
          _MenuItem(
            icon: Icons.calendar_month,
            iconColor: Colors.teal,
            title: '경기 일정',
            subtitle: '다가오는 경기 확인',
            onTap: () => context.go('/schedule'),
          ),
        ],
      ),
    );
  }
}

class _FavoritesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(favoriteTeamsProvider);
    final playersAsync = ref.watch(favoritePlayersProvider);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.favorite, color: AppColors.error, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('즐겨찾기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => context.push('/favorites'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('관리'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 즐겨찾기 팀
            Row(
              children: [
                const Icon(Icons.shield, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('팀', style: AppTextStyles.caption.copyWith(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            teamsAsync.when(
              data: (teams) {
                if (teams.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, color: Colors.grey.shade400),
                        const SizedBox(width: 8),
                        Text(
                          '팀을 추가해보세요',
                          style: AppTextStyles.body2.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: teams.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      return GestureDetector(
                        onTap: () => context.push('/team/${team.id}'),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white,
                                backgroundImage: team.logoUrl != null
                                    ? CachedNetworkImageProvider(team.logoUrl!)
                                    : null,
                                child: team.logoUrl == null
                                    ? const Icon(Icons.shield, color: Colors.grey)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 60,
                              child: Text(
                                team.shortName,
                                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500),
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
              loading: () => const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => const Text('불러오기 실패'),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // 즐겨찾기 선수
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('선수', style: AppTextStyles.caption.copyWith(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            playersAsync.when(
              data: (players) {
                if (players.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, color: Colors.grey.shade400),
                        const SizedBox(width: 8),
                        Text(
                          '선수를 추가해보세요',
                          style: AppTextStyles.body2.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: players.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final player = players[index];
                      return GestureDetector(
                        onTap: () => context.push('/player/${player.id}'),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: player.photoUrl != null
                                    ? CachedNetworkImageProvider(player.photoUrl!)
                                    : null,
                                child: player.photoUrl == null
                                    ? Text(
                                        player.name.isNotEmpty ? player.name[0] : '?',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 60,
                              child: Text(
                                player.nameKr,
                                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500),
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
              loading: () => const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => const Text('불러오기 실패'),
            ),
          ],
        ),
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
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: AppTextStyles.caption.copyWith(color: Colors.grey.shade600)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
