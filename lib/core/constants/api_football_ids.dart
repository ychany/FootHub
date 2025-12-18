/// API-Football ID 매핑
/// TheSportsDB ID → API-Football ID 변환용 상수

class ApiFootballIds {
  ApiFootballIds._();

  // ============ 리그 ID ============

  /// 리그 ID 매핑
  static const leagues = LeagueIds();

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

  // ============ 팀 ID ============

  /// 팀 ID 매핑
  static const teams = TeamIds();

  /// 팀 이름으로 API-Football ID 가져오기
  static int? getTeamId(String teamName) {
    final name = teamName.toLowerCase();

    // 국가대표
    if (name.contains('south korea') || name == 'korea' || name == '대한민국') return TeamIds.southKorea;
    if (name.contains('north korea')) return TeamIds.northKorea;

    // K리그
    if (name.contains('fc seoul') || name.contains('서울')) return TeamIds.fcSeoul;
    if (name.contains('jeonbuk') || name.contains('전북')) return TeamIds.jeonbukMotors;
    if (name.contains('ulsan') || name.contains('울산')) return TeamIds.ulsanHyundai;
    if (name.contains('pohang') || name.contains('포항')) return TeamIds.pohangSteelers;
    if (name.contains('suwon') && name.contains('blue') || name.contains('수원삼성')) return TeamIds.suwonBluewings;
    if (name.contains('daegu') || name.contains('대구')) return TeamIds.daeguFC;
    if (name.contains('incheon') || name.contains('인천')) return TeamIds.incheonUnited;
    if (name.contains('gangwon') || name.contains('강원')) return TeamIds.gangwonFC;
    if (name.contains('jeju') || name.contains('제주')) return TeamIds.jejuUnited;
    if (name.contains('gwangju') || name.contains('광주')) return TeamIds.gwangjuFC;
    if (name.contains('daejeon') || name.contains('대전')) return TeamIds.daejeonCitizen;
    if (name.contains('gimcheon') || name.contains('김천')) return TeamIds.gimcheonSangmu;
    if (name.contains('seongnam') || name.contains('성남')) return TeamIds.seongnamFC;

    // EPL
    if (name.contains('tottenham') || name.contains('spurs')) return TeamIds.tottenham;
    if (name.contains('manchester city') || name.contains('man city')) return TeamIds.manchesterCity;
    if (name.contains('manchester united') || name.contains('man utd')) return TeamIds.manchesterUnited;
    if (name.contains('arsenal')) return TeamIds.arsenal;
    if (name.contains('chelsea')) return TeamIds.chelsea;
    if (name.contains('liverpool')) return TeamIds.liverpool;

    // 라리가
    if (name.contains('barcelona')) return TeamIds.barcelona;
    if (name.contains('real madrid')) return TeamIds.realMadrid;
    if (name.contains('atletico madrid')) return TeamIds.atleticoMadrid;

    // 분데스리가
    if (name.contains('bayern')) return TeamIds.bayernMunich;
    if (name.contains('dortmund')) return TeamIds.dortmund;

    // 세리에A
    if (name.contains('juventus')) return TeamIds.juventus;
    if (name.contains('inter') && name.contains('milan')) return TeamIds.interMilan;
    if (name.contains('ac milan') || (name.contains('milan') && !name.contains('inter'))) return TeamIds.acMilan;
    if (name.contains('napoli')) return TeamIds.napoli;

    // 리그1
    if (name.contains('paris') || name.contains('psg')) return TeamIds.psg;

    return null;
  }

  /// TheSportsDB 팀 ID → API-Football 팀 ID 변환
  static int? convertTeamId(String sportsDbId) {
    return _sportsDbToApiFootball[sportsDbId];
  }

  /// TheSportsDB → API-Football 팀 ID 매핑
  static const Map<String, int> _sportsDbToApiFootball = {
    // 국가대표
    '134517': 17, // South Korea

    // K리그
    '140083': 2766, // FC Seoul
    '136935': 2762, // Jeonbuk Motors
    '136934': 2767, // Ulsan Hyundai
    '136929': 2764, // Pohang Steelers
    '136930': 2765, // Suwon Bluewings
    '136928': 2747, // Daegu FC
    '136931': 2763, // Incheon United
    '136922': 2746, // Gangwon FC
    '136932': 2761, // Jeju United
    '136933': 2759, // Gwangju FC
    '140085': 2750, // Daejeon Citizen
    '140084': 2768, // Gimcheon Sangmu
    '136927': 2757, // Seongnam FC

    // EPL
    '133616': 47,  // Tottenham
    '133613': 50,  // Manchester City
    '133612': 33,  // Manchester United
    '133604': 42,  // Arsenal
    '133610': 49,  // Chelsea
    '133602': 40,  // Liverpool

    // 라리가
    '133739': 529, // Barcelona
    '133738': 541, // Real Madrid
    '133703': 530, // Atletico Madrid

    // 분데스리가
    '133597': 157, // Bayern Munich
    '133598': 165, // Dortmund

    // 세리에A
    '133676': 496, // Juventus
    '133670': 505, // Inter Milan
    '133671': 489, // AC Milan
    '133684': 492, // Napoli

    // 리그1
    '133712': 85, // PSG
  };

