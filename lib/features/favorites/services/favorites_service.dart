import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_football_service.dart';
import '../../../core/constants/api_football_ids.dart';
import '../../../shared/models/team_model.dart';
import '../../../shared/models/player_model.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiFootballService _apiService = ApiFootballService();

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(AppConstants.usersCollection);

  CollectionReference<Map<String, dynamic>> get _teamsCollection =>
      _firestore.collection(AppConstants.teamsCollection);

  CollectionReference<Map<String, dynamic>> get _playersCollection =>
      _firestore.collection(AppConstants.playersCollection);

  // === Team Favorites ===

  // Get favorite team IDs
  Future<List<String>> getFavoriteTeamIds(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    if (!doc.exists) return [];

    final data = doc.data();
    return List<String>.from(data?['favoriteTeamIds'] ?? []);
  }

  // Stream favorite team IDs
  Stream<List<String>> favoriteTeamIdsStream(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return <String>[];
      final data = doc.data();
      return List<String>.from(data?['favoriteTeamIds'] ?? []);
    });
  }

  // Get favorite teams with details
  Future<List<Team>> getFavoriteTeams(String userId) async {
    final teamIds = await getFavoriteTeamIds(userId);
    if (teamIds.isEmpty) return [];

    final teams = <Team>[];
    for (final teamId in teamIds) {
      // 먼저 Firestore에서 확인
      final doc = await _teamsCollection.doc(teamId).get();
      if (doc.exists) {
        teams.add(Team.fromFirestore(doc));
      } else {
        // Firestore에 없으면 API에서 가져와서 저장 후 반환
        try {
          final apiTeamId = int.tryParse(teamId);
          if (apiTeamId != null) {
            final apiTeam = await _apiService.getTeamById(apiTeamId);
            if (apiTeam != null) {
              final team = _convertApiTeam(apiTeam);
              teams.add(team);
              // 백그라운드로 저장
              _saveTeamToFirestore(teamId, apiTeam);
            }
          }
        } catch (e) {
          // API 실패시 무시
        }
      }
    }
    return teams;
  }

  // Follow a team
  Future<void> followTeam(String userId, String teamId) async {
    // set with merge를 사용하여 문서가 없어도 생성됨
    await _usersCollection.doc(userId).set({
      'favoriteTeamIds': FieldValue.arrayUnion([teamId]),
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));

    // 팀 정보도 저장 (API에서 가져와서)
    await _saveTeamToFirestoreById(teamId);
  }

  // 팀 정보를 Firestore에 저장 (API에서 조회)
  Future<void> _saveTeamToFirestoreById(String teamId) async {
    try {
      final existingDoc = await _teamsCollection.doc(teamId).get();
      if (existingDoc.exists) return; // 이미 있으면 스킵

      final apiTeamId = int.tryParse(teamId);
      if (apiTeamId == null) return;

      final apiTeam = await _apiService.getTeamById(apiTeamId);
      if (apiTeam == null) return;

      await _saveTeamToFirestore(teamId, apiTeam);
    } catch (e) {
      // 에러 무시 - 저장 실패해도 즐겨찾기는 동작
    }
  }

  // 팀 정보를 Firestore에 저장
  Future<void> _saveTeamToFirestore(String teamId, ApiFootballTeam apiTeam) async {
    try {
      await _teamsCollection.doc(teamId).set({
        'name': apiTeam.name,
        'nameKr': apiTeam.name, // API-Football은 한글명 없음
        'shortName': apiTeam.code ?? apiTeam.name.substring(0, 3).toUpperCase(),
        'league': '', // 별도 조회 필요
        'country': apiTeam.country,
        'logoUrl': apiTeam.logo,
        'stadiumName': apiTeam.venue?.name,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      // 에러 무시
    }
  }

  // Unfollow a team
  Future<void> unfollowTeam(String userId, String teamId) async {
    await _usersCollection.doc(userId).set({
      'favoriteTeamIds': FieldValue.arrayRemove([teamId]),
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  // Check if team is followed
  Future<bool> isTeamFollowed(String userId, String teamId) async {
    final teamIds = await getFavoriteTeamIds(userId);
    return teamIds.contains(teamId);
  }

  // Toggle team follow status
  Future<bool> toggleTeamFollow(String userId, String teamId) async {
    final isFollowed = await isTeamFollowed(userId, teamId);

    if (isFollowed) {
      await unfollowTeam(userId, teamId);
      return false;
    } else {
      await followTeam(userId, teamId);
      return true;
    }
  }

  // === Player Favorites ===

  // Get favorite player IDs
  Future<List<String>> getFavoritePlayerIds(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    if (!doc.exists) return [];

    final data = doc.data();
    return List<String>.from(data?['favoritePlayerIds'] ?? []);
  }

  // Stream favorite player IDs
  Stream<List<String>> favoritePlayerIdsStream(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return <String>[];
      final data = doc.data();
      return List<String>.from(data?['favoritePlayerIds'] ?? []);
    });
  }

  // Get favorite players with details
  Future<List<Player>> getFavoritePlayers(String userId) async {
    final playerIds = await getFavoritePlayerIds(userId);
    if (playerIds.isEmpty) return [];

    final players = <Player>[];
    for (final playerId in playerIds) {
      // 먼저 Firestore에서 확인
      final doc = await _playersCollection.doc(playerId).get();
      if (doc.exists) {
        players.add(Player.fromFirestore(doc));
      } else {
        // Firestore에 없으면 API에서 가져와서 저장 후 반환
        try {
          final apiPlayerId = int.tryParse(playerId);
          if (apiPlayerId != null) {
            final apiPlayer = await _apiService.getPlayerById(apiPlayerId);
            if (apiPlayer != null) {
              final player = _convertApiPlayer(apiPlayer);
              players.add(player);
              // 백그라운드로 저장
              _savePlayerToFirestore(playerId, apiPlayer);
            }
          }
        } catch (e) {
          // API 실패시 무시
        }
      }
    }
    return players;
  }

  // Follow a player
  Future<void> followPlayer(String userId, String playerId) async {
    await _usersCollection.doc(userId).set({
      'favoritePlayerIds': FieldValue.arrayUnion([playerId]),
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));

    // 선수 정보도 저장 (API에서 가져와서)
    await _savePlayerToFirestoreById(playerId);
  }

  // 선수 정보를 Firestore에 저장 (API에서 조회)
  Future<void> _savePlayerToFirestoreById(String playerId) async {
    try {
      final existingDoc = await _playersCollection.doc(playerId).get();
      if (existingDoc.exists) return; // 이미 있으면 스킵

      final apiPlayerId = int.tryParse(playerId);
      if (apiPlayerId == null) return;

      final apiPlayer = await _apiService.getPlayerById(apiPlayerId);
      if (apiPlayer == null) return;

      await _savePlayerToFirestore(playerId, apiPlayer);
    } catch (e) {
      // 에러 무시 - 저장 실패해도 즐겨찾기는 동작
    }
  }

  // 선수 정보를 Firestore에 저장
  Future<void> _savePlayerToFirestore(String playerId, ApiFootballPlayer apiPlayer) async {
    try {
      final stats = apiPlayer.statistics.isNotEmpty ? apiPlayer.statistics.first : null;

      await _playersCollection.doc(playerId).set({
        'name': apiPlayer.name,
        'nameKr': apiPlayer.name, // API-Football은 한글명 없음
        'teamId': stats?.teamId?.toString() ?? '',
        'teamName': stats?.teamName ?? '',
        'position': stats?.position ?? '',
        'number': null, // 별도 조회 필요
        'nationality': apiPlayer.nationality,
        'photoUrl': apiPlayer.photo,
        'birthDate': apiPlayer.birthDate,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      // 에러 무시
    }
  }

  // Unfollow a player
  Future<void> unfollowPlayer(String userId, String playerId) async {
    await _usersCollection.doc(userId).set({
      'favoritePlayerIds': FieldValue.arrayRemove([playerId]),
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  // Check if player is followed
  Future<bool> isPlayerFollowed(String userId, String playerId) async {
    final playerIds = await getFavoritePlayerIds(userId);
    return playerIds.contains(playerId);
  }

  // Toggle player follow status
  Future<bool> togglePlayerFollow(String userId, String playerId) async {
    final isFollowed = await isPlayerFollowed(userId, playerId);

    if (isFollowed) {
      await unfollowPlayer(userId, playerId);
      return false;
    } else {
      await followPlayer(userId, playerId);
      return true;
    }
  }

  // === Search (using API-Football) ===

  // Search players using API-Football
  Future<List<Player>> searchPlayers(String query) async {
    if (query.length < 2) return [];

    try {
      final apiPlayers = await _apiService.searchPlayers(query);
      return apiPlayers.map((p) => _convertApiPlayer(p)).toList();
    } catch (e) {
      // Fallback to Firestore
      return _searchPlayersFromFirestore(query);
    }
  }

  // Firestore fallback for player search
  Future<List<Player>> _searchPlayersFromFirestore(String query) async {
    final snapshot = await _playersCollection.get();
    final lowerQuery = query.toLowerCase();

    return snapshot.docs
        .map((doc) => Player.fromFirestore(doc))
        .where((player) =>
            player.name.toLowerCase().contains(lowerQuery) ||
            player.nameKr.toLowerCase().contains(lowerQuery))
        .toList();
  }

  // Search teams using API-Football
  Future<List<Team>> searchTeams(String query) async {
    if (query.length < 2) return [];

    try {
      final apiTeams = await _apiService.searchTeams(query);
      return apiTeams.map((t) => _convertApiTeam(t)).toList();
    } catch (e) {
      // Fallback to Firestore
      return _searchTeamsFromFirestore(query);
    }
  }

  // Firestore fallback for team search
  Future<List<Team>> _searchTeamsFromFirestore(String query) async {
    final snapshot = await _teamsCollection.get();
    final lowerQuery = query.toLowerCase();

    return snapshot.docs
        .map((doc) => Team.fromFirestore(doc))
        .where((team) =>
            team.name.toLowerCase().contains(lowerQuery) ||
            team.nameKr.toLowerCase().contains(lowerQuery) ||
            team.shortName.toLowerCase().contains(lowerQuery))
        .toList();
  }

  // Get teams by league using API-Football
  Future<List<Team>> getTeamsByLeague(String league) async {
    try {
      final leagueId = ApiFootballIds.getLeagueId(league);
      if (leagueId == null) {
        print('getTeamsByLeague: leagueId is null for $league, using Firestore');
        return _getTeamsByLeagueFromFirestore(league);
      }

      final season = LeagueIds.getCurrentSeason();
      print('getTeamsByLeague: Fetching league $leagueId season $season');
      final apiTeams = await _apiService.getTeamsByLeague(leagueId, season);
      print('getTeamsByLeague: Got ${apiTeams.length} teams from API');

      if (apiTeams.isEmpty) {
        // 현재 시즌에 팀이 없으면 이전 시즌 시도
        final prevSeasonTeams = await _apiService.getTeamsByLeague(leagueId, season - 1);
        print('getTeamsByLeague: Got ${prevSeasonTeams.length} teams from prev season');
        if (prevSeasonTeams.isNotEmpty) {
          final teams = prevSeasonTeams.map((t) => _convertApiTeam(t)).toList();
          teams.sort((a, b) => a.name.compareTo(b.name));
          return teams;
        }
      }

      final teams = apiTeams.map((t) => _convertApiTeam(t)).toList();
      teams.sort((a, b) => a.name.compareTo(b.name));
      return teams;
    } catch (e) {
      // Fallback to Firestore
      print('getTeamsByLeague: Error $e, using Firestore fallback');
      return _getTeamsByLeagueFromFirestore(league);
    }
  }

  // Firestore fallback for teams by league
  Future<List<Team>> _getTeamsByLeagueFromFirestore(String league) async {
    final snapshot = await _teamsCollection
        .where('league', isEqualTo: league)
        .orderBy('name')
        .get();

    return snapshot.docs.map((doc) => Team.fromFirestore(doc)).toList();
  }

  // Get players by team using API-Football
  Future<List<Player>> getPlayersByTeam(String teamId) async {
    try {
      final apiTeamId = int.tryParse(teamId);
      if (apiTeamId == null) {
        return _getPlayersByTeamFromFirestore(teamId);
      }

      final squadPlayers = await _apiService.getTeamSquad(apiTeamId);
      return squadPlayers.map((p) => _convertSquadPlayer(p, teamId)).toList();
    } catch (e) {
      // Fallback to Firestore
      return _getPlayersByTeamFromFirestore(teamId);
    }
  }

  // Firestore fallback for players by team
  Future<List<Player>> _getPlayersByTeamFromFirestore(String teamId) async {
    final snapshot = await _playersCollection
        .where('teamId', isEqualTo: teamId)
        .orderBy('number')
        .get();

    return snapshot.docs.map((doc) => Player.fromFirestore(doc)).toList();
  }

  // === Converters ===

  // Convert ApiFootballTeam to Team model
  Team _convertApiTeam(ApiFootballTeam apiTeam) {
    return Team(
      id: apiTeam.id.toString(),
      name: apiTeam.name,
      nameKr: apiTeam.name, // API-Football은 한글명 없음
      shortName: apiTeam.code ?? (apiTeam.name.length > 3
          ? apiTeam.name.substring(0, 3).toUpperCase()
          : apiTeam.name.toUpperCase()),
      league: '', // 별도 조회 필요
      country: apiTeam.country,
      logoUrl: apiTeam.logo,
      stadiumName: apiTeam.venue?.name,
    );
  }

  // Convert ApiFootballPlayer to Player model
  Player _convertApiPlayer(ApiFootballPlayer apiPlayer) {
    final stats = apiPlayer.statistics.isNotEmpty ? apiPlayer.statistics.first : null;

    return Player(
      id: apiPlayer.id.toString(),
      name: apiPlayer.name,
      nameKr: apiPlayer.name, // API-Football은 한글명 없음
      teamId: stats?.teamId?.toString() ?? '',
      teamName: stats?.teamName ?? '',
      position: stats?.position ?? '',
      number: null, // 별도 조회 필요
      nationality: apiPlayer.nationality,
      photoUrl: apiPlayer.photo,
      birthDate: _parseDateString(apiPlayer.birthDate),
    );
  }

  // Convert ApiFootballSquadPlayer to Player model
  Player _convertSquadPlayer(ApiFootballSquadPlayer squadPlayer, String teamId) {
    return Player(
      id: squadPlayer.id.toString(),
      name: squadPlayer.name,
      nameKr: squadPlayer.name,
      teamId: teamId,
      teamName: '', // 별도 조회 필요
      position: squadPlayer.position ?? '',
      number: squadPlayer.number,
      nationality: null,
      photoUrl: squadPlayer.photo,
      birthDate: null,
    );
  }

  // Parse date string to DateTime
  DateTime? _parseDateString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }
}
