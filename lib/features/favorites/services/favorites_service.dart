import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/sports_db_service.dart';
import '../../../shared/models/team_model.dart';
import '../../../shared/models/player_model.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SportsDbService _sportsDbService = SportsDbService();

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
          final sportsDbTeam = await _sportsDbService.getTeamById(teamId);
          if (sportsDbTeam != null) {
            final team = _convertSportsDbTeam(sportsDbTeam);
            teams.add(team);
            // 백그라운드로 저장
            _saveTeamToFirestore(teamId);
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
    await _saveTeamToFirestore(teamId);
  }

  // 팀 정보를 Firestore에 저장
  Future<void> _saveTeamToFirestore(String teamId) async {
    try {
      final existingDoc = await _teamsCollection.doc(teamId).get();
      if (existingDoc.exists) return; // 이미 있으면 스킵

      final sportsDbTeam = await _sportsDbService.getTeamById(teamId);
      if (sportsDbTeam == null) return;

      await _teamsCollection.doc(teamId).set({
        'name': sportsDbTeam.name,
        'nameKr': sportsDbTeam.nameKr ?? sportsDbTeam.name,
        'shortName': sportsDbTeam.name.length > 3
            ? sportsDbTeam.name.substring(0, 3).toUpperCase()
            : sportsDbTeam.name.toUpperCase(),
        'league': sportsDbTeam.league ?? '',
        'country': sportsDbTeam.country,
        'logoUrl': sportsDbTeam.badge,
        'stadiumName': sportsDbTeam.stadium,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      // 에러 무시 - 저장 실패해도 즐겨찾기는 동작
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
          final sportsDbPlayer = await _sportsDbService.getPlayerById(playerId);
          if (sportsDbPlayer != null) {
            final player = _convertSportsDbPlayer(sportsDbPlayer);
            players.add(player);
            // 백그라운드로 저장
            _savePlayerToFirestore(playerId);
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
    await _savePlayerToFirestore(playerId);
  }

  // 선수 정보를 Firestore에 저장
  Future<void> _savePlayerToFirestore(String playerId) async {
    try {
      final existingDoc = await _playersCollection.doc(playerId).get();
      if (existingDoc.exists) return; // 이미 있으면 스킵

      final sportsDbPlayer = await _sportsDbService.getPlayerById(playerId);
      if (sportsDbPlayer == null) return;

      await _playersCollection.doc(playerId).set({
        'name': sportsDbPlayer.name,
        'nameKr': sportsDbPlayer.nameKr ?? sportsDbPlayer.name,
        'teamId': sportsDbPlayer.teamId ?? '',
        'teamName': sportsDbPlayer.team ?? '',
        'position': sportsDbPlayer.position ?? '',
        'number': int.tryParse(sportsDbPlayer.number ?? ''),
        'nationality': sportsDbPlayer.nationality,
        'photoUrl': sportsDbPlayer.photo,
        'birthDate': sportsDbPlayer.dateBorn,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      // 에러 무시 - 저장 실패해도 즐겨찾기는 동작
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

  // === Search (using SportsDB API) ===

  // Search teams using SportsDB API
  Future<List<Team>> searchTeams(String query) async {
    if (query.length < 2) return [];

    try {
      final sportsDbTeams = await _sportsDbService.searchTeams(query);
      return sportsDbTeams.map((t) => _convertSportsDbTeam(t)).toList();
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

  // Search players using SportsDB API
  Future<List<Player>> searchPlayers(String query) async {
    if (query.length < 2) return [];

    try {
      final sportsDbPlayers = await _sportsDbService.searchPlayers(query);
      return sportsDbPlayers.map((p) => _convertSportsDbPlayer(p)).toList();
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

  // Get teams by league using SportsDB API
  Future<List<Team>> getTeamsByLeague(String league) async {
    try {
      final sportsDbTeams = await _sportsDbService.getTeamsByLeague(league);
      return sportsDbTeams.map((t) => _convertSportsDbTeam(t)).toList();
    } catch (e) {
      // Fallback to Firestore
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

  // Get players by team using SportsDB API
  Future<List<Player>> getPlayersByTeam(String teamId) async {
    try {
      final sportsDbPlayers = await _sportsDbService.getPlayersByTeam(teamId);
      return sportsDbPlayers.map((p) => _convertSportsDbPlayer(p)).toList();
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

  // Convert SportsDbTeam to Team model
  Team _convertSportsDbTeam(SportsDbTeam sportsDbTeam) {
    return Team(
      id: sportsDbTeam.id,
      name: sportsDbTeam.name,
      nameKr: sportsDbTeam.nameKr ?? sportsDbTeam.name,
      shortName: sportsDbTeam.name.length > 3
          ? sportsDbTeam.name.substring(0, 3).toUpperCase()
          : sportsDbTeam.name.toUpperCase(),
      league: sportsDbTeam.league ?? '',
      country: sportsDbTeam.country,
      logoUrl: sportsDbTeam.badge,
      stadiumName: sportsDbTeam.stadium,
    );
  }

  // Convert SportsDbPlayer to Player model
  Player _convertSportsDbPlayer(SportsDbPlayer sportsDbPlayer) {
    return Player(
      id: sportsDbPlayer.id,
      name: sportsDbPlayer.name,
      nameKr: sportsDbPlayer.nameKr ?? sportsDbPlayer.name,
      teamId: sportsDbPlayer.teamId ?? '',
      teamName: sportsDbPlayer.team ?? '',
      position: sportsDbPlayer.position ?? '',
      number: int.tryParse(sportsDbPlayer.number ?? ''),
      nationality: sportsDbPlayer.nationality,
      photoUrl: sportsDbPlayer.photo,
      birthDate: _parseDateString(sportsDbPlayer.dateBorn),
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
