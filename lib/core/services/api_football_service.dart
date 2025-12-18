import 'dart:convert';
import 'package:http/http.dart' as http;

/// API-Football 서비스
/// API Key: 845ed01c6cbc3b264fd6cd78f8da9823 (Pro)
/// Base URL: https://v3.football.api-sports.io
/// 문서: https://www.api-football.com/documentation-v3
class ApiFootballService {
  static const String _baseUrl = 'https://v3.football.api-sports.io';
  static const String _apiKey = '845ed01c6cbc3b264fd6cd78f8da9823';

  // 싱글톤 패턴
  static final ApiFootballService _instance = ApiFootballService._internal();
  factory ApiFootballService() => _instance;
  ApiFootballService._internal();

  /// API 호출 헬퍼
  Future<Map<String, dynamic>?> _get(String endpoint) async {
    try {
      final url = '$_baseUrl/$endpoint';
      final response = await http.get(
        Uri.parse(url),
        headers: {'x-apisports-key': _apiKey},
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty || response.body.trim().isEmpty) {
          return null;
        }
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('API-Football Error: $e');
      return null;
    }
  }

  // ============ 리그 ============

  /// 모든 리그 조회
  Future<List<ApiFootballLeague>> getAllLeagues() async {
    final data = await _get('leagues');
    if (data == null || data['response'] == null) return [];

    return (data['response'] as List)
        .map((json) => ApiFootballLeague.fromJson(json))
        .toList();
  }

  /// 리그 검색
  Future<List<ApiFootballLeague>> searchLeagues(String query) async {
    final data = await _get('leagues?search=${Uri.encodeComponent(query)}');
    if (data == null || data['response'] == null) return [];

    return (data['response'] as List)
        .map((json) => ApiFootballLeague.fromJson(json))
        .toList();
  }

  /// 리그 ID로 조회
  Future<ApiFootballLeague?> getLeagueById(int leagueId) async {
    final data = await _get('leagues?id=$leagueId');
    if (data == null || data['response'] == null || (data['response'] as List).isEmpty) {
      return null;
    }
    return ApiFootballLeague.fromJson((data['response'] as List).first);
  }

  // ============ 팀 ============

  /// 팀 검색
  Future<List<ApiFootballTeam>> searchTeams(String query) async {
    final data = await _get('teams?search=${Uri.encodeComponent(query)}');
    if (data == null || data['response'] == null) return [];

    return (data['response'] as List)
        .map((json) => ApiFootballTeam.fromJson(json))
        .toList();
  }

  /// 팀 ID로 조회
  Future<ApiFootballTeam?> getTeamById(int teamId) async {
    final data = await _get('teams?id=$teamId');
    if (data == null || data['response'] == null || (data['response'] as List).isEmpty) {
      return null;
    }
    return ApiFootballTeam.fromJson((data['response'] as List).first);
  }

  /// 리그별 팀 목록
  Future<List<ApiFootballTeam>> getTeamsByLeague(int leagueId, int season) async {
    final data = await _get('teams?league=$leagueId&season=$season');
    if (data == null || data['response'] == null) return [];

    return (data['response'] as List)
        .map((json) => ApiFootballTeam.fromJson(json))
        .toList();
  }

  // ============ 경기장 ============

  /// 경기장 ID로 조회
  Future<ApiFootballVenue?> getVenueById(int venueId) async {
    final data = await _get('venues?id=$venueId');
    if (data == null || data['response'] == null || (data['response'] as List).isEmpty) {
      return null;
    }
    return ApiFootballVenue.fromJson((data['response'] as List).first);
  }

  /// 경기장 이름으로 검색
  Future<List<ApiFootballVenue>> searchVenues(String query) async {
    final data = await _get('venues?search=${Uri.encodeComponent(query)}');
    if (data == null || data['response'] == null) return [];

    return (data['response'] as List)
        .map((json) => ApiFootballVenue.fromJson(json))
        .toList();
  }

  /// 도시별 경기장 조회
  Future<List<ApiFootballVenue>> getVenuesByCity(String city) async {
    final data = await _get('venues?city=${Uri.encodeComponent(city)}');
    if (data == null || data['response'] == null) return [];

    return (data['response'] as List)
        .map((json) => ApiFootballVenue.fromJson(json))
        .toList();
  }

  /// 국가별 경기장 조회
  Future<List<ApiFootballVenue>> getVenuesByCountry(String country) async {
    final data = await _get('venues?country=${Uri.encodeComponent(country)}');
    if (data == null || data['response'] == null) return [];

    return (data['response'] as List)
        .map((json) => ApiFootballVenue.fromJson(json))
        .toList();
  }

  // ============ 선수 ============

  /// 선수 검색 (이름으로)
  Future<List<ApiFootballPlayer>> searchPlayers(String query) async {
    final season = DateTime.now().year;
    final data = await _get('players?search=${Uri.encodeComponent(query)}&season=$season');
    if (data == null || data['response'] == null) return [];

    return (data['response'] as List)
        .map((json) => ApiFootballPlayer.fromJson(json))
        .toList();
  }

  /// 선수 ID로 조회
  Future<ApiFootballPlayer?> getPlayerById(int playerId, {int? season}) async {
    String endpoint = 'players?id=$playerId';
    if (season != null) {
      endpoint += '&season=$season';
    } else {
      endpoint += '&season=${DateTime.now().year}';
    }

    final data = await _get(endpoint);
    if (data == null || data['response'] == null || (data['response'] as List).isEmpty) {
      return null;
    }
    return ApiFootballPlayer.fromJson((data['response'] as List).first);
  }

  /// 팀별 선수 목록 (스쿼드)
  Future<List<ApiFootballSquadPlayer>> getTeamSquad(int teamId) async {
    final data = await _get('players/squads?team=$teamId');
    if (data == null || data['response'] == null || (data['response'] as List).isEmpty) {
      return [];
    }

    final teamData = (data['response'] as List).first;
    if (teamData['players'] == null) return [];

    final players = (teamData['players'] as List)
        .map((json) => ApiFootballSquadPlayer.fromJson(json))
        .toList();

    // 선수 ID 기준 중복 제거
    final seenIds = <int>{};
    return players.where((player) {
      if (seenIds.contains(player.id)) return false;
      seenIds.add(player.id);
      return true;
    }).toList();
  }

  /// 선수 이적 기록
  Future<List<ApiFootballTransfer>> getPlayerTransfers(int playerId) async {
    final data = await _get('transfers?player=$playerId');
    if (data == null || data['response'] == null || (data['response'] as List).isEmpty) {
      return [];
    }

    final playerData = (data['response'] as List).first;
    if (playerData['transfers'] == null) return [];

    return (playerData['transfers'] as List)
        .map((json) => ApiFootballTransfer.fromJson(json))
        .toList();
  }

  /// 팀 이적 기록 조회
  Future<List<ApiFootballTeamTransfer>> getTeamTransfers(int teamId) async {
    final data = await _get('transfers?team=$teamId');
    if (data == null || data['response'] == null) return [];

    return (data['response'] as List)
        .map((json) => ApiFootballTeamTransfer.fromJson(json))
        .toList();
  }

  /// 경기별 부상/결장 선수 조회
  Future<List<ApiFootballInjury>> getFixtureInjuries(int fixtureId) async {
    final data = await _get('injuries?fixture=$fixtureId');
    if (data == null || data['response'] == null) return [];

    return (data['response'] as List)
        .map((json) => ApiFootballInjury.fromJson(json))
        .toList();
  }

