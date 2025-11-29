import 'dart:convert';
import 'package:http/http.dart' as http;

/// TheSportsDB API 서비스
/// API Key: 869004 (Premium)
/// 문서: https://www.thesportsdb.com/api.php
class SportsDbService {
  static const String _baseUrl = 'https://www.thesportsdb.com/api/v1/json';
  static const String _apiKey = '869004';

  // 싱글톤 패턴
  static final SportsDbService _instance = SportsDbService._internal();
  factory SportsDbService() => _instance;
  SportsDbService._internal();

  /// API 호출 헬퍼
  Future<Map<String, dynamic>?> _get(String endpoint) async {
    try {
      final url = '$_baseUrl/$_apiKey/$endpoint';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('SportsDB API Error: $e');
      return null;
    }
  }

  // ============ 팀 검색 ============

  /// 팀 이름으로 검색
  Future<List<SportsDbTeam>> searchTeams(String teamName) async {
    final data = await _get('searchteams.php?t=${Uri.encodeComponent(teamName)}');
    if (data == null || data['teams'] == null) return [];

    return (data['teams'] as List)
        .map((json) => SportsDbTeam.fromJson(json))
        .toList();
  }

  /// 리그별 팀 목록
  Future<List<SportsDbTeam>> getTeamsByLeague(String leagueName) async {
    final data = await _get('search_all_teams.php?l=${Uri.encodeComponent(leagueName)}');
    if (data == null || data['teams'] == null) return [];

    return (data['teams'] as List)
        .map((json) => SportsDbTeam.fromJson(json))
        .toList();
  }

  /// 팀 ID로 조회
  Future<SportsDbTeam?> getTeamById(String teamId) async {
    final data = await _get('lookupteam.php?id=$teamId');
    if (data == null || data['teams'] == null || (data['teams'] as List).isEmpty) {
      return null;
    }
    return SportsDbTeam.fromJson((data['teams'] as List).first);
  }

  // ============ 선수 검색 ============

  /// 선수 이름으로 검색
  Future<List<SportsDbPlayer>> searchPlayers(String playerName) async {
    final data = await _get('searchplayers.php?p=${Uri.encodeComponent(playerName)}');
    if (data == null || data['player'] == null) return [];

    return (data['player'] as List)
        .map((json) => SportsDbPlayer.fromJson(json))
        .toList();
  }

  /// 팀의 선수 목록
  Future<List<SportsDbPlayer>> getPlayersByTeam(String teamId) async {
    final data = await _get('lookup_all_players.php?id=$teamId');
    if (data == null || data['player'] == null) return [];

    return (data['player'] as List)
        .map((json) => SportsDbPlayer.fromJson(json))
        .toList();
  }

  // ============ 리그 ============

  /// 모든 리그 목록
  Future<List<SportsDbLeague>> getAllLeagues() async {
    final data = await _get('all_leagues.php');
    if (data == null || data['leagues'] == null) return [];

    return (data['leagues'] as List)
        .map((json) => SportsDbLeague.fromJson(json))
        .toList();
  }

  /// 국가와 스포츠로 리그 검색
  Future<List<SportsDbLeague>> searchLeagues(String country, String sport) async {
    final data = await _get(
        'search_all_leagues.php?c=${Uri.encodeComponent(country)}&s=${Uri.encodeComponent(sport)}');
    if (data == null || data['countries'] == null) return [];

    return (data['countries'] as List)
        .map((json) => SportsDbLeague.fromJson(json))
        .toList();
  }

  // ============ 경기 일정 ============

  /// 특정 날짜의 경기
  Future<List<SportsDbEvent>> getEventsByDate(DateTime date, {String? sport, String? league}) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    String endpoint = 'eventsday.php?d=$dateStr';

    if (sport != null) {
      endpoint += '&s=${Uri.encodeComponent(sport)}';
    }
    if (league != null) {
      endpoint += '&l=${Uri.encodeComponent(league)}';
    }

    final data = await _get(endpoint);
    if (data == null || data['events'] == null) return [];

