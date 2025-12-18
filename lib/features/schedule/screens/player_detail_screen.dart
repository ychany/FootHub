import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/api_football_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../favorites/providers/favorites_provider.dart';

// Providers (API-Football 사용)
final playerDetailProvider =
    FutureProvider.family<ApiFootballPlayer?, String>((ref, playerId) async {
  final service = ApiFootballService();
  final id = int.tryParse(playerId);
  if (id == null) return null;
  return service.getPlayerById(id);
});

final playerTeamProvider =
    FutureProvider.family<ApiFootballTeam?, String?>((ref, teamId) async {
  if (teamId == null || teamId.isEmpty) return null;
  final service = ApiFootballService();
  final id = int.tryParse(teamId);
  if (id == null) return null;
  return service.getTeamById(id);
});

// 이적 기록 Provider
final playerTransfersProvider =
    FutureProvider.family<List<ApiFootballTransfer>, String>((ref, playerId) async {
  final service = ApiFootballService();
  final id = int.tryParse(playerId);
  if (id == null) return [];
  return service.getPlayerTransfers(id);
});

// 트로피 Provider
final playerTrophiesProvider =
    FutureProvider.family<List<ApiFootballTrophy>, String>((ref, playerId) async {
  final service = ApiFootballService();
  final id = int.tryParse(playerId);
  if (id == null) return [];
  return service.getPlayerTrophies(id);
});

class PlayerDetailScreen extends ConsumerWidget {
  final String playerId;

  static const _textSecondary = Color(0xFF6B7280);
  static const _background = Color(0xFFF9FAFB);