  /// 팀별 부상/결장 선수 조회 (현재 시즌)
  Future<List<ApiFootballInjury>> getTeamInjuries(int teamId, int season) async {
    final data = await _get('injuries?team=$teamId&season=$season');
    if (data == null || data['response'] == null) return [];

    final injuries = (data['response'] as List)
        .map((json) => ApiFootballInjury.fromJson(json))
        .toList();

    // 선수 ID 기준 중복 제거 (가장 최근 부상 정보만 유지)
    final seenPlayerIds = <int>{};
    return injuries.where((injury) {
      if (seenPlayerIds.contains(injury.playerId)) return false;
      seenPlayerIds.add(injury.playerId);
      return true;
    }).toList();
  }

  /// 선수 트로피
  Future<List<ApiFootballTrophy>> getPlayerTrophies(int playerId) async {
    final data = await _get('trophies?player=$playerId');
    if (data == null || data['response'] == null) return [];

    return (data['response'] as List)
        .map((json) => ApiFootballTrophy.fromJson(json))
        .toList();
  }

  // ============ 경기 (Fixtures) ============

  /// 날짜별 경기 조회
  Future<List<ApiFootballFixture>> getFixturesByDate(DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final data = await _get('fixtures?date=$dateStr');
    if (data == null || data['response'] == null) return [];

    return (data['response'] as List)
        .map((json) => ApiFootballFixture.fromJson(json))
        .toList();
  }

  /// 리그/시즌별 경기 조회
  Future<List<ApiFootballFixture>> getFixturesByLeague(int leagueId, int season) async {
    final data = await _get('fixtures?league=$leagueId&season=$season');
    if (data == null || data['response'] == null) return [];

    return (data['response'] as List)
        .map((json) => ApiFootballFixture.fromJson(json))
        .toList();
  }

  /// 팀의 다음 경기들
  Future<List<ApiFootballFixture>> getTeamNextFixtures(int teamId, {int count = 5}) async {
    final data = await _get('fixtures?team=$teamId&next=$count');
    if (data == null || data['response'] == null) return [];

    return (data['response'] as List)
        .map((json) => ApiFootballFixture.fromJson(json))
        .toList();
  }

  /// 팀의 지난 경기들
  Future<List<ApiFootballFixture>> getTeamLastFixtures(int teamId, {int count = 5}) async {
    final data = await _get('fixtures?team=$teamId&last=$count');
    if (data == null || data['response'] == null) return [];

    return (data['response'] as List)
        .map((json) => ApiFootballFixture.fromJson(json))
        .toList();
  }

  /// 경기 ID로 조회
  Future<ApiFootballFixture?> getFixtureById(int fixtureId) async {
    final data = await _get('fixtures?id=$fixtureId');
    if (data == null || data['response'] == null || (data['response'] as List).isEmpty) {
      return null;
    }
    return ApiFootballFixture.fromJson((data['response'] as List).first);
  }

  /// 라이브 경기 조회
  Future<List<ApiFootballFixture>> getLiveFixtures() async {
    final data = await _get('fixtures?live=all');
    if (data == null || data['response'] == null) return [];

    return (data['response'] as List)
        .map((json) => ApiFootballFixture.fromJson(json))
        .toList();
  }

  /// 팀의 시즌 전체 경기
  Future<List<ApiFootballFixture>> getTeamSeasonFixtures(int teamId, int season) async {
    final data = await _get('fixtures?team=$teamId&season=$season');
    if (data == null || data['response'] == null) return [];

    return (data['response'] as List)
        .map((json) => ApiFootballFixture.fromJson(json))
        .toList();
  }

  // ============ 경기 상세 ============

  /// 경기 라인업
  Future<List<ApiFootballLineup>> getFixtureLineups(int fixtureId) async {
    final data = await _get('fixtures/lineups?fixture=$fixtureId');
    if (data == null || data['response'] == null) return [];

    return (data['response'] as List)
        .map((json) => ApiFootballLineup.fromJson(json))
        .toList();
  }

  /// 경기 통계
  Future<List<ApiFootballTeamStats>> getFixtureStatistics(int fixtureId) async {
    final data = await _get('fixtures/statistics?fixture=$fixtureId');
    if (data == null || data['response'] == null) return [];

    return (data['response'] as List)
        .map((json) => ApiFootballTeamStats.fromJson(json))
        .toList();
  }

  /// 경기 이벤트 (타임라인)
  Future<List<ApiFootballEvent>> getFixtureEvents(int fixtureId) async {
    final data = await _get('fixtures/events?fixture=$fixtureId');
    if (data == null || data['response'] == null) return [];

    return (data['response'] as List)
        .map((json) => ApiFootballEvent.fromJson(json))
        .toList();
  }

  /// 상대전적 (Head to Head)
  Future<List<ApiFootballFixture>> getHeadToHead(int team1Id, int team2Id) async {
    final data = await _get('fixtures/headtohead?h2h=$team1Id-$team2Id');
    if (data == null || data['response'] == null) return [];

    return (data['response'] as List)
        .map((json) => ApiFootballFixture.fromJson(json))
        .toList();
  }

  // ============ 예측/오즈 ============

  /// 경기 예측 조회
  Future<ApiFootballPrediction?> getFixturePrediction(int fixtureId) async {
    final data = await _get('predictions?fixture=$fixtureId');
    if (data == null || data['response'] == null || (data['response'] as List).isEmpty) {
      return null;
    }
    return ApiFootballPrediction.fromJson((data['response'] as List).first);
  }

  /// 경기 오즈 조회
  Future<List<ApiFootballOdds>> getFixtureOdds(int fixtureId) async {
    final data = await _get('odds?fixture=$fixtureId');
    if (data == null || data['response'] == null || (data['response'] as List).isEmpty) {
      return [];
    }

    final response = (data['response'] as List).first;
    final bookmakers = response['bookmakers'] as List? ?? [];

    return bookmakers.map((b) => ApiFootballOdds.fromJson(b)).toList();
  }

  // ============ 순위 ============

  /// 팀 시즌 통계 조회
  Future<ApiFootballTeamSeasonStats?> getTeamStatistics(int teamId, int leagueId, int season) async {
    final data = await _get('teams/statistics?team=$teamId&league=$leagueId&season=$season');
    if (data == null || data['response'] == null) return null;

    return ApiFootballTeamSeasonStats.fromJson(data['response'] as Map<String, dynamic>);
  }

  /// 리그 순위표
  Future<List<ApiFootballStanding>> getStandings(int leagueId, int season) async {
    final data = await _get('standings?league=$leagueId&season=$season');
    if (data == null || data['response'] == null || (data['response'] as List).isEmpty) {
      return [];
    }

    final leagueData = (data['response'] as List).first;
    if (leagueData['league'] == null || leagueData['league']['standings'] == null) {
      return [];
    }

    final standings = leagueData['league']['standings'] as List;
    if (standings.isEmpty) return [];

    // K리그처럼 스플릿 시스템인 경우 가장 많은 팀이 있는 그룹(정규시즌 전체) 선택
    // 그렇지 않으면 첫 번째 그룹 사용
    List<dynamic> selectedGroup = standings[0] as List;

    if (standings.length > 1) {
      // 가장 팀 수가 많은 그룹 찾기 (정규시즌 전체 순위)
      for (final group in standings) {
        if ((group as List).length > selectedGroup.length) {
          selectedGroup = group;
        }
      }
    }

    return selectedGroup
        .map((json) => ApiFootballStanding.fromJson(json))
        .toList();
  }

  // ============ 득점왕/어시스트왕 ============

