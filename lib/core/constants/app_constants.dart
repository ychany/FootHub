import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

// App Constants
class AppConstants {
  static const String appName = 'MatchLog';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String attendanceCollection = 'attendance_records';
  static const String diaryCollection = 'match_diary';
  static const String schedulesCollection = 'schedules';
  static const String notificationSettingsCollection = 'notification_settings';
  static const String teamsCollection = 'teams';
  static const String playersCollection = 'players';

  // Storage Paths
  static const String attendancePhotosPath = 'attendance_photos';

  // Leagues - 기본 리그 목록 (5대 리그 + 유럽 대회 + A매치)
  // 자국 리그는 userLocalLeagueIdsProvider를 통해 동적으로 추가됨
  static const List<String> supportedLeagues = [
    'English Premier League',
    'Spanish La Liga',
    'Italian Serie A',
    'German Bundesliga',
    'French Ligue 1',
    'UEFA Champions League',
    'UEFA Europa League',
    'UEFA Conference League',
    'Domestic Cups',
    'International Friendlies',
  ];

  // 순위표가 있는 리그 (A매치 제외)
  static const List<String> leaguesWithStandings = [
    'English Premier League',
    'Spanish La Liga',
    'Italian Serie A',
    'German Bundesliga',
    'French Ligue 1',
    'UEFA Champions League',
    'UEFA Europa League',
    'UEFA Conference League',
  ];

  // 5대 국가 컵대회 (필터용)
  static const String domesticCups = 'Domestic Cups';

  // 리그 이름을 한국어로 표시
  static const Map<String, String> leagueDisplayNames = {
    'English Premier League': 'EPL',
    'Spanish La Liga': '라리가',
    'Italian Serie A': '세리에 A',
    'German Bundesliga': '분데스리가',
    'French Ligue 1': '리그 1',
    'South Korean K League 1': 'K리그1',
    'South Korean K League 2': 'K리그2',
    'UEFA Champions League': 'UCL',
    'UEFA Europa League': 'UEL',
    'UEFA Conference League': 'UECL',
    'International Friendlies': 'A매치',
    'Domestic Cups': '컵대회',
  };

  // API-Football 리그 이름 → 앱 내부 리그 이름 매핑
  static const Map<String, String> apiFootballLeagueMapping = {
    'Premier League': 'English Premier League',
    'La Liga': 'Spanish La Liga',
    'Serie A': 'Italian Serie A',
    'Bundesliga': 'German Bundesliga',
    'Ligue 1': 'French Ligue 1',
    'K League 1': 'South Korean K League 1',
    'K League 2': 'South Korean K League 2',
    'UEFA Champions League': 'UEFA Champions League',
    'UEFA Europa League': 'UEFA Europa League',
    'UEFA Conference League': 'UEFA Conference League',
    'International Friendlies': 'International Friendlies',
    // 추가 변형 이름들
    'Primera Division': 'Spanish La Liga',
    'Friendlies': 'International Friendlies',
  };

  // 앱 내부 리그 이름 → API-Football 리그 ID 매핑
  static const Map<String, int> leagueNameToId = {
    'English Premier League': 39,
    'Spanish La Liga': 140,
    'Italian Serie A': 135,
    'German Bundesliga': 78,
    'French Ligue 1': 61,
    'South Korean K League 1': 292,
    'South Korean K League 2': 293,
    'UEFA Champions League': 2,
    'UEFA Europa League': 3,
    'UEFA Conference League': 848,
    'International Friendlies': 10,
  };

  // 리그 ID로 필터 이름 가져오기
  static String? getLeagueNameById(int leagueId) {
    for (final entry in leagueNameToId.entries) {
      if (entry.value == leagueId) return entry.key;
    }
    return null;
  }

  // 리그 ID로 로컬라이즈된 이름 가져오기
  static String getLocalizedLeagueNameById(BuildContext context, int leagueId) {
    final leagueName = getLeagueNameById(leagueId);
    if (leagueName != null) {
      return getLocalizedLeagueName(context, leagueName);
    }
    return leagueId.toString();
  }