    return (data['events'] as List)
        .map((json) => SportsDbEvent.fromJson(json))
        .toList();
  }

  /// 리그의 다음 경기들
  Future<List<SportsDbEvent>> getNextLeagueEvents(String leagueId) async {
    final data = await _get('eventsnextleague.php?id=$leagueId');
    if (data == null || data['events'] == null) return [];

    return (data['events'] as List)
        .map((json) => SportsDbEvent.fromJson(json))
        .toList();
  }

  /// 리그의 지난 경기들
  Future<List<SportsDbEvent>> getPastLeagueEvents(String leagueId) async {
    final data = await _get('eventspastleague.php?id=$leagueId');
    if (data == null || data['events'] == null) return [];

    return (data['events'] as List)
        .map((json) => SportsDbEvent.fromJson(json))
        .toList();
  }

  /// 팀의 다음 경기들
  Future<List<SportsDbEvent>> getNextTeamEvents(String teamId) async {
    final data = await _get('eventsnext.php?id=$teamId');
    if (data == null || data['events'] == null) return [];

    return (data['events'] as List)
        .map((json) => SportsDbEvent.fromJson(json))
        .toList();
  }

  /// 팀의 지난 경기들
  Future<List<SportsDbEvent>> getPastTeamEvents(String teamId) async {
    final data = await _get('eventslast.php?id=$teamId');
    if (data == null || data['events'] == null) return [];

    return (data['events'] as List)
        .map((json) => SportsDbEvent.fromJson(json))
        .toList();
  }

  /// 이벤트 검색
  Future<List<SportsDbEvent>> searchEvents(String eventName, {String? season}) async {
    String endpoint = 'searchevents.php?e=${Uri.encodeComponent(eventName)}';
    if (season != null) {
      endpoint += '&s=${Uri.encodeComponent(season)}';
    }

    final data = await _get(endpoint);
    if (data == null || data['event'] == null) return [];

    return (data['event'] as List)
        .map((json) => SportsDbEvent.fromJson(json))
        .toList();
  }

  /// 이벤트 ID로 조회
  Future<SportsDbEvent?> getEventById(String eventId) async {
    final data = await _get('lookupevent.php?id=$eventId');
    if (data == null || data['events'] == null || (data['events'] as List).isEmpty) {
      return null;
    }
    return SportsDbEvent.fromJson((data['events'] as List).first);
  }

  // ============ 경기장 ============

  /// 경기장 검색
  Future<List<SportsDbVenue>> searchVenues(String venueName) async {
    final data = await _get('searchvenues.php?v=${Uri.encodeComponent(venueName)}');
    if (data == null || data['venues'] == null) return [];

    return (data['venues'] as List)
        .map((json) => SportsDbVenue.fromJson(json))
        .toList();
  }
}

// ============ 모델 클래스들 ============

/// 팀 모델
class SportsDbTeam {
  final String id;
  final String name;
  final String? nameKr;
  final String? league;
  final String? country;
  final String? stadium;
  final String? stadiumCapacity;
  final String? badge;
  final String? jersey;
  final String? logo;
  final String? banner;
  final String? description;

  SportsDbTeam({
    required this.id,
    required this.name,
    this.nameKr,
    this.league,
    this.country,
    this.stadium,
    this.stadiumCapacity,
    this.badge,
    this.jersey,
    this.logo,
    this.banner,
    this.description,
  });

  factory SportsDbTeam.fromJson(Map<String, dynamic> json) {
    return SportsDbTeam(
      id: json['idTeam'] ?? '',
      name: json['strTeam'] ?? '',
      nameKr: json['strTeamAlternate'],
      league: json['strLeague'],
      country: json['strCountry'],
      stadium: json['strStadium'],
      stadiumCapacity: json['intStadiumCapacity']?.toString(),
      badge: json['strBadge'],
      jersey: json['strJersey'],
      logo: json['strLogo'],
      banner: json['strBanner'],
      description: json['strDescriptionEN'],
    );
  }
}

/// 선수 모델
class SportsDbPlayer {
  final String id;
  final String name;
  final String? nameKr;
  final String? team;
  final String? teamId;
  final String? nationality;
  final String? position;
  final String? number;
  final String? dateBorn;
  final String? height;
  final String? weight;
  final String? photo;
  final String? thumb;
  final String? description;

  SportsDbPlayer({
    required this.id,
    required this.name,
    this.nameKr,
    this.team,
    this.teamId,
    this.nationality,
    this.position,
    this.number,
    this.dateBorn,
    this.height,
    this.weight,
    this.photo,
    this.thumb,
    this.description,
  });

  factory SportsDbPlayer.fromJson(Map<String, dynamic> json) {
    return SportsDbPlayer(
      id: json['idPlayer'] ?? '',
      name: json['strPlayer'] ?? '',
      nameKr: json['strPlayerAlternate'],
      team: json['strTeam'],
      teamId: json['idTeam'],
      nationality: json['strNationality'],
      position: json['strPosition'],
      number: json['strNumber'],
      dateBorn: json['dateBorn'],
      height: json['strHeight'],
      weight: json['strWeight'],
      photo: json['strCutout'] ?? json['strThumb'],
      thumb: json['strThumb'],
      description: json['strDescriptionEN'],
    );
  }
}

