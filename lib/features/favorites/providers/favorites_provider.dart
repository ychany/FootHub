import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/team_model.dart';
import '../../../shared/models/player_model.dart';
import '../services/favorites_service.dart';
import '../../auth/providers/auth_provider.dart';

// Favorites Service Provider
final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  return FavoritesService();
});

// === Team Favorites ===

// Favorite Team IDs Provider
final favoriteTeamIdsProvider = StreamProvider<List<String>>((ref) {
  final service = ref.watch(favoritesServiceProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return Stream.value([]);
  return service.favoriteTeamIdsStream(userId);
});

// Favorite Teams with Details Provider
final favoriteTeamsProvider = FutureProvider<List<Team>>((ref) async {
  final service = ref.watch(favoritesServiceProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return [];
  return service.getFavoriteTeams(userId);
});

// Is Team Followed Provider
final isTeamFollowedProvider =
    FutureProvider.family<bool, String>((ref, teamId) async {
  final service = ref.watch(favoritesServiceProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return false;
  return service.isTeamFollowed(userId, teamId);
});

// === Player Favorites ===

// Favorite Player IDs Provider
final favoritePlayerIdsProvider = StreamProvider<List<String>>((ref) {
  final service = ref.watch(favoritesServiceProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return Stream.value([]);
  return service.favoritePlayerIdsStream(userId);
});

// Favorite Players with Details Provider
final favoritePlayersProvider = FutureProvider<List<Player>>((ref) async {
  final service = ref.watch(favoritesServiceProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return [];
  return service.getFavoritePlayers(userId);
});

// Is Player Followed Provider
final isPlayerFollowedProvider =
    FutureProvider.family<bool, String>((ref, playerId) async {
  final service = ref.watch(favoritesServiceProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return false;
  return service.isPlayerFollowed(userId, playerId);
});

// === Search ===

// Team Search Query Provider
final teamSearchQueryProvider = StateProvider<String>((ref) => '');

// Team Search Results Provider
final teamSearchResultsProvider = FutureProvider<List<Team>>((ref) async {
  final service = ref.watch(favoritesServiceProvider);
  final query = ref.watch(teamSearchQueryProvider);

  if (query.isEmpty) return [];
  return service.searchTeams(query);
});

// Player Search Query Provider
final playerSearchQueryProvider = StateProvider<String>((ref) => '');

// Player Search Results Provider
final playerSearchResultsProvider = FutureProvider<List<Player>>((ref) async {
  final service = ref.watch(favoritesServiceProvider);
  final query = ref.watch(playerSearchQueryProvider);

  if (query.isEmpty) return [];
  return service.searchPlayers(query);
});

// === Teams by League ===
final teamsByLeagueProvider =
    FutureProvider.family<List<Team>, String>((ref, league) async {
  final service = ref.watch(favoritesServiceProvider);
  return service.getTeamsByLeague(league);
});

// === Players by Team ===
final playersByTeamProvider =
    FutureProvider.family<List<Player>, String>((ref, teamId) async {
  final service = ref.watch(favoritesServiceProvider);
  return service.getPlayersByTeam(teamId);
});

// Alias for team squad (used in player search by team)
final teamSquadProvider = playersByTeamProvider;

// Favorites Notifier for actions
class FavoritesNotifier extends StateNotifier<AsyncValue<void>> {
  final FavoritesService _service;
  final Ref _ref;

  FavoritesNotifier(this._service, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> toggleTeamFollow(String teamId) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      throw Exception('LOGIN_REQUIRED');
    }

    state = const AsyncValue.loading();
    try {
      final isNowFollowed = await _service.toggleTeamFollow(userId, teamId);
      state = const AsyncValue.data(null);
      // Invalidate related providers
      _ref.invalidate(isTeamFollowedProvider(teamId));
      _ref.invalidate(favoriteTeamsProvider);
      return isNowFollowed;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> followTeam(String teamId) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncValue.loading();
    try {
      await _service.followTeam(userId, teamId);
      state = const AsyncValue.data(null);
      _ref.invalidate(isTeamFollowedProvider(teamId));
      _ref.invalidate(favoriteTeamsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> unfollowTeam(String teamId) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncValue.loading();
    try {
      await _service.unfollowTeam(userId, teamId);
      state = const AsyncValue.data(null);
      _ref.invalidate(isTeamFollowedProvider(teamId));
      _ref.invalidate(favoriteTeamsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> togglePlayerFollow(String playerId) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      throw Exception('LOGIN_REQUIRED');
    }

    state = const AsyncValue.loading();
    try {
      final isNowFollowed = await _service.togglePlayerFollow(userId, playerId);
      state = const AsyncValue.data(null);
      _ref.invalidate(isPlayerFollowedProvider(playerId));
      _ref.invalidate(favoritePlayersProvider);
      return isNowFollowed;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> followPlayer(String playerId) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncValue.loading();
    try {
      await _service.followPlayer(userId, playerId);
      state = const AsyncValue.data(null);
      _ref.invalidate(isPlayerFollowedProvider(playerId));
      _ref.invalidate(favoritePlayersProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> unfollowPlayer(String playerId) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    state = const AsyncValue.loading();
    try {
      await _service.unfollowPlayer(userId, playerId);
      state = const AsyncValue.data(null);
      _ref.invalidate(isPlayerFollowedProvider(playerId));
      _ref.invalidate(favoritePlayersProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final favoritesNotifierProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(favoritesServiceProvider);
  return FavoritesNotifier(service, ref);
});

// Selected Tab Provider for Favorites Screen
enum FavoritesTab { teams, players }

final selectedFavoritesTabProvider = StateProvider<FavoritesTab>((ref) {
  return FavoritesTab.teams;
});