  /// TheSportsDB 리그 ID → API-Football 리그 ID 변환
  static int? convertLeagueId(String sportsDbId) {
    return _sportsDbLeagueToApiFootball[sportsDbId];
  }

  /// TheSportsDB → API-Football 리그 ID 매핑
  static const Map<String, int> _sportsDbLeagueToApiFootball = {
    '4464': 292,  // K League 1
    '4328': 39,   // Premier League
    '4335': 140,  // La Liga
    '4331': 78,   // Bundesliga
    '4332': 135,  // Serie A
    '4334': 61,   // Ligue 1
    '4480': 2,    // Champions League
    '4481': 3,    // Europa League
    '4429': 1,    // World Cup
    '4562': 10,   // Friendlies
    '4866': 81,   // Asian Cup (AFC)
  };
}

/// 리그 ID 상수
class LeagueIds {
  const LeagueIds();

  // 한국
  static const int kLeague1 = 292;
  static const int kLeague2 = 293;
  static const int kLeague3 = 295;
  static const int koreaFaCup = 294;

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

  // 국제 대회
  static const int worldCup = 1;
  static const int euro = 4;
  static const int asianCup = 81;
  static const int friendlies = 10;
  static const int worldCupQualAsia = 30; // 월드컵 예선 아시아

  // 현재 시즌 반환
  static int getCurrentSeason() {
    final now = DateTime.now();
    // 유럽 리그: 8월~다음해 5월 → 시작 연도 기준
    // K리그: 2월~11월 → 해당 연도 기준
    if (now.month >= 7) {
      return now.year;
    }
    return now.year;
  }

  /// 지원 리그 목록 (순위표 있는 리그)
  static const List<LeagueInfo> supportedLeagues = [
    LeagueInfo(id: kLeague1, name: 'K리그1', nameEn: 'K League 1', country: 'South Korea'),
    LeagueInfo(id: kLeague2, name: 'K리그2', nameEn: 'K League 2', country: 'South Korea'),
    LeagueInfo(id: premierLeague, name: '프리미어리그', nameEn: 'Premier League', country: 'England'),
    LeagueInfo(id: laLiga, name: '라리가', nameEn: 'La Liga', country: 'Spain'),
    LeagueInfo(id: bundesliga, name: '분데스리가', nameEn: 'Bundesliga', country: 'Germany'),
    LeagueInfo(id: serieA, name: '세리에 A', nameEn: 'Serie A', country: 'Italy'),
    LeagueInfo(id: ligue1, name: '리그 1', nameEn: 'Ligue 1', country: 'France'),
    LeagueInfo(id: championsLeague, name: 'UEFA 챔피언스리그', nameEn: 'Champions League', country: 'Europe'),
    LeagueInfo(id: europaLeague, name: 'UEFA 유로파리그', nameEn: 'Europa League', country: 'Europe'),
  ];

  /// ID로 리그 정보 가져오기
  static LeagueInfo? getLeagueInfo(int id) {
    try {
      return supportedLeagues.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// 팀 ID 상수
class TeamIds {
  const TeamIds();

  // 국가대표
  static const int southKorea = 17;
  static const int northKorea = 1561;
  static const int japan = 2;
  static const int china = 902;

  // K리그 1
  static const int fcSeoul = 2766;
  static const int jeonbukMotors = 2762;
  static const int ulsanHyundai = 2767;
  static const int pohangSteelers = 2764;
  static const int suwonBluewings = 2765;
  static const int daeguFC = 2747;
  static const int incheonUnited = 2763;
  static const int gangwonFC = 2746;
  static const int jejuUnited = 2761;
  static const int gwangjuFC = 2759;
  static const int daejeonCitizen = 2750;
  static const int gimcheonSangmu = 2768;
  static const int seongnamFC = 2757;
  static const int suwonFC = 2756;

  // EPL
  static const int tottenham = 47;
  static const int manchesterCity = 50;
  static const int manchesterUnited = 33;
  static const int arsenal = 42;
  static const int chelsea = 49;
  static const int liverpool = 40;
  static const int newcastle = 34;
  static const int brighton = 51;
  static const int astonVilla = 66;
  static const int westHam = 48;

  // 라리가
  static const int barcelona = 529;
  static const int realMadrid = 541;
  static const int atleticoMadrid = 530;
  static const int realSociedad = 548;
  static const int villarreal = 533;

  // 분데스리가
  static const int bayernMunich = 157;
  static const int dortmund = 165;
  static const int leverkusen = 168;
  static const int leipzig = 173;

  // 세리에A
  static const int juventus = 496;
  static const int interMilan = 505;
  static const int acMilan = 489;
  static const int napoli = 492;
  static const int roma = 497;

  // 리그1
  static const int psg = 85;
  static const int marseille = 81;
  static const int monaco = 91;

  // 기타
  static const int mexico = 16;
  static const int southAfrica = 1531;
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
