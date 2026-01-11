// API-Football ID 상수

class ApiFootballIds {
  ApiFootballIds._();

  /// 리그 이름으로 API-Football ID 가져오기
  static int? getLeagueId(String leagueName) {
    final name = leagueName.toLowerCase();

    // K리그
    if (name.contains('k league 1') || name.contains('k리그')) return LeagueIds.kLeague1;
    if (name.contains('k league 2')) return LeagueIds.kLeague2;

    // 유럽 5대 리그
    if (name.contains('premier league') || name.contains('epl')) return LeagueIds.premierLeague;
    if (name.contains('la liga') || name.contains('laliga')) return LeagueIds.laLiga;
    if (name.contains('bundesliga')) return LeagueIds.bundesliga;
    if (name.contains('serie a')) return LeagueIds.serieA;
    if (name.contains('ligue 1')) return LeagueIds.ligue1;

    // 유럽 대회
    if (name.contains('champions league') || name.contains('ucl')) return LeagueIds.championsLeague;
    if (name.contains('europa league') || name.contains('uel')) return LeagueIds.europaLeague;
    if (name.contains('conference league')) return LeagueIds.conferenceLeague;

    // 국제 대회
    if (name.contains('world cup') && !name.contains('qualif')) return LeagueIds.worldCup;
    if (name.contains('euro') && name.contains('championship')) return LeagueIds.euro;
    if (name.contains('asian cup')) return LeagueIds.asianCup;
    if (name.contains('friendl')) return LeagueIds.friendlies;

    return null;
  }
}

/// 리그 ID 상수
class LeagueIds {
  const LeagueIds();

  // 한국
  static const int kLeague1 = 292;
  static const int kLeague2 = 293;

  // 유럽 5대 리그
  static const int premierLeague = 39;
  static const int laLiga = 140;
  static const int bundesliga = 78;
  static const int serieA = 135;
  static const int ligue1 = 61;

  // 유럽 대회
  static const int championsLeague = 2;
  static const int europaLeague = 3;
  static const int conferenceLeague = 848;

  // 5대 리그 국내 컵 대회
  static const int faCup = 45;
  static const int eflCup = 48; // Carabao Cup
  static const int dfbPokal = 81;
  static const int copaDelRey = 143;
  static const int coupeDeFrance = 66;
  static const int coppaItalia = 137;

  // 컵 대회 ID 목록 (토너먼트 형식)
  static const List<int> cupCompetitionIds = [
    faCup, eflCup, dfbPokal, copaDelRey, coupeDeFrance, coppaItalia,
  ];

  /// 컵 대회 여부 확인
  static bool isCupCompetition(int leagueId) {
    return cupCompetitionIds.contains(leagueId);
  }

  // 국제 대회 - 본선
  static const int worldCup = 1;
  static const int euro = 4;
  static const int asianCup = 81;
  static const int copaAmerica = 9;
  static const int africaCup = 6;
  static const int goldCup = 22; // CONCACAF Gold Cup

  // 국제 대회 - 예선
  static const int worldCupQualEurope = 32;
  static const int worldCupQualAsia = 30;
  static const int worldCupQualAfrica = 29;
  static const int worldCupQualSouthAmerica = 28;
  static const int worldCupQualNorthAmerica = 31;
  static const int euroQualification = 960;
  static const int asianCupQualification = 530;

  // 국제 대회 - 네이션스리그
  static const int uefaNationsLeague = 5;
  static const int concacafNationsLeague = 378;

  // 친선경기
  static const int friendlies = 10;

  // A매치 전체 (국가대표 경기) ID 목록
  static const List<int> internationalLeagueIds = [
    // 본선
    worldCup, euro, asianCup, copaAmerica, africaCup, goldCup,
    // 예선
    worldCupQualEurope, worldCupQualAsia, worldCupQualAfrica,
    worldCupQualSouthAmerica, worldCupQualNorthAmerica,
    euroQualification, asianCupQualification,
    // 네이션스리그
    uefaNationsLeague, concacafNationsLeague,
    // 친선
    friendlies,
  ];

  // 현재 시즌 반환
  static int getCurrentSeason() {
    final now = DateTime.now();
    if (now.month >= 7) {
      return now.year;
    }
    return now.year;
  }