/// 리그 모델
class SportsDbLeague {
  final String id;
  final String name;
  final String? nameKr;
  final String? sport;
  final String? country;
  final String? badge;
  final String? logo;
  final String? banner;
  final String? description;

  SportsDbLeague({
    required this.id,
    required this.name,
    this.nameKr,
    this.sport,
    this.country,
    this.badge,
    this.logo,
    this.banner,
    this.description,
  });

  factory SportsDbLeague.fromJson(Map<String, dynamic> json) {
    return SportsDbLeague(
      id: json['idLeague'] ?? '',
      name: json['strLeague'] ?? '',
      nameKr: json['strLeagueAlternate'],
      sport: json['strSport'],
      country: json['strCountry'],
      badge: json['strBadge'],
      logo: json['strLogo'],
      banner: json['strBanner'],
      description: json['strDescriptionEN'],
    );
  }
}

/// 경기(이벤트) 모델
class SportsDbEvent {
  final String id;
  final String name;
  final String? league;
  final String? leagueId;
  final String? season;
  final String? homeTeam;
  final String? homeTeamId;
  final String? awayTeam;
  final String? awayTeamId;
  final int? homeScore;
  final int? awayScore;
  final String? date;
  final String? time;
  final String? venue;
  final String? venueId;
  final String? thumb;
  final String? banner;
  final String? status;

  SportsDbEvent({
    required this.id,
    required this.name,
    this.league,
    this.leagueId,
    this.season,
    this.homeTeam,
    this.homeTeamId,
    this.awayTeam,
    this.awayTeamId,
    this.homeScore,
    this.awayScore,
    this.date,
    this.time,
    this.venue,
    this.venueId,
    this.thumb,
    this.banner,
    this.status,
  });

  factory SportsDbEvent.fromJson(Map<String, dynamic> json) {
    return SportsDbEvent(
      id: json['idEvent'] ?? '',
      name: json['strEvent'] ?? '',
      league: json['strLeague'],
      leagueId: json['idLeague'],
      season: json['strSeason'],
      homeTeam: json['strHomeTeam'],
      homeTeamId: json['idHomeTeam'],
      awayTeam: json['strAwayTeam'],
      awayTeamId: json['idAwayTeam'],
      homeScore: int.tryParse(json['intHomeScore']?.toString() ?? ''),
      awayScore: int.tryParse(json['intAwayScore']?.toString() ?? ''),
      date: json['dateEvent'],
      time: json['strTime'],
      venue: json['strVenue'],
      venueId: json['idVenue'],
      thumb: json['strThumb'],
      banner: json['strBanner'],
      status: json['strStatus'],
    );
  }

  /// 경기 완료 여부
  bool get isFinished => homeScore != null && awayScore != null;

  /// 스코어 표시 문자열
  String get scoreDisplay {
    if (isFinished) {
      return '$homeScore - $awayScore';
    }
    return 'vs';
  }

  /// 경기 날짜 DateTime (API는 UTC 시간 반환, 로컬 시간으로 변환)
  DateTime? get dateTime {
    if (date == null) return null;
    try {
      final parts = date!.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      int hour = 0;
      int minute = 0;

      if (time != null && time!.isNotEmpty) {
        final timeParts = time!.split(':');
        hour = int.parse(timeParts[0]);
        minute = int.parse(timeParts[1]);
      }

      // UTC로 파싱 후 로컬 시간으로 변환 (한국: UTC+9)
      // 시간 변환 시 날짜도 자동으로 변경됨
      final utcTime = DateTime.utc(year, month, day, hour, minute);
      return utcTime.toLocal();
    } catch (e) {
      return null;
    }
  }
}

/// 경기장 모델
class SportsDbVenue {
  final String id;
  final String name;
  final String? location;
  final String? country;
  final String? capacity;
  final String? description;
  final String? thumb;
  final String? map;

  SportsDbVenue({
    required this.id,
    required this.name,
    this.location,
    this.country,
    this.capacity,
    this.description,
    this.thumb,
    this.map,
  });

  factory SportsDbVenue.fromJson(Map<String, dynamic> json) {
    return SportsDbVenue(
      id: json['idVenue'] ?? '',
      name: json['strVenue'] ?? '',
      location: json['strLocation'],
      country: json['strCountry'],
      capacity: json['intCapacity']?.toString(),
      description: json['strDescriptionEN'],
      thumb: json['strThumb'],
      map: json['strMap'],
    );
  }
}
