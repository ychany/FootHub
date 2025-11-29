import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/sports_db_service.dart';
import '../../../shared/widgets/loading_indicator.dart';

// Providers
final playerDetailProvider = FutureProvider.family<SportsDbPlayer?, String>((ref, playerId) async {
  final service = SportsDbService();
  return service.getPlayerById(playerId);
});

// 선수의 팀 정보를 가져오는 provider
final playerTeamProvider = FutureProvider.family<SportsDbTeam?, String?>((ref, teamId) async {
  if (teamId == null || teamId.isEmpty) return null;
  final service = SportsDbService();
  return service.getTeamById(teamId);
});

final playerContractsProvider = FutureProvider.family<List<SportsDbContract>, String>((ref, playerId) async {
  final service = SportsDbService();
  return service.getPlayerContracts(playerId);
});

final playerHonoursProvider = FutureProvider.family<List<SportsDbHonour>, String>((ref, playerId) async {
  final service = SportsDbService();
  return service.getPlayerHonours(playerId);
});

final playerMilestonesProvider = FutureProvider.family<List<SportsDbMilestone>, String>((ref, playerId) async {
  final service = SportsDbService();
  return service.getPlayerMilestones(playerId);
});

final playerFormerTeamsProvider = FutureProvider.family<List<SportsDbFormerTeam>, String>((ref, playerId) async {
  final service = SportsDbService();
  return service.getPlayerFormerTeams(playerId);
});

class PlayerDetailScreen extends ConsumerWidget {
  final String playerId;

  const PlayerDetailScreen({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(playerDetailProvider(playerId));

    return Scaffold(
      body: playerAsync.when(
        data: (player) {
          if (player == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('선수 정보를 찾을 수 없습니다')),
            );
          }
          return _PlayerDetailContent(player: player);
        },
        loading: () => Scaffold(
          appBar: AppBar(),
          body: const LoadingIndicator(),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('오류: $e')),
        ),
      ),
    );
  }
}

class _PlayerDetailContent extends ConsumerWidget {
  final SportsDbPlayer player;