  /// 리그 득점왕 순위
  Future<List<ApiFootballTopScorer>> getTopScorers(int leagueId, int season) async {
    final data = await _get('players/topscorers?league=$leagueId&season=$season');
    if (data == null || data['response'] == null) return [];

    return (data['response'] as List)
        .map((json) => ApiFootballTopScorer.fromJson(json))
        .toList();
  }

  /// 리그 어시스트왕 순위
  Future<List<ApiFootballTopScorer>> getTopAssists(int leagueId, int season) async {
    final data = await _get('players/topassists?league=$leagueId&season=$season');
    if (data == null || data['response'] == null) return [];

    return (data['response'] as List)
        .map((json) => ApiFootballTopScorer.fromJson(json))
        .toList();
  }
}

// ============ 모델 클래스들 ============

/// 리그 모델
class ApiFootballLeague {
  final int id;
  final String name;
  final String type;
  final String? logo;
  final String? countryName;
  final String? countryCode;
  final String? countryFlag;

  ApiFootballLeague({
    required this.id,
    required this.name,
    required this.type,
    this.logo,
    this.countryName,
    this.countryCode,
    this.countryFlag,
  });

  factory ApiFootballLeague.fromJson(Map<String, dynamic> json) {
    final league = json['league'] ?? json;
    final country = json['country'];

    return ApiFootballLeague(
      id: league['id'] ?? 0,
      name: league['name'] ?? '',
      type: league['type'] ?? '',
      logo: league['logo'],
      countryName: country?['name'],
      countryCode: country?['code'],
      countryFlag: country?['flag'],
    );
  }
}

/// 팀 모델
class ApiFootballTeam {
  final int id;
  final String name;
  final String? code;
  final String? country;
  final int? founded;
  final bool national;
  final String? logo;
  final ApiFootballVenue? venue;

  ApiFootballTeam({
    required this.id,
    required this.name,
    this.code,
    this.country,
    this.founded,
    required this.national,
    this.logo,
    this.venue,
  });

  factory ApiFootballTeam.fromJson(Map<String, dynamic> json) {
    final team = json['team'] ?? json;
    final venueJson = json['venue'];

    return ApiFootballTeam(
      id: team['id'] ?? 0,
      name: team['name'] ?? '',
      code: team['code'],
      country: team['country'],
      founded: team['founded'],
      national: team['national'] ?? false,
      logo: team['logo'],
      venue: venueJson != null ? ApiFootballVenue.fromJson(venueJson) : null,
    );
  }
}

/// 경기장 모델
class ApiFootballVenue {
  final int? id;
  final String? name;
  final String? address;
  final String? city;
  final int? capacity;
  final String? surface;
  final String? image;

  ApiFootballVenue({
    this.id,
    this.name,
    this.address,
    this.city,
    this.capacity,
    this.surface,
    this.image,
  });

  factory ApiFootballVenue.fromJson(Map<String, dynamic> json) {
    return ApiFootballVenue(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      city: json['city'],
      capacity: json['capacity'],
      surface: json['surface'],
      image: json['image'],
    );
  }
}

/// 선수 모델
class ApiFootballPlayer {
  final int id;
  final String name;
  final String? firstName;
  final String? lastName;
  final int? age;
  final String? birthDate;
  final String? birthPlace;
  final String? birthCountry;
  final String? nationality;
  final String? height;
  final String? weight;
  final bool injured;
  final String? photo;
  final List<ApiFootballPlayerStats> statistics;

  ApiFootballPlayer({
    required this.id,
    required this.name,
    this.firstName,
    this.lastName,
    this.age,
    this.birthDate,
    this.birthPlace,
    this.birthCountry,
    this.nationality,
    this.height,
    this.weight,
    required this.injured,
    this.photo,
    required this.statistics,
  });

  factory ApiFootballPlayer.fromJson(Map<String, dynamic> json) {
    final player = json['player'] ?? json;
    final birth = player['birth'];
    final stats = json['statistics'] as List? ?? [];

    return ApiFootballPlayer(
      id: player['id'] ?? 0,
      name: player['name'] ?? '',
      firstName: player['firstname'],
      lastName: player['lastname'],
      age: player['age'],
      birthDate: birth?['date'],
      birthPlace: birth?['place'],
      birthCountry: birth?['country'],
      nationality: player['nationality'],
      height: player['height']?.toString(),
      weight: player['weight']?.toString(),
      injured: player['injured'] ?? false,
      photo: player['photo'],
      statistics: stats.map((s) => ApiFootballPlayerStats.fromJson(s)).toList(),
    );
  }
}

/// 선수 통계 모델
class ApiFootballPlayerStats {
  final int? teamId;
  final String? teamName;
  final String? teamLogo;
  final int? leagueId;
  final String? leagueName;
  final int? season;
  final int? appearances;
  final int? lineups;
  final int? minutes;
  final String? position;
  final String? rating;
  final int? goals;
  final int? assists;
  final int? yellowCards;
  final int? redCards;

  ApiFootballPlayerStats({
    this.teamId,
    this.teamName,
    this.teamLogo,
    this.leagueId,
    this.leagueName,
    this.season,
    this.appearances,
    this.lineups,
    this.minutes,
    this.position,
    this.rating,
    this.goals,
    this.assists,
    this.yellowCards,
    this.redCards,
  });

  factory ApiFootballPlayerStats.fromJson(Map<String, dynamic> json) {
    final team = json['team'];
    final league = json['league'];
    final games = json['games'];
    final goalsData = json['goals'];
    final cards = json['cards'];

    return ApiFootballPlayerStats(
      teamId: team?['id'],
      teamName: team?['name'],
      teamLogo: team?['logo'],
      leagueId: league?['id'],
      leagueName: league?['name'],
      season: league?['season'],
      appearances: games?['appearences'],
      lineups: games?['lineups'],
      minutes: games?['minutes'],
      position: games?['position'],
      rating: games?['rating'],
      goals: goalsData?['total'],
      assists: goalsData?['assists'],
      yellowCards: cards?['yellow'],
      redCards: cards?['red'],
    );
  }
}

/// 스쿼드 선수 모델
class ApiFootballSquadPlayer {
  final int id;
  final String name;
  final int? age;
  final int? number;
  final String? position;
  final String? photo;

  ApiFootballSquadPlayer({
    required this.id,
    required this.name,
    this.age,
    this.number,
    this.position,
    this.photo,
  });

  factory ApiFootballSquadPlayer.fromJson(Map<String, dynamic> json) {
    return ApiFootballSquadPlayer(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      age: json['age'],
      number: json['number'],
      position: json['position'],
      photo: json['photo'],
    );
  }
}

/// 이적 모델
class ApiFootballTransfer {
  final String? date;
  final String? type;
  final int? teamInId;
  final String? teamInName;
  final String? teamInLogo;
  final int? teamOutId;
  final String? teamOutName;
  final String? teamOutLogo;

  ApiFootballTransfer({
    this.date,
    this.type,
    this.teamInId,
    this.teamInName,
    this.teamInLogo,
    this.teamOutId,
    this.teamOutName,
    this.teamOutLogo,
  });

  factory ApiFootballTransfer.fromJson(Map<String, dynamic> json) {
    final teamIn = json['teams']?['in'];
    final teamOut = json['teams']?['out'];

    return ApiFootballTransfer(
      date: json['date'],
      type: json['type'],
      teamInId: teamIn?['id'],
      teamInName: teamIn?['name'],
      teamInLogo: teamIn?['logo'],
      teamOutId: teamOut?['id'],
      teamOutName: teamOut?['name'],
      teamOutLogo: teamOut?['logo'],
    );
  }
}

/// 트로피 모델
class ApiFootballTrophy {
  final String? league;
  final String? country;
  final String? season;
  final String? place;