  /// 지원 리그 목록 (순위표 있는 리그) - 5대 리그 + 국내컵 + 유럽 대회
  static const List<LeagueInfo> supportedLeagues = [
    // 5대 리그
    LeagueInfo(id: premierLeague, name: '프리미어리그', nameEn: 'Premier League', country: 'England'),
    LeagueInfo(id: laLiga, name: '라리가', nameEn: 'La Liga', country: 'Spain'),
    LeagueInfo(id: bundesliga, name: '분데스리가', nameEn: 'Bundesliga', country: 'Germany'),
    LeagueInfo(id: serieA, name: '세리에 A', nameEn: 'Serie A', country: 'Italy'),
    LeagueInfo(id: ligue1, name: '리그 1', nameEn: 'Ligue 1', country: 'France'),
    // 5대 리그 국내 컵 대회
    LeagueInfo(id: faCup, name: 'FA컵', nameEn: 'FA Cup', country: 'England'),
    LeagueInfo(id: eflCup, name: 'EFL컵', nameEn: 'EFL Cup', country: 'England'),
    LeagueInfo(id: copaDelRey, name: '코파 델 레이', nameEn: 'Copa del Rey', country: 'Spain'),
    LeagueInfo(id: dfbPokal, name: 'DFB 포칼', nameEn: 'DFB Pokal', country: 'Germany'),
    LeagueInfo(id: coppaItalia, name: '코파 이탈리아', nameEn: 'Coppa Italia', country: 'Italy'),
    LeagueInfo(id: coupeDeFrance, name: '쿠프 드 프랑스', nameEn: 'Coupe de France', country: 'France'),
    // 유럽 대회
    LeagueInfo(id: championsLeague, name: 'UEFA 챔피언스리그', nameEn: 'Champions League', country: 'Europe'),
    LeagueInfo(id: europaLeague, name: 'UEFA 유로파리그', nameEn: 'Europa League', country: 'Europe'),
  ];

  /// 자국 리그 목록 (국가 코드 기반)
  static List<LeagueInfo> getLocalLeagues(String countryCode) {
    switch (countryCode) {
      case 'KR':
        return const [
          LeagueInfo(id: kLeague1, name: 'K리그1', nameEn: 'K League 1', country: 'South Korea'),
          LeagueInfo(id: kLeague2, name: 'K리그2', nameEn: 'K League 2', country: 'South Korea'),
        ];
      case 'JP':
        return const [
          LeagueInfo(id: 98, name: 'J1 리그', nameEn: 'J1 League', country: 'Japan'),
          LeagueInfo(id: 99, name: 'J2 리그', nameEn: 'J2 League', country: 'Japan'),
        ];
      case 'CN':
        return const [
          LeagueInfo(id: 169, name: '중국 슈퍼리그', nameEn: 'Chinese Super League', country: 'China'),
        ];
      case 'US':
        return const [
          LeagueInfo(id: 253, name: 'MLS', nameEn: 'MLS', country: 'USA'),
        ];
      case 'BR':
        return const [
          LeagueInfo(id: 71, name: '브라질레이랑', nameEn: 'Brasileirão Série A', country: 'Brazil'),
          LeagueInfo(id: 72, name: '브라질레이랑 B', nameEn: 'Brasileirão Série B', country: 'Brazil'),
        ];
      case 'AR':
        return const [
          LeagueInfo(id: 128, name: '리가 프로페시오날', nameEn: 'Liga Profesional', country: 'Argentina'),
        ];
      case 'MX':
        return const [
          LeagueInfo(id: 262, name: '리가 MX', nameEn: 'Liga MX', country: 'Mexico'),
        ];
      case 'AU':
        return const [
          LeagueInfo(id: 188, name: 'A-리그', nameEn: 'A-League', country: 'Australia'),
        ];
      case 'SA':
        return const [
          LeagueInfo(id: 307, name: '사우디 프로리그', nameEn: 'Saudi Pro League', country: 'Saudi Arabia'),
        ];
      case 'PT':
        return const [
          LeagueInfo(id: 94, name: '프리메이라 리가', nameEn: 'Primeira Liga', country: 'Portugal'),
        ];
      case 'NL':
        return const [
          LeagueInfo(id: 88, name: '에레디비시', nameEn: 'Eredivisie', country: 'Netherlands'),
        ];
      case 'TR':
        return const [
          LeagueInfo(id: 203, name: '쉬페르 리그', nameEn: 'Süper Lig', country: 'Turkey'),
        ];
      // 5대 리그 국가는 이미 상단에 있으므로 빈 목록 반환
      case 'GB':
      case 'ES':
      case 'IT':
      case 'DE':
      case 'FR':
        return const [];
      default:
        return const [];
    }
  }

  /// 자국 리그 포함한 전체 리그 목록 (자국 리그는 맨 뒤에)
  static List<LeagueInfo> getAllLeagues(String countryCode) {
    final localLeagues = getLocalLeagues(countryCode);
    return [...supportedLeagues, ...localLeagues];
  }

  /// ID로 리그 정보 가져오기
  static LeagueInfo? getLeagueInfo(int id) {
    try {
      return supportedLeagues.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// 리그 정보 클래스
class LeagueInfo {
  final int id;
  final String name;
  final String nameEn;
  final String country;

  const LeagueInfo({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.country,
  });
}