  const _PlayerDetailContent({required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        // App Bar with player photo
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: _PlayerHeader(player: player),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Info Card
                _BasicInfoCard(player: player),
                const SizedBox(height: 16),

                // Contracts
                _ContractsSection(playerId: player.id),
                const SizedBox(height: 16),

                // Former Teams
                _FormerTeamsSection(playerId: player.id),
                const SizedBox(height: 16),

                // Honours
                _HonoursSection(playerId: player.id),
                const SizedBox(height: 16),

                // Milestones
                _MilestonesSection(playerId: player.id),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerHeader extends ConsumerWidget {
  final SportsDbPlayer player;

  const _PlayerHeader({required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(playerTeamProvider(player.teamId));
    final teamBadge = teamAsync.valueOrNull?.badge;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Player Photo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipOval(
                child: player.photo != null
                    ? CachedNetworkImage(
                        imageUrl: player.photo!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: Colors.white,
                          child: const Icon(Icons.person, size: 60, color: Colors.grey),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.white,
                          child: const Icon(Icons.person, size: 60, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.white,
                        child: const Icon(Icons.person, size: 60, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Player Name
            Text(
              player.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            // Team & Position
            if (player.team != null || player.position != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (teamBadge != null) ...[
                    CachedNetworkImage(
                      imageUrl: teamBadge,
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                      ),
                      errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 24, color: Colors.white54),
                    ),
                    const SizedBox(width: 6),
                  ] else if (teamAsync.isLoading) ...[
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (player.team != null)
                    Text(
                      player.team!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  if (player.team != null && player.position != null)
                    const Text(
                      ' | ',
                      style: TextStyle(color: Colors.white54),
                    ),
                  if (player.position != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getPositionKorean(player.position!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
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
      case 'forward':
        return '공격수';
      default:
        return position;
    }
  }
}

class _BasicInfoCard extends StatelessWidget {
  final SportsDbPlayer player;

  const _BasicInfoCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('기본 정보', style: AppTextStyles.subtitle1),
            const SizedBox(height: 16),
            _InfoRow(icon: Icons.flag, label: '국적', value: player.nationality ?? '-'),
            _InfoRow(icon: Icons.cake, label: '생년월일', value: player.dateBorn ?? '-'),
            _InfoRow(icon: Icons.height, label: '키', value: player.height ?? '-'),
            _InfoRow(icon: Icons.monitor_weight, label: '몸무게', value: player.weight ?? '-'),
            if (player.number != null)
              _InfoRow(icon: Icons.tag, label: '등번호', value: player.number!),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: AppTextStyles.body2.copyWith(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.body2),
          ),
        ],
      ),
    );
  }
}

class _ContractsSection extends ConsumerWidget {
  final String playerId;

  const _ContractsSection({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractsAsync = ref.watch(playerContractsProvider(playerId));

    return contractsAsync.when(
      data: (contracts) {
        if (contracts.isEmpty) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('계약 정보', style: AppTextStyles.subtitle1),
                  ],
                ),
                const SizedBox(height: 12),
                ...contracts.map((contract) => _ContractItem(contract: contract)),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ContractItem extends StatelessWidget {
  final SportsDbContract contract;

  const _ContractItem({required this.contract});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: contract.isCurrent
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: contract.isCurrent
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          // Team Badge
          if (contract.teamBadge != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: contract.teamBadge!,
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 40),
              ),
            )
          else
            const Icon(Icons.shield, size: 40, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        contract.teamName ?? '-',
                        style: AppTextStyles.body2.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (contract.isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '현재',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  contract.period,
                  style: AppTextStyles.caption.copyWith(color: Colors.grey),
                ),
                if (contract.wage != null && contract.wage!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '연봉: ${contract.wage}',
                    style: AppTextStyles.caption.copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormerTeamsSection extends ConsumerWidget {
  final String playerId;

  const _FormerTeamsSection({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formerTeamsAsync = ref.watch(playerFormerTeamsProvider(playerId));

    return formerTeamsAsync.when(
      data: (teams) {
        if (teams.isEmpty) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('경력', style: AppTextStyles.subtitle1),
                  ],
                ),
                const SizedBox(height: 12),
                ...teams.map((team) => _FormerTeamItem(team: team)),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _FormerTeamItem extends StatelessWidget {
  final SportsDbFormerTeam team;

  const _FormerTeamItem({required this.team});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Team Badge
          if (team.teamBadge != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: team.teamBadge!,
                width: 36,
                height: 36,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 36),
              ),
            )
          else
            const Icon(Icons.shield, size: 36, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.teamName ?? '-',
                  style: AppTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  team.period,
                  style: AppTextStyles.caption.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HonoursSection extends ConsumerWidget {
  final String playerId;

  const _HonoursSection({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final honoursAsync = ref.watch(playerHonoursProvider(playerId));

    return honoursAsync.when(
      data: (honours) {
        if (honours.isEmpty) return const SizedBox.shrink();

        // Group by team
        final groupedHonours = <String, List<SportsDbHonour>>{};
        for (final honour in honours) {
          final team = honour.teamName ?? '개인';
          groupedHonours.putIfAbsent(team, () => []).add(honour);
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events, size: 20, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text('수상 경력', style: AppTextStyles.subtitle1),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${honours.length}개',
                        style: TextStyle(
                          color: Colors.amber.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...groupedHonours.entries.map((entry) => _HonourGroup(
                      teamName: entry.key,
                      honours: entry.value,
                    )),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _HonourGroup extends StatelessWidget {
  final String teamName;
  final List<SportsDbHonour> honours;

  const _HonourGroup({required this.teamName, required this.honours});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          teamName,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        ...honours.map((h) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.stars, size: 14, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      h.honour ?? '-',
                      style: AppTextStyles.body2,
                    ),
                  ),
                  if (h.season != null)
                    Text(
                      h.season!,
                      style: AppTextStyles.caption.copyWith(color: Colors.grey),
                    ),
                ],
              ),
            )),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MilestonesSection extends ConsumerWidget {
  final String playerId;

  const _MilestonesSection({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestonesAsync = ref.watch(playerMilestonesProvider(playerId));

    return milestonesAsync.when(
      data: (milestones) {
        if (milestones.isEmpty) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('마일스톤', style: AppTextStyles.subtitle1),
                  ],
                ),
                const SizedBox(height: 12),
                ...milestones.map((m) => _MilestoneItem(milestone: m)),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _MilestoneItem extends StatelessWidget {
  final SportsDbMilestone milestone;

  const _MilestoneItem({required this.milestone});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            milestone.milestone ?? '-',
            style: AppTextStyles.body2.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (milestone.description != null) ...[
            const SizedBox(height: 4),
            Text(
              milestone.description!,
              style: AppTextStyles.caption.copyWith(color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
    );
  }
}