  ApiFootballTrophy({
    this.league,
    this.country,
    this.season,
    this.place,
  });

  factory ApiFootballTrophy.fromJson(Map<String, dynamic> json) {
    return ApiFootballTrophy(
      league: json['league'],
      country: json['country'],
      season: json['season'],
      place: json['place'],
    );
  }
}

/// 경기 모델
class ApiFootballFixture {
  final int id;
  final String? referee;
  final String timezone;
  final DateTime date;
  final int timestamp;
  final ApiFootballVenue? venue;
  final ApiFootballFixtureStatus status;
  final ApiFootballLeagueInfo league;
  final ApiFootballFixtureTeam homeTeam;
  final ApiFootballFixtureTeam awayTeam;
  final int? homeGoals;
  final int? awayGoals;
  final ApiFootballScore score;

  ApiFootballFixture({
    required this.id,
    this.referee,
    required this.timezone,
    required this.date,
    required this.timestamp,
    this.venue,
    required this.status,
    required this.league,
    required this.homeTeam,
    required this.awayTeam,
    this.homeGoals,
    this.awayGoals,
    required this.score,
  });

  factory ApiFootballFixture.fromJson(Map<String, dynamic> json) {
    final fixture = json['fixture'] ?? {};
    final teams = json['teams'] ?? {};
    final goals = json['goals'] ?? {};

    return ApiFootballFixture(
      id: fixture['id'] ?? 0,
      referee: fixture['referee'],
      timezone: fixture['timezone'] ?? 'UTC',
      date: DateTime.parse(fixture['date'] ?? DateTime.now().toIso8601String()),
      timestamp: fixture['timestamp'] ?? 0,
      venue: fixture['venue'] != null ? ApiFootballVenue.fromJson(fixture['venue']) : null,
      status: ApiFootballFixtureStatus.fromJson(fixture['status'] ?? {}),
      league: ApiFootballLeagueInfo.fromJson(json['league'] ?? {}),
      homeTeam: ApiFootballFixtureTeam.fromJson(teams['home'] ?? {}),
      awayTeam: ApiFootballFixtureTeam.fromJson(teams['away'] ?? {}),
      homeGoals: goals['home'],
      awayGoals: goals['away'],
      score: ApiFootballScore.fromJson(json['score'] ?? {}),
    );
  }

  /// 한국 시간으로 변환
  DateTime get dateKST => date.add(const Duration(hours: 9));

  /// 경기 완료 여부
  bool get isFinished => status.short == 'FT' || status.short == 'AET' || status.short == 'PEN';

  /// 경기 진행 중 여부
  bool get isLive => status.short == '1H' || status.short == 'HT' || status.short == '2H' ||
                     status.short == 'ET' || status.short == 'BT' || status.short == 'P';

  /// 경기 예정 여부
  bool get isScheduled => status.short == 'NS' || status.short == 'TBD';

  /// 스코어 표시 문자열
  String get scoreDisplay {
    if (isFinished || isLive) {
      return '${homeGoals ?? 0} - ${awayGoals ?? 0}';
    }
    return 'vs';
  }
}

/// 경기 상태 모델
class ApiFootballFixtureStatus {
  final String long;
  final String short;
  final int? elapsed;
  final int? extra;

  ApiFootballFixtureStatus({
    required this.long,
    required this.short,
    this.elapsed,
    this.extra,
  });

  factory ApiFootballFixtureStatus.fromJson(Map<String, dynamic> json) {
    return ApiFootballFixtureStatus(
      long: json['long'] ?? '',
      short: json['short'] ?? '',
      elapsed: json['elapsed'],
      extra: json['extra'],
    );
  }
}

/// 리그 정보 모델 (경기 내)
class ApiFootballLeagueInfo {
  final int id;
  final String name;
  final String? country;
  final String? logo;
  final String? flag;
  final int? season;
  final String? round;

  ApiFootballLeagueInfo({
    required this.id,
    required this.name,
    this.country,
    this.logo,
    this.flag,
    this.season,
    this.round,
  });

  factory ApiFootballLeagueInfo.fromJson(Map<String, dynamic> json) {
    return ApiFootballLeagueInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      country: json['country'],
      logo: json['logo'],
      flag: json['flag'],
      season: json['season'],
      round: json['round'],
    );
  }
}

/// 경기 팀 정보 모델
class ApiFootballFixtureTeam {
  final int id;
  final String name;
  final String? logo;
  final bool? winner;

  ApiFootballFixtureTeam({
    required this.id,
    required this.name,
    this.logo,
    this.winner,
  });

  factory ApiFootballFixtureTeam.fromJson(Map<String, dynamic> json) {
    return ApiFootballFixtureTeam(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      logo: json['logo'],
      winner: json['winner'],
    );
  }
}

/// 스코어 모델
class ApiFootballScore {
  final int? halftimeHome;
  final int? halftimeAway;
  final int? fulltimeHome;
  final int? fulltimeAway;
  final int? extratimeHome;
  final int? extratimeAway;
  final int? penaltyHome;
  final int? penaltyAway;

  ApiFootballScore({
    this.halftimeHome,
    this.halftimeAway,
    this.fulltimeHome,
    this.fulltimeAway,
    this.extratimeHome,
    this.extratimeAway,
    this.penaltyHome,
    this.penaltyAway,
  });

  factory ApiFootballScore.fromJson(Map<String, dynamic> json) {
    final halftime = json['halftime'] ?? {};
    final fulltime = json['fulltime'] ?? {};
    final extratime = json['extratime'] ?? {};
    final penalty = json['penalty'] ?? {};

    return ApiFootballScore(
      halftimeHome: halftime['home'],
      halftimeAway: halftime['away'],
      fulltimeHome: fulltime['home'],
      fulltimeAway: fulltime['away'],
      extratimeHome: extratime['home'],
      extratimeAway: extratime['away'],
      penaltyHome: penalty['home'],
      penaltyAway: penalty['away'],
    );
  }
}

/// 라인업 모델
class ApiFootballLineup {
  final int teamId;
  final String teamName;
  final String? teamLogo;
  final String? formation;
  final ApiFootballCoach? coach;
  final List<ApiFootballLineupPlayer> startXI;
  final List<ApiFootballLineupPlayer> substitutes;

  ApiFootballLineup({
    required this.teamId,
    required this.teamName,
    this.teamLogo,
    this.formation,
    this.coach,
    required this.startXI,
    required this.substitutes,
  });

  factory ApiFootballLineup.fromJson(Map<String, dynamic> json) {
    final team = json['team'] ?? {};
    final startXIList = json['startXI'] as List? ?? [];
    final substitutesList = json['substitutes'] as List? ?? [];

    return ApiFootballLineup(
      teamId: team['id'] ?? 0,
      teamName: team['name'] ?? '',
      teamLogo: team['logo'],
      formation: json['formation'],
      coach: json['coach'] != null ? ApiFootballCoach.fromJson(json['coach']) : null,
      startXI: startXIList.map((p) => ApiFootballLineupPlayer.fromJson(p['player'] ?? p)).toList(),
      substitutes: substitutesList.map((p) => ApiFootballLineupPlayer.fromJson(p['player'] ?? p)).toList(),
    );
  }
}

/// 감독 모델
class ApiFootballCoach {
  final int? id;
  final String? name;
  final String? photo;

  ApiFootballCoach({
    this.id,
    this.name,
    this.photo,
  });

  factory ApiFootballCoach.fromJson(Map<String, dynamic> json) {
    return ApiFootballCoach(
      id: json['id'],
      name: json['name'],
      photo: json['photo'],
    );
  }
}