  const PlayerDetailScreen({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(playerDetailProvider(playerId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: playerAsync.when(
          data: (player) {
            if (player == null) {
              return SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(context),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off,
                                size: 64, color: _textSecondary),
                            const SizedBox(height: 16),
                            Text(
                              '선수 정보를 찾을 수 없습니다',
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
            return _PlayerDetailContent(player: player, playerId: playerId);
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
              '선수 정보',
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

class _PlayerDetailContent extends ConsumerWidget {
  final ApiFootballPlayer player;
  final String playerId;

  static const _background = Color(0xFFF9FAFB);

  const _PlayerDetailContent({required this.player, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 헤더
              _PlayerHeader(player: player, playerId: playerId),

              // 컨텐츠
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Basic Info Card
                    _BasicInfoCard(player: player),
                    const SizedBox(height: 12),

                    // Statistics Card
                    if (player.statistics.isNotEmpty)
                      _StatisticsCard(player: player),

                    // Transfers (이적 기록)
                    _TransfersSection(playerId: playerId),

                    // Trophies (트로피)
                    _TrophiesSection(playerId: playerId),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerHeader extends ConsumerWidget {
  final ApiFootballPlayer player;
  final String playerId;

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _PlayerHeader({required this.player, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = player.statistics.isNotEmpty ? player.statistics.first : null;
    final teamId = stats?.teamId?.toString();
    final teamAsync = ref.watch(playerTeamProvider(teamId));
    final teamLogo = teamAsync.valueOrNull?.logo;

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
                    '선수 정보',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                _PlayerFavoriteButton(playerId: playerId),
              ],
            ),
          ),

          // 선수 사진
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _border, width: 3),
              color: Colors.grey.shade100,
            ),
            child: ClipOval(
              child: player.photo != null
                  ? CachedNetworkImage(
                      imageUrl: player.photo!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Icon(
                        Icons.person,
                        size: 50,
                        color: _textSecondary,
                      ),
                      errorWidget: (_, __, ___) => Icon(
                        Icons.person,
                        size: 50,
                        color: _textSecondary,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 50,
                      color: _textSecondary,
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // 선수 이름
          Text(
            player.name,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // 팀 & 포지션
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (teamLogo != null) ...[
                CachedNetworkImage(
                  imageUrl: teamLogo,
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF6B7280)),
                  ),
                  errorWidget: (_, __, ___) =>
                      Icon(Icons.shield, size: 20, color: _textSecondary),
                ),
                const SizedBox(width: 6),
              ] else if (teamAsync.isLoading) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF6B7280)),
                ),
                const SizedBox(width: 6),
              ],
              if (stats?.teamName != null)
                Text(
                  stats!.teamName!,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                  ),
                ),
              if (stats?.teamName != null && stats?.position != null)
                Text(
                  ' · ',
                  style: TextStyle(color: _textSecondary.withValues(alpha: 0.5)),
                ),
              if (stats?.position != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getPositionKorean(stats!.position!),
                    style: TextStyle(
                      color: _primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getPositionKorean(String position) {
    switch (position.toLowerCase()) {
      case 'goalkeeper':
        return '골키퍼';
      case 'defender':
        return '수비수';
      case 'midfielder':
        return '미드필더';
      case 'attacker':
      case 'forward':
        return '공격수';
      default:
        return position;
    }
  }
}

class _BasicInfoCard extends StatelessWidget {
  final ApiFootballPlayer player;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _border = Color(0xFFE5E7EB);

  const _BasicInfoCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                child: Icon(Icons.person_outline, color: _primary, size: 20),
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
          _InfoRow(icon: Icons.flag_outlined, label: '국적', value: player.nationality ?? '-'),
          _InfoRow(icon: Icons.cake_outlined, label: '생년월일', value: player.birthDate ?? '-'),
          if (player.age != null)
            _InfoRow(icon: Icons.calendar_today_outlined, label: '나이', value: '${player.age}세'),
          _InfoRow(icon: Icons.height, label: '키', value: player.height ?? '-'),
          _InfoRow(icon: Icons.fitness_center_outlined, label: '몸무게', value: player.weight ?? '-'),
          if (player.birthPlace != null)
            _InfoRow(icon: Icons.location_on_outlined, label: '출생지', value: player.birthPlace!),
        ],
      ),
    );
  }
}

class _StatisticsCard extends StatelessWidget {
  final ApiFootballPlayer player;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _StatisticsCard({required this.player});

  @override
  Widget build(BuildContext context) {
    final stats = player.statistics.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                child: Icon(Icons.sports_soccer, color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '시즌 통계',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    if (stats.leagueName != null)
                      Text(
                        '${stats.leagueName} ${stats.season ?? ''}',
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
          const SizedBox(height: 16),
          Row(
            children: [
              _StatItem(label: '출전', value: '${stats.appearances ?? 0}'),
              _StatItem(label: '선발', value: '${stats.lineups ?? 0}'),
              _StatItem(label: '골', value: '${stats.goals ?? 0}'),
              _StatItem(label: '도움', value: '${stats.assists ?? 0}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatItem(label: '출전시간', value: '${stats.minutes ?? 0}분'),
              _StatItem(label: '경고', value: '${stats.yellowCards ?? 0}', valueColor: Colors.amber),
              _StatItem(label: '퇴장', value: '${stats.redCards ?? 0}', valueColor: Colors.red),
              if (stats.rating != null)
                _StatItem(label: '평점', value: stats.rating!, valueColor: _primary),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _StatItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: valueColor ?? _textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _textSecondary,
            ),
          ),
        ],
      ),
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

class _TransfersSection extends ConsumerWidget {
  final String playerId;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _TransfersSection({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfersAsync = ref.watch(playerTransfersProvider(playerId));

    return transfersAsync.when(
      data: (transfers) {
        if (transfers.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                    child: Icon(Icons.swap_horiz, color: _primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '이적 기록',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...transfers.take(5).map((transfer) => _TransferItem(transfer: transfer)),
              if (transfers.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '외 ${transfers.length - 5}건의 이적 기록',
                    style: TextStyle(fontSize: 12, color: _textSecondary),
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

class _TransferItem extends StatelessWidget {
  final ApiFootballTransfer transfer;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _TransferItem({required this.transfer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          // From Team
          Expanded(
            child: Row(
              children: [
                if (transfer.teamOutLogo != null)
                  CachedNetworkImage(
                    imageUrl: transfer.teamOutLogo!,
                    width: 24,
                    height: 24,
                    errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 24),
                  )
                else
                  const Icon(Icons.shield, size: 24, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    transfer.teamOutName ?? '-',
                    style: const TextStyle(fontSize: 11, color: _textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Arrow
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, size: 16, color: _textSecondary),
          ),
          // To Team
          Expanded(
            child: Row(
              children: [
                if (transfer.teamInLogo != null)
                  CachedNetworkImage(
                    imageUrl: transfer.teamInLogo!,
                    width: 24,
                    height: 24,
                    errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 24),
                  )
                else
                  const Icon(Icons.shield, size: 24, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    transfer.teamInName ?? '-',
                    style: const TextStyle(fontSize: 11, color: _textPrimary),
                    overflow: TextOverflow.ellipsis,
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

class _TrophiesSection extends ConsumerWidget {
  final String playerId;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _warning = Color(0xFFF59E0B);

  const _TrophiesSection({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trophiesAsync = ref.watch(playerTrophiesProvider(playerId));

    return trophiesAsync.when(
      data: (trophies) {
        if (trophies.isEmpty) return const SizedBox.shrink();

        // Winner만 필터링
        final winnerTrophies = trophies.where((t) => t.place == 'Winner').toList();
        if (winnerTrophies.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                      color: _warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.emoji_events, color: _warning, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '수상 경력',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${winnerTrophies.length}개',
                      style: TextStyle(
                        color: _warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...winnerTrophies.take(10).map((trophy) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.star, size: 14, color: _warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trophy.league ?? '-',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                    if (trophy.season != null)
                      Text(
                        trophy.season!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _textSecondary,
                        ),
                      ),
                  ],
                ),
              )),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PlayerFavoriteButton extends ConsumerWidget {
  final String playerId;

  static const _error = Color(0xFFEF4444);

  const _PlayerFavoriteButton({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowedAsync = ref.watch(isPlayerFollowedProvider(playerId));

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
              .togglePlayerFollow(playerId);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    isFollowed ? '즐겨찾기에서 제거되었습니다' : '즐겨찾기에 추가되었습니다'),
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
              .togglePlayerFollow(playerId);
        },
      ),
    );
  }
}
