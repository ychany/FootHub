import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/sports_db_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../favorites/providers/favorites_provider.dart';

// Providers
final playerDetailProvider =
    FutureProvider.family<SportsDbPlayer?, String>((ref, playerId) async {
  final service = SportsDbService();
  return service.getPlayerById(playerId);
});

final playerTeamProvider =
    FutureProvider.family<SportsDbTeam?, String?>((ref, teamId) async {
  if (teamId == null || teamId.isEmpty) return null;
  final service = SportsDbService();
  return service.getTeamById(teamId);
});

final playerContractsProvider =
    FutureProvider.family<List<SportsDbContract>, String>((ref, playerId) async {
  final service = SportsDbService();
  return service.getPlayerContracts(playerId);
});

final playerHonoursProvider =
    FutureProvider.family<List<SportsDbHonour>, String>((ref, playerId) async {
  final service = SportsDbService();
  return service.getPlayerHonours(playerId);
});

final playerMilestonesProvider =
    FutureProvider.family<List<SportsDbMilestone>, String>((ref, playerId) async {
  final service = SportsDbService();
  return service.getPlayerMilestones(playerId);
});

final playerFormerTeamsProvider =
    FutureProvider.family<List<SportsDbFormerTeam>, String>((ref, playerId) async {
  final service = SportsDbService();
  return service.getPlayerFormerTeams(playerId);
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
                    _buildAppBar(context, null),
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
            return _PlayerDetailContent(player: player);
          },
          loading: () => const LoadingIndicator(),
          error: (e, _) => SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, null),
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

  Widget _buildAppBar(BuildContext context, SportsDbPlayer? player) {
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
  final SportsDbPlayer player;

  static const _background = Color(0xFFF9FAFB);

  const _PlayerDetailContent({required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 헤더
              _PlayerHeader(player: player),

              // 컨텐츠
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Basic Info Card
                    _BasicInfoCard(player: player),
                    const SizedBox(height: 12),

                    // Contracts
                    _ContractsSection(playerId: player.id),

                    // Former Teams
                    _FormerTeamsSection(playerId: player.id),

                    // Honours
                    _HonoursSection(playerId: player.id),

                    // Milestones
                    _MilestonesSection(playerId: player.id),

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
  final SportsDbPlayer player;

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _PlayerHeader({required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(playerTeamProvider(player.teamId));
    final teamBadge = teamAsync.valueOrNull?.badge;

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
                _PlayerFavoriteButton(playerId: player.id),
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
              if (teamBadge != null) ...[
                CachedNetworkImage(
                  imageUrl: teamBadge,
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
              if (player.team != null)
                Text(
                  player.team!,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                  ),
                ),
              if (player.team != null && player.position != null)
                Text(
                  ' · ',
                  style: TextStyle(color: _textSecondary.withValues(alpha: 0.5)),
                ),
              if (player.position != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getPositionKorean(player.position!),
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
      case 'forward':
        return '공격수';
      default:
        return position;
    }
  }
}

class _BasicInfoCard extends StatelessWidget {
  final SportsDbPlayer player;

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
          _InfoRow(icon: Icons.cake_outlined, label: '생년월일', value: player.dateBorn ?? '-'),
          _InfoRow(icon: Icons.height, label: '키', value: player.height ?? '-'),
          _InfoRow(icon: Icons.fitness_center_outlined, label: '몸무게', value: player.weight ?? '-'),
          if (player.number != null)
            _InfoRow(icon: Icons.tag, label: '등번호', value: player.number!),
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

class _ContractsSection extends ConsumerWidget {
  final String playerId;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _border = Color(0xFFE5E7EB);

  const _ContractsSection({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractsAsync = ref.watch(playerContractsProvider(playerId));

    return contractsAsync.when(
      data: (contracts) {
        if (contracts.isEmpty) return const SizedBox.shrink();

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
                    child:
                        Icon(Icons.description_outlined, color: _primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '계약 정보',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...contracts.map((contract) => _ContractItem(contract: contract)),
            ],
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

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _ContractItem({required this.contract});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: contract.teamId != null
          ? () => context.push('/team/${contract.teamId}')
          : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: contract.isCurrent
              ? _primary.withValues(alpha: 0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: contract.isCurrent
                ? _primary.withValues(alpha: 0.2)
                : _border,
          ),
        ),
        child: Row(
          children: [
            // Team Badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: contract.teamBadge != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: contract.teamBadge!,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) =>
                            Icon(Icons.shield, size: 24, color: _textSecondary),
                      ),
                    )
                  : Icon(Icons.shield, size: 24, color: _textSecondary),
            ),
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
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                      ),
                      if (contract.isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '현재',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contract.period,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textSecondary,
                    ),
                  ),
                  if (contract.wage != null && contract.wage!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '연봉: ${contract.wage}',
                      style: TextStyle(
                        fontSize: 11,
                        color: _textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (contract.teamId != null)
              Icon(Icons.chevron_right, color: _textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _FormerTeamsSection extends ConsumerWidget {
  final String playerId;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _border = Color(0xFFE5E7EB);

  const _FormerTeamsSection({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formerTeamsAsync = ref.watch(playerFormerTeamsProvider(playerId));

    return formerTeamsAsync.when(
      data: (teams) {
        if (teams.isEmpty) return const SizedBox.shrink();

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
                    child: Icon(Icons.history, color: _primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '경력',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...teams.map((team) => _FormerTeamItem(team: team)),
            ],
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

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _FormerTeamItem({required this.team});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: team.teamId != null
          ? () => context.push('/team/${team.teamId}')
          : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            // Team Badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: team.teamBadge != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: team.teamBadge!,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) =>
                            Icon(Icons.shield, size: 20, color: _textSecondary),
                      ),
                    )
                  : Icon(Icons.shield, size: 20, color: _textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.teamName ?? '-',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    team.period,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (team.teamId != null)
              Icon(Icons.chevron_right, color: _textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _HonoursSection extends ConsumerWidget {
  final String playerId;

  static const _textPrimary = Color(0xFF111827);
  static const _border = Color(0xFFE5E7EB);
  static const _warning = Color(0xFFF59E0B);

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
                      '${honours.length}개',
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
              ...groupedHonours.entries.map((entry) => _HonourGroup(
                    teamName: entry.key,
                    honours: entry.value,
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

class _HonourGroup extends StatelessWidget {
  final String teamName;
  final List<SportsDbHonour> honours;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _warning = Color(0xFFF59E0B);

  const _HonourGroup({required this.teamName, required this.honours});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            teamName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
        ),
        ...honours.map((h) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.star, size: 14, color: _warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      h.honour ?? '-',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  if (h.season != null)
                    Text(
                      h.season!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _textSecondary,
                      ),
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

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _border = Color(0xFFE5E7EB);

  const _MilestonesSection({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestonesAsync = ref.watch(playerMilestonesProvider(playerId));

    return milestonesAsync.when(
      data: (milestones) {
        if (milestones.isEmpty) return const SizedBox.shrink();

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
                    child: Icon(Icons.flag_outlined, color: _primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '마일스톤',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...milestones.map((m) => _MilestoneItem(milestone: m)),
            ],
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

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _MilestoneItem({required this.milestone});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            milestone.milestone ?? '-',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          if (milestone.description != null) ...[
            const SizedBox(height: 4),
            Text(
              milestone.description!,
              style: const TextStyle(
                fontSize: 12,
                color: _textSecondary,
              ),
            ),
          ],
        ],
      ),
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