/// 라인업 선수 모델
class ApiFootballLineupPlayer {
  final int id;
  final String name;
  final int? number;
  final String? pos;
  final String? grid;

  ApiFootballLineupPlayer({
    required this.id,
    required this.name,
    this.number,
    this.pos,
    this.grid,
  });

  factory ApiFootballLineupPlayer.fromJson(Map<String, dynamic> json) {
    return ApiFootballLineupPlayer(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      number: json['number'],
      pos: json['pos'],
      grid: json['grid'],
    );
  }
}

/// 경기 통계 모델
class ApiFootballTeamStats {
  final int teamId;
  final String teamName;
  final String? teamLogo;
  final Map<String, dynamic> statistics;

  ApiFootballTeamStats({
    required this.teamId,
    required this.teamName,
    this.teamLogo,
    required this.statistics,
  });

  factory ApiFootballTeamStats.fromJson(Map<String, dynamic> json) {
    final team = json['team'] ?? {};
    final statsList = json['statistics'] as List? ?? [];

    final statsMap = <String, dynamic>{};
    for (final stat in statsList) {
      final type = stat['type'] as String?;
      final value = stat['value'];
      if (type != null) {
        statsMap[type] = value;
      }
    }

    return ApiFootballTeamStats(
      teamId: team['id'] ?? 0,
      teamName: team['name'] ?? '',
      teamLogo: team['logo'],
      statistics: statsMap,
    );
  }

  // 편의 메서드들
  String? get possession => statistics['Ball Possession']?.toString();
  int? get shotsTotal => statistics['Total Shots'];
  int? get shotsOnTarget => statistics['Shots on Goal'];
  int? get corners => statistics['Corner Kicks'];
  int? get fouls => statistics['Fouls'];
  int? get yellowCards => statistics['Yellow Cards'];
  int? get redCards => statistics['Red Cards'];
  int? get offsides => statistics['Offsides'];
  String? get passAccuracy => statistics['Passes %']?.toString();
}

/// 경기 이벤트 모델 (타임라인)
class ApiFootballEvent {
  final int? elapsed;
  final int? extra;
  final int teamId;
  final String teamName;
  final String? teamLogo;
  final int? playerId;
  final String? playerName;
  final int? assistId;
  final String? assistName;
  final String type;
  final String? detail;
  final String? comments;

  ApiFootballEvent({
    this.elapsed,
    this.extra,
    required this.teamId,
    required this.teamName,
    this.teamLogo,
    this.playerId,
    this.playerName,
    this.assistId,
    this.assistName,
    required this.type,
    this.detail,
    this.comments,
  });

  factory ApiFootballEvent.fromJson(Map<String, dynamic> json) {
    final time = json['time'] ?? {};
    final team = json['team'] ?? {};
    final player = json['player'] ?? {};
    final assist = json['assist'] ?? {};

    return ApiFootballEvent(
      elapsed: time['elapsed'],
      extra: time['extra'],
      teamId: team['id'] ?? 0,
      teamName: team['name'] ?? '',
      teamLogo: team['logo'],
      playerId: player['id'],
      playerName: player['name'],
      assistId: assist['id'],
      assistName: assist['name'],
      type: json['type'] ?? '',
      detail: json['detail'],
      comments: json['comments'],
    );
  }

  /// 골 여부
  bool get isGoal => type == 'Goal';

  /// 카드 여부
  bool get isCard => type == 'Card';

  /// 교체 여부
  bool get isSubstitution => type == 'subst';

  /// 시간 표시 문자열
  String get timeDisplay {
    if (extra != null && extra! > 0) {
      return "$elapsed'+$extra";
    }
    return "$elapsed'";
  }
}

/// 팀 시즌 통계 모델
class ApiFootballTeamSeasonStats {
  final int teamId;
  final String teamName;
  final String? teamLogo;
  final int leagueId;
  final String leagueName;
  final String? leagueLogo;
  final String? leagueCountry;
  final int season;
  final String? form;
  final ApiFootballFixturesStats fixtures;
  final ApiFootballGoalsStats goals;
  final int? biggestStreak;
  final ApiFootballBiggestWins? biggestWins;
  final ApiFootballBiggestLoses? biggestLoses;
  final ApiFootballCleanSheetStats cleanSheet;
  final ApiFootballFailedToScoreStats failedToScore;
  final ApiFootballPenaltyStats? penalty;
  final Map<String, ApiFootballLineupStats>? lineups;
  final ApiFootballCardsStats? cards;

  ApiFootballTeamSeasonStats({
    required this.teamId,
    required this.teamName,
    this.teamLogo,
    required this.leagueId,
    required this.leagueName,
    this.leagueLogo,
    this.leagueCountry,
    required this.season,
    this.form,
    required this.fixtures,
    required this.goals,
    this.biggestStreak,
    this.biggestWins,
    this.biggestLoses,
    required this.cleanSheet,
    required this.failedToScore,
    this.penalty,
    this.lineups,
    this.cards,
  });

  factory ApiFootballTeamSeasonStats.fromJson(Map<String, dynamic> json) {
    final team = json['team'] ?? {};
    final league = json['league'] ?? {};

    return ApiFootballTeamSeasonStats(
      teamId: team['id'] ?? 0,
      teamName: team['name'] ?? '',
      teamLogo: team['logo'],
      leagueId: league['id'] ?? 0,
      leagueName: league['name'] ?? '',
      leagueLogo: league['logo'],
      leagueCountry: league['country'],
      season: league['season'] ?? 0,
      form: json['form'],
      fixtures: ApiFootballFixturesStats.fromJson(json['fixtures'] ?? {}),
      goals: ApiFootballGoalsStats.fromJson(json['goals'] ?? {}),
      biggestStreak: json['biggest']?['streak']?['wins'],
      biggestWins: json['biggest']?['wins'] != null
          ? ApiFootballBiggestWins.fromJson(json['biggest']['wins'])
          : null,
      biggestLoses: json['biggest']?['loses'] != null
          ? ApiFootballBiggestLoses.fromJson(json['biggest']['loses'])
          : null,
      cleanSheet: ApiFootballCleanSheetStats.fromJson(json['clean_sheet'] ?? {}),
      failedToScore: ApiFootballFailedToScoreStats.fromJson(json['failed_to_score'] ?? {}),
      penalty: json['penalty'] != null
          ? ApiFootballPenaltyStats.fromJson(json['penalty'])
          : null,
      lineups: null, // 필요시 구현
      cards: json['cards'] != null
          ? ApiFootballCardsStats.fromJson(json['cards'])
          : null,
    );
  }

  // 총 경기 수
  int get totalPlayed => fixtures.played.total;

  // 승률
  double get winRate => totalPlayed > 0 ? (fixtures.wins.total / totalPlayed) * 100 : 0;

  // 평균 득점
  double get avgGoalsFor => totalPlayed > 0 ? goals.goalsFor.total / totalPlayed : 0;

  // 평균 실점
  double get avgGoalsAgainst => totalPlayed > 0 ? goals.goalsAgainst.total / totalPlayed : 0;
}

/// 경기 통계
class ApiFootballFixturesStats {
  final ApiFootballHomeAwayTotal played;
  final ApiFootballHomeAwayTotal wins;
  final ApiFootballHomeAwayTotal draws;
  final ApiFootballHomeAwayTotal loses;

  ApiFootballFixturesStats({
    required this.played,
    required this.wins,
    required this.draws,
    required this.loses,
  });

