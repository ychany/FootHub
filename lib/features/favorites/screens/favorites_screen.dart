import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/error_helper.dart';
import '../../../core/utils/auth_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/team_model.dart';
import '../../../shared/models/player_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/team_logo.dart';
import '../../../shared/widgets/banner_ad_widget.dart';
import '../providers/favorites_provider.dart';
import '../../league/screens/league_list_screen.dart' show userLocalLeagueIdsProvider;

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  static const _primaryColor = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _background = Color(0xFFF9FAFB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedFavoritesTabProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _background,
        bottomNavigationBar: const BottomBannerAdWidget(),
        body: SafeArea(
          child: Column(
            children: [
              // 헤더
              _buildHeader(context, ref, selectedTab),
              // 본문
              Expanded(
                child: Column(
                  children: [
                    // Tab Bar
                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context)!;
                        return Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _TabButton(
                                  label: l10n.teams,
                                  isSelected: selectedTab == FavoritesTab.teams,
                                  onTap: () {
                                    ref.read(selectedFavoritesTabProvider.notifier).state =
                                        FavoritesTab.teams;
                                  },
                                ),
                              ),
                              Expanded(
                                child: _TabButton(
                                  label: l10n.players,
                                  isSelected: selectedTab == FavoritesTab.players,
                                  onTap: () {
                                    ref.read(selectedFavoritesTabProvider.notifier).state =
                                        FavoritesTab.players;
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Content
                    Expanded(
                      child: selectedTab == FavoritesTab.teams
                          ? const _TeamsTab()
                          : const _PlayersTab(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, FavoritesTab selectedTab) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.favorites,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () => _showAddDialog(context, ref, selectedTab),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add, color: _primaryColor, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, FavoritesTab tab) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => tab == FavoritesTab.teams
            ? _AddTeamSheet(scrollController: scrollController)
            : _AddPlayerSheet(scrollController: scrollController),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TeamsTab extends ConsumerWidget {
  const _TeamsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(favoriteTeamsProvider);

    return teamsAsync.when(
      data: (teams) {
        if (teams.isEmpty) {
          return const EmptyFavoritesState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: teams.length,
          itemBuilder: (context, index) {
            return _TeamCard(
              team: teams[index],
              onUnfollow: () {
                ref
                    .read(favoritesNotifierProvider.notifier)
                    .unfollowTeam(teams[index].id);
              },
            );
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => ErrorState(
        message: ErrorHelper.getLocalizedErrorMessage(context, e),
        onRetry: () => ref.invalidate(favoriteTeamsProvider),
      ),
    );
  }
}

class _PlayersTab extends ConsumerWidget {
  const _PlayersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(favoritePlayersProvider);

    return playersAsync.when(
      data: (players) {
        if (players.isEmpty) {
          return const EmptyFavoritesState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: players.length,
          itemBuilder: (context, index) {
            return _PlayerCard(
              player: players[index],
              onUnfollow: () {
                ref
                    .read(favoritesNotifierProvider.notifier)
                    .unfollowPlayer(players[index].id);
              },
            );
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => ErrorState(
        message: ErrorHelper.getLocalizedErrorMessage(context, e),
        onRetry: () => ref.invalidate(favoritePlayersProvider),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final Team team;
  final VoidCallback onUnfollow;

  const _TeamCard({
    required this.team,
    required this.onUnfollow,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => context.push('/team/${team.id}'),
        leading: TeamLogo(
          logoUrl: team.logoUrl,
          teamName: team.name,
          size: 48,
        ),
        title: Text(
          team.nameKr,
          style: AppTextStyles.subtitle1.copyWith(color: Colors.black87),
        ),
        subtitle: Text(
          '${team.league} | ${team.stadiumName ?? ""}',
          style: AppTextStyles.caption.copyWith(color: Colors.grey.shade600),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.favorite, color: AppColors.error),
          onPressed: () => _confirmUnfollow(context),
        ),
      ),
    );
  }

  void _confirmUnfollow(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unfollowTeam),
        content: Text(l10n.unfollowTeamConfirm(team.nameKr)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onUnfollow();
            },
            child: Text(l10n.unfollow, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final Player player;
  final VoidCallback onUnfollow;

  const _PlayerCard({
    required this.player,
    required this.onUnfollow,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => context.push('/player/${player.id}'),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage:
              player.photoUrl != null ? NetworkImage(player.photoUrl!) : null,
          child: player.photoUrl == null
              ? Text(
                  player.name.isNotEmpty ? player.name.substring(0, 1) : '?',
                  style: const TextStyle(color: Colors.white),
                )
              : null,
        ),
        title: Text(
          player.nameKr,
          style: AppTextStyles.subtitle1.copyWith(color: Colors.black87),
        ),
        subtitle: Text(
          '${player.teamName} | ${player.position}',
          style: AppTextStyles.caption.copyWith(color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (player.number != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#${player.number}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.favorite, color: AppColors.error),
              onPressed: () => _confirmUnfollow(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmUnfollow(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unfollowPlayer),
        content: Text(l10n.unfollowPlayerConfirm(player.nameKr)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onUnfollow();
            },
            child: Text(l10n.unfollow, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _AddTeamSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const _AddTeamSheet({required this.scrollController});

  @override
  ConsumerState<_AddTeamSheet> createState() => _AddTeamSheetState();
}

class _AddTeamSheetState extends ConsumerState<_AddTeamSheet> {
  String? selectedLeague;
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(AppLocalizations.of(context)!.addTeam, style: AppTextStyles.headline3),
          const SizedBox(height: 16),

          // Search
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchTeam,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (value) {
              ref.read(teamSearchQueryProvider.notifier).state = value;
            },
          ),
          const SizedBox(height: 16),

          // League filter
          _buildLeagueFilter(),
          const SizedBox(height: 16),

          // Results
          Expanded(
            child: _buildTeamResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamResults() {
    final searchQuery = ref.watch(teamSearchQueryProvider);

    if (searchQuery.isNotEmpty) {
      final searchResults = ref.watch(teamSearchResultsProvider);
      return searchResults.when(
        data: (teams) => _buildTeamList(teams),
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Error: $e')),
      );
    }

    if (selectedLeague != null) {
      final leagueTeams = ref.watch(teamsByLeagueProvider(selectedLeague!));
      return leagueTeams.when(
        data: (teams) => _buildTeamList(teams),
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Error: $e')),
      );
    }

    return Center(
      child: Text(AppLocalizations.of(context)!.selectLeagueOrSearch),
    );
  }

  Widget _buildTeamList(List<Team> teams) {
    if (teams.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.teamNotFound));
    }

    // StreamProvider를 사용하여 실시간으로 즐겨찾기 상태 확인
    final favoriteTeamIdsAsync = ref.watch(favoriteTeamIdsProvider);

    return ListView.builder(
      controller: widget.scrollController,
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];

        return favoriteTeamIdsAsync.when(
          data: (favoriteIds) {
            final isFollowed = favoriteIds.contains(team.id);
            return ListTile(
              onTap: () {
                Navigator.pop(context);
                context.push('/team/${team.id}');
              },
              leading: TeamLogo(
                logoUrl: team.logoUrl,
                teamName: team.name,
                size: 40,
              ),
              title: Text(
                team.nameKr,
                style: const TextStyle(color: Colors.black87),
              ),
              subtitle: Text(
                _getLeagueDisplayName(team.league),
                style: TextStyle(color: Colors.grey.shade600),
              ),
              trailing: IconButton(
                icon: Icon(
                  isFollowed ? Icons.favorite : Icons.favorite_border,
                  color: isFollowed ? AppColors.error : Colors.grey,
                ),
                onPressed: () async {
                  try {
                    await ref
                        .read(favoritesNotifierProvider.notifier)
                        .toggleTeamFollow(team.id);
                  } catch (e) {
                    if (e.toString().contains('LOGIN_REQUIRED') && context.mounted) {
                      showLoginRequiredDialog(context);
                    }
                  }
                },
              ),
            );
          },
          loading: () => ListTile(
            leading: TeamLogo(
              logoUrl: team.logoUrl,
              teamName: team.name,
              size: 40,
            ),
            title: Text(
              team.nameKr,
              style: const TextStyle(color: Colors.black87),
            ),
            subtitle: Text(
              _getLeagueDisplayName(team.league),
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, __) => ListTile(
            onTap: () {
              Navigator.pop(context);
              context.push('/team/${team.id}');
            },
            leading: TeamLogo(
              logoUrl: team.logoUrl,
              teamName: team.name,
              size: 40,
            ),
            title: Text(
              team.nameKr,
              style: const TextStyle(color: Colors.black87),
            ),
            subtitle: Text(
              _getLeagueDisplayName(team.league),
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.grey),
              onPressed: () async {
                try {
                  await ref
                      .read(favoritesNotifierProvider.notifier)
                      .toggleTeamFollow(team.id);
                } catch (e) {
                  if (e.toString().contains('LOGIN_REQUIRED') && context.mounted) {
                    showLoginRequiredDialog(context);
                  }
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeagueFilter() {
    final l10n = AppLocalizations.of(context)!;
    final localLeagueIds = ref.watch(userLocalLeagueIdsProvider);

    // 자국 리그 이름 목록 생성
    final localLeagueNames = localLeagueIds
        .map((id) => AppConstants.getLeagueNameById(id))
        .whereType<String>()
        .toList();

    // 전체 리그 목록: 기본 리그 + 자국 리그
    final allLeagues = [
      ...AppConstants.supportedLeagues,
      ...localLeagueNames,
    ];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _LeagueFilterChip(
            label: l10n.all,
            isSelected: selectedLeague == null,
            onTap: () => setState(() => selectedLeague = null),
          ),
          ...allLeagues.map((league) => _LeagueFilterChip(
            label: _getLeagueDisplayName(league),
            isSelected: selectedLeague == league,
            onTap: () => setState(() => selectedLeague = league),
          )),
        ],
      ),
    );
  }

  String _getLeagueDisplayName(String league) {
    // A매치 (국제대회) 여부 판별
    if (AppConstants.isInternationalMatch(league)) {
      return AppLocalizations.of(context)!.national;
    }
    return AppConstants.getLocalizedLeagueName(context, league);
  }
}

class _AddPlayerSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const _AddPlayerSheet({required this.scrollController});

  @override
  ConsumerState<_AddPlayerSheet> createState() => _AddPlayerSheetState();
}

class _AddPlayerSheetState extends ConsumerState<_AddPlayerSheet> {
  final searchController = TextEditingController();
  final playerFilterController = TextEditingController();
  Team? _selectedTeam;
  String _playerFilter = '';
  String? _selectedLeague;

  @override
  void dispose() {
    searchController.dispose();
    playerFilterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 헤더 (팀 선택 시 뒤로가기 버튼 표시)
          Row(
            children: [
              if (_selectedTeam != null)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTeam = null;
                      _playerFilter = '';
                      playerFilterController.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    margin: const EdgeInsets.only(right: 8),
                    child: const Icon(Icons.arrow_back, size: 24),
                  ),
                ),
              Expanded(
                child: Text(
                  _selectedTeam != null
                      ? _selectedTeam!.nameKr
                      : l10n.addPlayer,
                  style: AppTextStyles.headline3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 팀 검색 또는 선수 필터
          if (_selectedTeam == null) ...[
            // 리그 필터
            _buildLeagueFilter(),
            const SizedBox(height: 12),
            // 팀 검색
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: l10n.searchTeamFirst,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                ref.read(teamSearchQueryProvider.notifier).state = value;
              },
            ),
          ] else ...[
            TextField(
              controller: playerFilterController,
              decoration: InputDecoration(
                hintText: l10n.filterPlayers,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _playerFilter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          playerFilterController.clear();
                          setState(() => _playerFilter = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _playerFilter = value);
              },
            ),
          ],
          const SizedBox(height: 16),

          // 결과
          Expanded(
            child: _selectedTeam == null
                ? _buildTeamSearchResults()
                : _buildTeamPlayers(),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSearchResults() {
    final l10n = AppLocalizations.of(context)!;
    final searchQuery = ref.watch(teamSearchQueryProvider);

    // 검색어가 있으면 검색 결과 표시
    if (searchQuery.isNotEmpty) {
      final searchResults = ref.watch(teamSearchResultsProvider);
      return searchResults.when(
        data: (teams) => _buildTeamList(teams),
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Error: $e')),
      );
    }

    // 리그가 선택되면 해당 리그 팀 표시
    if (_selectedLeague != null) {
      final leagueTeams = ref.watch(teamsByLeagueProvider(_selectedLeague!));
      return leagueTeams.when(
        data: (teams) => _buildTeamList(teams),
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Error: $e')),
      );
    }

    // 아무것도 선택 안됨
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            l10n.searchTeamToAddPlayer,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamList(List<Team> teams) {
    final l10n = AppLocalizations.of(context)!;
    if (teams.isEmpty) {
      return Center(child: Text(l10n.teamNotFound));
    }
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        return ListTile(
          onTap: () {
            setState(() {
              _selectedTeam = team;
              searchController.clear();
              ref.read(teamSearchQueryProvider.notifier).state = '';
            });
          },
          leading: TeamLogo(
            logoUrl: team.logoUrl,
            teamName: team.name,
            size: 40,
          ),
          title: Text(
            team.nameKr,
            style: const TextStyle(color: Colors.black87),
          ),
          subtitle: Text(
            AppConstants.getLocalizedLeagueName(context, team.league),
            style: TextStyle(color: Colors.grey.shade600),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        );
      },
    );
  }

  Widget _buildTeamPlayers() {
    final l10n = AppLocalizations.of(context)!;
    final playersAsync = ref.watch(teamSquadProvider(_selectedTeam!.id));
    final favoritePlayerIdsAsync = ref.watch(favoritePlayerIdsProvider);

    return playersAsync.when(
      data: (players) {
        if (players.isEmpty) {
          return Center(child: Text(l10n.playerNotFound));
        }

        // 로컬 필터링 (글자 수 제한 없음)
        final filteredPlayers = _playerFilter.isEmpty
            ? players
            : players.where((p) {
                final query = _playerFilter.toLowerCase();
                return p.name.toLowerCase().contains(query) ||
                    p.nameKr.toLowerCase().contains(query) ||
                    p.position.toLowerCase().contains(query);
              }).toList();

        if (filteredPlayers.isEmpty) {
          return Center(child: Text(l10n.playerNotFound));
        }

        return ListView.builder(
          controller: widget.scrollController,
          itemCount: filteredPlayers.length,
          itemBuilder: (context, index) {
            final player = filteredPlayers[index];

            return favoritePlayerIdsAsync.when(
              data: (favoriteIds) {
                final isFollowed = favoriteIds.contains(player.id);
                return _buildPlayerTile(player, isFollowed);
              },
              loading: () => _buildPlayerTile(player, false, isLoading: true),
              error: (_, __) => _buildPlayerTile(player, false),
            );
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildPlayerTile(Player player, bool isFollowed, {bool isLoading = false}) {
    return ListTile(
      onTap: () {
        Navigator.pop(context);
        context.push('/player/${player.id}');
      },
      leading: CircleAvatar(
        backgroundImage: player.photoUrl != null
            ? NetworkImage(player.photoUrl!)
            : null,
        child: player.photoUrl == null
            ? Text(
                player.name.isNotEmpty ? player.name.substring(0, 1) : '?',
                style: const TextStyle(color: Colors.white),
              )
            : null,
      ),
      title: Text(
        player.nameKr,
        style: const TextStyle(color: Colors.black87),
      ),
      subtitle: Text(
        player.position,
        style: TextStyle(color: Colors.grey.shade600),
      ),
      trailing: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              icon: Icon(
                isFollowed ? Icons.favorite : Icons.favorite_border,
                color: isFollowed ? AppColors.error : Colors.grey,
              ),
              onPressed: () async {
                try {
                  await ref
                      .read(favoritesNotifierProvider.notifier)
                      .togglePlayerFollow(player.id);
                } catch (e) {
                  if (e.toString().contains('LOGIN_REQUIRED') && mounted) {
                    showLoginRequiredDialog(context);
                  }
                }
              },
            ),
    );
  }

  Widget _buildLeagueFilter() {
    final l10n = AppLocalizations.of(context)!;
    final localLeagueIds = ref.watch(userLocalLeagueIdsProvider);

    // 자국 리그 이름 목록 생성
    final localLeagueNames = localLeagueIds
        .map((id) => AppConstants.getLeagueNameById(id))
        .whereType<String>()
        .toList();

    // 전체 리그 목록: 기본 리그 + 자국 리그
    final allLeagues = [
      ...AppConstants.supportedLeagues,
      ...localLeagueNames,
    ];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _LeagueFilterChip(
            label: l10n.all,
            isSelected: _selectedLeague == null,
            onTap: () => setState(() => _selectedLeague = null),
          ),
          ...allLeagues.map((league) => _LeagueFilterChip(
            label: _getLeagueDisplayName(league),
            isSelected: _selectedLeague == league,
            onTap: () => setState(() => _selectedLeague = league),
          )),
        ],
      ),
    );
  }

  String _getLeagueDisplayName(String league) {
    // A매치 (국제대회) 여부 판별
    if (AppConstants.isInternationalMatch(league)) {
      return AppLocalizations.of(context)!.national;
    }
    return AppConstants.getLocalizedLeagueName(context, league);
  }
}

class _LeagueFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LeagueFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.black87,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        backgroundColor: Colors.grey.shade200,
        checkmarkColor: AppColors.primary,
      ),
    );
  }
}
