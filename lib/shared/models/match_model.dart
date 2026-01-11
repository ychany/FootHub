import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum MatchStatus {
  scheduled,
  live,
  finished,
  postponed,
  cancelled,
}

class Match extends Equatable {
  final String id;
  final String league;
  final int? leagueId; // API-Football 리그 ID
  final String? leagueCountry; // 리그 국가
  final String homeTeamId;
  final String homeTeamName;
  final String? homeTeamLogo;
  final String awayTeamId;
  final String awayTeamName;
  final String? awayTeamLogo;
  final DateTime kickoff;
  final String stadium;
  final String? broadcast;
  final int? homeScore;
  final int? awayScore;
  final MatchStatus status;
  final bool followedBoost;
  final List<MatchEvent>? events;
  final int? elapsed; // 라이브 경기 경과 시간 (분)
  final int? extra; // 라이브 경기 추가 시간 (분)
  final String? statusShort; // API 상태 코드 (1H, HT, 2H, FT 등)
  final int? penaltyHome; // 승부차기 홈팀 점수
  final int? penaltyAway; // 승부차기 원정팀 점수

  const Match({
    required this.id,
    required this.league,
    this.leagueId,
    this.leagueCountry,
    required this.homeTeamId,
    required this.homeTeamName,
    this.homeTeamLogo,
    required this.awayTeamId,
    required this.awayTeamName,
    this.awayTeamLogo,
    required this.kickoff,
    required this.stadium,
    this.broadcast,
    this.homeScore,
    this.awayScore,
    this.status = MatchStatus.scheduled,
    this.followedBoost = false,
    this.events,
    this.elapsed,
    this.extra,
    this.statusShort,
    this.penaltyHome,
    this.penaltyAway,
  });

  bool get isFinished => status == MatchStatus.finished;
  bool get isLive => status == MatchStatus.live;
  bool get isHalftime => statusShort == 'HT';
  bool get isPenaltyShootout => statusShort == 'PEN';

  String get scoreDisplay {
    if (homeScore == null || awayScore == null) return 'vs';
    return '$homeScore - $awayScore';
  }

  /// 승부차기 점수 표시 문자열
  String? get penaltyScoreDisplay {
    if (isPenaltyShootout && penaltyHome != null && penaltyAway != null) {
      return '($penaltyHome - $penaltyAway)';
    }
    return null;
  }