  factory ApiFootballFixturesStats.fromJson(Map<String, dynamic> json) {
    return ApiFootballFixturesStats(
      played: ApiFootballHomeAwayTotal.fromJson(json['played'] ?? {}),
      wins: ApiFootballHomeAwayTotal.fromJson(json['wins'] ?? {}),
      draws: ApiFootballHomeAwayTotal.fromJson(json['draws'] ?? {}),
      loses: ApiFootballHomeAwayTotal.fromJson(json['loses'] ?? {}),
    );
  }
}

/// 홈/어웨이/전체 통계
class ApiFootballHomeAwayTotal {
  final int home;
  final int away;
  final int total;

  ApiFootballHomeAwayTotal({
    required this.home,
    required this.away,
    required this.total,
  });

  factory ApiFootballHomeAwayTotal.fromJson(Map<String, dynamic> json) {
    return ApiFootballHomeAwayTotal(
      home: json['home'] ?? 0,
      away: json['away'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}

/// 골 통계
class ApiFootballGoalsStats {
  final ApiFootballGoalDetail goalsFor;
  final ApiFootballGoalDetail goalsAgainst;

  ApiFootballGoalsStats({
    required this.goalsFor,
    required this.goalsAgainst,
  });

  factory ApiFootballGoalsStats.fromJson(Map<String, dynamic> json) {
    return ApiFootballGoalsStats(
      goalsFor: ApiFootballGoalDetail.fromJson(json['for'] ?? {}),
      goalsAgainst: ApiFootballGoalDetail.fromJson(json['against'] ?? {}),
    );
  }
}

/// 골 상세 통계
class ApiFootballGoalDetail {
  final int home;
  final int away;
  final int total;
  final double? avgHome;
  final double? avgAway;
  final double? avgTotal;

  ApiFootballGoalDetail({
    required this.home,
    required this.away,
    required this.total,
    this.avgHome,
    this.avgAway,
    this.avgTotal,
  });

  factory ApiFootballGoalDetail.fromJson(Map<String, dynamic> json) {
    final totalData = json['total'] ?? {};
    final avgData = json['average'] ?? {};

    return ApiFootballGoalDetail(
      home: totalData['home'] ?? 0,
      away: totalData['away'] ?? 0,
      total: totalData['total'] ?? 0,
      avgHome: double.tryParse(avgData['home']?.toString() ?? ''),
      avgAway: double.tryParse(avgData['away']?.toString() ?? ''),
      avgTotal: double.tryParse(avgData['total']?.toString() ?? ''),
    );
  }
}

/// 최대 승리 통계
class ApiFootballBiggestWins {
  final String? home;
  final String? away;

  ApiFootballBiggestWins({this.home, this.away});

  factory ApiFootballBiggestWins.fromJson(Map<String, dynamic> json) {
    return ApiFootballBiggestWins(
      home: json['home'],
      away: json['away'],
    );
  }
}

/// 최대 패배 통계
class ApiFootballBiggestLoses {
  final String? home;
  final String? away;

  ApiFootballBiggestLoses({this.home, this.away});

  factory ApiFootballBiggestLoses.fromJson(Map<String, dynamic> json) {
    return ApiFootballBiggestLoses(
      home: json['home'],
      away: json['away'],
    );
  }
}

/// 클린시트 통계
class ApiFootballCleanSheetStats {
  final int home;
  final int away;
  final int total;

  ApiFootballCleanSheetStats({
    required this.home,
    required this.away,
    required this.total,
  });

  factory ApiFootballCleanSheetStats.fromJson(Map<String, dynamic> json) {
    return ApiFootballCleanSheetStats(
      home: json['home'] ?? 0,
      away: json['away'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}

/// 무득점 경기 통계
class ApiFootballFailedToScoreStats {
  final int home;
  final int away;
  final int total;

  ApiFootballFailedToScoreStats({
    required this.home,
    required this.away,
    required this.total,
  });

  factory ApiFootballFailedToScoreStats.fromJson(Map<String, dynamic> json) {
    return ApiFootballFailedToScoreStats(
      home: json['home'] ?? 0,
      away: json['away'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}

/// 패널티 통계
class ApiFootballPenaltyStats {
  final int scored;
  final int missed;
  final int total;
  final double? percentage;

  ApiFootballPenaltyStats({
    required this.scored,
    required this.missed,
    required this.total,
    this.percentage,
  });

  factory ApiFootballPenaltyStats.fromJson(Map<String, dynamic> json) {
    final scored = json['scored'] ?? {};
    final missed = json['missed'] ?? {};

    return ApiFootballPenaltyStats(
      scored: scored['total'] ?? 0,
      missed: missed['total'] ?? 0,
      total: (scored['total'] ?? 0) + (missed['total'] ?? 0),
      percentage: double.tryParse(scored['percentage']?.toString().replaceAll('%', '') ?? ''),
    );
  }
}

/// 라인업 통계
class ApiFootballLineupStats {
  final String formation;
  final int played;

  ApiFootballLineupStats({
    required this.formation,
    required this.played,
  });

  factory ApiFootballLineupStats.fromJson(Map<String, dynamic> json) {
    return ApiFootballLineupStats(
      formation: json['formation'] ?? '',
      played: json['played'] ?? 0,
    );
  }
}

/// 카드 통계
class ApiFootballCardsStats {
  final Map<String, int> yellow;
  final Map<String, int> red;

  ApiFootballCardsStats({
    required this.yellow,
    required this.red,
  });

  factory ApiFootballCardsStats.fromJson(Map<String, dynamic> json) {
    final yellowData = json['yellow'] ?? {};
    final redData = json['red'] ?? {};

    int parseTotal(Map<String, dynamic> data) {
      int total = 0;
      data.forEach((key, value) {
        if (value is Map && value['total'] != null) {
          total += (value['total'] as int?) ?? 0;
        }
      });
      return total;
    }

    return ApiFootballCardsStats(
      yellow: {'total': parseTotal(yellowData)},
      red: {'total': parseTotal(redData)},
    );
  }

  int get totalYellow => yellow['total'] ?? 0;
  int get totalRed => red['total'] ?? 0;
}

/// 경기 예측 모델
class ApiFootballPrediction {
  final String? winner;
  final int? winnerId;
  final String? winnerComment;
  final ApiFootballPredictionPercent percent;
  final ApiFootballPredictionComparison? comparison;
  final ApiFootballPredictionTeamInfo? homeTeam;
  final ApiFootballPredictionTeamInfo? awayTeam;

  ApiFootballPrediction({
    this.winner,
    this.winnerId,
    this.winnerComment,
    required this.percent,
    this.comparison,
    this.homeTeam,
    this.awayTeam,
  });

  factory ApiFootballPrediction.fromJson(Map<String, dynamic> json) {
    final predictions = json['predictions'] ?? {};
    final winner = predictions['winner'] ?? {};
    final teams = json['teams'] ?? {};

    return ApiFootballPrediction(
      winner: winner['name'],
      winnerId: winner['id'],
      winnerComment: winner['comment'],
      percent: ApiFootballPredictionPercent.fromJson(predictions['percent'] ?? {}),
      comparison: json['comparison'] != null
          ? ApiFootballPredictionComparison.fromJson(json['comparison'])
          : null,
      homeTeam: teams['home'] != null
          ? ApiFootballPredictionTeamInfo.fromJson(teams['home'])
          : null,
      awayTeam: teams['away'] != null
          ? ApiFootballPredictionTeamInfo.fromJson(teams['away'])
          : null,
    );
  }
}

/// 예측 퍼센트 모델
class ApiFootballPredictionPercent {
  final String? home;
  final String? draw;
  final String? away;

  ApiFootballPredictionPercent({
    this.home,
    this.draw,
    this.away,
  });

  factory ApiFootballPredictionPercent.fromJson(Map<String, dynamic> json) {
    return ApiFootballPredictionPercent(
      home: json['home'],
      draw: json['draw'],
      away: json['away'],
    );
  }

  double get homePercent => double.tryParse(home?.replaceAll('%', '') ?? '0') ?? 0;
  double get drawPercent => double.tryParse(draw?.replaceAll('%', '') ?? '0') ?? 0;
  double get awayPercent => double.tryParse(away?.replaceAll('%', '') ?? '0') ?? 0;
}

/// 예측 비교 모델
class ApiFootballPredictionComparison {
  final ApiFootballComparisonItem? form;
  final ApiFootballComparisonItem? att;
  final ApiFootballComparisonItem? def;
  final ApiFootballComparisonItem? poissonDistribution;
  final ApiFootballComparisonItem? h2h;
  final ApiFootballComparisonItem? goals;
  final ApiFootballComparisonItem? total;

  ApiFootballPredictionComparison({
    this.form,
    this.att,
    this.def,
    this.poissonDistribution,
    this.h2h,
    this.goals,
    this.total,
  });

  factory ApiFootballPredictionComparison.fromJson(Map<String, dynamic> json) {
    return ApiFootballPredictionComparison(
      form: json['form'] != null ? ApiFootballComparisonItem.fromJson(json['form']) : null,
      att: json['att'] != null ? ApiFootballComparisonItem.fromJson(json['att']) : null,
      def: json['def'] != null ? ApiFootballComparisonItem.fromJson(json['def']) : null,
      poissonDistribution: json['poisson_distribution'] != null
          ? ApiFootballComparisonItem.fromJson(json['poisson_distribution'])
          : null,
      h2h: json['h2h'] != null ? ApiFootballComparisonItem.fromJson(json['h2h']) : null,
      goals: json['goals'] != null ? ApiFootballComparisonItem.fromJson(json['goals']) : null,
      total: json['total'] != null ? ApiFootballComparisonItem.fromJson(json['total']) : null,
    );
  }
}

/// 비교 항목 모델
class ApiFootballComparisonItem {
  final String? home;
  final String? away;

  ApiFootballComparisonItem({this.home, this.away});

  factory ApiFootballComparisonItem.fromJson(Map<String, dynamic> json) {
    return ApiFootballComparisonItem(
      home: json['home'],
      away: json['away'],
    );
  }

  double get homePercent => double.tryParse(home?.replaceAll('%', '') ?? '0') ?? 0;
  double get awayPercent => double.tryParse(away?.replaceAll('%', '') ?? '0') ?? 0;
}

/// 예측 팀 정보 모델
class ApiFootballPredictionTeamInfo {
  final int id;
  final String name;
  final String? logo;
  final ApiFootballTeamLastMatches? last5;
  final ApiFootballTeamLeagueInfo? league;

  ApiFootballPredictionTeamInfo({
    required this.id,
    required this.name,
    this.logo,
    this.last5,
    this.league,
  });

  factory ApiFootballPredictionTeamInfo.fromJson(Map<String, dynamic> json) {
    return ApiFootballPredictionTeamInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      logo: json['logo'],
      last5: json['last_5'] != null
          ? ApiFootballTeamLastMatches.fromJson(json['last_5'])
          : null,
      league: json['league'] != null
          ? ApiFootballTeamLeagueInfo.fromJson(json['league'])
          : null,
    );
  }
}

/// 최근 5경기 정보
class ApiFootballTeamLastMatches {
  final String? form;
  final String? att;
  final String? def;
  final ApiFootballLastMatchesGoals? goals;

  ApiFootballTeamLastMatches({
    this.form,
    this.att,
    this.def,
    this.goals,
  });

  factory ApiFootballTeamLastMatches.fromJson(Map<String, dynamic> json) {
    return ApiFootballTeamLastMatches(
      form: json['form'],
      att: json['att'],
      def: json['def'],
      goals: json['goals'] != null
          ? ApiFootballLastMatchesGoals.fromJson(json['goals'])
          : null,
    );
  }
}

/// 최근 경기 골 정보
class ApiFootballLastMatchesGoals {
  final ApiFootballGoalAverage? goalsFor;
  final ApiFootballGoalAverage? goalsAgainst;

  ApiFootballLastMatchesGoals({this.goalsFor, this.goalsAgainst});

  factory ApiFootballLastMatchesGoals.fromJson(Map<String, dynamic> json) {
    return ApiFootballLastMatchesGoals(
      goalsFor: json['for'] != null ? ApiFootballGoalAverage.fromJson(json['for']) : null,
      goalsAgainst: json['against'] != null ? ApiFootballGoalAverage.fromJson(json['against']) : null,
    );
  }
}

/// 골 평균 정보
class ApiFootballGoalAverage {
  final int? total;
  final double? average;

  ApiFootballGoalAverage({this.total, this.average});

  factory ApiFootballGoalAverage.fromJson(Map<String, dynamic> json) {
    return ApiFootballGoalAverage(
      total: json['total'],
      average: double.tryParse(json['average']?.toString() ?? ''),
    );
  }
}

/// 팀 리그 정보 (예측용)
class ApiFootballTeamLeagueInfo {
  final String? form;
  final int? played;
  final int? wins;
  final int? draws;
  final int? loses;
  final int? goalsFor;
  final int? goalsAgainst;

  ApiFootballTeamLeagueInfo({
    this.form,
    this.played,
    this.wins,
    this.draws,
    this.loses,
    this.goalsFor,
    this.goalsAgainst,
  });

  factory ApiFootballTeamLeagueInfo.fromJson(Map<String, dynamic> json) {
    final fixtures = json['fixtures'] ?? {};
    final goals = json['goals'] ?? {};

    return ApiFootballTeamLeagueInfo(
      form: json['form'],
      played: fixtures['played']?['total'],
      wins: fixtures['wins']?['total'],
      draws: fixtures['draws']?['total'],
      loses: fixtures['loses']?['total'],
      goalsFor: goals['for']?['total']?['total'],
      goalsAgainst: goals['against']?['total']?['total'],
    );
  }
}

/// 배당률 모델
class ApiFootballOdds {
  final int bookmarkerId;
  final String bookmakerName;
  final List<ApiFootballBet> bets;

  ApiFootballOdds({
    required this.bookmarkerId,
    required this.bookmakerName,
    required this.bets,
  });

  factory ApiFootballOdds.fromJson(Map<String, dynamic> json) {
    final bets = json['bets'] as List? ?? [];

    return ApiFootballOdds(
      bookmarkerId: json['id'] ?? 0,
      bookmakerName: json['name'] ?? '',
      bets: bets.map((b) => ApiFootballBet.fromJson(b)).toList(),
    );
  }

  /// 1X2 (승무패) 배당 가져오기
  ApiFootballBet? get matchWinner {
    try {
      return bets.firstWhere((b) => b.name == 'Match Winner');
    } catch (_) {
      return null;
    }
  }
}

/// 배팅 종류 모델
class ApiFootballBet {
  final int id;
  final String name;
  final List<ApiFootballOddValue> values;

  ApiFootballBet({
    required this.id,
    required this.name,
    required this.values,
  });

  factory ApiFootballBet.fromJson(Map<String, dynamic> json) {
    final values = json['values'] as List? ?? [];

    return ApiFootballBet(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      values: values.map((v) => ApiFootballOddValue.fromJson(v)).toList(),
    );
  }

  /// 홈 승리 배당
  String? get homeOdd {
    try {
      return values.firstWhere((v) => v.value == 'Home').odd;
    } catch (_) {
      return null;
    }
  }

  /// 무승부 배당
  String? get drawOdd {
    try {
      return values.firstWhere((v) => v.value == 'Draw').odd;
    } catch (_) {
      return null;
    }
  }

  /// 원정 승리 배당
  String? get awayOdd {
    try {
      return values.firstWhere((v) => v.value == 'Away').odd;
    } catch (_) {
      return null;
    }
  }
}

/// 배당률 값 모델
class ApiFootballOddValue {
  final String value;
  final String odd;

  ApiFootballOddValue({
    required this.value,
    required this.odd,
  });

  factory ApiFootballOddValue.fromJson(Map<String, dynamic> json) {
    return ApiFootballOddValue(
      value: json['value']?.toString() ?? '',
      odd: json['odd']?.toString() ?? '',
    );
  }
}

/// 팀 이적 모델 (팀별 조회용)
class ApiFootballTeamTransfer {
  final int playerId;
  final String playerName;
  final String? playerPhoto;
  final List<ApiFootballTransfer> transfers;

  ApiFootballTeamTransfer({
    required this.playerId,
    required this.playerName,
    this.playerPhoto,
    required this.transfers,
  });

  factory ApiFootballTeamTransfer.fromJson(Map<String, dynamic> json) {
    final player = json['player'] ?? {};
    final transfersList = json['transfers'] as List? ?? [];

    return ApiFootballTeamTransfer(
      playerId: player['id'] ?? 0,
      playerName: player['name'] ?? '',
      playerPhoto: null, // API에서 제공하지 않음
      transfers: transfersList.map((t) => ApiFootballTransfer.fromJson(t)).toList(),
    );
  }

  /// 가장 최근 이적
  ApiFootballTransfer? get latestTransfer => transfers.isNotEmpty ? transfers.first : null;

  /// 특정 팀으로의 영입 여부
  bool isTransferIn(int teamId) {
    final latest = latestTransfer;
    return latest != null && latest.teamInId == teamId;
  }

  /// 특정 팀에서의 방출 여부
  bool isTransferOut(int teamId) {
    final latest = latestTransfer;
    return latest != null && latest.teamOutId == teamId;
  }
}

/// 순위 모델
class ApiFootballStanding {
  final int rank;
  final int teamId;
  final String teamName;
  final String? teamLogo;
  final int points;
  final int goalsDiff;
  final String? form;
  final String? description;
  final int played;
  final int win;
  final int draw;
  final int lose;
  final int goalsFor;
  final int goalsAgainst;

  ApiFootballStanding({
    required this.rank,
    required this.teamId,
    required this.teamName,
    this.teamLogo,
    required this.points,
    required this.goalsDiff,
    this.form,
    this.description,
    required this.played,
    required this.win,
    required this.draw,
    required this.lose,
    required this.goalsFor,
    required this.goalsAgainst,
  });

  factory ApiFootballStanding.fromJson(Map<String, dynamic> json) {
    final team = json['team'] ?? {};
    final all = json['all'] ?? {};
    final goals = all['goals'] ?? {};

    return ApiFootballStanding(
      rank: json['rank'] ?? 0,
      teamId: team['id'] ?? 0,
      teamName: team['name'] ?? '',
      teamLogo: team['logo'],
      points: json['points'] ?? 0,
      goalsDiff: json['goalsDiff'] ?? 0,
      form: json['form'],
      description: json['description'],
      played: all['played'] ?? 0,
      win: all['win'] ?? 0,
      draw: all['draw'] ?? 0,
      lose: all['lose'] ?? 0,
      goalsFor: goals['for'] ?? 0,
      goalsAgainst: goals['against'] ?? 0,
    );
  }
}

/// 득점왕/어시스트왕 모델
class ApiFootballTopScorer {
  final int rank;
  final int playerId;
  final String playerName;
  final String? playerPhoto;
  final int teamId;
  final String teamName;
  final String? teamLogo;
  final int? goals;
  final int? assists;
  final int? appearances;
  final int? minutes;
  final int? penalties;
  final String? nationality;

  ApiFootballTopScorer({
    required this.rank,
    required this.playerId,
    required this.playerName,
    this.playerPhoto,
    required this.teamId,
    required this.teamName,
    this.teamLogo,
    this.goals,
    this.assists,
    this.appearances,
    this.minutes,
    this.penalties,
    this.nationality,
  });

  factory ApiFootballTopScorer.fromJson(Map<String, dynamic> json) {
    final player = json['player'] ?? {};
    final statistics = (json['statistics'] as List?)?.isNotEmpty == true
        ? json['statistics'][0]
        : {};
    final team = statistics['team'] ?? {};
    final goals = statistics['goals'] ?? {};
    final games = statistics['games'] ?? {};
    final penalty = statistics['penalty'] ?? {};

    return ApiFootballTopScorer(
      rank: 0, // API에서 순위 제공 안 함, 리스트 인덱스로 설정
      playerId: player['id'] ?? 0,
      playerName: player['name'] ?? '',
      playerPhoto: player['photo'],
      teamId: team['id'] ?? 0,
      teamName: team['name'] ?? '',
      teamLogo: team['logo'],
      goals: goals['total'],
      assists: goals['assists'],
      appearances: games['appearences'], // API 오타 그대로 사용
      minutes: games['minutes'],
      penalties: penalty['scored'],
      nationality: player['nationality'],
    );
  }
}

/// 부상/결장 선수 모델
class ApiFootballInjury {
  final int playerId;
  final String playerName;
  final String? playerPhoto;
  final String? type; // "Missing Fixture" 등
  final String? reason; // "Injury", "Suspended", "Doubtful" 등
  final int teamId;
  final String teamName;
  final String? teamLogo;
  final int? fixtureId;
  final int? leagueId;
  final String? leagueName;
  final int? season;

  ApiFootballInjury({
    required this.playerId,
    required this.playerName,
    this.playerPhoto,
    this.type,
    this.reason,
    required this.teamId,
    required this.teamName,
    this.teamLogo,
    this.fixtureId,
    this.leagueId,
    this.leagueName,
    this.season,
  });

  factory ApiFootballInjury.fromJson(Map<String, dynamic> json) {
    final player = json['player'] ?? {};
    final team = json['team'] ?? {};
    final fixture = json['fixture'] ?? {};
    final league = json['league'] ?? {};

    return ApiFootballInjury(
      playerId: player['id'] ?? 0,
      playerName: player['name'] ?? '',
      playerPhoto: player['photo'],
      type: player['type'],
      reason: player['reason'],
      teamId: team['id'] ?? 0,
      teamName: team['name'] ?? '',
      teamLogo: team['logo'],
      fixtureId: fixture['id'],
      leagueId: league['id'],
      leagueName: league['name'],
      season: league['season'],
    );
  }

  /// 부상인지 확인
  bool get isInjury => reason?.toLowerCase().contains('injur') ?? false;

  /// 출전 정지인지 확인
  bool get isSuspended => reason?.toLowerCase().contains('suspend') ?? false;

  /// 의심스러운 상태인지 (출전 불확실)
  bool get isDoubtful => reason?.toLowerCase().contains('doubt') ?? false;

  /// 상태 아이콘 (UI용)
  String get statusIcon {
    if (isSuspended) return '🟥'; // 레드카드/정지
    if (isInjury) return '🤕'; // 부상
    if (isDoubtful) return '❓'; // 불확실
    return '❌'; // 기타 결장
  }

  /// 상태 텍스트 (한국어)
  String get statusText {
    if (isSuspended) return '출전 정지';
    if (isInjury) return '부상';
    if (isDoubtful) return '출전 불투명';
    return '결장';
  }
}
