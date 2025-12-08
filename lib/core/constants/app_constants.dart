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

  // Leagues - API에서 사용하는 실제 리그 이름 (TheSportsDB 기준)
  static const List<String> supportedLeagues = [
    'English Premier League',
    'Spanish La Liga',
    'Italian Serie A',
    'German Bundesliga',
    'French Ligue 1',
    'South Korean K League 1',
    'UEFA Champions League',
    'UEFA Europa League',
    'International Friendlies',
  ];

  // 순위표가 있는 리그 (A매치 제외)
  static const List<String> leaguesWithStandings = [
    'English Premier League',
    'Spanish La Liga',
    'Italian Serie A',
    'German Bundesliga',
    'French Ligue 1',
    'South Korean K League 1',
    'UEFA Champions League',
    'UEFA Europa League',
  ];

  // 리그 이름을 한국어로 표시
  static const Map<String, String> leagueDisplayNames = {
    'English Premier League': 'EPL',
    'Spanish La Liga': '라리가',
    'Italian Serie A': '세리에 A',
    'German Bundesliga': '분데스리가',
    'French Ligue 1': '리그 1',
    'South Korean K League 1': 'K리그',
    'UEFA Champions League': 'UCL',
    'UEFA Europa League': 'UEL',
    'International Friendlies': 'A매치',
  };

  // 표시 이름으로 리그 이름 가져오기 (역방향)
  static String getLeagueDisplayName(String league) {
    return leagueDisplayNames[league] ?? league;
  }

  // API
  static const String apiFootballBaseUrl = 'https://api-football-v1.p.rapidapi.com/v3';

  // Notification
  static const int notifyBeforeMinutes = 30;
}