  factory Match.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Timestamp 안전하게 파싱하는 헬퍼 함수
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return Match(
      id: doc.id,
      league: data['league'] as String? ?? '',
      leagueId: data['leagueId'] as int?,
      leagueCountry: data['leagueCountry'] as String?,
      homeTeamId: data['homeTeamId'] as String? ?? '',
      homeTeamName: data['homeTeamName'] as String? ?? '',
      homeTeamLogo: data['homeTeamLogo'] as String?,
      awayTeamId: data['awayTeamId'] as String? ?? '',
      awayTeamName: data['awayTeamName'] as String? ?? '',
      awayTeamLogo: data['awayTeamLogo'] as String?,
      kickoff: parseTimestamp(data['kickoff']),
      stadium: data['stadium'] as String? ?? '',
      broadcast: data['broadcast'] as String?,
      homeScore: data['homeScore'] as int?,
      awayScore: data['awayScore'] as int?,
      status: MatchStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => MatchStatus.scheduled,
      ),
      followedBoost: data['followedBoost'] as bool? ?? false,
      events: (data['events'] as List<dynamic>?)
          ?.map((e) => MatchEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      elapsed: data['elapsed'] as int?,
      extra: data['extra'] as int?,
      statusShort: data['statusShort'] as String?,
      penaltyHome: data['penaltyHome'] as int?,
      penaltyAway: data['penaltyAway'] as int?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'league': league,
      'leagueId': leagueId,
      'leagueCountry': leagueCountry,
      'homeTeamId': homeTeamId,
      'homeTeamName': homeTeamName,
      'homeTeamLogo': homeTeamLogo,
      'awayTeamId': awayTeamId,
      'awayTeamName': awayTeamName,
      'awayTeamLogo': awayTeamLogo,
      'kickoff': Timestamp.fromDate(kickoff),
      'stadium': stadium,
      'broadcast': broadcast,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'status': status.name,
      'followedBoost': followedBoost,
      'events': events?.map((e) => e.toJson()).toList(),
      'elapsed': elapsed,
      'extra': extra,
      'statusShort': statusShort,
      'penaltyHome': penaltyHome,
      'penaltyAway': penaltyAway,
    };
  }

  Match copyWith({
    String? id,
    String? league,
    int? leagueId,
    String? leagueCountry,
    String? homeTeamId,
    String? homeTeamName,
    String? homeTeamLogo,
    String? awayTeamId,
    String? awayTeamName,
    String? awayTeamLogo,
    DateTime? kickoff,
    String? stadium,
    String? broadcast,
    int? homeScore,
    int? awayScore,
    MatchStatus? status,
    bool? followedBoost,
    List<MatchEvent>? events,
    int? elapsed,
    int? extra,
    String? statusShort,
    int? penaltyHome,
    int? penaltyAway,
  }) {
    return Match(
      id: id ?? this.id,
      league: league ?? this.league,
      leagueId: leagueId ?? this.leagueId,
      leagueCountry: leagueCountry ?? this.leagueCountry,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      homeTeamName: homeTeamName ?? this.homeTeamName,
      homeTeamLogo: homeTeamLogo ?? this.homeTeamLogo,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      awayTeamName: awayTeamName ?? this.awayTeamName,
      awayTeamLogo: awayTeamLogo ?? this.awayTeamLogo,
      kickoff: kickoff ?? this.kickoff,
      stadium: stadium ?? this.stadium,
      broadcast: broadcast ?? this.broadcast,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      status: status ?? this.status,
      followedBoost: followedBoost ?? this.followedBoost,
      events: events ?? this.events,
      elapsed: elapsed ?? this.elapsed,
      extra: extra ?? this.extra,
      statusShort: statusShort ?? this.statusShort,
      penaltyHome: penaltyHome ?? this.penaltyHome,
      penaltyAway: penaltyAway ?? this.penaltyAway,
    );
  }

  @override
  List<Object?> get props => [
        id,
        league,
        homeTeamId,
        awayTeamId,
        kickoff,
        homeScore,
        awayScore,
        status,
        elapsed,
        extra,
        statusShort,
        penaltyHome,
        penaltyAway,
      ];

  // Example dummy data
  static List<Match> dummyMatches() {
    return [
      Match(
        id: 'match_001',
        league: 'EPL',
        homeTeamId: 'team_tottenham',
        homeTeamName: 'Tottenham Hotspur',
        awayTeamId: 'team_mancity',
        awayTeamName: 'Manchester City',
        kickoff: DateTime.now().add(const Duration(days: 1)),
        stadium: 'Tottenham Hotspur Stadium',
        broadcast: 'SPOTV',
        status: MatchStatus.scheduled,
        followedBoost: true,
      ),
      Match(
        id: 'match_002',
        league: 'La Liga',
        homeTeamId: 'team_realmadrid',
        homeTeamName: 'Real Madrid',
        awayTeamId: 'team_barcelona',
        awayTeamName: 'FC Barcelona',
        kickoff: DateTime.now().subtract(const Duration(days: 1)),
        stadium: 'Santiago Bernabu',
        broadcast: 'SPOTV',
        homeScore: 2,
        awayScore: 1,
        status: MatchStatus.finished,
      ),
      Match(
        id: 'match_003',
        league: 'K-League',
        homeTeamId: 'team_fcseoul',
        homeTeamName: 'FC Seoul',
        awayTeamId: 'team_jeonbuk',
        awayTeamName: 'Jeonbuk Motors',
        kickoff: DateTime.now().add(const Duration(hours: 2)),
        stadium: '0',
        broadcast: 'SPOTV',
        status: MatchStatus.scheduled,
        followedBoost: false,
      ),
    ];
  }
}

class MatchEvent extends Equatable {
  final int minute;
  final String type; // goal, yellow_card, red_card, substitution
  final String playerName;
  final String teamId;
  final String? assistPlayerName;

  const MatchEvent({
    required this.minute,
    required this.type,
    required this.playerName,
    required this.teamId,
    this.assistPlayerName,
  });

  factory MatchEvent.fromJson(Map<String, dynamic> json) {
    return MatchEvent(
      minute: json['minute'] as int,
      type: json['type'] as String,
      playerName: json['playerName'] as String,
      teamId: json['teamId'] as String,
      assistPlayerName: json['assistPlayerName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minute': minute,
      'type': type,
      'playerName': playerName,
      'teamId': teamId,
      'assistPlayerName': assistPlayerName,
    };
  }

  @override
  List<Object?> get props => [minute, type, playerName, teamId];
}
