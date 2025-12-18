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

    return (teamData['players'] as List)
        .map((json) => ApiFootballSquadPlayer.fromJson(json))
        .toList();
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

  // ============ 순위 ============

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