  // 필터 이름으로 리그 ID 가져오기
  static int? getLeagueIdByName(String leagueName) {
    return leagueNameToId[leagueName];
  }

  // 표시 이름으로 리그 이름 가져오기 (역방향) - 기본 한국어
  static String getLeagueDisplayName(String league) {
    return leagueDisplayNames[league] ?? league;
  }

  // Locale-aware 리그 이름 가져오기
  static String getLocalizedLeagueName(BuildContext context, String league) {
    final l10n = AppLocalizations.of(context)!;
    switch (league) {
      case 'English Premier League':
        return l10n.leagueEPL;
      case 'Spanish La Liga':
        return l10n.leagueLaLiga;
      case 'Italian Serie A':
        return l10n.leagueSerieA;
      case 'German Bundesliga':
        return l10n.leagueBundesliga;
      case 'French Ligue 1':
        return l10n.leagueLigue1;
      case 'South Korean K League 1':
        return l10n.leagueKLeague1;
      case 'South Korean K League 2':
        return l10n.leagueKLeague2;
      case 'UEFA Champions League':
        return l10n.leagueUCL;
      case 'UEFA Europa League':
        return l10n.leagueUEL;
      case 'UEFA Conference League':
        return l10n.leagueUECL;
      case 'Domestic Cups':
        return l10n.leagueDomesticCups;
      case 'International Friendlies':
        return l10n.leagueInternational;
      default:
        return league;
    }
  }

  // API-Football 리그 이름을 앱 내부 이름으로 변환
  static String normalizeLeagueName(String apiLeagueName) {
    return apiFootballLeagueMapping[apiLeagueName] ?? apiLeagueName;
  }

  // 리그 이름 매칭 (필터링용) - 대소문자 무시, 부분 일치
  static bool isLeagueMatch(String matchLeague, String filterLeague) {
    final matchLower = matchLeague.toLowerCase();
    final filterLower = filterLeague.toLowerCase();

    // 정확히 일치
    if (matchLower == filterLower) return true;

    // API-Football 이름 매핑 확인
    final normalizedMatch = normalizeLeagueName(matchLeague).toLowerCase();
    if (normalizedMatch == filterLower) return true;

    // 부분 일치 (양방향)
    if (matchLower.contains(filterLower) || filterLower.contains(matchLower)) return true;

    // 핵심 키워드 매칭
    final keywords = _extractLeagueKeywords(filterLower);
    for (final keyword in keywords) {
      if (matchLower.contains(keyword)) return true;
    }

    return false;
  }

  // 리그 필터에서 핵심 키워드 추출
  static List<String> _extractLeagueKeywords(String league) {
    final keywords = <String>[];
    if (league.contains('premier')) keywords.add('premier');
    if (league.contains('la liga')) keywords.add('la liga');
    if (league.contains('serie a')) keywords.add('serie a');
    if (league.contains('bundesliga')) keywords.add('bundesliga');
    if (league.contains('ligue 1')) keywords.add('ligue 1');
    if (league.contains('k league')) keywords.add('k league');
    if (league.contains('champions')) keywords.add('champions');
    if (league.contains('europa')) keywords.add('europa');
    if (league.contains('conference')) keywords.add('conference');
    if (league.contains('friendl')) keywords.add('friendl');
    return keywords;
  }

  // 국제대회 (A매치) 여부 판별 - 리그 이름 기반
  static bool isInternationalMatch(String leagueName) {
    final lower = leagueName.toLowerCase();
    return lower.contains('friendl') ||
           lower.contains('world cup') ||
           lower.contains('euro') ||
           lower.contains('asian cup') ||
           lower.contains('copa america') ||
           lower.contains('africa cup') ||
           lower.contains('gold cup') ||
           lower.contains('nations league') ||
           lower.contains('qualification') ||
           lower.contains('qualifiers') ||
           lower.contains('wcq') || // World Cup Qualifiers 축약
           lower.contains('예선');
  }

  // API
  static const String apiFootballBaseUrl = 'https://api-football-v1.p.rapidapi.com/v3';

  // Notification
  static const int notifyBeforeMinutes = 30;
}
