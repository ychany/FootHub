import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// App name
  ///
  /// In ko, this message translates to:
  /// **'FootHub'**
  String get appName;

  /// App tagline
  ///
  /// In ko, this message translates to:
  /// **'FootHub'**
  String get appTagline;

  /// Home tab label
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get home;

  /// Schedule tab label
  ///
  /// In ko, this message translates to:
  /// **'일정'**
  String get schedule;

  /// Standings tab label
  ///
  /// In ko, this message translates to:
  /// **'순위'**
  String get standings;

  /// Tournament tab label for cup competitions
  ///
  /// In ko, this message translates to:
  /// **'토너먼트'**
  String get tournament;

  /// Generic error message for loading data
  ///
  /// In ko, this message translates to:
  /// **'데이터를 불러올 수 없습니다'**
  String get cannotLoadData;

  /// Leagues tab label
  ///
  /// In ko, this message translates to:
  /// **'리그'**
  String get leagues;

  /// Community tab label
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티'**
  String get community;

  /// Favorites tab label
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기'**
  String get favorites;

  /// Profile tab label
  ///
  /// In ko, this message translates to:
  /// **'내 정보'**
  String get profile;

  /// Greeting message
  ///
  /// In ko, this message translates to:
  /// **'안녕하세요, {name}님'**
  String hello(String name);

  /// Default user name
  ///
  /// In ko, this message translates to:
  /// **'축구팬'**
  String get footballFan;

  /// Record button
  ///
  /// In ko, this message translates to:
  /// **'기록하기'**
  String get record;

  /// Attendance record
  ///
  /// In ko, this message translates to:
  /// **'직관 기록'**
  String get attendanceRecord;

  /// My attendance record section title
  ///
  /// In ko, this message translates to:
  /// **'나의 직관 기록'**
  String get myAttendanceRecord;

  /// My attendance diary
  ///
  /// In ko, this message translates to:
  /// **'나의 직관 일기'**
  String get myAttendanceDiary;

  /// Attendance diary menu
  ///
  /// In ko, this message translates to:
  /// **'직관 일기'**
  String get attendanceDiary;

  /// My attendance records
  ///
  /// In ko, this message translates to:
  /// **'나의 직관 기록들'**
  String get myRecords;

  /// View all button
  ///
  /// In ko, this message translates to:
  /// **'전체보기'**
  String get viewAll;

  /// Manage button
  ///
  /// In ko, this message translates to:
  /// **'관리'**
  String get manage;

  /// Edit button
  ///
  /// In ko, this message translates to:
  /// **'편집'**
  String get edit;

  /// Delete button
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// Cancel button
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @selectYear.
  ///
  /// In ko, this message translates to:
  /// **'연도 선택'**
  String get selectYear;

  /// No description provided for @selectMonth.
  ///
  /// In ko, this message translates to:
  /// **'월 선택'**
  String get selectMonth;

  /// No description provided for @selectDay.
  ///
  /// In ko, this message translates to:
  /// **'일 선택'**
  String get selectDay;

  /// No description provided for @yearSuffix.
  ///
  /// In ko, this message translates to:
  /// **'년'**
  String get yearSuffix;

  /// No description provided for @monthSuffix.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get monthSuffix;

  /// No description provided for @daySuffix.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get daySuffix;

  /// Save button
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// Select button
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get select;

  /// Confirm button
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirm;

  /// Close button
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get close;

  /// More button
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get more;

  /// Refresh button
  ///
  /// In ko, this message translates to:
  /// **'새로고침'**
  String get refresh;

  /// Retry button
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get retry;

  /// Total matches label
  ///
  /// In ko, this message translates to:
  /// **'총 경기'**
  String get totalMatches;

  /// Match count unit
  ///
  /// In ko, this message translates to:
  /// **'경기'**
  String get matchCount;

  /// Win
  ///
  /// In ko, this message translates to:
  /// **'승리'**
  String get win;

  /// Win short
  ///
  /// In ko, this message translates to:
  /// **'승'**
  String get winShort;

  /// Draw
  ///
  /// In ko, this message translates to:
  /// **'무승부'**
  String get draw;

  /// Draw short
  ///
  /// In ko, this message translates to:
  /// **'무'**
  String get drawShort;

  /// Loss
  ///
  /// In ko, this message translates to:
  /// **'패배'**
  String get loss;

  /// Loss short
  ///
  /// In ko, this message translates to:
  /// **'패'**
  String get lossShort;

  /// Win rate
  ///
  /// In ko, this message translates to:
  /// **'승률'**
  String get winRate;

  /// Stadium
  ///
  /// In ko, this message translates to:
  /// **'경기장'**
  String get stadium;

  /// Stadium count unit
  ///
  /// In ko, this message translates to:
  /// **'곳'**
  String get stadiumCount;

  /// Times count unit
  ///
  /// In ko, this message translates to:
  /// **'회'**
  String get times;

  /// Cannot load stats error
  ///
  /// In ko, this message translates to:
  /// **'통계를 불러올 수 없습니다'**
  String get cannotLoadStats;

  /// Cannot load schedule error
  ///
  /// In ko, this message translates to:
  /// **'일정을 불러올 수 없습니다'**
  String get cannotLoadSchedule;

  /// Cannot load records error
  ///
  /// In ko, this message translates to:
  /// **'기록을 불러올 수 없습니다'**
  String get cannotLoadRecords;

  /// Cannot load team list error
  ///
  /// In ko, this message translates to:
  /// **'팀 목록을 불러올 수 없습니다'**
  String get cannotLoadTeamList;

  /// Load failed
  ///
  /// In ko, this message translates to:
  /// **'로드 실패'**
  String get loadFailed;

  /// Error occurred
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다'**
  String get errorOccurred;

  /// Live matches
  ///
  /// In ko, this message translates to:
  /// **'라이브 경기'**
  String get live;

  /// Live match count
  ///
  /// In ko, this message translates to:
  /// **'{count}경기'**
  String liveMatchCount(int count);

  /// Auto refresh message
  ///
  /// In ko, this message translates to:
  /// **'30초마다 자동 갱신'**
  String get autoRefreshEvery30Sec;

  /// No live matches
  ///
  /// In ko, this message translates to:
  /// **'진행 중인 경기가 없습니다'**
  String get noLiveMatches;

  /// First half
  ///
  /// In ko, this message translates to:
  /// **'전반'**
  String get firstHalf;

  /// Second half
  ///
  /// In ko, this message translates to:
  /// **'후반'**
  String get secondHalf;

  /// Half time
  ///
  /// In ko, this message translates to:
  /// **'하프타임'**
  String get halfTime;

  /// Extra time
  ///
  /// In ko, this message translates to:
  /// **'연장전'**
  String get extraTime;

  /// Penalties
  ///
  /// In ko, this message translates to:
  /// **'승부차기'**
  String get penalties;

  /// Finished
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get finished;

  /// Upcoming
  ///
  /// In ko, this message translates to:
  /// **'예정'**
  String get upcoming;

  /// Favorite team schedule section
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기 팀 일정'**
  String get favoriteTeamSchedule;

  /// Add favorite team prompt
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기 팀을 추가해보세요'**
  String get addFavoriteTeam;

  /// Add favorite team description
  ///
  /// In ko, this message translates to:
  /// **'팀을 추가하면 다가오는 경기 일정을 확인할 수 있어요'**
  String get addFavoriteTeamDesc;

  /// Recent records section
  ///
  /// In ko, this message translates to:
  /// **'최근 직관 기록'**
  String get recentRecords;

  /// First record prompt
  ///
  /// In ko, this message translates to:
  /// **'첫 직관 기록을 남겨보세요'**
  String get firstRecordPrompt;

  /// First record description
  ///
  /// In ko, this message translates to:
  /// **'경기장에서의 특별한 순간을 기록해보세요'**
  String get firstRecordDesc;

  /// Next match
  ///
  /// In ko, this message translates to:
  /// **'다음 경기'**
  String get nextMatch;

  /// No scheduled matches
  ///
  /// In ko, this message translates to:
  /// **'예정된 경기가 없습니다'**
  String get noScheduledMatches;

  /// Recent 5 matches
  ///
  /// In ko, this message translates to:
  /// **'최근 5경기'**
  String get recent5Matches;

  /// Select national team
  ///
  /// In ko, this message translates to:
  /// **'응원할 국가대표팀을 선택해주세요'**
  String get selectNationalTeam;

  /// Select national team prompt
  ///
  /// In ko, this message translates to:
  /// **'응원할 국가대표팀을 선택하세요'**
  String get selectNationalTeamPrompt;

  /// 2026 World Cup participants
  ///
  /// In ko, this message translates to:
  /// **'2026 월드컵 참가국'**
  String get worldCupParticipants;

  /// Search country
  ///
  /// In ko, this message translates to:
  /// **'국가 검색...'**
  String get searchCountry;

  /// Match schedule
  ///
  /// In ko, this message translates to:
  /// **'경기 일정'**
  String get matchSchedule;

  /// Today
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get today;

  /// Monthly
  ///
  /// In ko, this message translates to:
  /// **'월간'**
  String get monthly;

  /// Two weeks
  ///
  /// In ko, this message translates to:
  /// **'2주'**
  String get twoWeeks;

  /// Weekly
  ///
  /// In ko, this message translates to:
  /// **'주간'**
  String get weekly;

  /// Major filter
  ///
  /// In ko, this message translates to:
  /// **'주요'**
  String get major;

  /// All filter
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get all;

  /// Record attendance
  ///
  /// In ko, this message translates to:
  /// **'직관 기록하기'**
  String get recordAttendance;

  /// Attendance complete badge
  ///
  /// In ko, this message translates to:
  /// **'직관 완료'**
  String get attendanceComplete;

  /// Notification settings
  ///
  /// In ko, this message translates to:
  /// **'알림 설정'**
  String get notificationSettings;

  /// Match notification settings
  ///
  /// In ko, this message translates to:
  /// **'경기 알림 설정'**
  String get matchNotification;

  /// Kickoff notification
  ///
  /// In ko, this message translates to:
  /// **'경기 시작 알림'**
  String get kickoffNotification;

  /// Kickoff notification description
  ///
  /// In ko, this message translates to:
  /// **'킥오프 30분 전에 알림'**
  String get kickoffNotificationDesc;

  /// Lineup notification
  ///
  /// In ko, this message translates to:
  /// **'라인업 발표'**
  String get lineupNotification;

  /// Lineup notification description
  ///
  /// In ko, this message translates to:
  /// **'선발 명단 공개 시 알림'**
  String get lineupNotificationDesc;

  /// Result notification
  ///
  /// In ko, this message translates to:
  /// **'경기 결과'**
  String get resultNotification;

  /// Result notification description
  ///
  /// In ko, this message translates to:
  /// **'경기 종료 후 결과 알림'**
  String get resultNotificationDesc;

  /// Turn off notification
  ///
  /// In ko, this message translates to:
  /// **'알림 해제'**
  String get notificationOff;

  /// Notification set message
  ///
  /// In ko, this message translates to:
  /// **'알림이 설정되었습니다'**
  String get notificationSet;

  /// Notification removed message
  ///
  /// In ko, this message translates to:
  /// **'알림이 해제되었습니다'**
  String get notificationRemoved;

  /// Team
  ///
  /// In ko, this message translates to:
  /// **'팀'**
  String get team;

  /// Teams
  ///
  /// In ko, this message translates to:
  /// **'팀'**
  String get teams;

  /// Player
  ///
  /// In ko, this message translates to:
  /// **'선수'**
  String get player;

  /// Players
  ///
  /// In ko, this message translates to:
  /// **'선수'**
  String get players;

  /// Add team
  ///
  /// In ko, this message translates to:
  /// **'팀 추가'**
  String get addTeam;

  /// Add player
  ///
  /// In ko, this message translates to:
  /// **'선수 추가'**
  String get addPlayer;

  /// Search team
  ///
  /// In ko, this message translates to:
  /// **'팀 검색...'**
  String get searchTeam;

  /// Search player
  ///
  /// In ko, this message translates to:
  /// **'선수 검색...'**
  String get searchPlayer;

  /// Remove favorite
  ///
  /// In ko, this message translates to:
  /// **'해제'**
  String get removeFavorite;

  /// Unfollow
  ///
  /// In ko, this message translates to:
  /// **'해제'**
  String get unfollow;

  /// Unfollow team title
  ///
  /// In ko, this message translates to:
  /// **'팀 팔로우 해제'**
  String get unfollowTeam;

  /// Unfollow team confirmation
  ///
  /// In ko, this message translates to:
  /// **'{name}을(를) 즐겨찾기에서 제거하시겠습니까?'**
  String unfollowTeamConfirm(String name);

  /// Unfollow player title
  ///
  /// In ko, this message translates to:
  /// **'선수 팔로우 해제'**
  String get unfollowPlayer;

  /// Unfollow player confirmation
  ///
  /// In ko, this message translates to:
  /// **'{name}을(를) 즐겨찾기에서 제거하시겠습니까?'**
  String unfollowPlayerConfirm(String name);

  /// Select league or search team prompt
  ///
  /// In ko, this message translates to:
  /// **'리그를 선택하거나 팀을 검색하세요'**
  String get selectLeagueOrSearch;

  /// Team not found
  ///
  /// In ko, this message translates to:
  /// **'팀 정보를 찾을 수 없습니다'**
  String get teamNotFound;

  /// Player not found
  ///
  /// In ko, this message translates to:
  /// **'선수를 찾을 수 없습니다'**
  String get playerNotFound;

  /// Hint for team search in player add
  ///
  /// In ko, this message translates to:
  /// **'팀 이름을 검색하세요'**
  String get searchTeamFirst;

  /// Filter players hint
  ///
  /// In ko, this message translates to:
  /// **'선수 이름으로 필터...'**
  String get filterPlayers;

  /// Search team to add player guide
  ///
  /// In ko, this message translates to:
  /// **'팀을 검색해서 선수를 추가하세요'**
  String get searchTeamToAddPlayer;

  /// National/Country
  ///
  /// In ko, this message translates to:
  /// **'국가'**
  String get national;

  /// Add favorite team prompt
  ///
  /// In ko, this message translates to:
  /// **'좋아하는 팀을 추가해보세요'**
  String get addFavoriteTeamPrompt;

  /// Add favorite player prompt
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기 선수 추가'**
  String get addFavoritePlayerPrompt;

  /// List tab
  ///
  /// In ko, this message translates to:
  /// **'리스트'**
  String get list;

  /// Calendar tab
  ///
  /// In ko, this message translates to:
  /// **'달력'**
  String get calendar;

  /// Stats tab
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get stats;

  /// Delete record
  ///
  /// In ko, this message translates to:
  /// **'기록 삭제'**
  String get deleteRecord;

  /// Delete record confirmation
  ///
  /// In ko, this message translates to:
  /// **'이 기록을 삭제하시겠습니까?'**
  String get deleteRecordConfirm;

  /// Record deleted message
  ///
  /// In ko, this message translates to:
  /// **'기록이 삭제되었습니다'**
  String get recordDeleted;

  /// No record on date
  ///
  /// In ko, this message translates to:
  /// **'{date}에 기록이 없습니다'**
  String noRecordOnDate(String date);

  /// Select date
  ///
  /// In ko, this message translates to:
  /// **'날짜를 선택해주세요'**
  String get selectDate;

  /// No records yet
  ///
  /// In ko, this message translates to:
  /// **'아직 기록이 없습니다'**
  String get noRecordsYet;

  /// League stats
  ///
  /// In ko, this message translates to:
  /// **'리그별 통계'**
  String get leagueStats;

  /// Stadium visits
  ///
  /// In ko, this message translates to:
  /// **'경기장 방문 현황'**
  String get stadiumVisits;

  /// Visited stadiums
  ///
  /// In ko, this message translates to:
  /// **'방문한 경기장'**
  String get visitedStadiums;

  /// User
  ///
  /// In ko, this message translates to:
  /// **'사용자'**
  String get user;

  /// Active member badge
  ///
  /// In ko, this message translates to:
  /// **'활성 회원'**
  String get activeMember;

  /// Login prompt title
  ///
  /// In ko, this message translates to:
  /// **'로그인하고 시작하세요'**
  String get loginPromptTitle;

  /// Login prompt subtitle
  ///
  /// In ko, this message translates to:
  /// **'나만의 직관 기록을 저장하고 관리하세요'**
  String get loginPromptSubtitle;

  /// League standings
  ///
  /// In ko, this message translates to:
  /// **'리그 순위'**
  String get leagueStandings;

  /// Check league standings
  ///
  /// In ko, this message translates to:
  /// **'각 리그 순위표 확인'**
  String get checkLeagueStandings;

  /// Upcoming matches
  ///
  /// In ko, this message translates to:
  /// **'예정된 경기'**
  String get upcomingMatches;

  /// Match alerts and push notifications
  ///
  /// In ko, this message translates to:
  /// **'경기 알림, 푸시 알림'**
  String get matchAlertsPush;

  /// Timezone settings
  ///
  /// In ko, this message translates to:
  /// **'시간대 설정'**
  String get timezoneSettings;

  /// Match time display
  ///
  /// In ko, this message translates to:
  /// **'경기 시간 표시 기준'**
  String get matchTimeDisplay;

  /// Community title
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티'**
  String get communityTitle;

  /// Community description
  ///
  /// In ko, this message translates to:
  /// **'직관 후기, 정보 공유'**
  String get communityDesc;

  /// Help and support
  ///
  /// In ko, this message translates to:
  /// **'도움말 및 지원'**
  String get helpAndSupport;

  /// FAQ and contact
  ///
  /// In ko, this message translates to:
  /// **'FAQ, 문의하기'**
  String get faqContact;

  /// Logout
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get logout;

  /// Logout confirmation
  ///
  /// In ko, this message translates to:
  /// **'정말 로그아웃하시겠습니까?'**
  String get logoutConfirm;

  /// Language settings
  ///
  /// In ko, this message translates to:
  /// **'언어 설정'**
  String get languageSettings;

  /// Korean
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get korean;

  /// English
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get english;

  /// System default
  ///
  /// In ko, this message translates to:
  /// **'시스템 기본'**
  String get systemDefault;

  /// App version
  ///
  /// In ko, this message translates to:
  /// **'v{version}'**
  String appVersion(String version);

  /// Live matches screen title
  ///
  /// In ko, this message translates to:
  /// **'라이브 경기'**
  String get liveMatches;

  /// Updated seconds ago
  ///
  /// In ko, this message translates to:
  /// **'{seconds}초 전 업데이트'**
  String updatedSecondsAgo(int seconds);

  /// Updated minutes ago
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분 전 업데이트'**
  String updatedMinutesAgo(int minutes);

  /// Auto refresh 30 seconds
  ///
  /// In ko, this message translates to:
  /// **'30초마다 자동 갱신'**
  String get autoRefresh30Sec;

  /// No live matches title
  ///
  /// In ko, this message translates to:
  /// **'진행 중인 경기가 없습니다'**
  String get noLiveMatchesTitle;

  /// No live matches description
  ///
  /// In ko, this message translates to:
  /// **'경기가 시작되면 여기서 실시간으로 확인하세요'**
  String get noLiveMatchesDesc;

  /// Break preparation
  ///
  /// In ko, this message translates to:
  /// **'연장 준비'**
  String get breakPrep;

  /// First half minutes
  ///
  /// In ko, this message translates to:
  /// **'전반 {minutes}분'**
  String firstHalfMinutes(int minutes);

  /// Second half minutes
  ///
  /// In ko, this message translates to:
  /// **'후반 {minutes}분'**
  String secondHalfMinutes(int minutes);

  /// Search league hint
  ///
  /// In ko, this message translates to:
  /// **'리그 검색...'**
  String get searchLeague;

  /// No search results
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
  String get noSearchResults;

  /// Search error
  ///
  /// In ko, this message translates to:
  /// **'검색 중 오류가 발생했습니다'**
  String get searchError;

  /// Top 5 leagues
  ///
  /// In ko, this message translates to:
  /// **'5대 리그'**
  String get top5Leagues;

  /// European club competitions
  ///
  /// In ko, this message translates to:
  /// **'유럽 대회'**
  String get euroClubComps;

  /// Domestic cup competitions
  ///
  /// In ko, this message translates to:
  /// **'국내 컵 대회'**
  String get domesticCups;

  /// National team competitions
  ///
  /// In ko, this message translates to:
  /// **'국가대항전'**
  String get nationalComps;

  /// Other leagues
  ///
  /// In ko, this message translates to:
  /// **'기타 리그'**
  String get otherLeagues;

  /// User's local league based on device locale
  ///
  /// In ko, this message translates to:
  /// **'내 지역 리그'**
  String get myLocalLeague;

  /// Cannot load leagues
  ///
  /// In ko, this message translates to:
  /// **'리그 목록을 불러올 수 없습니다'**
  String get cannotLoadLeagues;

  /// By country
  ///
  /// In ko, this message translates to:
  /// **'국가별'**
  String get byCountry;

  /// Rank
  ///
  /// In ko, this message translates to:
  /// **'순위'**
  String get rank;

  /// Goals
  ///
  /// In ko, this message translates to:
  /// **'득점'**
  String get goals;

  /// Assists
  ///
  /// In ko, this message translates to:
  /// **'도움'**
  String get assists;

  /// Played/Matches
  ///
  /// In ko, this message translates to:
  /// **'경기'**
  String get played;

  /// Won
  ///
  /// In ko, this message translates to:
  /// **'승'**
  String get won;

  /// Drawn
  ///
  /// In ko, this message translates to:
  /// **'무'**
  String get drawn;

  /// Lost
  ///
  /// In ko, this message translates to:
  /// **'패'**
  String get lost;

  /// Goals for
  ///
  /// In ko, this message translates to:
  /// **'득점'**
  String get gf;

  /// Goals against
  ///
  /// In ko, this message translates to:
  /// **'실점'**
  String get ga;

  /// Goal difference
  ///
  /// In ko, this message translates to:
  /// **'득실'**
  String get gd;

  /// Points
  ///
  /// In ko, this message translates to:
  /// **'승점'**
  String get pts;

  /// Appearances
  ///
  /// In ko, this message translates to:
  /// **'출전'**
  String get appearances;

  /// No standings info
  ///
  /// In ko, this message translates to:
  /// **'순위 정보가 없습니다'**
  String get noStandingsInfo;

  /// Cannot load standings
  ///
  /// In ko, this message translates to:
  /// **'해당 리그의 순위 정보를 불러올 수 없습니다'**
  String get cannotLoadStandings;

  /// No goal rank info
  ///
  /// In ko, this message translates to:
  /// **'득점 순위 정보가 없습니다'**
  String get noGoalRankInfo;

  /// No assist rank info
  ///
  /// In ko, this message translates to:
  /// **'어시스트 순위 정보가 없습니다'**
  String get noAssistRankInfo;

  /// No league stats
  ///
  /// In ko, this message translates to:
  /// **'리그 통계 정보가 없습니다'**
  String get noLeagueStats;

  /// Recent form
  ///
  /// In ko, this message translates to:
  /// **'최근 폼'**
  String get recentForm;

  /// Last 5 games
  ///
  /// In ko, this message translates to:
  /// **'최근 5경기'**
  String get last5Games;

  /// Home/Away strength
  ///
  /// In ko, this message translates to:
  /// **'홈/원정 강자'**
  String get homeAwayStrength;

  /// Home strength
  ///
  /// In ko, this message translates to:
  /// **'홈 강자'**
  String get homeStrength;

  /// Away strength
  ///
  /// In ko, this message translates to:
  /// **'원정 강자'**
  String get awayStrength;

  /// Bottom analysis
  ///
  /// In ko, this message translates to:
  /// **'하위권 분석'**
  String get bottomAnalysis;

  /// Most losses
  ///
  /// In ko, this message translates to:
  /// **'최다 패배'**
  String get mostLosses;

  /// Most conceded
  ///
  /// In ko, this message translates to:
  /// **'최다 실점'**
  String get mostConceded;

  /// League overview
  ///
  /// In ko, this message translates to:
  /// **'리그 개요'**
  String get leagueOverview;

  /// Total goals
  ///
  /// In ko, this message translates to:
  /// **'총 골'**
  String get totalGoals;

  /// Goals per game
  ///
  /// In ko, this message translates to:
  /// **'경기당 골'**
  String get goalsPerGame;

  /// Home wins
  ///
  /// In ko, this message translates to:
  /// **'홈 승'**
  String get homeWins;

  /// Away wins
  ///
  /// In ko, this message translates to:
  /// **'원정 승'**
  String get awayWins;

  /// Home win
  ///
  /// In ko, this message translates to:
  /// **'홈 승'**
  String get homeWin;

  /// Away win
  ///
  /// In ko, this message translates to:
  /// **'원정 승'**
  String get awayWin;

  /// N games
  ///
  /// In ko, this message translates to:
  /// **'{count}경기'**
  String nGames(int count);

  /// Team ranking
  ///
  /// In ko, this message translates to:
  /// **'팀 순위'**
  String get teamRanking;

  /// Most goals
  ///
  /// In ko, this message translates to:
  /// **'최다 득점'**
  String get mostGoals;

  /// Most conceded goals
  ///
  /// In ko, this message translates to:
  /// **'최다 실점'**
  String get mostConcededGoals;

  /// Most wins
  ///
  /// In ko, this message translates to:
  /// **'최다 승리'**
  String get mostWins;

  /// Most draws
  ///
  /// In ko, this message translates to:
  /// **'최다 무승부'**
  String get mostDraws;

  /// No description provided for @nGoals.
  ///
  /// In ko, this message translates to:
  /// **'{count}골'**
  String nGoals(int count);

  /// N wins
  ///
  /// In ko, this message translates to:
  /// **'{count}승'**
  String nWins(int count);

  /// N draws
  ///
  /// In ko, this message translates to:
  /// **'{count}무'**
  String nDraws(int count);

  /// N losses
  ///
  /// In ko, this message translates to:
  /// **'{count}패'**
  String nLosses(int count);

  /// N conceded
  ///
  /// In ko, this message translates to:
  /// **'{count}실점'**
  String nConceded(int count);

  /// Goal analysis
  ///
  /// In ko, this message translates to:
  /// **'골 분석'**
  String get goalAnalysis;

  /// Home goals
  ///
  /// In ko, this message translates to:
  /// **'홈 골'**
  String get homeGoals;

  /// Away goals
  ///
  /// In ko, this message translates to:
  /// **'원정 골'**
  String get awayGoals;

  /// Top 5 goal difference
  ///
  /// In ko, this message translates to:
  /// **'득실차 상위 5팀'**
  String get top5GD;

  /// Card ranking
  ///
  /// In ko, this message translates to:
  /// **'카드 순위'**
  String get cardRanking;

  /// Most yellow cards
  ///
  /// In ko, this message translates to:
  /// **'최다 경고'**
  String get mostYellows;

  /// Most red cards
  ///
  /// In ko, this message translates to:
  /// **'최다 퇴장'**
  String get mostReds;

  /// No data
  ///
  /// In ko, this message translates to:
  /// **'데이터가 없습니다'**
  String get noData;

  /// Record not found
  ///
  /// In ko, this message translates to:
  /// **'기록을 찾을 수 없습니다'**
  String get recordNotFound;

  /// Diary tab
  ///
  /// In ko, this message translates to:
  /// **'일기'**
  String get diary;

  /// Details tab
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get details;

  /// Broadcast tab
  ///
  /// In ko, this message translates to:
  /// **'중계'**
  String get broadcast;

  /// Lineup tab
  ///
  /// In ko, this message translates to:
  /// **'라인업'**
  String get lineup;

  /// Head to head tab
  ///
  /// In ko, this message translates to:
  /// **'전적'**
  String get h2h;

  /// Match diary section title
  ///
  /// In ko, this message translates to:
  /// **'직관 일기'**
  String get matchDiary;

  /// Match info step
  ///
  /// In ko, this message translates to:
  /// **'경기 정보'**
  String get matchInfo;

  /// Date label
  ///
  /// In ko, this message translates to:
  /// **'날짜'**
  String get date;

  /// League label
  ///
  /// In ko, this message translates to:
  /// **'리그'**
  String get league;

  /// Seat label
  ///
  /// In ko, this message translates to:
  /// **'좌석'**
  String get seat;

  /// Additional info section title
  ///
  /// In ko, this message translates to:
  /// **'추가 정보'**
  String get additionalInfo;

  /// Weather label
  ///
  /// In ko, this message translates to:
  /// **'날씨'**
  String get weather;

  /// Companions label
  ///
  /// In ko, this message translates to:
  /// **'함께 간 사람'**
  String get companions;

  /// Ticket price label
  ///
  /// In ko, this message translates to:
  /// **'티켓 가격'**
  String get ticketPrice;

  /// Currency in Korean Won
  ///
  /// In ko, this message translates to:
  /// **'{price}원'**
  String currencyWon(String price);

  /// Stadium food section title
  ///
  /// In ko, this message translates to:
  /// **'경기장 음식'**
  String get stadiumFood;

  /// Memo section title
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get memo;

  /// MVP of today
  ///
  /// In ko, this message translates to:
  /// **'오늘의 MVP'**
  String get mvpToday;

  /// No stats info
  ///
  /// In ko, this message translates to:
  /// **'통계 정보가 없습니다'**
  String get noStatsInfo;

  /// Stats after match
  ///
  /// In ko, this message translates to:
  /// **'경기 종료 후 업데이트됩니다'**
  String get statsAfterMatch;

  /// Possession
  ///
  /// In ko, this message translates to:
  /// **'점유율'**
  String get possession;

  /// Shots
  ///
  /// In ko, this message translates to:
  /// **'슈팅'**
  String get shots;

  /// Shots on target
  ///
  /// In ko, this message translates to:
  /// **'유효 슈팅'**
  String get shotsOnTarget;

  /// Corners
  ///
  /// In ko, this message translates to:
  /// **'코너킥'**
  String get corners;

  /// Fouls
  ///
  /// In ko, this message translates to:
  /// **'파울'**
  String get fouls;

  /// Offsides
  ///
  /// In ko, this message translates to:
  /// **'오프사이드'**
  String get offsides;

  /// Yellow cards
  ///
  /// In ko, this message translates to:
  /// **'경고'**
  String get yellowCards;

  /// Red cards
  ///
  /// In ko, this message translates to:
  /// **'퇴장'**
  String get redCards;

  /// Match name section
  ///
  /// In ko, this message translates to:
  /// **'경기명'**
  String get matchName;

  /// Home team
  ///
  /// In ko, this message translates to:
  /// **'홈팀'**
  String get homeTeam;

  /// Away team
  ///
  /// In ko, this message translates to:
  /// **'원정팀'**
  String get awayTeam;

  /// Home short
  ///
  /// In ko, this message translates to:
  /// **'홈 성적'**
  String get homeShort;

  /// Away short
  ///
  /// In ko, this message translates to:
  /// **'원정 성적'**
  String get awayShort;

  /// Score
  ///
  /// In ko, this message translates to:
  /// **'스코어'**
  String get score;

  /// Photos section
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get photos;

  /// Camera
  ///
  /// In ko, this message translates to:
  /// **'카메라'**
  String get camera;

  /// Gallery
  ///
  /// In ko, this message translates to:
  /// **'갤러리'**
  String get gallery;

  /// Tags section
  ///
  /// In ko, this message translates to:
  /// **'태그'**
  String get tags;

  /// Victory tag
  ///
  /// In ko, this message translates to:
  /// **'승리'**
  String get tagVictory;

  /// Comeback tag
  ///
  /// In ko, this message translates to:
  /// **'역전'**
  String get tagComeback;

  /// Goal fest tag
  ///
  /// In ko, this message translates to:
  /// **'골잔치'**
  String get tagGoalFest;

  /// Clean sheet tag
  ///
  /// In ko, this message translates to:
  /// **'클린시트'**
  String get tagCleanSheet;

  /// First match tag
  ///
  /// In ko, this message translates to:
  /// **'첫직관'**
  String get tagFirstMatch;

  /// Away tag
  ///
  /// In ko, this message translates to:
  /// **'원정'**
  String get tagAway;

  /// Korean currency unit
  ///
  /// In ko, this message translates to:
  /// **'원'**
  String get currencyUnit;

  /// Switch to search mode
  ///
  /// In ko, this message translates to:
  /// **'검색으로'**
  String get switchToSearch;

  /// Switch to manual input
  ///
  /// In ko, this message translates to:
  /// **'직접 입력'**
  String get switchToManual;

  /// Add tag hint
  ///
  /// In ko, this message translates to:
  /// **'태그 추가'**
  String get addTag;

  /// Suggested tags section
  ///
  /// In ko, this message translates to:
  /// **'추천 태그'**
  String get suggestedTags;

  /// Companion hint text
  ///
  /// In ko, this message translates to:
  /// **'예: 친구들, 가족'**
  String get companionHint;

  /// Food review hint text
  ///
  /// In ko, this message translates to:
  /// **'먹은 음식, 맛 평가 등'**
  String get foodReviewHint;

  /// Price hint text
  ///
  /// In ko, this message translates to:
  /// **'예: 50,000'**
  String get priceHint;

  /// Penalty goal
  ///
  /// In ko, this message translates to:
  /// **'페널티골'**
  String get penaltyGoal;

  /// Missed penalty
  ///
  /// In ko, this message translates to:
  /// **'PK 실축'**
  String get missedPenalty;

  /// Own goal
  ///
  /// In ko, this message translates to:
  /// **'자책'**
  String get ownGoal;

  /// Goal
  ///
  /// In ko, this message translates to:
  /// **'골'**
  String get goal;

  /// Yellow card
  ///
  /// In ko, this message translates to:
  /// **'경고'**
  String get yellowCard;

  /// Red card
  ///
  /// In ko, this message translates to:
  /// **'퇴장'**
  String get redCard;

  /// Card
  ///
  /// In ko, this message translates to:
  /// **'카드'**
  String get card;

  /// Substitution
  ///
  /// In ko, this message translates to:
  /// **'교체'**
  String get substitution;

  /// Grass field
  ///
  /// In ko, this message translates to:
  /// **'잔디'**
  String get grass;

  /// Win result
  ///
  /// In ko, this message translates to:
  /// **'승'**
  String get resultWin;

  /// Draw result
  ///
  /// In ko, this message translates to:
  /// **'무'**
  String get resultDraw;

  /// Loss result
  ///
  /// In ko, this message translates to:
  /// **'패'**
  String get resultLoss;

  /// Goals scored
  ///
  /// In ko, this message translates to:
  /// **'득점 {home} : {away}'**
  String goalsScored(int home, int away);

  /// No description provided for @nMatches.
  ///
  /// In ko, this message translates to:
  /// **'{count}경기'**
  String nMatches(int count);

  /// Stadium capacity
  ///
  /// In ko, this message translates to:
  /// **'수용인원'**
  String get capacity;

  /// Profile tab
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get profileTab;

  /// Career tab
  ///
  /// In ko, this message translates to:
  /// **'커리어'**
  String get careerTab;

  /// Matches tab
  ///
  /// In ko, this message translates to:
  /// **'출전경기'**
  String get matchesTab;

  /// No match records
  ///
  /// In ko, this message translates to:
  /// **'직관 기록이 없습니다'**
  String get noMatchRecords;

  /// Assist
  ///
  /// In ko, this message translates to:
  /// **'도움'**
  String get assist;

  /// Matches played
  ///
  /// In ko, this message translates to:
  /// **'출전'**
  String get matchesPlayed;

  /// Playing time
  ///
  /// In ko, this message translates to:
  /// **'출전시간'**
  String get playingTime;

  /// Club teams
  ///
  /// In ko, this message translates to:
  /// **'소속팀'**
  String get clubTeams;

  /// National team
  ///
  /// In ko, this message translates to:
  /// **'국가대표'**
  String get nationalTeam;

  /// Season
  ///
  /// In ko, this message translates to:
  /// **'시즌'**
  String get season;

  /// Team short
  ///
  /// In ko, this message translates to:
  /// **'팀'**
  String get teamShort;

  /// Matches
  ///
  /// In ko, this message translates to:
  /// **'경기'**
  String get matches;

  /// Rating
  ///
  /// In ko, this message translates to:
  /// **'평점'**
  String get rating;

  /// Started/Lineups
  ///
  /// In ko, this message translates to:
  /// **'선발'**
  String get started;

  /// Goalkeeper position
  ///
  /// In ko, this message translates to:
  /// **'골키퍼'**
  String get goalkeeper;

  /// Defender position
  ///
  /// In ko, this message translates to:
  /// **'수비수'**
  String get defender;

  /// Midfielder position
  ///
  /// In ko, this message translates to:
  /// **'미드필더'**
  String get midfielder;

  /// Attacker position
  ///
  /// In ko, this message translates to:
  /// **'공격수'**
  String get attacker;

  /// Nationality
  ///
  /// In ko, this message translates to:
  /// **'국적'**
  String get nationality;

  /// Birth date
  ///
  /// In ko, this message translates to:
  /// **'생년월일'**
  String get birthDate;

  /// Age
  ///
  /// In ko, this message translates to:
  /// **'나이'**
  String get age;

  /// Age in years
  ///
  /// In ko, this message translates to:
  /// **'{years}세'**
  String ageYears(int years);

  /// Height
  ///
  /// In ko, this message translates to:
  /// **'키'**
  String get height;

  /// Weight
  ///
  /// In ko, this message translates to:
  /// **'몸무게'**
  String get weight;

  /// Birth place
  ///
  /// In ko, this message translates to:
  /// **'출생지'**
  String get birthPlace;

  /// Injured status
  ///
  /// In ko, this message translates to:
  /// **'부상'**
  String get injured;

  /// Suspended status
  ///
  /// In ko, this message translates to:
  /// **'정지'**
  String get suspended;

  /// Other
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get other;

  /// Season stats tab
  ///
  /// In ko, this message translates to:
  /// **'시즌 통계'**
  String get seasonStats;

  /// Player info title
  ///
  /// In ko, this message translates to:
  /// **'선수 정보'**
  String get playerInfo;

  /// Player not found description
  ///
  /// In ko, this message translates to:
  /// **'선수 정보를 찾을 수 없습니다'**
  String get playerNotFoundDesc;

  /// Error prefix
  ///
  /// In ko, this message translates to:
  /// **'오류'**
  String get error;

  /// Current season
  ///
  /// In ko, this message translates to:
  /// **'현재 시즌'**
  String get currentSeason;

  /// Season stats summary title
  ///
  /// In ko, this message translates to:
  /// **'{season} 통계 요약'**
  String seasonStatsSummary(String season);

  /// No season stats
  ///
  /// In ko, this message translates to:
  /// **'시즌 통계 정보가 없습니다'**
  String get noSeasonStats;

  /// Loading season stats
  ///
  /// In ko, this message translates to:
  /// **'시즌별 통계를 불러오는 중...'**
  String get loadingSeasonStats;

  /// Basic info section
  ///
  /// In ko, this message translates to:
  /// **'기본 정보'**
  String get basicInfo;

  /// Injury and suspension history
  ///
  /// In ko, this message translates to:
  /// **'부상/출전정지 이력'**
  String get injuryHistory;

  /// N records
  ///
  /// In ko, this message translates to:
  /// **'{count}건'**
  String nRecords(int count);

  /// Currently out status
  ///
  /// In ko, this message translates to:
  /// **'현재 결장 중'**
  String get currentlyOut;

  /// Recent history
  ///
  /// In ko, this message translates to:
  /// **'최근 이력'**
  String get recentHistory;

  /// Transfer history
  ///
  /// In ko, this message translates to:
  /// **'이적 기록'**
  String get transferHistory;

  /// More transfer records
  ///
  /// In ko, this message translates to:
  /// **'외 {count}건의 이적 기록'**
  String moreTransfers(int count);

  /// Trophies section
  ///
  /// In ko, this message translates to:
  /// **'수상 경력'**
  String get trophies;

  /// N trophies
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String nTrophies(int count);

  /// Added to favorites message
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기에 추가되었습니다'**
  String get addedToFavorites;

  /// Removed from favorites message
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기에서 제거되었습니다'**
  String get removedFromFavorites;

  /// No timeline info
  ///
  /// In ko, this message translates to:
  /// **'타임라인 정보가 없습니다'**
  String get noTimelineInfo;

  /// Updated after match ends
  ///
  /// In ko, this message translates to:
  /// **'경기 종료 후 업데이트됩니다'**
  String get updatedAfterMatch;

  /// Assist by player
  ///
  /// In ko, this message translates to:
  /// **'어시스트: {name}'**
  String assistBy(String name);

  /// No lineup info
  ///
  /// In ko, this message translates to:
  /// **'라인업 정보가 없습니다'**
  String get noLineupInfo;

  /// Starters with count
  ///
  /// In ko, this message translates to:
  /// **'선발 ({count})'**
  String startersCount(int count);

  /// No starter info
  ///
  /// In ko, this message translates to:
  /// **'선발 정보 없음'**
  String get noStarterInfo;

  /// Substitutes with count
  ///
  /// In ko, this message translates to:
  /// **'교체 ({count})'**
  String substitutesCount(int count);

  /// No team info
  ///
  /// In ko, this message translates to:
  /// **'팀 정보가 없습니다'**
  String get noTeamInfo;

  /// No H2H record
  ///
  /// In ko, this message translates to:
  /// **'상대전적 기록이 없습니다'**
  String get noH2HRecord;

  /// Recent matches
  ///
  /// In ko, this message translates to:
  /// **'최근 경기'**
  String get recentMatches;

  /// Weather sunny
  ///
  /// In ko, this message translates to:
  /// **'맑음 ☀️'**
  String get weatherSunny;

  /// Weather cloudy
  ///
  /// In ko, this message translates to:
  /// **'흐림 ☁️'**
  String get weatherCloudy;

  /// Weather rainy
  ///
  /// In ko, this message translates to:
  /// **'비 🌧️'**
  String get weatherRainy;

  /// Weather snowy
  ///
  /// In ko, this message translates to:
  /// **'눈 ❄️'**
  String get weatherSnowy;

  /// Weather windy
  ///
  /// In ko, this message translates to:
  /// **'바람 💨'**
  String get weatherWindy;

  /// Match record title
  ///
  /// In ko, this message translates to:
  /// **'직관 기록'**
  String get matchRecord;

  /// Diary write step
  ///
  /// In ko, this message translates to:
  /// **'일기 작성'**
  String get diaryWrite;

  /// Search results
  ///
  /// In ko, this message translates to:
  /// **'검색 결과'**
  String get searchResults;

  /// Seat info
  ///
  /// In ko, this message translates to:
  /// **'좌석 정보'**
  String get seatInfo;

  /// Seat hint
  ///
  /// In ko, this message translates to:
  /// **'예: A블록 12열 34번'**
  String get seatHint;

  /// Go to diary button
  ///
  /// In ko, this message translates to:
  /// **'일기 작성하기 →'**
  String get goToDiary;

  /// One liner section
  ///
  /// In ko, this message translates to:
  /// **'오늘의 한 줄'**
  String get oneLiner;

  /// One liner hint
  ///
  /// In ko, this message translates to:
  /// **'경기를 한 줄로 표현한다면?'**
  String get oneLinerHint;

  /// Diary section title
  ///
  /// In ko, this message translates to:
  /// **'직관 일기'**
  String get diarySection;

  /// Diary hint
  ///
  /// In ko, this message translates to:
  /// **'오늘 경기는 어땠나요? 자유롭게 기록해보세요.'**
  String get diaryHint;

  /// Match search tab
  ///
  /// In ko, this message translates to:
  /// **'경기 검색'**
  String get matchSearch;

  /// Manual input tab
  ///
  /// In ko, this message translates to:
  /// **'직접 입력'**
  String get manualInput;

  /// Team search hint
  ///
  /// In ko, this message translates to:
  /// **'팀 이름으로 검색 (선택사항)'**
  String get teamSearchHint;

  /// Select league
  ///
  /// In ko, this message translates to:
  /// **'리그 선택'**
  String get selectLeague;

  /// Enter match name hint
  ///
  /// In ko, this message translates to:
  /// **'경기명을 입력하세요'**
  String get enterMatchName;

  /// My supported team
  ///
  /// In ko, this message translates to:
  /// **'내가 응원한 팀'**
  String get mySupportedTeam;

  /// Win/Draw/Loss stats info
  ///
  /// In ko, this message translates to:
  /// **'승/무/패 통계에 반영됩니다'**
  String get winDrawLossStats;

  /// Search or enter stadium
  ///
  /// In ko, this message translates to:
  /// **'경기장 검색 또는 직접 입력'**
  String get searchOrEnterStadium;

  /// Today's match rating
  ///
  /// In ko, this message translates to:
  /// **'오늘 경기 평점'**
  String get todaysMatchRating;

  /// Rating worst
  ///
  /// In ko, this message translates to:
  /// **'최악 😢'**
  String get ratingWorst;

  /// Rating best
  ///
  /// In ko, this message translates to:
  /// **'최고 🔥'**
  String get ratingBest;

  /// Today's mood
  ///
  /// In ko, this message translates to:
  /// **'오늘의 기분'**
  String get todaysMood;

  /// Today's MVP
  ///
  /// In ko, this message translates to:
  /// **'오늘의 MVP'**
  String get todaysMvp;

  /// Select player
  ///
  /// In ko, this message translates to:
  /// **'선수 선택'**
  String get selectPlayer;

  /// Select match first
  ///
  /// In ko, this message translates to:
  /// **'먼저 경기를 선택해주세요'**
  String get selectMatchFirst;

  /// Login required
  ///
  /// In ko, this message translates to:
  /// **'로그인이 필요합니다'**
  String get loginRequired;

  /// Diary saved
  ///
  /// In ko, this message translates to:
  /// **'직관 일기가 저장되었습니다!'**
  String get diarySaved;

  /// Save failed
  ///
  /// In ko, this message translates to:
  /// **'저장 실패: {error}'**
  String saveFailed(String error);

  /// Search player name
  ///
  /// In ko, this message translates to:
  /// **'선수 이름 검색'**
  String get searchPlayerName;

  /// No player info
  ///
  /// In ko, this message translates to:
  /// **'선수 정보가 없습니다'**
  String get noPlayerInfo;

  /// Enter team name directly
  ///
  /// In ko, this message translates to:
  /// **'팀 이름을 직접 입력하세요'**
  String get enterTeamNameDirectly;

  /// Team name hint
  ///
  /// In ko, this message translates to:
  /// **'팀 이름'**
  String get teamName;

  /// Search team with label
  ///
  /// In ko, this message translates to:
  /// **'{label} 검색'**
  String searchTeamLabel(String label);

  /// Excited mood
  ///
  /// In ko, this message translates to:
  /// **'신남'**
  String get moodExcited;

  /// Happy mood
  ///
  /// In ko, this message translates to:
  /// **'기쁨'**
  String get moodHappy;

  /// Satisfied mood
  ///
  /// In ko, this message translates to:
  /// **'만족'**
  String get moodSatisfied;

  /// Neutral mood
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get moodNeutral;

  /// Disappointed mood
  ///
  /// In ko, this message translates to:
  /// **'아쉬움'**
  String get moodDisappointed;

  /// Sad mood
  ///
  /// In ko, this message translates to:
  /// **'슬픔'**
  String get moodSad;

  /// Angry mood
  ///
  /// In ko, this message translates to:
  /// **'분노'**
  String get moodAngry;

  /// Select this team button
  ///
  /// In ko, this message translates to:
  /// **'이 팀으로 선택'**
  String get selectThisTeam;

  /// Search by team name hint
  ///
  /// In ko, this message translates to:
  /// **'팀 이름으로 검색'**
  String get searchByTeamName;

  /// Select league or search team prompt
  ///
  /// In ko, this message translates to:
  /// **'리그를 선택하거나\n팀 이름을 검색하세요'**
  String get selectLeagueOrSearchTeam;

  /// Venue search title
  ///
  /// In ko, this message translates to:
  /// **'경기장 검색'**
  String get venueSearch;

  /// Enter venue name directly
  ///
  /// In ko, this message translates to:
  /// **'경기장 이름을 직접 입력하세요'**
  String get enterVenueNameDirectly;

  /// Venue name hint
  ///
  /// In ko, this message translates to:
  /// **'경기장 이름'**
  String get venueName;

  /// Select this venue button
  ///
  /// In ko, this message translates to:
  /// **'이 경기장으로 선택'**
  String get selectThisVenue;

  /// Select country
  ///
  /// In ko, this message translates to:
  /// **'국가 선택'**
  String get selectCountry;

  /// Search by venue name hint
  ///
  /// In ko, this message translates to:
  /// **'경기장 이름으로 검색'**
  String get searchByVenueName;

  /// Select country or search venue prompt
  ///
  /// In ko, this message translates to:
  /// **'국가를 선택하거나\n경기장 이름을 검색하세요'**
  String get selectCountryOrSearchVenue;

  /// No name fallback
  ///
  /// In ko, this message translates to:
  /// **'이름 없음'**
  String get noName;

  /// Edit match record title
  ///
  /// In ko, this message translates to:
  /// **'직관 기록 수정'**
  String get editMatchRecord;

  /// Edit match diary title
  ///
  /// In ko, this message translates to:
  /// **'직관 일기 수정'**
  String get editMatchDiary;

  /// Cannot load record error
  ///
  /// In ko, this message translates to:
  /// **'기록을 불러올 수 없습니다'**
  String get cannotLoadRecord;

  /// Saved message
  ///
  /// In ko, this message translates to:
  /// **'수정되었습니다!'**
  String get saved;

  /// Edit diary tab label
  ///
  /// In ko, this message translates to:
  /// **'일기 수정'**
  String get editDiary;

  /// Edit diary button
  ///
  /// In ko, this message translates to:
  /// **'일기 수정하기 →'**
  String get editDiaryButton;

  /// Add tag hint
  ///
  /// In ko, this message translates to:
  /// **'태그 추가'**
  String get addTagHint;

  /// Suggested tags label
  ///
  /// In ko, this message translates to:
  /// **'추천 태그'**
  String get suggestedTagsLabel;

  /// Additional info section
  ///
  /// In ko, this message translates to:
  /// **'추가 정보'**
  String get additionalInfoSection;

  /// No description provided for @matchInfoNotFound.
  ///
  /// In ko, this message translates to:
  /// **'경기 정보를 찾을 수 없습니다'**
  String get matchInfoNotFound;

  /// No description provided for @errorWithMessage.
  ///
  /// In ko, this message translates to:
  /// **'오류: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @tabComparison.
  ///
  /// In ko, this message translates to:
  /// **'비교'**
  String get tabComparison;

  /// No description provided for @tabStats.
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get tabStats;

  /// No description provided for @tabLineup.
  ///
  /// In ko, this message translates to:
  /// **'라인업'**
  String get tabLineup;

  /// No description provided for @tabRanking.
  ///
  /// In ko, this message translates to:
  /// **'순위'**
  String get tabRanking;

  /// No description provided for @tabPrediction.
  ///
  /// In ko, this message translates to:
  /// **'예측'**
  String get tabPrediction;

  /// No description provided for @tabComments.
  ///
  /// In ko, this message translates to:
  /// **'댓글'**
  String get tabComments;

  /// No description provided for @matchEnded.
  ///
  /// In ko, this message translates to:
  /// **'경기 종료'**
  String get matchEnded;

  /// No description provided for @leagueLabel.
  ///
  /// In ko, this message translates to:
  /// **'리그'**
  String get leagueLabel;

  /// No description provided for @seasonLabel.
  ///
  /// In ko, this message translates to:
  /// **'시즌'**
  String get seasonLabel;

  /// No description provided for @roundLabel.
  ///
  /// In ko, this message translates to:
  /// **'라운드'**
  String get roundLabel;

  /// No description provided for @dateLabel.
  ///
  /// In ko, this message translates to:
  /// **'날짜'**
  String get dateLabel;

  /// No description provided for @timeLabel.
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get timeLabel;

  /// No description provided for @venueLabel.
  ///
  /// In ko, this message translates to:
  /// **'경기장'**
  String get venueLabel;

  /// No description provided for @statusLabel.
  ///
  /// In ko, this message translates to:
  /// **'상태'**
  String get statusLabel;

  /// No description provided for @refereeLabel.
  ///
  /// In ko, this message translates to:
  /// **'주심'**
  String get refereeLabel;

  /// No description provided for @statusFinished.
  ///
  /// In ko, this message translates to:
  /// **'경기 종료'**
  String get statusFinished;

  /// No description provided for @statusHalftime.
  ///
  /// In ko, this message translates to:
  /// **'하프타임'**
  String get statusHalftime;

  /// No description provided for @statusLive.
  ///
  /// In ko, this message translates to:
  /// **'진행 중'**
  String get statusLive;

  /// No description provided for @statusScheduled.
  ///
  /// In ko, this message translates to:
  /// **'예정'**
  String get statusScheduled;

  /// No description provided for @statusTBD.
  ///
  /// In ko, this message translates to:
  /// **'시간 미정'**
  String get statusTBD;

  /// No description provided for @statusPostponed.
  ///
  /// In ko, this message translates to:
  /// **'연기'**
  String get statusPostponed;

  /// No description provided for @statusCancelled.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get statusCancelled;

  /// No description provided for @statusAET.
  ///
  /// In ko, this message translates to:
  /// **'연장 종료'**
  String get statusAET;

  /// No description provided for @statusPEN.
  ///
  /// In ko, this message translates to:
  /// **'승부차기 종료'**
  String get statusPEN;

  /// No description provided for @noPredictionInfo.
  ///
  /// In ko, this message translates to:
  /// **'예측 정보가 없습니다'**
  String get noPredictionInfo;

  /// No description provided for @cannotLoadPrediction.
  ///
  /// In ko, this message translates to:
  /// **'예측 정보를 불러올 수 없습니다'**
  String get cannotLoadPrediction;

  /// No description provided for @odds.
  ///
  /// In ko, this message translates to:
  /// **'배당률'**
  String get odds;

  /// No description provided for @drawLabel.
  ///
  /// In ko, this message translates to:
  /// **'무승부'**
  String get drawLabel;

  /// No description provided for @liveOdds.
  ///
  /// In ko, this message translates to:
  /// **'실시간 배당률'**
  String get liveOdds;

  /// No description provided for @allCategory.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get allCategory;

  /// No description provided for @noBettingInfo.
  ///
  /// In ko, this message translates to:
  /// **'배팅 정보가 없습니다'**
  String get noBettingInfo;

  /// No description provided for @categoryMainBets.
  ///
  /// In ko, this message translates to:
  /// **'주요 배팅'**
  String get categoryMainBets;

  /// No description provided for @categoryGoalRelated.
  ///
  /// In ko, this message translates to:
  /// **'골 관련'**
  String get categoryGoalRelated;

  /// No description provided for @categoryHandicap.
  ///
  /// In ko, this message translates to:
  /// **'핸디캡'**
  String get categoryHandicap;

  /// No description provided for @categoryHalfTime.
  ///
  /// In ko, this message translates to:
  /// **'전/후반'**
  String get categoryHalfTime;

  /// No description provided for @categoryTeamRelated.
  ///
  /// In ko, this message translates to:
  /// **'팀 관련'**
  String get categoryTeamRelated;

  /// No description provided for @categoryOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get categoryOther;

  /// No description provided for @initialOdd.
  ///
  /// In ko, this message translates to:
  /// **'초기 {value}'**
  String initialOdd(String value);

  /// No description provided for @matchPrediction.
  ///
  /// In ko, this message translates to:
  /// **'승부 예측'**
  String get matchPrediction;

  /// No description provided for @expectedWinner.
  ///
  /// In ko, this message translates to:
  /// **'예상 승자'**
  String get expectedWinner;

  /// No description provided for @drawPrediction.
  ///
  /// In ko, this message translates to:
  /// **'무승부'**
  String get drawPrediction;

  /// No description provided for @detailedAnalysis.
  ///
  /// In ko, this message translates to:
  /// **'상세 분석'**
  String get detailedAnalysis;

  /// No description provided for @comparisonForm.
  ///
  /// In ko, this message translates to:
  /// **'폼'**
  String get comparisonForm;

  /// No description provided for @comparisonAttack.
  ///
  /// In ko, this message translates to:
  /// **'공격력'**
  String get comparisonAttack;

  /// No description provided for @comparisonDefense.
  ///
  /// In ko, this message translates to:
  /// **'수비력'**
  String get comparisonDefense;

  /// No description provided for @comparisonH2H.
  ///
  /// In ko, this message translates to:
  /// **'상대전적'**
  String get comparisonH2H;

  /// No description provided for @comparisonGoals.
  ///
  /// In ko, this message translates to:
  /// **'득점력'**
  String get comparisonGoals;

  /// No description provided for @lineupLoadError.
  ///
  /// In ko, this message translates to:
  /// **'라인업 로딩 오류: {error}'**
  String lineupLoadError(String error);

  /// No description provided for @lineupUpdateBeforeMatch.
  ///
  /// In ko, this message translates to:
  /// **'경기 시작 전 업데이트됩니다'**
  String get lineupUpdateBeforeMatch;

  /// No description provided for @substitutes.
  ///
  /// In ko, this message translates to:
  /// **'교체 선수'**
  String get substitutes;

  /// No description provided for @substitutionRecord.
  ///
  /// In ko, this message translates to:
  /// **'교체 기록'**
  String get substitutionRecord;

  /// No description provided for @bench.
  ///
  /// In ko, this message translates to:
  /// **'벤치'**
  String get bench;

  /// No description provided for @playerAppsLabel.
  ///
  /// In ko, this message translates to:
  /// **'출전'**
  String get playerAppsLabel;

  /// No description provided for @playerGoalsLabel.
  ///
  /// In ko, this message translates to:
  /// **'골'**
  String get playerGoalsLabel;

  /// No description provided for @playerAssistsLabel.
  ///
  /// In ko, this message translates to:
  /// **'어시스트'**
  String get playerAssistsLabel;

  /// No description provided for @playerPassAccuracy.
  ///
  /// In ko, this message translates to:
  /// **'패스 성공률'**
  String get playerPassAccuracy;

  /// No description provided for @noMatchStats.
  ///
  /// In ko, this message translates to:
  /// **'경기 통계가 없습니다'**
  String get noMatchStats;

  /// No description provided for @statsUpdateDuringMatch.
  ///
  /// In ko, this message translates to:
  /// **'경기 중 또는 경기 후에 업데이트됩니다'**
  String get statsUpdateDuringMatch;

  /// No description provided for @attackSection.
  ///
  /// In ko, this message translates to:
  /// **'공격'**
  String get attackSection;

  /// No description provided for @shotsLabel.
  ///
  /// In ko, this message translates to:
  /// **'슈팅'**
  String get shotsLabel;

  /// No description provided for @shotsOnLabel.
  ///
  /// In ko, this message translates to:
  /// **'유효 슈팅'**
  String get shotsOnLabel;

  /// No description provided for @offsidesLabel.
  ///
  /// In ko, this message translates to:
  /// **'오프사이드'**
  String get offsidesLabel;

  /// No description provided for @passSection.
  ///
  /// In ko, this message translates to:
  /// **'패스'**
  String get passSection;

  /// No description provided for @totalPassLabel.
  ///
  /// In ko, this message translates to:
  /// **'총 패스'**
  String get totalPassLabel;

  /// No description provided for @keyPassLabel.
  ///
  /// In ko, this message translates to:
  /// **'키 패스'**
  String get keyPassLabel;

  /// No description provided for @defenseSection.
  ///
  /// In ko, this message translates to:
  /// **'수비'**
  String get defenseSection;

  /// No description provided for @tackleLabel.
  ///
  /// In ko, this message translates to:
  /// **'태클'**
  String get tackleLabel;

  /// No description provided for @interceptLabel.
  ///
  /// In ko, this message translates to:
  /// **'인터셉트'**
  String get interceptLabel;

  /// No description provided for @blockLabel.
  ///
  /// In ko, this message translates to:
  /// **'블록'**
  String get blockLabel;

  /// No description provided for @duelDribbleSection.
  ///
  /// In ko, this message translates to:
  /// **'듀얼 & 드리블'**
  String get duelDribbleSection;

  /// No description provided for @duelLabel.
  ///
  /// In ko, this message translates to:
  /// **'듀얼'**
  String get duelLabel;

  /// No description provided for @dribbleLabel.
  ///
  /// In ko, this message translates to:
  /// **'드리블'**
  String get dribbleLabel;

  /// No description provided for @foulCardSection.
  ///
  /// In ko, this message translates to:
  /// **'파울 & 카드'**
  String get foulCardSection;

  /// No description provided for @foulLabel.
  ///
  /// In ko, this message translates to:
  /// **'파울'**
  String get foulLabel;

  /// No description provided for @foulDrawnLabel.
  ///
  /// In ko, this message translates to:
  /// **'피파울'**
  String get foulDrawnLabel;

  /// No description provided for @cardsLabel.
  ///
  /// In ko, this message translates to:
  /// **'카드'**
  String get cardsLabel;

  /// No description provided for @goalkeeperSection.
  ///
  /// In ko, this message translates to:
  /// **'골키퍼'**
  String get goalkeeperSection;

  /// No description provided for @savesLabel.
  ///
  /// In ko, this message translates to:
  /// **'선방'**
  String get savesLabel;

  /// No description provided for @concededLabel.
  ///
  /// In ko, this message translates to:
  /// **'실점'**
  String get concededLabel;

  /// No description provided for @viewPlayerDetail.
  ///
  /// In ko, this message translates to:
  /// **'선수 상세 정보 보기'**
  String get viewPlayerDetail;

  /// No description provided for @positionGoalkeeper.
  ///
  /// In ko, this message translates to:
  /// **'골키퍼'**
  String get positionGoalkeeper;

  /// No description provided for @positionDefender.
  ///
  /// In ko, this message translates to:
  /// **'수비수'**
  String get positionDefender;

  /// No description provided for @positionMidfielder.
  ///
  /// In ko, this message translates to:
  /// **'미드필더'**
  String get positionMidfielder;

  /// No description provided for @positionAttacker.
  ///
  /// In ko, this message translates to:
  /// **'공격수'**
  String get positionAttacker;

  /// No description provided for @missingPlayers.
  ///
  /// In ko, this message translates to:
  /// **'결장 선수'**
  String get missingPlayers;

  /// No description provided for @checkingMissingInfo.
  ///
  /// In ko, this message translates to:
  /// **'결장 정보 확인 중...'**
  String get checkingMissingInfo;

  /// No description provided for @injurySuspension.
  ///
  /// In ko, this message translates to:
  /// **'정지'**
  String get injurySuspension;

  /// No description provided for @injuryKnee.
  ///
  /// In ko, this message translates to:
  /// **'무릎 부상'**
  String get injuryKnee;

  /// No description provided for @injuryHamstring.
  ///
  /// In ko, this message translates to:
  /// **'햄스트링 부상'**
  String get injuryHamstring;

  /// No description provided for @injuryAnkle.
  ///
  /// In ko, this message translates to:
  /// **'발목 부상'**
  String get injuryAnkle;

  /// No description provided for @injuryMuscle.
  ///
  /// In ko, this message translates to:
  /// **'근육 부상'**
  String get injuryMuscle;

  /// No description provided for @injuryBack.
  ///
  /// In ko, this message translates to:
  /// **'허리 부상'**
  String get injuryBack;

  /// No description provided for @injuryIllness.
  ///
  /// In ko, this message translates to:
  /// **'질병'**
  String get injuryIllness;

  /// No description provided for @injuryGeneral.
  ///
  /// In ko, this message translates to:
  /// **'부상'**
  String get injuryGeneral;

  /// No description provided for @injuryDoubtful.
  ///
  /// In ko, this message translates to:
  /// **'불투명'**
  String get injuryDoubtful;

  /// No description provided for @injuryOut.
  ///
  /// In ko, this message translates to:
  /// **'결장'**
  String get injuryOut;

  /// No description provided for @sectionStats.
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get sectionStats;

  /// No description provided for @sectionBroadcast.
  ///
  /// In ko, this message translates to:
  /// **'중계'**
  String get sectionBroadcast;

  /// No description provided for @cannotLoadTimeline.
  ///
  /// In ko, this message translates to:
  /// **'타임라인을 불러올 수 없습니다'**
  String get cannotLoadTimeline;

  /// No description provided for @possessionLabel.
  ///
  /// In ko, this message translates to:
  /// **'점유율'**
  String get possessionLabel;

  /// No description provided for @cornersLabel.
  ///
  /// In ko, this message translates to:
  /// **'코너킥'**
  String get cornersLabel;

  /// No description provided for @foulsLabel.
  ///
  /// In ko, this message translates to:
  /// **'파울'**
  String get foulsLabel;

  /// No description provided for @warningsLabel.
  ///
  /// In ko, this message translates to:
  /// **'경고'**
  String get warningsLabel;

  /// No description provided for @sendOffsLabel.
  ///
  /// In ko, this message translates to:
  /// **'퇴장'**
  String get sendOffsLabel;

  /// No description provided for @assistLabel.
  ///
  /// In ko, this message translates to:
  /// **'어시스트: {name}'**
  String assistLabel(String name);

  /// No description provided for @goalLabel.
  ///
  /// In ko, this message translates to:
  /// **'골'**
  String get goalLabel;

  /// No description provided for @warningCard.
  ///
  /// In ko, this message translates to:
  /// **'경고'**
  String get warningCard;

  /// No description provided for @sendOffCard.
  ///
  /// In ko, this message translates to:
  /// **'퇴장'**
  String get sendOffCard;

  /// No description provided for @cardLabel.
  ///
  /// In ko, this message translates to:
  /// **'카드'**
  String get cardLabel;

  /// No description provided for @substitutionLabel.
  ///
  /// In ko, this message translates to:
  /// **'교체'**
  String get substitutionLabel;

  /// No description provided for @matchNotificationSettings.
  ///
  /// In ko, this message translates to:
  /// **'경기 알림 설정'**
  String get matchNotificationSettings;

  /// No description provided for @turnOffNotification.
  ///
  /// In ko, this message translates to:
  /// **'알림 해제'**
  String get turnOffNotification;

  /// No description provided for @cancelLabel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancelLabel;

  /// No description provided for @saveLabel.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get saveLabel;

  /// No description provided for @leagueRanking.
  ///
  /// In ko, this message translates to:
  /// **'리그 순위'**
  String get leagueRanking;

  /// No description provided for @homeAwayRecord.
  ///
  /// In ko, this message translates to:
  /// **'홈/원정 성적'**
  String get homeAwayRecord;

  /// No description provided for @last5Matches.
  ///
  /// In ko, this message translates to:
  /// **'최근 5경기'**
  String get last5Matches;

  /// No description provided for @goalStats.
  ///
  /// In ko, this message translates to:
  /// **'득점/실점 통계'**
  String get goalStats;

  /// No description provided for @teamStyleComparison.
  ///
  /// In ko, this message translates to:
  /// **'팀 스타일 비교'**
  String get teamStyleComparison;

  /// No description provided for @keyPlayers.
  ///
  /// In ko, this message translates to:
  /// **'주요 선수'**
  String get keyPlayers;

  /// No description provided for @h2hRecord.
  ///
  /// In ko, this message translates to:
  /// **'상대전적'**
  String get h2hRecord;

  /// No description provided for @winLabel.
  ///
  /// In ko, this message translates to:
  /// **'승'**
  String get winLabel;

  /// No description provided for @drawShortLabel.
  ///
  /// In ko, this message translates to:
  /// **'무'**
  String get drawShortLabel;

  /// No description provided for @goalsDisplay.
  ///
  /// In ko, this message translates to:
  /// **'득점 {home} : {away}'**
  String goalsDisplay(int home, int away);

  /// No description provided for @recentNMatches.
  ///
  /// In ko, this message translates to:
  /// **'최근 {count}경기'**
  String recentNMatches(int count);

  /// No description provided for @noRankingInfo.
  ///
  /// In ko, this message translates to:
  /// **'순위 정보가 없습니다'**
  String get noRankingInfo;

  /// No description provided for @rankingLabel.
  ///
  /// In ko, this message translates to:
  /// **'순위'**
  String get rankingLabel;

  /// No description provided for @pointsLabel.
  ///
  /// In ko, this message translates to:
  /// **'승점'**
  String get pointsLabel;

  /// No description provided for @matchesPlayedLabel.
  ///
  /// In ko, this message translates to:
  /// **'경기'**
  String get matchesPlayedLabel;

  /// No description provided for @winDrawLossLabel.
  ///
  /// In ko, this message translates to:
  /// **'승-무-패'**
  String get winDrawLossLabel;

  /// No description provided for @goalsForLabel.
  ///
  /// In ko, this message translates to:
  /// **'득점'**
  String get goalsForLabel;

  /// No description provided for @goalsAgainstLabel.
  ///
  /// In ko, this message translates to:
  /// **'실점'**
  String get goalsAgainstLabel;

  /// No description provided for @goalDiffLabel.
  ///
  /// In ko, this message translates to:
  /// **'득실차'**
  String get goalDiffLabel;

  /// No description provided for @dataLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'데이터 로드 실패'**
  String get dataLoadFailed;

  /// No description provided for @noRecordInfo.
  ///
  /// In ko, this message translates to:
  /// **'성적 정보가 없습니다'**
  String get noRecordInfo;

  /// No description provided for @avgGoalsFor.
  ///
  /// In ko, this message translates to:
  /// **'평균 득점'**
  String get avgGoalsFor;

  /// No description provided for @avgGoalsAgainst.
  ///
  /// In ko, this message translates to:
  /// **'평균 실점'**
  String get avgGoalsAgainst;

  /// No description provided for @noStatsAvailable.
  ///
  /// In ko, this message translates to:
  /// **'통계 정보가 없습니다'**
  String get noStatsAvailable;

  /// No description provided for @totalGoalsFor.
  ///
  /// In ko, this message translates to:
  /// **'총 득점'**
  String get totalGoalsFor;

  /// No description provided for @totalGoalsAgainst.
  ///
  /// In ko, this message translates to:
  /// **'총 실점'**
  String get totalGoalsAgainst;

  /// No description provided for @goalsPerMatch.
  ///
  /// In ko, this message translates to:
  /// **'경기당 득점'**
  String get goalsPerMatch;

  /// No description provided for @concededPerMatch.
  ///
  /// In ko, this message translates to:
  /// **'경기당 실점'**
  String get concededPerMatch;

  /// No description provided for @noPlayerStats.
  ///
  /// In ko, this message translates to:
  /// **'선수 통계 정보가 없습니다'**
  String get noPlayerStats;

  /// No description provided for @goalLeaders.
  ///
  /// In ko, this message translates to:
  /// **'득점 리더'**
  String get goalLeaders;

  /// No description provided for @assistLeaders.
  ///
  /// In ko, this message translates to:
  /// **'도움 리더'**
  String get assistLeaders;

  /// No description provided for @assistDataLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'도움 데이터 로드 실패'**
  String get assistDataLoadFailed;

  /// No description provided for @cannotLoadPlayerStats.
  ///
  /// In ko, this message translates to:
  /// **'선수 통계를 불러올 수 없습니다'**
  String get cannotLoadPlayerStats;

  /// No description provided for @radarWinRate.
  ///
  /// In ko, this message translates to:
  /// **'승률'**
  String get radarWinRate;

  /// No description provided for @radarAttack.
  ///
  /// In ko, this message translates to:
  /// **'공격력'**
  String get radarAttack;

  /// No description provided for @radarDefense.
  ///
  /// In ko, this message translates to:
  /// **'수비력'**
  String get radarDefense;

  /// No description provided for @radarCleanSheet.
  ///
  /// In ko, this message translates to:
  /// **'클린시트'**
  String get radarCleanSheet;

  /// No description provided for @radarHomeRecord.
  ///
  /// In ko, this message translates to:
  /// **'홈 성적'**
  String get radarHomeRecord;

  /// No description provided for @cleanSheetLabel.
  ///
  /// In ko, this message translates to:
  /// **'클린시트'**
  String get cleanSheetLabel;

  /// No description provided for @failedToScoreLabel.
  ///
  /// In ko, this message translates to:
  /// **'무득점 경기'**
  String get failedToScoreLabel;

  /// No description provided for @cannotLoadRanking.
  ///
  /// In ko, this message translates to:
  /// **'순위를 불러올 수 없습니다'**
  String get cannotLoadRanking;

  /// No description provided for @retryButton.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get retryButton;

  /// No description provided for @teamColumnHeader.
  ///
  /// In ko, this message translates to:
  /// **'팀'**
  String get teamColumnHeader;

  /// No description provided for @matchesColumnHeader.
  ///
  /// In ko, this message translates to:
  /// **'경기'**
  String get matchesColumnHeader;

  /// No description provided for @winsColumnHeader.
  ///
  /// In ko, this message translates to:
  /// **'승'**
  String get winsColumnHeader;

  /// No description provided for @drawsColumnHeader.
  ///
  /// In ko, this message translates to:
  /// **'무'**
  String get drawsColumnHeader;

  /// No description provided for @lossesColumnHeader.
  ///
  /// In ko, this message translates to:
  /// **'패'**
  String get lossesColumnHeader;

  /// No description provided for @goalDiffColumnHeader.
  ///
  /// In ko, this message translates to:
  /// **'득실'**
  String get goalDiffColumnHeader;

  /// No description provided for @pointsColumnHeader.
  ///
  /// In ko, this message translates to:
  /// **'승점'**
  String get pointsColumnHeader;

  /// No description provided for @matchTeams.
  ///
  /// In ko, this message translates to:
  /// **'경기 팀'**
  String get matchTeams;

  /// No description provided for @relegationLabel.
  ///
  /// In ko, this message translates to:
  /// **'강등'**
  String get relegationLabel;

  /// No description provided for @promotionLabel.
  ///
  /// In ko, this message translates to:
  /// **'승격'**
  String get promotionLabel;

  /// No description provided for @playoffLabel.
  ///
  /// In ko, this message translates to:
  /// **'플레이오프'**
  String get playoffLabel;

  /// No description provided for @advanceLabel.
  ///
  /// In ko, this message translates to:
  /// **'진출'**
  String get advanceLabel;

  /// No description provided for @matchGroup.
  ///
  /// In ko, this message translates to:
  /// **'경기 조'**
  String get matchGroup;

  /// No description provided for @commentWriteFailed.
  ///
  /// In ko, this message translates to:
  /// **'댓글 작성 실패: {error}'**
  String commentWriteFailed(String error);

  /// No description provided for @deleteComment.
  ///
  /// In ko, this message translates to:
  /// **'댓글 삭제'**
  String get deleteComment;

  /// No description provided for @deleteCommentConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 댓글을 삭제하시겠습니까?'**
  String get deleteCommentConfirm;

  /// No description provided for @deleteButton.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get deleteButton;

  /// No description provided for @commentDeleted.
  ///
  /// In ko, this message translates to:
  /// **'댓글이 삭제되었습니다'**
  String get commentDeleted;

  /// No description provided for @deleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패: {error}'**
  String deleteFailed(String error);

  /// No description provided for @liveComments.
  ///
  /// In ko, this message translates to:
  /// **'실시간 댓글'**
  String get liveComments;

  /// No description provided for @commentsRefreshed.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 새로고침했습니다'**
  String get commentsRefreshed;

  /// No description provided for @refreshButton.
  ///
  /// In ko, this message translates to:
  /// **'새로고침'**
  String get refreshButton;

  /// No description provided for @cannotLoadComments.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 불러올 수 없습니다'**
  String get cannotLoadComments;

  /// No description provided for @noCommentsYet.
  ///
  /// In ko, this message translates to:
  /// **'아직 댓글이 없습니다.\n첫 번째 댓글을 남겨보세요!'**
  String get noCommentsYet;

  /// No description provided for @beFirstToComment.
  ///
  /// In ko, this message translates to:
  /// **'첫 댓글을 남겨보세요!'**
  String get beFirstToComment;

  /// No description provided for @commentInputHint.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 입력하세요...'**
  String get commentInputHint;

  /// No description provided for @justNow.
  ///
  /// In ko, this message translates to:
  /// **'방금 전'**
  String get justNow;

  /// No description provided for @noPlayerStatsInfo.
  ///
  /// In ko, this message translates to:
  /// **'선수 통계 정보가 없습니다'**
  String get noPlayerStatsInfo;

  /// No description provided for @topScorer.
  ///
  /// In ko, this message translates to:
  /// **'득점 리더'**
  String get topScorer;

  /// No description provided for @topAssister.
  ///
  /// In ko, this message translates to:
  /// **'도움 리더'**
  String get topAssister;

  /// No description provided for @nAssists.
  ///
  /// In ko, this message translates to:
  /// **'{count}도움'**
  String nAssists(int count);

  /// No description provided for @seasonWithYear.
  ///
  /// In ko, this message translates to:
  /// **'{year}-{nextYear} 시즌'**
  String seasonWithYear(int year, int nextYear);

  /// No description provided for @goalDifference.
  ///
  /// In ko, this message translates to:
  /// **'득실'**
  String get goalDifference;

  /// No description provided for @standingsErrorMessage.
  ///
  /// In ko, this message translates to:
  /// **'순위를 불러올 수 없습니다'**
  String get standingsErrorMessage;

  /// No description provided for @nTimes.
  ///
  /// In ko, this message translates to:
  /// **'{count}회'**
  String nTimes(int count);

  /// No description provided for @nPlayers.
  ///
  /// In ko, this message translates to:
  /// **'{count}명'**
  String nPlayers(int count);

  /// No description provided for @nTeams.
  ///
  /// In ko, this message translates to:
  /// **'{count}팀'**
  String nTeams(int count);

  /// No description provided for @matchTeam.
  ///
  /// In ko, this message translates to:
  /// **'경기 팀'**
  String get matchTeam;

  /// No description provided for @relegation.
  ///
  /// In ko, this message translates to:
  /// **'강등'**
  String get relegation;

  /// No description provided for @promotion.
  ///
  /// In ko, this message translates to:
  /// **'승격'**
  String get promotion;

  /// No description provided for @playoff.
  ///
  /// In ko, this message translates to:
  /// **'플레이오프'**
  String get playoff;

  /// No description provided for @groupStageWithYear.
  ///
  /// In ko, this message translates to:
  /// **'{year} 조별리그'**
  String groupStageWithYear(int year);

  /// No description provided for @qualified.
  ///
  /// In ko, this message translates to:
  /// **'진출'**
  String get qualified;

  /// No description provided for @betCategoryMain.
  ///
  /// In ko, this message translates to:
  /// **'주요 배팅'**
  String get betCategoryMain;

  /// No description provided for @betCategoryGoal.
  ///
  /// In ko, this message translates to:
  /// **'골 관련'**
  String get betCategoryGoal;

  /// No description provided for @betCategoryHandicap.
  ///
  /// In ko, this message translates to:
  /// **'핸디캡'**
  String get betCategoryHandicap;

  /// No description provided for @betCategoryHalf.
  ///
  /// In ko, this message translates to:
  /// **'전/후반'**
  String get betCategoryHalf;

  /// No description provided for @betCategoryTeam.
  ///
  /// In ko, this message translates to:
  /// **'팀 관련'**
  String get betCategoryTeam;

  /// No description provided for @betCategoryOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get betCategoryOther;

  /// No description provided for @betMatchWinner.
  ///
  /// In ko, this message translates to:
  /// **'승무패'**
  String get betMatchWinner;

  /// No description provided for @betHomeAway.
  ///
  /// In ko, this message translates to:
  /// **'홈/원정'**
  String get betHomeAway;

  /// No description provided for @betDoubleChance.
  ///
  /// In ko, this message translates to:
  /// **'더블찬스'**
  String get betDoubleChance;

  /// No description provided for @betBothTeamsScore.
  ///
  /// In ko, this message translates to:
  /// **'양팀 득점'**
  String get betBothTeamsScore;

  /// No description provided for @betExactScore.
  ///
  /// In ko, this message translates to:
  /// **'정확한 스코어'**
  String get betExactScore;

  /// No description provided for @betGoalsOverUnder.
  ///
  /// In ko, this message translates to:
  /// **'총 골 수'**
  String get betGoalsOverUnder;

  /// No description provided for @betOverUnder.
  ///
  /// In ko, this message translates to:
  /// **'오버/언더'**
  String get betOverUnder;

  /// No description provided for @betAsianHandicap.
  ///
  /// In ko, this message translates to:
  /// **'아시안 핸디캡'**
  String get betAsianHandicap;

  /// No description provided for @betHandicap.
  ///
  /// In ko, this message translates to:
  /// **'핸디캡'**
  String get betHandicap;

  /// No description provided for @betFirstHalfWinner.
  ///
  /// In ko, this message translates to:
  /// **'전반 승패'**
  String get betFirstHalfWinner;

  /// No description provided for @betSecondHalfWinner.
  ///
  /// In ko, this message translates to:
  /// **'후반 승패'**
  String get betSecondHalfWinner;

  /// No description provided for @betHalfTimeFullTime.
  ///
  /// In ko, this message translates to:
  /// **'전반/후반 결과'**
  String get betHalfTimeFullTime;

  /// No description provided for @betOddEven.
  ///
  /// In ko, this message translates to:
  /// **'홀/짝'**
  String get betOddEven;

  /// No description provided for @betTotalHome.
  ///
  /// In ko, this message translates to:
  /// **'홈팀 총 골'**
  String get betTotalHome;

  /// No description provided for @betTotalAway.
  ///
  /// In ko, this message translates to:
  /// **'원정팀 총 골'**
  String get betTotalAway;

  /// No description provided for @betCleanSheetHome.
  ///
  /// In ko, this message translates to:
  /// **'홈팀 무실점'**
  String get betCleanSheetHome;

  /// No description provided for @betCleanSheetAway.
  ///
  /// In ko, this message translates to:
  /// **'원정팀 무실점'**
  String get betCleanSheetAway;

  /// No description provided for @betWinToNilHome.
  ///
  /// In ko, this message translates to:
  /// **'홈팀 완봉승'**
  String get betWinToNilHome;

  /// No description provided for @betWinToNilAway.
  ///
  /// In ko, this message translates to:
  /// **'원정팀 완봉승'**
  String get betWinToNilAway;

  /// No description provided for @betCornersOverUnder.
  ///
  /// In ko, this message translates to:
  /// **'코너킥 수'**
  String get betCornersOverUnder;

  /// No description provided for @betCardsOverUnder.
  ///
  /// In ko, this message translates to:
  /// **'카드 수'**
  String get betCardsOverUnder;

  /// No description provided for @betFirstTeamToScore.
  ///
  /// In ko, this message translates to:
  /// **'선제골 팀'**
  String get betFirstTeamToScore;

  /// No description provided for @betLastTeamToScore.
  ///
  /// In ko, this message translates to:
  /// **'마지막 득점 팀'**
  String get betLastTeamToScore;

  /// No description provided for @betHighestScoringHalf.
  ///
  /// In ko, this message translates to:
  /// **'최다 득점 반'**
  String get betHighestScoringHalf;

  /// No description provided for @betToScoreInBothHalves.
  ///
  /// In ko, this message translates to:
  /// **'양 반전 득점'**
  String get betToScoreInBothHalves;

  /// No description provided for @betHomeWinBothHalves.
  ///
  /// In ko, this message translates to:
  /// **'홈팀 양 반전 승리'**
  String get betHomeWinBothHalves;

  /// No description provided for @betAwayWinBothHalves.
  ///
  /// In ko, this message translates to:
  /// **'원정팀 양 반전 승리'**
  String get betAwayWinBothHalves;

  /// No description provided for @cannotLoadLeagueInfo.
  ///
  /// In ko, this message translates to:
  /// **'리그 정보를 불러올 수 없습니다'**
  String get cannotLoadLeagueInfo;

  /// No description provided for @topScorersRanking.
  ///
  /// In ko, this message translates to:
  /// **'득점 순위'**
  String get topScorersRanking;

  /// No description provided for @topAssistsRanking.
  ///
  /// In ko, this message translates to:
  /// **'도움 순위'**
  String get topAssistsRanking;

  /// No description provided for @noTopScorersInfo.
  ///
  /// In ko, this message translates to:
  /// **'득점 순위 정보가 없습니다'**
  String get noTopScorersInfo;

  /// No description provided for @noTopAssistsInfo.
  ///
  /// In ko, this message translates to:
  /// **'도움 순위 정보가 없습니다'**
  String get noTopAssistsInfo;

  /// No description provided for @cannotLoadTopScorers.
  ///
  /// In ko, this message translates to:
  /// **'득점 순위를 불러올 수 없습니다'**
  String get cannotLoadTopScorers;

  /// No description provided for @cannotLoadTopAssists.
  ///
  /// In ko, this message translates to:
  /// **'도움 순위를 불러올 수 없습니다'**
  String get cannotLoadTopAssists;

  /// No description provided for @goalsFor.
  ///
  /// In ko, this message translates to:
  /// **'득점'**
  String get goalsFor;

  /// No description provided for @goalsAgainst.
  ///
  /// In ko, this message translates to:
  /// **'실점'**
  String get goalsAgainst;

  /// No description provided for @uclDirect.
  ///
  /// In ko, this message translates to:
  /// **'UCL 직행'**
  String get uclDirect;

  /// No description provided for @uclQualification.
  ///
  /// In ko, this message translates to:
  /// **'UCL 예선'**
  String get uclQualification;

  /// No description provided for @uclRoundOf16.
  ///
  /// In ko, this message translates to:
  /// **'UCL 16강'**
  String get uclRoundOf16;

  /// No description provided for @uclPlayoff.
  ///
  /// In ko, this message translates to:
  /// **'UCL PO'**
  String get uclPlayoff;

  /// No description provided for @uelDirect.
  ///
  /// In ko, this message translates to:
  /// **'UEL 직행'**
  String get uelDirect;

  /// No description provided for @uelRoundOf16.
  ///
  /// In ko, this message translates to:
  /// **'UEL 16강'**
  String get uelRoundOf16;

  /// No description provided for @uelPlayoff.
  ///
  /// In ko, this message translates to:
  /// **'UEL PO'**
  String get uelPlayoff;

  /// No description provided for @ueclRoundOf16.
  ///
  /// In ko, this message translates to:
  /// **'UECL 16강'**
  String get ueclRoundOf16;

  /// No description provided for @ueclPlayoff.
  ///
  /// In ko, this message translates to:
  /// **'UECL PO'**
  String get ueclPlayoff;

  /// No description provided for @roundOf16.
  ///
  /// In ko, this message translates to:
  /// **'16강'**
  String get roundOf16;

  /// No description provided for @groupStage.
  ///
  /// In ko, this message translates to:
  /// **'조별리그'**
  String get groupStage;

  /// No description provided for @mon.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In ko, this message translates to:
  /// **'화'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In ko, this message translates to:
  /// **'수'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In ko, this message translates to:
  /// **'목'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In ko, this message translates to:
  /// **'금'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In ko, this message translates to:
  /// **'토'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get sun;

  /// No description provided for @dateWithWeekday.
  ///
  /// In ko, this message translates to:
  /// **'{month}월 {day}일 ({weekday})'**
  String dateWithWeekday(Object day, Object month, Object weekday);

  /// No description provided for @matchFinished.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get matchFinished;

  /// No description provided for @noMatchSchedule.
  ///
  /// In ko, this message translates to:
  /// **'경기 일정이 없습니다'**
  String get noMatchSchedule;

  /// No description provided for @tomorrow.
  ///
  /// In ko, this message translates to:
  /// **'내일'**
  String get tomorrow;

  /// No description provided for @yesterday.
  ///
  /// In ko, this message translates to:
  /// **'어제'**
  String get yesterday;

  /// No description provided for @champion.
  ///
  /// In ko, this message translates to:
  /// **'우승'**
  String get champion;

  /// No description provided for @finalMatch.
  ///
  /// In ko, this message translates to:
  /// **'결승전'**
  String get finalMatch;

  /// No description provided for @runnerUp.
  ///
  /// In ko, this message translates to:
  /// **'준우승'**
  String get runnerUp;

  /// No description provided for @currentRank.
  ///
  /// In ko, this message translates to:
  /// **'현재 순위'**
  String get currentRank;

  /// No description provided for @seasonEnd.
  ///
  /// In ko, this message translates to:
  /// **'시즌 종료'**
  String get seasonEnd;

  /// No description provided for @winShortForm.
  ///
  /// In ko, this message translates to:
  /// **'승'**
  String get winShortForm;

  /// No description provided for @drawShortForm.
  ///
  /// In ko, this message translates to:
  /// **'무'**
  String get drawShortForm;

  /// No description provided for @lossShortForm.
  ///
  /// In ko, this message translates to:
  /// **'패'**
  String get lossShortForm;

  /// No description provided for @xMatches.
  ///
  /// In ko, this message translates to:
  /// **'{count}경기'**
  String xMatches(int count);

  /// No description provided for @xPoints.
  ///
  /// In ko, this message translates to:
  /// **'{count}점'**
  String xPoints(int count);

  /// No description provided for @xGoals.
  ///
  /// In ko, this message translates to:
  /// **'{count}골'**
  String xGoals(int count);

  /// No description provided for @todayWithDate.
  ///
  /// In ko, this message translates to:
  /// **'오늘 {date}'**
  String todayWithDate(String date);

  /// No description provided for @tomorrowWithDate.
  ///
  /// In ko, this message translates to:
  /// **'내일 {date}'**
  String tomorrowWithDate(String date);

  /// No description provided for @yesterdayWithDate.
  ///
  /// In ko, this message translates to:
  /// **'어제 {date}'**
  String yesterdayWithDate(String date);

  /// No description provided for @info.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get info;

  /// No description provided for @statistics.
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get statistics;

  /// No description provided for @squad.
  ///
  /// In ko, this message translates to:
  /// **'선수단'**
  String get squad;

  /// No description provided for @transfers.
  ///
  /// In ko, this message translates to:
  /// **'이적'**
  String get transfers;

  /// No description provided for @country.
  ///
  /// In ko, this message translates to:
  /// **'국가'**
  String get country;

  /// No description provided for @founded.
  ///
  /// In ko, this message translates to:
  /// **'창단'**
  String get founded;

  /// No description provided for @type.
  ///
  /// In ko, this message translates to:
  /// **'유형'**
  String get type;

  /// No description provided for @code.
  ///
  /// In ko, this message translates to:
  /// **'코드'**
  String get code;

  /// No description provided for @manager.
  ///
  /// In ko, this message translates to:
  /// **'감독'**
  String get manager;

  /// No description provided for @cleanSheet.
  ///
  /// In ko, this message translates to:
  /// **'클린시트'**
  String get cleanSheet;

  /// No description provided for @failedToScore.
  ///
  /// In ko, this message translates to:
  /// **'무득점'**
  String get failedToScore;

  /// No description provided for @penaltyKick.
  ///
  /// In ko, this message translates to:
  /// **'페널티킥'**
  String get penaltyKick;

  /// No description provided for @hamstring.
  ///
  /// In ko, this message translates to:
  /// **'햄스트링'**
  String get hamstring;

  /// No description provided for @illness.
  ///
  /// In ko, this message translates to:
  /// **'질병'**
  String get illness;

  /// No description provided for @doubtful.
  ///
  /// In ko, this message translates to:
  /// **'불투명'**
  String get doubtful;

  /// No description provided for @absent.
  ///
  /// In ko, this message translates to:
  /// **'결장'**
  String get absent;

  /// No description provided for @forward.
  ///
  /// In ko, this message translates to:
  /// **'공격수'**
  String get forward;

  /// No description provided for @incoming.
  ///
  /// In ko, this message translates to:
  /// **'영입'**
  String get incoming;

  /// No description provided for @outgoing.
  ///
  /// In ko, this message translates to:
  /// **'방출'**
  String get outgoing;

  /// No description provided for @loan.
  ///
  /// In ko, this message translates to:
  /// **'임대'**
  String get loan;

  /// No description provided for @transfer.
  ///
  /// In ko, this message translates to:
  /// **'이적'**
  String get transfer;

  /// No description provided for @foundedYear.
  ///
  /// In ko, this message translates to:
  /// **'창단 {year}'**
  String foundedYear(int year);

  /// No description provided for @foundedIn.
  ///
  /// In ko, this message translates to:
  /// **'창단 {year}'**
  String foundedIn(int year);

  /// No description provided for @seasonFormat.
  ///
  /// In ko, this message translates to:
  /// **'{year1}/{year2} 시즌'**
  String seasonFormat(int year1, int year2);

  /// No description provided for @averageFormat.
  ///
  /// In ko, this message translates to:
  /// **'평균 {value}'**
  String averageFormat(String value);

  /// No description provided for @homeAwayFormat.
  ///
  /// In ko, this message translates to:
  /// **'홈 {home} / 원정 {away}'**
  String homeAwayFormat(int home, int away);

  /// No description provided for @homeAwayComparison.
  ///
  /// In ko, this message translates to:
  /// **'홈/원정 비교'**
  String get homeAwayComparison;

  /// No description provided for @goalsByMinute.
  ///
  /// In ko, this message translates to:
  /// **'시간대별 골 분포'**
  String get goalsByMinute;

  /// No description provided for @injurySuspended.
  ///
  /// In ko, this message translates to:
  /// **'정지'**
  String get injurySuspended;

  /// No description provided for @injuryAbsent.
  ///
  /// In ko, this message translates to:
  /// **'결장'**
  String get injuryAbsent;

  /// No description provided for @positionForward.
  ///
  /// In ko, this message translates to:
  /// **'공격수'**
  String get positionForward;

  /// No description provided for @filterAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get filterAll;

  /// No description provided for @transferIncoming.
  ///
  /// In ko, this message translates to:
  /// **'영입'**
  String get transferIncoming;

  /// No description provided for @transferOutgoing.
  ///
  /// In ko, this message translates to:
  /// **'방출'**
  String get transferOutgoing;

  /// No description provided for @transferTypeLoan.
  ///
  /// In ko, this message translates to:
  /// **'임대'**
  String get transferTypeLoan;

  /// No description provided for @transferTypePermanent.
  ///
  /// In ko, this message translates to:
  /// **'이적'**
  String get transferTypePermanent;

  /// No description provided for @transferLoanReturn.
  ///
  /// In ko, this message translates to:
  /// **'임대 복귀'**
  String get transferLoanReturn;

  /// No description provided for @freeTransfer.
  ///
  /// In ko, this message translates to:
  /// **'프리'**
  String get freeTransfer;

  /// No description provided for @freeTransferLabel.
  ///
  /// In ko, this message translates to:
  /// **'자유 이적'**
  String get freeTransferLabel;

  /// No description provided for @transferFee.
  ///
  /// In ko, this message translates to:
  /// **'이적료'**
  String get transferFee;

  /// No description provided for @noTransferInfo.
  ///
  /// In ko, this message translates to:
  /// **'이적 정보가 없습니다'**
  String get noTransferInfo;

  /// No description provided for @teamInfo.
  ///
  /// In ko, this message translates to:
  /// **'팀 정보'**
  String get teamInfo;

  /// No description provided for @homeStadium.
  ///
  /// In ko, this message translates to:
  /// **'홈 경기장'**
  String get homeStadium;

  /// No description provided for @careerTeamCount.
  ///
  /// In ko, this message translates to:
  /// **'경력: {count}개 팀'**
  String careerTeamCount(int count);

  /// No description provided for @seasonRecord.
  ///
  /// In ko, this message translates to:
  /// **'시즌 성적'**
  String get seasonRecord;

  /// No description provided for @seasonRecordTitle.
  ///
  /// In ko, this message translates to:
  /// **'시즌 기록'**
  String get seasonRecordTitle;

  /// No description provided for @longestWinStreak.
  ///
  /// In ko, this message translates to:
  /// **'최다 연승'**
  String get longestWinStreak;

  /// No description provided for @homeBiggestWin.
  ///
  /// In ko, this message translates to:
  /// **'홈 최다 득점 승리'**
  String get homeBiggestWin;

  /// No description provided for @awayBiggestWin.
  ///
  /// In ko, this message translates to:
  /// **'원정 최다 득점 승리'**
  String get awayBiggestWin;

  /// No description provided for @homeBiggestLoss.
  ///
  /// In ko, this message translates to:
  /// **'홈 최다 실점 패배'**
  String get homeBiggestLoss;

  /// No description provided for @awayBiggestLoss.
  ///
  /// In ko, this message translates to:
  /// **'원정 최다 실점 패배'**
  String get awayBiggestLoss;

  /// No description provided for @noSchedule.
  ///
  /// In ko, this message translates to:
  /// **'일정이 없습니다'**
  String get noSchedule;

  /// No description provided for @pastMatches.
  ///
  /// In ko, this message translates to:
  /// **'지난 경기'**
  String get pastMatches;

  /// No description provided for @injuredPlayers.
  ///
  /// In ko, this message translates to:
  /// **'부상/결장 선수'**
  String get injuredPlayers;

  /// No description provided for @unknownTeam.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없음'**
  String get unknownTeam;

  /// No description provided for @transferFromTeam.
  ///
  /// In ko, this message translates to:
  /// **'← {teamName}'**
  String transferFromTeam(String teamName);

  /// No description provided for @transferToTeam.
  ///
  /// In ko, this message translates to:
  /// **'→ {teamName}'**
  String transferToTeam(String teamName);

  /// No description provided for @yearsCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}년'**
  String yearsCount(int count);

  /// No description provided for @winStreak.
  ///
  /// In ko, this message translates to:
  /// **'{count}연승'**
  String winStreak(int count);

  /// No description provided for @currentLanguage.
  ///
  /// In ko, this message translates to:
  /// **'현재: {language}'**
  String currentLanguage(String language);

  /// No description provided for @languageChangeNote.
  ///
  /// In ko, this message translates to:
  /// **'언어를 변경하면 앱의 모든 텍스트가 해당 언어로 표시됩니다.'**
  String get languageChangeNote;

  /// No description provided for @profileEdit.
  ///
  /// In ko, this message translates to:
  /// **'프로필 수정'**
  String get profileEdit;

  /// No description provided for @name.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get name;

  /// No description provided for @selectFavoriteTeam.
  ///
  /// In ko, this message translates to:
  /// **'응원팀 선택'**
  String get selectFavoriteTeam;

  /// No description provided for @favoriteTeamDescription.
  ///
  /// In ko, this message translates to:
  /// **'좋아하는 팀을 선택하면 관련 경기 정보를 우선적으로 보여드려요'**
  String get favoriteTeamDescription;

  /// No description provided for @noFavoriteTeam.
  ///
  /// In ko, this message translates to:
  /// **'선택한 팀 없음'**
  String get noFavoriteTeam;

  /// No description provided for @profileSaved.
  ///
  /// In ko, this message translates to:
  /// **'프로필이 저장되었습니다'**
  String get profileSaved;

  /// No description provided for @pleaseEnterName.
  ///
  /// In ko, this message translates to:
  /// **'이름을 입력해주세요'**
  String get pleaseEnterName;

  /// No description provided for @timezoneDescription.
  ///
  /// In ko, this message translates to:
  /// **'경기 시간을 선택한 시간대에 맞춰 표시합니다'**
  String get timezoneDescription;

  /// No description provided for @matchNotifications.
  ///
  /// In ko, this message translates to:
  /// **'경기 알림'**
  String get matchNotifications;

  /// No description provided for @matchNotificationsDesc.
  ///
  /// In ko, this message translates to:
  /// **'경기 시작 전 알림을 받습니다'**
  String get matchNotificationsDesc;

  /// No description provided for @liveScoreNotifications.
  ///
  /// In ko, this message translates to:
  /// **'실시간 점수 알림'**
  String get liveScoreNotifications;

  /// No description provided for @liveScoreNotificationsDesc.
  ///
  /// In ko, this message translates to:
  /// **'골, 레드카드 등 주요 이벤트 알림'**
  String get liveScoreNotificationsDesc;

  /// No description provided for @communityNotifications.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티 알림'**
  String get communityNotifications;

  /// No description provided for @communityNotificationsDesc.
  ///
  /// In ko, this message translates to:
  /// **'좋아요, 댓글 등 새 알림'**
  String get communityNotificationsDesc;

  /// No description provided for @marketingNotifications.
  ///
  /// In ko, this message translates to:
  /// **'마케팅 알림'**
  String get marketingNotifications;

  /// No description provided for @marketingNotificationsDesc.
  ///
  /// In ko, this message translates to:
  /// **'이벤트, 프로모션 등 알림'**
  String get marketingNotificationsDesc;

  /// No description provided for @helpSupport.
  ///
  /// In ko, this message translates to:
  /// **'도움말 및 지원'**
  String get helpSupport;

  /// No description provided for @faq.
  ///
  /// In ko, this message translates to:
  /// **'자주 묻는 질문'**
  String get faq;

  /// No description provided for @contactSupport.
  ///
  /// In ko, this message translates to:
  /// **'고객 지원 문의'**
  String get contactSupport;

  /// No description provided for @enterDisplayName.
  ///
  /// In ko, this message translates to:
  /// **'표시될 이름을 입력하세요'**
  String get enterDisplayName;

  /// No description provided for @email.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get email;

  /// No description provided for @changePassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 변경'**
  String get changePassword;

  /// No description provided for @changePasswordDesc.
  ///
  /// In ko, this message translates to:
  /// **'계정 보안을 위해 정기적으로 변경하세요'**
  String get changePasswordDesc;

  /// No description provided for @deleteAccount.
  ///
  /// In ko, this message translates to:
  /// **'회원 탈퇴'**
  String get deleteAccount;

  /// No description provided for @deleteAccountDesc.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴 시 모든 데이터가 삭제됩니다'**
  String get deleteAccountDesc;

  /// No description provided for @profilePhoto.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진 변경'**
  String get profilePhoto;

  /// No description provided for @selectFromGallery.
  ///
  /// In ko, this message translates to:
  /// **'갤러리에서 선택'**
  String get selectFromGallery;

  /// No description provided for @selectFromGalleryDesc.
  ///
  /// In ko, this message translates to:
  /// **'저장된 사진에서 선택합니다'**
  String get selectFromGalleryDesc;

  /// No description provided for @takePhoto.
  ///
  /// In ko, this message translates to:
  /// **'카메라로 촬영'**
  String get takePhoto;

  /// No description provided for @takePhotoDesc.
  ///
  /// In ko, this message translates to:
  /// **'새로운 사진을 촬영합니다'**
  String get takePhotoDesc;

  /// No description provided for @deletePhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 삭제'**
  String get deletePhoto;

  /// No description provided for @deletePhotoDesc.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진을 제거합니다'**
  String get deletePhotoDesc;

  /// No description provided for @photoUploaded.
  ///
  /// In ko, this message translates to:
  /// **'사진이 업로드되었습니다. 저장을 눌러 적용하세요.'**
  String get photoUploaded;

  /// No description provided for @photoUploadFailed.
  ///
  /// In ko, this message translates to:
  /// **'사진 업로드 실패: {error}'**
  String photoUploadFailed(String error);

  /// No description provided for @photoWillBeDeleted.
  ///
  /// In ko, this message translates to:
  /// **'사진이 삭제됩니다. 저장을 눌러 적용하세요.'**
  String get photoWillBeDeleted;

  /// No description provided for @profileUpdated.
  ///
  /// In ko, this message translates to:
  /// **'프로필이 수정되었습니다'**
  String get profileUpdated;

  /// No description provided for @updateFailed.
  ///
  /// In ko, this message translates to:
  /// **'수정 실패: {error}'**
  String updateFailed(String error);

  /// No description provided for @currentPassword.
  ///
  /// In ko, this message translates to:
  /// **'현재 비밀번호'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호 확인'**
  String get confirmNewPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In ko, this message translates to:
  /// **'8자 이상 입력하세요'**
  String get passwordMinLength;

  /// No description provided for @passwordMismatch.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호가 일치하지 않습니다'**
  String get passwordMismatch;

  /// No description provided for @passwordTooShort.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호는 6자 이상이어야 합니다'**
  String get passwordTooShort;

  /// No description provided for @passwordChangePreparing.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 변경 기능 준비 중'**
  String get passwordChangePreparing;

  /// No description provided for @change.
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get change;

  /// No description provided for @confirmDeleteAccount.
  ///
  /// In ko, this message translates to:
  /// **'정말 탈퇴하시겠습니까?'**
  String get confirmDeleteAccount;

  /// No description provided for @deleteWarningRecords.
  ///
  /// In ko, this message translates to:
  /// **'모든 직관 기록이 삭제됩니다'**
  String get deleteWarningRecords;

  /// No description provided for @deleteWarningFavorites.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기 정보가 삭제됩니다'**
  String get deleteWarningFavorites;

  /// No description provided for @deleteWarningPhoto.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진이 삭제됩니다'**
  String get deleteWarningPhoto;

  /// No description provided for @deleteWarningIrreversible.
  ///
  /// In ko, this message translates to:
  /// **'이 작업은 되돌릴 수 없습니다'**
  String get deleteWarningIrreversible;

  /// No description provided for @deleteAccountPreparing.
  ///
  /// In ko, this message translates to:
  /// **'회원 탈퇴 기능 준비 중'**
  String get deleteAccountPreparing;

  /// No description provided for @timezoneSettingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'타임존 설정'**
  String get timezoneSettingsTitle;

  /// No description provided for @searchTimezone.
  ///
  /// In ko, this message translates to:
  /// **'타임존 검색...'**
  String get searchTimezone;

  /// No description provided for @currentSetting.
  ///
  /// In ko, this message translates to:
  /// **'현재 설정'**
  String get currentSetting;

  /// No description provided for @timezoneChanged.
  ///
  /// In ko, this message translates to:
  /// **'타임존이 {name}으로 변경되었습니다'**
  String timezoneChanged(String name);

  /// No description provided for @timezoneKoreaSeoul.
  ///
  /// In ko, this message translates to:
  /// **'한국 (서울)'**
  String get timezoneKoreaSeoul;

  /// No description provided for @timezoneJapanTokyo.
  ///
  /// In ko, this message translates to:
  /// **'일본 (도쿄)'**
  String get timezoneJapanTokyo;

  /// No description provided for @timezoneChinaShanghai.
  ///
  /// In ko, this message translates to:
  /// **'중국 (상하이)'**
  String get timezoneChinaShanghai;

  /// No description provided for @timezoneSingapore.
  ///
  /// In ko, this message translates to:
  /// **'싱가포르'**
  String get timezoneSingapore;

  /// No description provided for @timezoneHongKong.
  ///
  /// In ko, this message translates to:
  /// **'홍콩'**
  String get timezoneHongKong;

  /// No description provided for @timezoneThailandBangkok.
  ///
  /// In ko, this message translates to:
  /// **'태국 (방콕)'**
  String get timezoneThailandBangkok;

  /// No description provided for @timezoneIndonesiaJakarta.
  ///
  /// In ko, this message translates to:
  /// **'인도네시아 (자카르타)'**
  String get timezoneIndonesiaJakarta;

  /// No description provided for @timezoneIndiaKolkata.
  ///
  /// In ko, this message translates to:
  /// **'인도 (콜카타)'**
  String get timezoneIndiaKolkata;

  /// No description provided for @timezoneUAEDubai.
  ///
  /// In ko, this message translates to:
  /// **'UAE (두바이)'**
  String get timezoneUAEDubai;

  /// No description provided for @timezoneUKLondon.
  ///
  /// In ko, this message translates to:
  /// **'영국 (런던)'**
  String get timezoneUKLondon;

  /// No description provided for @timezoneFranceParis.
  ///
  /// In ko, this message translates to:
  /// **'프랑스 (파리)'**
  String get timezoneFranceParis;

  /// No description provided for @timezoneGermanyBerlin.
  ///
  /// In ko, this message translates to:
  /// **'독일 (베를린)'**
  String get timezoneGermanyBerlin;

  /// No description provided for @timezoneItalyRome.
  ///
  /// In ko, this message translates to:
  /// **'이탈리아 (로마)'**
  String get timezoneItalyRome;

  /// No description provided for @timezoneSpainMadrid.
  ///
  /// In ko, this message translates to:
  /// **'스페인 (마드리드)'**
  String get timezoneSpainMadrid;

  /// No description provided for @timezoneNetherlandsAmsterdam.
  ///
  /// In ko, this message translates to:
  /// **'네덜란드 (암스테르담)'**
  String get timezoneNetherlandsAmsterdam;

  /// No description provided for @timezoneRussiaMoscow.
  ///
  /// In ko, this message translates to:
  /// **'러시아 (모스크바)'**
  String get timezoneRussiaMoscow;

  /// No description provided for @timezoneUSEastNewYork.
  ///
  /// In ko, this message translates to:
  /// **'미국 동부 (뉴욕)'**
  String get timezoneUSEastNewYork;

  /// No description provided for @timezoneUSWestLA.
  ///
  /// In ko, this message translates to:
  /// **'미국 서부 (LA)'**
  String get timezoneUSWestLA;

  /// No description provided for @timezoneUSCentralChicago.
  ///
  /// In ko, this message translates to:
  /// **'미국 중부 (시카고)'**
  String get timezoneUSCentralChicago;

  /// No description provided for @timezoneBrazilSaoPaulo.
  ///
  /// In ko, this message translates to:
  /// **'브라질 (상파울루)'**
  String get timezoneBrazilSaoPaulo;

  /// No description provided for @timezoneAustraliaSydney.
  ///
  /// In ko, this message translates to:
  /// **'호주 (시드니)'**
  String get timezoneAustraliaSydney;

  /// No description provided for @timezoneNewZealandAuckland.
  ///
  /// In ko, this message translates to:
  /// **'뉴질랜드 (오클랜드)'**
  String get timezoneNewZealandAuckland;

  /// No description provided for @pushNotifications.
  ///
  /// In ko, this message translates to:
  /// **'푸시 알림'**
  String get pushNotifications;

  /// No description provided for @receivePushNotifications.
  ///
  /// In ko, this message translates to:
  /// **'푸시 알림 받기'**
  String get receivePushNotifications;

  /// No description provided for @masterSwitch.
  ///
  /// In ko, this message translates to:
  /// **'모든 알림의 마스터 스위치'**
  String get masterSwitch;

  /// No description provided for @favoriteTeamMatchNotifications.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기 팀 경기 알림'**
  String get favoriteTeamMatchNotifications;

  /// No description provided for @favoriteTeamMatchNotificationsDesc.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기한 팀의 경기에 대한 알림을 설정합니다'**
  String get favoriteTeamMatchNotificationsDesc;

  /// No description provided for @matchStartNotification.
  ///
  /// In ko, this message translates to:
  /// **'경기 시작 알림'**
  String get matchStartNotification;

  /// No description provided for @matchStartNotificationDesc.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기 팀 경기 시작 전 미리 알림'**
  String get matchStartNotificationDesc;

  /// No description provided for @notificationTime.
  ///
  /// In ko, this message translates to:
  /// **'알림 시간'**
  String get notificationTime;

  /// No description provided for @notificationTimeDesc.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기 팀 경기 시작 전 알림 시간'**
  String get notificationTimeDesc;

  /// No description provided for @minutes15Before.
  ///
  /// In ko, this message translates to:
  /// **'15분 전'**
  String get minutes15Before;

  /// No description provided for @minutes30Before.
  ///
  /// In ko, this message translates to:
  /// **'30분 전'**
  String get minutes30Before;

  /// No description provided for @hour1Before.
  ///
  /// In ko, this message translates to:
  /// **'1시간 전'**
  String get hour1Before;

  /// No description provided for @hours2Before.
  ///
  /// In ko, this message translates to:
  /// **'2시간 전'**
  String get hours2Before;

  /// No description provided for @newMatchScheduleNotification.
  ///
  /// In ko, this message translates to:
  /// **'새 경기 일정 알림'**
  String get newMatchScheduleNotification;

  /// No description provided for @newMatchScheduleNotificationDesc.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기 팀의 새로운 경기 일정 등록 알림'**
  String get newMatchScheduleNotificationDesc;

  /// No description provided for @favoriteTeamLiveNotifications.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기 팀 실시간 알림'**
  String get favoriteTeamLiveNotifications;

  /// No description provided for @favoriteTeamLiveNotificationsDesc.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기한 팀의 경기 중 실시간 알림을 설정합니다'**
  String get favoriteTeamLiveNotificationsDesc;

  /// No description provided for @liveScoreUpdates.
  ///
  /// In ko, this message translates to:
  /// **'라이브 스코어 업데이트'**
  String get liveScoreUpdates;

  /// No description provided for @liveScoreUpdatesDesc.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기 팀 경기 중 골/이벤트 실시간 알림'**
  String get liveScoreUpdatesDesc;

  /// No description provided for @favoritePlayerLiveNotifications.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기 선수 실시간 알림'**
  String get favoritePlayerLiveNotifications;

  /// No description provided for @favoritePlayerLiveNotificationsDesc.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기한 선수의 이벤트 발생 시 알림을 설정합니다'**
  String get favoritePlayerLiveNotificationsDesc;

  /// No description provided for @favoritePlayerEvents.
  ///
  /// In ko, this message translates to:
  /// **'선수 이벤트 알림'**
  String get favoritePlayerEvents;

  /// No description provided for @favoritePlayerEventsDesc.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기 선수 골/어시스트/레드카드 알림'**
  String get favoritePlayerEventsDesc;

  /// No description provided for @lineupNotifications.
  ///
  /// In ko, this message translates to:
  /// **'라인업 알림'**
  String get lineupNotifications;

  /// No description provided for @lineupNotificationsDesc.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기 팀 경기 라인업 발표 시 알림'**
  String get lineupNotificationsDesc;

  /// No description provided for @resultNotifications.
  ///
  /// In ko, this message translates to:
  /// **'경기 결과 알림'**
  String get resultNotifications;

  /// No description provided for @resultNotificationsDesc.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기 팀 경기 종료 시 결과 알림'**
  String get resultNotificationsDesc;

  /// No description provided for @notificationPermissionGuide.
  ///
  /// In ko, this message translates to:
  /// **'알림 권한 안내'**
  String get notificationPermissionGuide;

  /// No description provided for @notificationPermissionDesc.
  ///
  /// In ko, this message translates to:
  /// **'알림을 받으려면 기기 설정에서 FootHub 앱의 알림 권한을 허용해주세요.'**
  String get notificationPermissionDesc;

  /// No description provided for @errorWithMsg.
  ///
  /// In ko, this message translates to:
  /// **'오류 발생: {error}'**
  String errorWithMsg(String error);

  /// No description provided for @helpAndSupportTitle.
  ///
  /// In ko, this message translates to:
  /// **'도움말 및 지원'**
  String get helpAndSupportTitle;

  /// No description provided for @faqTitle.
  ///
  /// In ko, this message translates to:
  /// **'자주 묻는 질문'**
  String get faqTitle;

  /// No description provided for @contactUs.
  ///
  /// In ko, this message translates to:
  /// **'문의하기'**
  String get contactUs;

  /// No description provided for @appInfo.
  ///
  /// In ko, this message translates to:
  /// **'앱 정보'**
  String get appInfo;

  /// No description provided for @emailInquiry.
  ///
  /// In ko, this message translates to:
  /// **'이메일 문의'**
  String get emailInquiry;

  /// No description provided for @bugReport.
  ///
  /// In ko, this message translates to:
  /// **'버그 신고'**
  String get bugReport;

  /// No description provided for @bugReportDesc.
  ///
  /// In ko, this message translates to:
  /// **'오류나 문제점을 알려주세요'**
  String get bugReportDesc;

  /// No description provided for @featureSuggestion.
  ///
  /// In ko, this message translates to:
  /// **'기능 제안'**
  String get featureSuggestion;

  /// No description provided for @featureSuggestionDesc.
  ///
  /// In ko, this message translates to:
  /// **'새로운 아이디어를 공유해주세요'**
  String get featureSuggestionDesc;

  /// No description provided for @appVersionLabel.
  ///
  /// In ko, this message translates to:
  /// **'앱 버전'**
  String get appVersionLabel;

  /// No description provided for @buildNumber.
  ///
  /// In ko, this message translates to:
  /// **'빌드 번호'**
  String get buildNumber;

  /// No description provided for @developer.
  ///
  /// In ko, this message translates to:
  /// **'개발자'**
  String get developer;

  /// No description provided for @patchNotes.
  ///
  /// In ko, this message translates to:
  /// **'패치노트'**
  String get patchNotes;

  /// No description provided for @emailCopied.
  ///
  /// In ko, this message translates to:
  /// **'이메일 앱을 열 수 없어 주소가 복사되었습니다'**
  String get emailCopied;

  /// No description provided for @bugReportHint.
  ///
  /// In ko, this message translates to:
  /// **'발견한 버그나 문제점을 자세히 설명해주세요...'**
  String get bugReportHint;

  /// No description provided for @featureSuggestionHint.
  ///
  /// In ko, this message translates to:
  /// **'원하시는 기능을 자세히 설명해주세요...'**
  String get featureSuggestionHint;

  /// No description provided for @submit.
  ///
  /// In ko, this message translates to:
  /// **'제출'**
  String get submit;

  /// No description provided for @legalInfo.
  ///
  /// In ko, this message translates to:
  /// **'법적 정보'**
  String get legalInfo;

  /// No description provided for @privacyPolicy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보처리방침'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In ko, this message translates to:
  /// **'이용약관'**
  String get termsOfService;

  /// No description provided for @supportWebsite.
  ///
  /// In ko, this message translates to:
  /// **'지원 웹사이트'**
  String get supportWebsite;

  /// No description provided for @faqAddRecord.
  ///
  /// In ko, this message translates to:
  /// **'직관 기록은 어떻게 추가하나요?'**
  String get faqAddRecord;

  /// No description provided for @faqAddRecordAnswer.
  ///
  /// In ko, this message translates to:
  /// **'홈 화면이나 직관 일기 탭에서 + 버튼을 눌러 새로운 직관 기록을 추가할 수 있습니다. 경기 일정에서 원하는 경기를 선택한 후 \"직관 기록\" 버튼을 눌러도 됩니다.'**
  String get faqAddRecordAnswer;

  /// No description provided for @faqAddFavorite.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기 팀은 어떻게 추가하나요?'**
  String get faqAddFavorite;

  /// No description provided for @faqAddFavoriteAnswer.
  ///
  /// In ko, this message translates to:
  /// **'내 정보 탭에서 즐겨찾기 섹션의 \"관리\" 버튼을 누르거나, 팀 상세 페이지에서 하트 버튼을 눌러 즐겨찾기에 추가할 수 있습니다.'**
  String get faqAddFavoriteAnswer;

  /// No description provided for @faqSchedule.
  ///
  /// In ko, this message translates to:
  /// **'경기 일정은 어디서 확인하나요?'**
  String get faqSchedule;

  /// No description provided for @faqScheduleAnswer.
  ///
  /// In ko, this message translates to:
  /// **'하단 메뉴의 \"일정\" 탭에서 캘린더 형태로 경기 일정을 확인할 수 있습니다. 리그별로 필터링도 가능합니다.'**
  String get faqScheduleAnswer;

  /// No description provided for @faqNotification.
  ///
  /// In ko, this message translates to:
  /// **'알림은 어떻게 설정하나요?'**
  String get faqNotification;

  /// No description provided for @faqNotificationAnswer.
  ///
  /// In ko, this message translates to:
  /// **'내 정보 > 알림 설정에서 경기 시작 알림, 즐겨찾기 팀 경기 알림 등을 설정할 수 있습니다.'**
  String get faqNotificationAnswer;

  /// No description provided for @faqSupportedLeagues.
  ///
  /// In ko, this message translates to:
  /// **'지원하는 리그는 무엇인가요?'**
  String get faqSupportedLeagues;

  /// No description provided for @faqSupportedLeaguesAnswer.
  ///
  /// In ko, this message translates to:
  /// **'EPL(잉글랜드), 라리가(스페인), 분데스리가(독일), 세리에A(이탈리아), 리그앙(프랑스), K리그, 챔피언스리그, 유로파리그, 컨퍼런스리그를 지원합니다.'**
  String get faqSupportedLeaguesAnswer;

  /// No description provided for @userDefault.
  ///
  /// In ko, this message translates to:
  /// **'사용자'**
  String get userDefault;

  /// No description provided for @emptyAttendanceTitle.
  ///
  /// In ko, this message translates to:
  /// **'직관 기록이 없습니다'**
  String get emptyAttendanceTitle;

  /// No description provided for @emptyAttendanceSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'첫 번째 경기 직관을 기록해보세요!'**
  String get emptyAttendanceSubtitle;

  /// No description provided for @addRecord.
  ///
  /// In ko, this message translates to:
  /// **'기록 추가'**
  String get addRecord;

  /// No description provided for @emptyDiaryTitle.
  ///
  /// In ko, this message translates to:
  /// **'다이어리 기록이 없습니다'**
  String get emptyDiaryTitle;

  /// No description provided for @emptyDiarySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'경기를 보고 기록해보세요!'**
  String get emptyDiarySubtitle;

  /// No description provided for @viewSchedule.
  ///
  /// In ko, this message translates to:
  /// **'일정 보기'**
  String get viewSchedule;

  /// No description provided for @emptyScheduleTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘 경기가 없습니다'**
  String get emptyScheduleTitle;

  /// No description provided for @emptyScheduleSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'다른 날짜를 선택해보세요'**
  String get emptyScheduleSubtitle;

  /// No description provided for @emptyFavoritesTitle.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기가 없습니다'**
  String get emptyFavoritesTitle;

  /// No description provided for @emptyFavoritesSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'좋아하는 팀과 선수를 추가해보세요!'**
  String get emptyFavoritesSubtitle;

  /// No description provided for @findTeam.
  ///
  /// In ko, this message translates to:
  /// **'팀 찾기'**
  String get findTeam;

  /// No description provided for @emptySearchTitle.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
  String get emptySearchTitle;

  /// No description provided for @emptySearchSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'\"{query}\"에 대한 결과가 없습니다'**
  String emptySearchSubtitle(String query);

  /// No description provided for @errorTitle.
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다'**
  String get errorTitle;

  /// No description provided for @errorDefaultSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도해주세요'**
  String get errorDefaultSubtitle;

  /// No description provided for @anonymous.
  ///
  /// In ko, this message translates to:
  /// **'익명'**
  String get anonymous;

  /// No description provided for @monthJan.
  ///
  /// In ko, this message translates to:
  /// **'1월'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In ko, this message translates to:
  /// **'2월'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In ko, this message translates to:
  /// **'3월'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In ko, this message translates to:
  /// **'4월'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In ko, this message translates to:
  /// **'5월'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In ko, this message translates to:
  /// **'6월'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In ko, this message translates to:
  /// **'7월'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In ko, this message translates to:
  /// **'8월'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In ko, this message translates to:
  /// **'9월'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In ko, this message translates to:
  /// **'10월'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In ko, this message translates to:
  /// **'11월'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In ko, this message translates to:
  /// **'12월'**
  String get monthDec;

  /// No description provided for @yearMonthFormat.
  ///
  /// In ko, this message translates to:
  /// **'{year}년 {month}월'**
  String yearMonthFormat(int year, int month);

  /// No description provided for @post.
  ///
  /// In ko, this message translates to:
  /// **'게시글'**
  String get post;

  /// No description provided for @postDeleted.
  ///
  /// In ko, this message translates to:
  /// **'게시글이 삭제되었습니다'**
  String get postDeleted;

  /// No description provided for @deletePost.
  ///
  /// In ko, this message translates to:
  /// **'게시글 삭제'**
  String get deletePost;

  /// No description provided for @deletePostConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 게시글을 삭제하시겠습니까?'**
  String get deletePostConfirm;

  /// No description provided for @postNotFound.
  ///
  /// In ko, this message translates to:
  /// **'게시글을 찾을 수 없습니다'**
  String get postNotFound;

  /// No description provided for @comment.
  ///
  /// In ko, this message translates to:
  /// **'댓글'**
  String get comment;

  /// No description provided for @commentCount.
  ///
  /// In ko, this message translates to:
  /// **'댓글 {count}'**
  String commentCount(int count);

  /// No description provided for @enterComment.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 입력하세요'**
  String get enterComment;

  /// No description provided for @loadCommentsFailed.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 불러오는데 실패했습니다: {error}'**
  String loadCommentsFailed(String error);

  /// No description provided for @myAttendanceStats.
  ///
  /// In ko, this message translates to:
  /// **'나의 직관 통계'**
  String get myAttendanceStats;

  /// No description provided for @totalAttendance.
  ///
  /// In ko, this message translates to:
  /// **'총 직관'**
  String get totalAttendance;

  /// No description provided for @attendanceCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}경기'**
  String attendanceCount(int count);

  /// No description provided for @winRatePercent.
  ///
  /// In ko, this message translates to:
  /// **'{rate}%'**
  String winRatePercent(String rate);

  /// No description provided for @mostVisited.
  ///
  /// In ko, this message translates to:
  /// **'최다 방문: {stadium} ({count}회)'**
  String mostVisited(String stadium, int count);

  /// No description provided for @minutesAgo.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분 전'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 전'**
  String hoursAgo(int hours);

  /// No description provided for @daysAgo.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 전'**
  String daysAgo(int days);

  /// No description provided for @attendanceStats.
  ///
  /// In ko, this message translates to:
  /// **'직관 통계'**
  String get attendanceStats;

  /// No description provided for @frequentStadiums.
  ///
  /// In ko, this message translates to:
  /// **'자주 가는 구장'**
  String get frequentStadiums;

  /// No description provided for @noAttendanceRecordsYet.
  ///
  /// In ko, this message translates to:
  /// **'아직 직관 기록이 없습니다'**
  String get noAttendanceRecordsYet;

  /// No description provided for @postsLabel.
  ///
  /// In ko, this message translates to:
  /// **'게시글'**
  String get postsLabel;

  /// No description provided for @attendanceLabel.
  ///
  /// In ko, this message translates to:
  /// **'직관'**
  String get attendanceLabel;

  /// No description provided for @championship.
  ///
  /// In ko, this message translates to:
  /// **'챔피언십'**
  String get championship;

  /// No description provided for @lowerSplit.
  ///
  /// In ko, this message translates to:
  /// **'하위 스플릿'**
  String get lowerSplit;

  /// No description provided for @promotionPlayoff.
  ///
  /// In ko, this message translates to:
  /// **'승격 PO'**
  String get promotionPlayoff;

  /// No description provided for @competition.
  ///
  /// In ko, this message translates to:
  /// **'대회'**
  String get competition;

  /// No description provided for @seasonFormatChanged.
  ///
  /// In ko, this message translates to:
  /// **'2024-25 시즌부터 새 리그 형식으로 변경되어'**
  String get seasonFormatChanged;

  /// No description provided for @standingsNotAvailable.
  ///
  /// In ko, this message translates to:
  /// **'순위표가 아직 제공되지 않습니다'**
  String get standingsNotAvailable;

  /// No description provided for @checkScheduleTab.
  ///
  /// In ko, this message translates to:
  /// **'일정 탭에서 경기 일정을 확인하세요'**
  String get checkScheduleTab;

  /// No description provided for @rankHeader.
  ///
  /// In ko, this message translates to:
  /// **'순위'**
  String get rankHeader;

  /// No description provided for @playerHeader.
  ///
  /// In ko, this message translates to:
  /// **'선수'**
  String get playerHeader;

  /// No description provided for @appsHeader.
  ///
  /// In ko, this message translates to:
  /// **'출전'**
  String get appsHeader;

  /// No description provided for @goalsHeader.
  ///
  /// In ko, this message translates to:
  /// **'득점'**
  String get goalsHeader;

  /// No description provided for @assistsHeader.
  ///
  /// In ko, this message translates to:
  /// **'어시'**
  String get assistsHeader;

  /// No description provided for @teamHeader.
  ///
  /// In ko, this message translates to:
  /// **'팀'**
  String get teamHeader;

  /// No description provided for @matchesHeader.
  ///
  /// In ko, this message translates to:
  /// **'경기'**
  String get matchesHeader;

  /// No description provided for @wonHeader.
  ///
  /// In ko, this message translates to:
  /// **'승'**
  String get wonHeader;

  /// No description provided for @drawnHeader.
  ///
  /// In ko, this message translates to:
  /// **'무'**
  String get drawnHeader;

  /// No description provided for @lostHeader.
  ///
  /// In ko, this message translates to:
  /// **'패'**
  String get lostHeader;

  /// No description provided for @gfHeader.
  ///
  /// In ko, this message translates to:
  /// **'득점'**
  String get gfHeader;

  /// No description provided for @gaHeader.
  ///
  /// In ko, this message translates to:
  /// **'실점'**
  String get gaHeader;

  /// No description provided for @gdHeader.
  ///
  /// In ko, this message translates to:
  /// **'득실'**
  String get gdHeader;

  /// No description provided for @ptsHeader.
  ///
  /// In ko, this message translates to:
  /// **'승점'**
  String get ptsHeader;

  /// No description provided for @recentFormTitle.
  ///
  /// In ko, this message translates to:
  /// **'최근 폼'**
  String get recentFormTitle;

  /// No description provided for @homeAwayStrong.
  ///
  /// In ko, this message translates to:
  /// **'홈/원정 강자'**
  String get homeAwayStrong;

  /// No description provided for @homeStrong.
  ///
  /// In ko, this message translates to:
  /// **'홈 강자'**
  String get homeStrong;

  /// No description provided for @awayStrong.
  ///
  /// In ko, this message translates to:
  /// **'원정 강자'**
  String get awayStrong;

  /// No description provided for @bottomAnalysisTitle.
  ///
  /// In ko, this message translates to:
  /// **'하위권 분석'**
  String get bottomAnalysisTitle;

  /// No description provided for @mostLossesLabel.
  ///
  /// In ko, this message translates to:
  /// **'최다 패배'**
  String get mostLossesLabel;

  /// No description provided for @lossesCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}패'**
  String lossesCount(int count);

  /// No description provided for @mostConcededLabel.
  ///
  /// In ko, this message translates to:
  /// **'최다 실점'**
  String get mostConcededLabel;

  /// No description provided for @concededCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}실점'**
  String concededCount(int count);

  /// No description provided for @leagueOverviewTitle.
  ///
  /// In ko, this message translates to:
  /// **'리그 개요'**
  String get leagueOverviewTitle;

  /// No description provided for @totalGoalsLabel.
  ///
  /// In ko, this message translates to:
  /// **'총 골'**
  String get totalGoalsLabel;

  /// No description provided for @goalsPerGameLabel.
  ///
  /// In ko, this message translates to:
  /// **'경기당 골'**
  String get goalsPerGameLabel;

  /// No description provided for @homeWinsLabel.
  ///
  /// In ko, this message translates to:
  /// **'홈 승리'**
  String get homeWinsLabel;

  /// No description provided for @awayWinsLabel.
  ///
  /// In ko, this message translates to:
  /// **'원정 승리'**
  String get awayWinsLabel;

  /// No description provided for @homeWinShort.
  ///
  /// In ko, this message translates to:
  /// **'홈 승'**
  String get homeWinShort;

  /// No description provided for @awayWinShort.
  ///
  /// In ko, this message translates to:
  /// **'원정 승'**
  String get awayWinShort;

  /// No description provided for @gamesCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}경기'**
  String gamesCount(int count);

  /// No description provided for @recentMatchRecords.
  ///
  /// In ko, this message translates to:
  /// **'최근 직관 기록'**
  String get recentMatchRecords;

  /// No description provided for @totalCount.
  ///
  /// In ko, this message translates to:
  /// **'총 {count}개'**
  String totalCount(int count);

  /// No description provided for @searchTitleContentAuthor.
  ///
  /// In ko, this message translates to:
  /// **'제목, 내용, 작성자 검색'**
  String get searchTitleContentAuthor;

  /// No description provided for @hasMatchRecord.
  ///
  /// In ko, this message translates to:
  /// **'직관 기록 있음'**
  String get hasMatchRecord;

  /// No description provided for @clearAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 해제'**
  String get clearAll;

  /// No description provided for @noPostsYet.
  ///
  /// In ko, this message translates to:
  /// **'아직 게시글이 없습니다'**
  String get noPostsYet;

  /// No description provided for @writeFirstPost.
  ///
  /// In ko, this message translates to:
  /// **'첫 번째 게시글을 작성해보세요!'**
  String get writeFirstPost;

  /// No description provided for @writePost.
  ///
  /// In ko, this message translates to:
  /// **'글쓰기'**
  String get writePost;

  /// No description provided for @noSearchResultsForQuery.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
  String get noSearchResultsForQuery;

  /// No description provided for @clearSearchQuery.
  ///
  /// In ko, this message translates to:
  /// **'검색어 지우기'**
  String get clearSearchQuery;

  /// No description provided for @reset.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get reset;

  /// No description provided for @showOnlyWithMatchRecord.
  ///
  /// In ko, this message translates to:
  /// **'직관 기록이 있는 게시글만 보기'**
  String get showOnlyWithMatchRecord;

  /// No description provided for @matchDate.
  ///
  /// In ko, this message translates to:
  /// **'경기 날짜'**
  String get matchDate;

  /// No description provided for @selectLeagueFilter.
  ///
  /// In ko, this message translates to:
  /// **'리그 선택'**
  String get selectLeagueFilter;

  /// No description provided for @allLeagues.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get allLeagues;

  /// No description provided for @searching.
  ///
  /// In ko, this message translates to:
  /// **'검색 중...'**
  String get searching;

  /// No description provided for @searchMatch.
  ///
  /// In ko, this message translates to:
  /// **'경기 검색'**
  String get searchMatch;

  /// No description provided for @searchResultsCount.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과 ({count})'**
  String searchResultsCount(int count);

  /// No description provided for @noMatchesOnDate.
  ///
  /// In ko, this message translates to:
  /// **'해당 날짜에 경기가 없습니다'**
  String get noMatchesOnDate;

  /// No description provided for @moreMatchesCount.
  ///
  /// In ko, this message translates to:
  /// **'외 {count}개 더 있음'**
  String moreMatchesCount(int count);

  /// No description provided for @applySelectedMatch.
  ///
  /// In ko, this message translates to:
  /// **'선택한 경기로 필터 적용'**
  String get applySelectedMatch;

  /// No description provided for @apply.
  ///
  /// In ko, this message translates to:
  /// **'적용하기'**
  String get apply;

  /// No description provided for @selected.
  ///
  /// In ko, this message translates to:
  /// **'선택됨'**
  String get selected;

  /// No description provided for @enterTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목을 입력해주세요'**
  String get enterTitle;

  /// No description provided for @enterContent.
  ///
  /// In ko, this message translates to:
  /// **'내용을 입력해주세요'**
  String get enterContent;

  /// No description provided for @postEdited.
  ///
  /// In ko, this message translates to:
  /// **'게시글이 수정되었습니다'**
  String get postEdited;

  /// No description provided for @postCreated.
  ///
  /// In ko, this message translates to:
  /// **'게시글이 작성되었습니다'**
  String get postCreated;

  /// No description provided for @selectMatchRecord.
  ///
  /// In ko, this message translates to:
  /// **'직관 기록 선택'**
  String get selectMatchRecord;

  /// No description provided for @deselectRecord.
  ///
  /// In ko, this message translates to:
  /// **'선택 해제'**
  String get deselectRecord;

  /// No description provided for @loadingStats.
  ///
  /// In ko, this message translates to:
  /// **'통계를 불러오는 중...'**
  String get loadingStats;

  /// No description provided for @myAttendanceStatsTitle.
  ///
  /// In ko, this message translates to:
  /// **'나의 직관 통계'**
  String get myAttendanceStatsTitle;

  /// No description provided for @totalMatchesCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}경기'**
  String totalMatchesCount(int count);

  /// No description provided for @winRatePercentValue.
  ///
  /// In ko, this message translates to:
  /// **'{rate}%'**
  String winRatePercentValue(String rate);

  /// No description provided for @mostVisitedStadium.
  ///
  /// In ko, this message translates to:
  /// **'최다 방문: {stadium} ({count}회)'**
  String mostVisitedStadium(String stadium, int count);

  /// No description provided for @editPost.
  ///
  /// In ko, this message translates to:
  /// **'글 수정'**
  String get editPost;

  /// No description provided for @register.
  ///
  /// In ko, this message translates to:
  /// **'등록'**
  String get register;

  /// No description provided for @enterTitleHint.
  ///
  /// In ko, this message translates to:
  /// **'제목을 입력하세요'**
  String get enterTitleHint;

  /// No description provided for @matchRecordLabel.
  ///
  /// In ko, this message translates to:
  /// **'직관 기록'**
  String get matchRecordLabel;

  /// No description provided for @loadMyMatchRecord.
  ///
  /// In ko, this message translates to:
  /// **'나의 직관 기록 불러오기 (선택)'**
  String get loadMyMatchRecord;

  /// No description provided for @myAttendanceStatsLabel.
  ///
  /// In ko, this message translates to:
  /// **'나의 직관 통계'**
  String get myAttendanceStatsLabel;

  /// No description provided for @showMyStats.
  ///
  /// In ko, this message translates to:
  /// **'나의 직관 통계 자랑하기 (선택)'**
  String get showMyStats;

  /// No description provided for @contentHint.
  ///
  /// In ko, this message translates to:
  /// **'내용을 입력하세요\n\n직관 후기, 경기 정보, 꿀팁 등을 자유롭게 공유해보세요!'**
  String get contentHint;

  /// No description provided for @tagsOptional.
  ///
  /// In ko, this message translates to:
  /// **'태그 (선택)'**
  String get tagsOptional;

  /// No description provided for @tagInputHint.
  ///
  /// In ko, this message translates to:
  /// **'태그 입력 (최대 5개)'**
  String get tagInputHint;

  /// No description provided for @add.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get add;

  /// No description provided for @communityGuideline.
  ///
  /// In ko, this message translates to:
  /// **'타인을 비방하거나 불쾌감을 주는 내용은 삭제될 수 있습니다.'**
  String get communityGuideline;

  /// No description provided for @postNotFoundError.
  ///
  /// In ko, this message translates to:
  /// **'게시글을 찾을 수 없습니다'**
  String get postNotFoundError;

  /// No description provided for @noEditPermission.
  ///
  /// In ko, this message translates to:
  /// **'수정 권한이 없습니다'**
  String get noEditPermission;

  /// No description provided for @noDeletePermission.
  ///
  /// In ko, this message translates to:
  /// **'삭제 권한이 없습니다'**
  String get noDeletePermission;

  /// No description provided for @commentNotFoundError.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 찾을 수 없습니다'**
  String get commentNotFoundError;

  /// No description provided for @matchLog.
  ///
  /// In ko, this message translates to:
  /// **'FootHub'**
  String get matchLog;

  /// No description provided for @myFootballRecord.
  ///
  /// In ko, this message translates to:
  /// **'나만의 축구 직관 기록'**
  String get myFootballRecord;

  /// No description provided for @emailLabel.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get passwordLabel;

  /// No description provided for @enterEmail.
  ///
  /// In ko, this message translates to:
  /// **'이메일을 입력해주세요'**
  String get enterEmail;

  /// No description provided for @invalidEmailFormat.
  ///
  /// In ko, this message translates to:
  /// **'올바른 이메일 형식을 입력해주세요'**
  String get invalidEmailFormat;

  /// No description provided for @enterPasswordPlease.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 입력해주세요'**
  String get enterPasswordPlease;

  /// No description provided for @loginAction.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get loginAction;

  /// No description provided for @signUpAction.
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get signUpAction;

  /// No description provided for @noAccountSignUp.
  ///
  /// In ko, this message translates to:
  /// **'계정이 없으신가요? 회원가입'**
  String get noAccountSignUp;

  /// No description provided for @hasAccountLogin.
  ///
  /// In ko, this message translates to:
  /// **'이미 계정이 있으신가요? 로그인'**
  String get hasAccountLogin;

  /// No description provided for @orDivider.
  ///
  /// In ko, this message translates to:
  /// **'또는'**
  String get orDivider;

  /// No description provided for @continueWithGoogle.
  ///
  /// In ko, this message translates to:
  /// **'Google로 계속하기'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In ko, this message translates to:
  /// **'Apple로 계속하기'**
  String get continueWithApple;

  /// No description provided for @forgotPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 잊으셨나요?'**
  String get forgotPassword;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In ko, this message translates to:
  /// **'이미 사용 중인 이메일입니다'**
  String get emailAlreadyInUse;

  /// No description provided for @invalidEmailError.
  ///
  /// In ko, this message translates to:
  /// **'올바르지 않은 이메일 형식입니다'**
  String get invalidEmailError;

  /// No description provided for @weakPasswordError.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 너무 약합니다'**
  String get weakPasswordError;

  /// No description provided for @userNotFoundError.
  ///
  /// In ko, this message translates to:
  /// **'등록되지 않은 이메일입니다'**
  String get userNotFoundError;

  /// No description provided for @wrongPasswordError.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 올바르지 않습니다'**
  String get wrongPasswordError;

  /// No description provided for @authServiceUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'인증 서비스를 사용할 수 없습니다. 잠시 후 다시 시도해주세요.'**
  String get authServiceUnavailable;

  /// No description provided for @genericAuthError.
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다. 다시 시도해주세요.'**
  String get genericAuthError;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 재설정'**
  String get resetPasswordTitle;

  /// No description provided for @enterRegisteredEmail.
  ///
  /// In ko, this message translates to:
  /// **'가입한 이메일을 입력하세요'**
  String get enterRegisteredEmail;

  /// No description provided for @sendButton.
  ///
  /// In ko, this message translates to:
  /// **'보내기'**
  String get sendButton;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 재설정 이메일을 보냈습니다'**
  String get passwordResetEmailSent;

  /// No description provided for @untilOpening.
  ///
  /// In ko, this message translates to:
  /// **'개막까지'**
  String get untilOpening;

  /// No description provided for @scheduleTab.
  ///
  /// In ko, this message translates to:
  /// **'일정'**
  String get scheduleTab;

  /// No description provided for @infoTab.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get infoTab;

  /// No description provided for @squadTab.
  ///
  /// In ko, this message translates to:
  /// **'선수단'**
  String get squadTab;

  /// No description provided for @selectCountryButton.
  ///
  /// In ko, this message translates to:
  /// **'국가 선택하기'**
  String get selectCountryButton;

  /// No description provided for @errorPrefix.
  ///
  /// In ko, this message translates to:
  /// **'오류'**
  String get errorPrefix;

  /// No description provided for @cannotLoadTeamInfo.
  ///
  /// In ko, this message translates to:
  /// **'팀 정보를 불러올 수 없습니다'**
  String get cannotLoadTeamInfo;

  /// No description provided for @basicInfoSection.
  ///
  /// In ko, this message translates to:
  /// **'기본 정보'**
  String get basicInfoSection;

  /// No description provided for @countryLabel.
  ///
  /// In ko, this message translates to:
  /// **'국가'**
  String get countryLabel;

  /// No description provided for @homeStadiumLabel.
  ///
  /// In ko, this message translates to:
  /// **'홈 경기장'**
  String get homeStadiumLabel;

  /// No description provided for @capacityLabel.
  ///
  /// In ko, this message translates to:
  /// **'수용 인원'**
  String get capacityLabel;

  /// No description provided for @capacityValue.
  ///
  /// In ko, this message translates to:
  /// **'{count}명'**
  String capacityValue(int count);

  /// No description provided for @foundedLabel.
  ///
  /// In ko, this message translates to:
  /// **'창단'**
  String get foundedLabel;

  /// No description provided for @last5Form.
  ///
  /// In ko, this message translates to:
  /// **'최근 5경기 폼'**
  String get last5Form;

  /// No description provided for @noFormInfo.
  ///
  /// In ko, this message translates to:
  /// **'폼 정보가 없습니다'**
  String get noFormInfo;

  /// No description provided for @loseShort.
  ///
  /// In ko, this message translates to:
  /// **'패'**
  String get loseShort;

  /// No description provided for @cannotLoadFormInfo.
  ///
  /// In ko, this message translates to:
  /// **'폼 정보를 불러올 수 없습니다'**
  String get cannotLoadFormInfo;

  /// No description provided for @competitionsSection.
  ///
  /// In ko, this message translates to:
  /// **'참가 대회'**
  String get competitionsSection;

  /// No description provided for @tapForLeagueDetail.
  ///
  /// In ko, this message translates to:
  /// **'탭하여 리그 상세'**
  String get tapForLeagueDetail;

  /// No description provided for @noCompetitionInfo.
  ///
  /// In ko, this message translates to:
  /// **'참가 대회 정보가 없습니다'**
  String get noCompetitionInfo;

  /// No description provided for @cannotLoadCompetitionInfo.
  ///
  /// In ko, this message translates to:
  /// **'대회 정보를 불러올 수 없습니다'**
  String get cannotLoadCompetitionInfo;

  /// No description provided for @noSquadInfo.
  ///
  /// In ko, this message translates to:
  /// **'선수단 정보가 없습니다'**
  String get noSquadInfo;

  /// No description provided for @goalkeepersSection.
  ///
  /// In ko, this message translates to:
  /// **'골키퍼'**
  String get goalkeepersSection;

  /// No description provided for @defendersSection.
  ///
  /// In ko, this message translates to:
  /// **'수비수'**
  String get defendersSection;

  /// No description provided for @midfieldersSection.
  ///
  /// In ko, this message translates to:
  /// **'미드필더'**
  String get midfieldersSection;

  /// No description provided for @attackersSection.
  ///
  /// In ko, this message translates to:
  /// **'공격수'**
  String get attackersSection;

  /// No description provided for @squadInfoNote.
  ///
  /// In ko, this message translates to:
  /// **'국가대표 선수단 정보는\n대회별로 소집됩니다'**
  String get squadInfoNote;

  /// No description provided for @worldCup.
  ///
  /// In ko, this message translates to:
  /// **'월드컵'**
  String get worldCup;

  /// No description provided for @worldCupQualAfc.
  ///
  /// In ko, this message translates to:
  /// **'월드컵 예선 (AFC)'**
  String get worldCupQualAfc;

  /// No description provided for @asianCup.
  ///
  /// In ko, this message translates to:
  /// **'아시안컵'**
  String get asianCup;

  /// No description provided for @friendlyMatch.
  ///
  /// In ko, this message translates to:
  /// **'친선경기'**
  String get friendlyMatch;

  /// No description provided for @matchNameHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 친선경기, 프리시즌, FA컵'**
  String get matchNameHint;

  /// No description provided for @leaguesByCountry.
  ///
  /// In ko, this message translates to:
  /// **'국가별 리그'**
  String get leaguesByCountry;

  /// No description provided for @mainCountries.
  ///
  /// In ko, this message translates to:
  /// **'주요 국가'**
  String get mainCountries;

  /// No description provided for @allCountries.
  ///
  /// In ko, this message translates to:
  /// **'전체 국가'**
  String get allCountries;

  /// No description provided for @noCountryCode.
  ///
  /// In ko, this message translates to:
  /// **'국가 코드가 없습니다'**
  String get noCountryCode;

  /// No description provided for @leagueSection.
  ///
  /// In ko, this message translates to:
  /// **'리그'**
  String get leagueSection;

  /// No description provided for @cupSection.
  ///
  /// In ko, this message translates to:
  /// **'컵 대회'**
  String get cupSection;

  /// No description provided for @otherSection.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get otherSection;

  /// No description provided for @invalidLeagueId.
  ///
  /// In ko, this message translates to:
  /// **'잘못된 리그 ID입니다'**
  String get invalidLeagueId;

  /// No description provided for @deleteAction.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get deleteAction;

  /// No description provided for @justNowShort.
  ///
  /// In ko, this message translates to:
  /// **'방금 전'**
  String get justNowShort;

  /// No description provided for @noBettingInCategory.
  ///
  /// In ko, this message translates to:
  /// **'해당 카테고리에 배팅이 없습니다'**
  String get noBettingInCategory;

  /// No description provided for @anonymousUser.
  ///
  /// In ko, this message translates to:
  /// **'익명'**
  String get anonymousUser;

  /// No description provided for @cannotFindComment.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 찾을 수 없습니다'**
  String get cannotFindComment;

  /// No description provided for @noDeletePermissionComment.
  ///
  /// In ko, this message translates to:
  /// **'삭제 권한이 없습니다'**
  String get noDeletePermissionComment;

  /// No description provided for @countryKorea.
  ///
  /// In ko, this message translates to:
  /// **'대한민국'**
  String get countryKorea;

  /// No description provided for @countryEngland.
  ///
  /// In ko, this message translates to:
  /// **'잉글랜드'**
  String get countryEngland;

  /// No description provided for @countrySpain.
  ///
  /// In ko, this message translates to:
  /// **'스페인'**
  String get countrySpain;

  /// No description provided for @countryGermany.
  ///
  /// In ko, this message translates to:
  /// **'독일'**
  String get countryGermany;

  /// No description provided for @countryItaly.
  ///
  /// In ko, this message translates to:
  /// **'이탈리아'**
  String get countryItaly;

  /// No description provided for @countryFrance.
  ///
  /// In ko, this message translates to:
  /// **'프랑스'**
  String get countryFrance;

  /// No description provided for @countryJapan.
  ///
  /// In ko, this message translates to:
  /// **'일본'**
  String get countryJapan;

  /// No description provided for @noLeaguesInCountry.
  ///
  /// In ko, this message translates to:
  /// **'{country}에 등록된 리그가 없습니다'**
  String noLeaguesInCountry(String country);

  /// No description provided for @standingsTab.
  ///
  /// In ko, this message translates to:
  /// **'순위'**
  String get standingsTab;

  /// No description provided for @scorersTab.
  ///
  /// In ko, this message translates to:
  /// **'득점'**
  String get scorersTab;

  /// No description provided for @assistsTab.
  ///
  /// In ko, this message translates to:
  /// **'도움'**
  String get assistsTab;

  /// No description provided for @statsTab.
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get statsTab;

  /// No description provided for @noStandingsData.
  ///
  /// In ko, this message translates to:
  /// **'순위 정보가 없습니다'**
  String get noStandingsData;

  /// No description provided for @cannotLoadStandingsForSeason.
  ///
  /// In ko, this message translates to:
  /// **'해당 시즌의 순위 정보를 불러올 수 없습니다'**
  String get cannotLoadStandingsForSeason;

  /// No description provided for @noGoalRankData.
  ///
  /// In ko, this message translates to:
  /// **'득점 순위 정보가 없습니다'**
  String get noGoalRankData;

  /// No description provided for @noAssistRankData.
  ///
  /// In ko, this message translates to:
  /// **'어시스트 순위 정보가 없습니다'**
  String get noAssistRankData;

  /// No description provided for @noLeagueStatsData.
  ///
  /// In ko, this message translates to:
  /// **'리그 통계 정보가 없습니다'**
  String get noLeagueStatsData;

  /// No description provided for @leagueOverviewCard.
  ///
  /// In ko, this message translates to:
  /// **'리그 개요'**
  String get leagueOverviewCard;

  /// No description provided for @nGamesLabel.
  ///
  /// In ko, this message translates to:
  /// **'{count}경기'**
  String nGamesLabel(int count);

  /// No description provided for @teamRankingCard.
  ///
  /// In ko, this message translates to:
  /// **'팀 순위'**
  String get teamRankingCard;

  /// No description provided for @mostScoringTeam.
  ///
  /// In ko, this message translates to:
  /// **'최다 득점'**
  String get mostScoringTeam;

  /// No description provided for @mostConcededTeam.
  ///
  /// In ko, this message translates to:
  /// **'최다 실점'**
  String get mostConcededTeam;

  /// No description provided for @mostWinsTeam.
  ///
  /// In ko, this message translates to:
  /// **'최다 승리'**
  String get mostWinsTeam;

  /// No description provided for @mostDrawsTeam.
  ///
  /// In ko, this message translates to:
  /// **'최다 무승부'**
  String get mostDrawsTeam;

  /// No description provided for @nGoalsLabel.
  ///
  /// In ko, this message translates to:
  /// **'{count}골'**
  String nGoalsLabel(int count);

  /// No description provided for @nWinsLabel.
  ///
  /// In ko, this message translates to:
  /// **'{count}승'**
  String nWinsLabel(int count);

  /// No description provided for @nDrawsLabel.
  ///
  /// In ko, this message translates to:
  /// **'{count}무'**
  String nDrawsLabel(int count);

  /// No description provided for @goalAnalysisCard.
  ///
  /// In ko, this message translates to:
  /// **'골 분석'**
  String get goalAnalysisCard;

  /// No description provided for @totalNGoals.
  ///
  /// In ko, this message translates to:
  /// **'총 {count}골'**
  String totalNGoals(int count);

  /// No description provided for @top5GoalDiff.
  ///
  /// In ko, this message translates to:
  /// **'득실차 상위 5팀'**
  String get top5GoalDiff;

  /// No description provided for @errorLabel.
  ///
  /// In ko, this message translates to:
  /// **'오류: {error}'**
  String errorLabel(String error);

  /// No description provided for @rankColumn.
  ///
  /// In ko, this message translates to:
  /// **'순위'**
  String get rankColumn;

  /// No description provided for @teamColumn.
  ///
  /// In ko, this message translates to:
  /// **'팀'**
  String get teamColumn;

  /// No description provided for @matchesColumn.
  ///
  /// In ko, this message translates to:
  /// **'경기'**
  String get matchesColumn;

  /// No description provided for @winColumn.
  ///
  /// In ko, this message translates to:
  /// **'승'**
  String get winColumn;

  /// No description provided for @drawColumn.
  ///
  /// In ko, this message translates to:
  /// **'무'**
  String get drawColumn;

  /// No description provided for @loseColumn.
  ///
  /// In ko, this message translates to:
  /// **'패'**
  String get loseColumn;

  /// No description provided for @goalsForColumn.
  ///
  /// In ko, this message translates to:
  /// **'득점'**
  String get goalsForColumn;

  /// No description provided for @goalsAgainstColumn.
  ///
  /// In ko, this message translates to:
  /// **'실점'**
  String get goalsAgainstColumn;

  /// No description provided for @goalDiffColumn.
  ///
  /// In ko, this message translates to:
  /// **'득실'**
  String get goalDiffColumn;

  /// No description provided for @pointsColumn.
  ///
  /// In ko, this message translates to:
  /// **'승점'**
  String get pointsColumn;

  /// No description provided for @playerColumn.
  ///
  /// In ko, this message translates to:
  /// **'선수'**
  String get playerColumn;

  /// No description provided for @appsColumn.
  ///
  /// In ko, this message translates to:
  /// **'출전'**
  String get appsColumn;

  /// No description provided for @goalsColumn.
  ///
  /// In ko, this message translates to:
  /// **'득점'**
  String get goalsColumn;

  /// No description provided for @assistsColumn.
  ///
  /// In ko, this message translates to:
  /// **'어시'**
  String get assistsColumn;

  /// No description provided for @dateFormatFull.
  ///
  /// In ko, this message translates to:
  /// **'yyyy년 M월 d일 (E)'**
  String get dateFormatFull;

  /// No description provided for @dateFormatMedium.
  ///
  /// In ko, this message translates to:
  /// **'yyyy년 M월 d일'**
  String get dateFormatMedium;

  /// No description provided for @dateFormatWithTime.
  ///
  /// In ko, this message translates to:
  /// **'yyyy.MM.dd (E) HH:mm'**
  String get dateFormatWithTime;

  /// No description provided for @dateFormatShort.
  ///
  /// In ko, this message translates to:
  /// **'MM.dd (E)'**
  String get dateFormatShort;

  /// No description provided for @dateFormatHeader.
  ///
  /// In ko, this message translates to:
  /// **'M월 d일 EEEE'**
  String get dateFormatHeader;

  /// No description provided for @dateFormatDiary.
  ///
  /// In ko, this message translates to:
  /// **'yyyy.MM.dd (E)'**
  String get dateFormatDiary;

  /// No description provided for @dateFormatSlash.
  ///
  /// In ko, this message translates to:
  /// **'yyyy/MM/dd (E)'**
  String get dateFormatSlash;

  /// No description provided for @searchAllMatchesForDate.
  ///
  /// In ko, this message translates to:
  /// **'{date} 전체 경기 조회'**
  String searchAllMatchesForDate(String date);

  /// No description provided for @searchLeagueMatchesForDate.
  ///
  /// In ko, this message translates to:
  /// **'{date} {league} 경기 조회'**
  String searchLeagueMatchesForDate(String date, String league);

  /// No description provided for @stadiumListForCountry.
  ///
  /// In ko, this message translates to:
  /// **'{country} 경기장 목록'**
  String stadiumListForCountry(String country);

  /// No description provided for @leagueEPL.
  ///
  /// In ko, this message translates to:
  /// **'EPL'**
  String get leagueEPL;

  /// No description provided for @leagueLaLiga.
  ///
  /// In ko, this message translates to:
  /// **'라리가'**
  String get leagueLaLiga;

  /// No description provided for @leagueSerieA.
  ///
  /// In ko, this message translates to:
  /// **'세리에 A'**
  String get leagueSerieA;

  /// No description provided for @leagueBundesliga.
  ///
  /// In ko, this message translates to:
  /// **'분데스리가'**
  String get leagueBundesliga;

  /// No description provided for @leagueLigue1.
  ///
  /// In ko, this message translates to:
  /// **'리그 1'**
  String get leagueLigue1;

  /// No description provided for @leagueKLeague1.
  ///
  /// In ko, this message translates to:
  /// **'K리그1'**
  String get leagueKLeague1;

  /// No description provided for @leagueKLeague2.
  ///
  /// In ko, this message translates to:
  /// **'K리그2'**
  String get leagueKLeague2;

  /// No description provided for @leagueUCL.
  ///
  /// In ko, this message translates to:
  /// **'UCL'**
  String get leagueUCL;

  /// No description provided for @leagueUEL.
  ///
  /// In ko, this message translates to:
  /// **'UEL'**
  String get leagueUEL;

  /// No description provided for @leagueUECL.
  ///
  /// In ko, this message translates to:
  /// **'UECL'**
  String get leagueUECL;

  /// No description provided for @leagueDomesticCups.
  ///
  /// In ko, this message translates to:
  /// **'컵대회'**
  String get leagueDomesticCups;

  /// No description provided for @leagueInternational.
  ///
  /// In ko, this message translates to:
  /// **'A매치'**
  String get leagueInternational;

  /// League team list title
  ///
  /// In ko, this message translates to:
  /// **'{league} 팀 목록'**
  String leagueTeamList(String league);

  /// No description provided for @worldCup2026.
  ///
  /// In ko, this message translates to:
  /// **'2026 FIFA 월드컵'**
  String get worldCup2026;

  /// No description provided for @myDiaryTitle.
  ///
  /// In ko, this message translates to:
  /// **'나의 직관일기'**
  String get myDiaryTitle;

  /// No description provided for @yearlySummary.
  ///
  /// In ko, this message translates to:
  /// **'{year}년 직관 요약'**
  String yearlySummary(int year);

  /// No description provided for @matchUnit.
  ///
  /// In ko, this message translates to:
  /// **'경기'**
  String get matchUnit;

  /// No description provided for @nMatchesUnit.
  ///
  /// In ko, this message translates to:
  /// **'{count}경기'**
  String nMatchesUnit(int count);

  /// No description provided for @nYearsUnit.
  ///
  /// In ko, this message translates to:
  /// **'{count}년'**
  String nYearsUnit(int count);

  /// No description provided for @totalViews.
  ///
  /// In ko, this message translates to:
  /// **'총 관람'**
  String get totalViews;

  /// No description provided for @averageRating.
  ///
  /// In ko, this message translates to:
  /// **'평균 평점'**
  String get averageRating;

  /// No description provided for @pointsUnit.
  ///
  /// In ko, this message translates to:
  /// **'점'**
  String get pointsUnit;

  /// No description provided for @invalidCoachId.
  ///
  /// In ko, this message translates to:
  /// **'잘못된 감독 ID입니다'**
  String get invalidCoachId;

  /// No description provided for @homeGoal.
  ///
  /// In ko, this message translates to:
  /// **'홈 골'**
  String get homeGoal;

  /// No description provided for @awayGoal.
  ///
  /// In ko, this message translates to:
  /// **'원정 골'**
  String get awayGoal;

  /// No description provided for @noDataAvailable.
  ///
  /// In ko, this message translates to:
  /// **'데이터가 없습니다'**
  String get noDataAvailable;

  /// No description provided for @loadFailedShort.
  ///
  /// In ko, this message translates to:
  /// **'불러오기 실패'**
  String get loadFailedShort;

  /// No description provided for @ageLabel.
  ///
  /// In ko, this message translates to:
  /// **'나이'**
  String get ageLabel;

  /// No description provided for @birthDateLabel.
  ///
  /// In ko, this message translates to:
  /// **'생년월일'**
  String get birthDateLabel;

  /// No description provided for @birthPlaceLabel.
  ///
  /// In ko, this message translates to:
  /// **'출생지'**
  String get birthPlaceLabel;

  /// No description provided for @championTitle.
  ///
  /// In ko, this message translates to:
  /// **'우승'**
  String get championTitle;

  /// No description provided for @runnerUpTitle.
  ///
  /// In ko, this message translates to:
  /// **'준우승'**
  String get runnerUpTitle;

  /// No description provided for @careerTitle.
  ///
  /// In ko, this message translates to:
  /// **'경력'**
  String get careerTitle;

  /// No description provided for @currentLabel.
  ///
  /// In ko, this message translates to:
  /// **'현재'**
  String get currentLabel;

  /// No description provided for @suspendedLabel.
  ///
  /// In ko, this message translates to:
  /// **'정지'**
  String get suspendedLabel;

  /// No description provided for @worldCupShort.
  ///
  /// In ko, this message translates to:
  /// **'월드컵'**
  String get worldCupShort;

  /// No description provided for @asianCupShort.
  ///
  /// In ko, this message translates to:
  /// **'아시안컵'**
  String get asianCupShort;

  /// No description provided for @friendlyMatchLabel.
  ///
  /// In ko, this message translates to:
  /// **'친선경기'**
  String get friendlyMatchLabel;

  /// No description provided for @ageYearsValue.
  ///
  /// In ko, this message translates to:
  /// **'{age}세'**
  String ageYearsValue(int age);

  /// No description provided for @birthCountry.
  ///
  /// In ko, this message translates to:
  /// **'출생 국가'**
  String get birthCountry;

  /// No description provided for @coachCareer.
  ///
  /// In ko, this message translates to:
  /// **'감독 경력'**
  String get coachCareer;

  /// No description provided for @careerYears.
  ///
  /// In ko, this message translates to:
  /// **'{years}년'**
  String careerYears(int years);

  /// No description provided for @trophyRecord.
  ///
  /// In ko, this message translates to:
  /// **'수상 기록'**
  String get trophyRecord;

  /// No description provided for @andNMore.
  ///
  /// In ko, this message translates to:
  /// **'외 {count}개'**
  String andNMore(int count);

  /// No description provided for @mostWatchedTeam.
  ///
  /// In ko, this message translates to:
  /// **'가장 많이 본 팀'**
  String get mostWatchedTeam;

  /// No description provided for @selectSeason.
  ///
  /// In ko, this message translates to:
  /// **'시즌 선택'**
  String get selectSeason;

  /// No description provided for @languageSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'한국어, English'**
  String get languageSubtitle;

  /// No description provided for @suspensionHistory.
  ///
  /// In ko, this message translates to:
  /// **'출전정지 이력'**
  String get suspensionHistory;

  /// No description provided for @nCases.
  ///
  /// In ko, this message translates to:
  /// **'{count}건'**
  String nCases(int count);

  /// No description provided for @currentlySuspended.
  ///
  /// In ko, this message translates to:
  /// **'현재 출전정지 중'**
  String get currentlySuspended;

  /// No description provided for @coachInfo.
  ///
  /// In ko, this message translates to:
  /// **'감독 정보'**
  String get coachInfo;

  /// No description provided for @errorLoginRequired.
  ///
  /// In ko, this message translates to:
  /// **'로그인이 필요합니다'**
  String get errorLoginRequired;

  /// No description provided for @errorPostNotFound.
  ///
  /// In ko, this message translates to:
  /// **'게시글을 찾을 수 없습니다'**
  String get errorPostNotFound;

  /// No description provided for @errorPostEditPermissionDenied.
  ///
  /// In ko, this message translates to:
  /// **'수정 권한이 없습니다'**
  String get errorPostEditPermissionDenied;

  /// No description provided for @errorPostDeletePermissionDenied.
  ///
  /// In ko, this message translates to:
  /// **'삭제 권한이 없습니다'**
  String get errorPostDeletePermissionDenied;

  /// No description provided for @errorCommentNotFound.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 찾을 수 없습니다'**
  String get errorCommentNotFound;

  /// No description provided for @errorCommentDeletePermissionDenied.
  ///
  /// In ko, this message translates to:
  /// **'삭제 권한이 없습니다'**
  String get errorCommentDeletePermissionDenied;

  /// No description provided for @errorNetworkError.
  ///
  /// In ko, this message translates to:
  /// **'네트워크 오류가 발생했습니다'**
  String get errorNetworkError;

  /// No description provided for @errorUnknown.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없는 오류가 발생했습니다'**
  String get errorUnknown;

  /// No description provided for @injuryGroin.
  ///
  /// In ko, this message translates to:
  /// **'사타구니 부상'**
  String get injuryGroin;

  /// No description provided for @injuryShoulder.
  ///
  /// In ko, this message translates to:
  /// **'어깨 부상'**
  String get injuryShoulder;

  /// No description provided for @injuryAchilles.
  ///
  /// In ko, this message translates to:
  /// **'아킬레스 부상'**
  String get injuryAchilles;

  /// No description provided for @injuryCalf.
  ///
  /// In ko, this message translates to:
  /// **'종아리 부상'**
  String get injuryCalf;

  /// No description provided for @injuryThigh.
  ///
  /// In ko, this message translates to:
  /// **'허벅지 부상'**
  String get injuryThigh;

  /// No description provided for @injuryHip.
  ///
  /// In ko, this message translates to:
  /// **'엉덩이 부상'**
  String get injuryHip;

  /// No description provided for @injuryFracture.
  ///
  /// In ko, this message translates to:
  /// **'골절'**
  String get injuryFracture;

  /// No description provided for @injuryConcussion.
  ///
  /// In ko, this message translates to:
  /// **'뇌진탕'**
  String get injuryConcussion;

  /// No description provided for @injuryLigament.
  ///
  /// In ko, this message translates to:
  /// **'인대 부상'**
  String get injuryLigament;

  /// No description provided for @injurySurgery.
  ///
  /// In ko, this message translates to:
  /// **'수술'**
  String get injurySurgery;

  /// No description provided for @statusSuspension.
  ///
  /// In ko, this message translates to:
  /// **'출전정지'**
  String get statusSuspension;

  /// No description provided for @statusRedCard.
  ///
  /// In ko, this message translates to:
  /// **'레드카드 징계'**
  String get statusRedCard;

  /// No description provided for @statusYellowCard.
  ///
  /// In ko, this message translates to:
  /// **'옐로카드 누적'**
  String get statusYellowCard;

  /// No description provided for @statusBan.
  ///
  /// In ko, this message translates to:
  /// **'출전금지'**
  String get statusBan;

  /// No description provided for @statusDisciplinary.
  ///
  /// In ko, this message translates to:
  /// **'징계'**
  String get statusDisciplinary;

  /// No description provided for @statusMissing.
  ///
  /// In ko, this message translates to:
  /// **'결장'**
  String get statusMissing;

  /// No description provided for @statusPersonal.
  ///
  /// In ko, this message translates to:
  /// **'개인 사유'**
  String get statusPersonal;

  /// No description provided for @statusInternational.
  ///
  /// In ko, this message translates to:
  /// **'국가대표 차출'**
  String get statusInternational;

  /// No description provided for @statusRest.
  ///
  /// In ko, this message translates to:
  /// **'휴식'**
  String get statusRest;

  /// No description provided for @statusFitness.
  ///
  /// In ko, this message translates to:
  /// **'컨디션 조절'**
  String get statusFitness;

  /// No description provided for @statusSuspended.
  ///
  /// In ko, this message translates to:
  /// **'출전 정지'**
  String get statusSuspended;

  /// No description provided for @statusInjury.
  ///
  /// In ko, this message translates to:
  /// **'부상'**
  String get statusInjury;

  /// No description provided for @statusDoubtful.
  ///
  /// In ko, this message translates to:
  /// **'출전 불투명'**
  String get statusDoubtful;

  /// No description provided for @statusAbsent.
  ///
  /// In ko, this message translates to:
  /// **'결장'**
  String get statusAbsent;

  /// No description provided for @betFirstHalfOU.
  ///
  /// In ko, this message translates to:
  /// **'전반 오버/언더'**
  String get betFirstHalfOU;

  /// No description provided for @betSecondHalfOU.
  ///
  /// In ko, this message translates to:
  /// **'후반 오버/언더'**
  String get betSecondHalfOU;

  /// No description provided for @betHalfFullTime.
  ///
  /// In ko, this message translates to:
  /// **'전반/풀타임'**
  String get betHalfFullTime;

  /// No description provided for @betHomeTeamGoals.
  ///
  /// In ko, this message translates to:
  /// **'홈팀 골'**
  String get betHomeTeamGoals;

  /// No description provided for @betAwayTeamGoals.
  ///
  /// In ko, this message translates to:
  /// **'원정팀 골'**
  String get betAwayTeamGoals;

  /// No description provided for @betDrawNoBet.
  ///
  /// In ko, this message translates to:
  /// **'무승부 제외'**
  String get betDrawNoBet;

  /// No description provided for @betResultBothScore.
  ///
  /// In ko, this message translates to:
  /// **'결과+양팀득점'**
  String get betResultBothScore;

  /// No description provided for @betFirstHalfExact.
  ///
  /// In ko, this message translates to:
  /// **'전반 정확한 스코어'**
  String get betFirstHalfExact;

  /// No description provided for @betGoalsDifference.
  ///
  /// In ko, this message translates to:
  /// **'골 차이'**
  String get betGoalsDifference;

  /// No description provided for @periodOngoing.
  ///
  /// In ko, this message translates to:
  /// **'진행 중'**
  String get periodOngoing;

  /// No description provided for @periodCurrent.
  ///
  /// In ko, this message translates to:
  /// **'현재'**
  String get periodCurrent;

  /// No description provided for @errorNetwork.
  ///
  /// In ko, this message translates to:
  /// **'인터넷 연결을 확인해주세요'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In ko, this message translates to:
  /// **'서버 응답이 없습니다. 잠시 후 다시 시도해주세요'**
  String get errorTimeout;

  /// No description provided for @errorServer.
  ///
  /// In ko, this message translates to:
  /// **'일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요'**
  String get errorServer;

  /// No description provided for @errorFirebasePermission.
  ///
  /// In ko, this message translates to:
  /// **'접근 권한이 없습니다'**
  String get errorFirebasePermission;

  /// No description provided for @errorFirebaseNotFound.
  ///
  /// In ko, this message translates to:
  /// **'요청한 데이터를 찾을 수 없습니다'**
  String get errorFirebaseNotFound;

  /// No description provided for @errorFirebaseUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'서비스를 일시적으로 사용할 수 없습니다'**
  String get errorFirebaseUnavailable;

  /// No description provided for @accountDeleted.
  ///
  /// In ko, this message translates to:
  /// **'회원 탈퇴가 완료되었습니다'**
  String get accountDeleted;

  /// No description provided for @accountDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'회원 탈퇴 실패: {error}'**
  String accountDeleteFailed(String error);

  /// No description provided for @report.
  ///
  /// In ko, this message translates to:
  /// **'신고'**
  String get report;

  /// No description provided for @reportPost.
  ///
  /// In ko, this message translates to:
  /// **'게시글 신고'**
  String get reportPost;

  /// No description provided for @reportComment.
  ///
  /// In ko, this message translates to:
  /// **'댓글 신고'**
  String get reportComment;

  /// No description provided for @reportUser.
  ///
  /// In ko, this message translates to:
  /// **'사용자 신고'**
  String get reportUser;

  /// No description provided for @reportReason.
  ///
  /// In ko, this message translates to:
  /// **'신고 사유'**
  String get reportReason;

  /// No description provided for @reportReasonSpam.
  ///
  /// In ko, this message translates to:
  /// **'스팸/광고'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In ko, this message translates to:
  /// **'욕설/비방'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonInappropriate.
  ///
  /// In ko, this message translates to:
  /// **'부적절한 콘텐츠'**
  String get reportReasonInappropriate;

  /// No description provided for @reportReasonFalseInfo.
  ///
  /// In ko, this message translates to:
  /// **'허위 정보'**
  String get reportReasonFalseInfo;

  /// No description provided for @reportReasonOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get reportReasonOther;

  /// No description provided for @reportAdditionalInfo.
  ///
  /// In ko, this message translates to:
  /// **'추가 설명 (선택)'**
  String get reportAdditionalInfo;

  /// No description provided for @reportAdditionalInfoHint.
  ///
  /// In ko, this message translates to:
  /// **'신고 사유를 자세히 입력해주세요'**
  String get reportAdditionalInfoHint;

  /// No description provided for @reportSubmit.
  ///
  /// In ko, this message translates to:
  /// **'신고하기'**
  String get reportSubmit;

  /// No description provided for @reportSubmitted.
  ///
  /// In ko, this message translates to:
  /// **'신고가 접수되었습니다'**
  String get reportSubmitted;

  /// No description provided for @reportFailed.
  ///
  /// In ko, this message translates to:
  /// **'신고 접수 실패: {error}'**
  String reportFailed(String error);

  /// No description provided for @reportAlreadySubmitted.
  ///
  /// In ko, this message translates to:
  /// **'이미 신고한 콘텐츠입니다'**
  String get reportAlreadySubmitted;

  /// No description provided for @reportConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'신고하시겠습니까?'**
  String get reportConfirmTitle;

  /// No description provided for @reportConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'허위 신고는 제재를 받을 수 있습니다.'**
  String get reportConfirmMessage;

  /// No description provided for @blockUser.
  ///
  /// In ko, this message translates to:
  /// **'사용자 차단'**
  String get blockUser;

  /// No description provided for @blockUserConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 사용자를 차단하시겠습니까?'**
  String get blockUserConfirm;

  /// No description provided for @blockUserDesc.
  ///
  /// In ko, this message translates to:
  /// **'차단한 사용자 관리'**
  String get blockUserDesc;

  /// No description provided for @userBlocked.
  ///
  /// In ko, this message translates to:
  /// **'사용자가 차단되었습니다'**
  String get userBlocked;

  /// No description provided for @blockedUsersManagement.
  ///
  /// In ko, this message translates to:
  /// **'차단 사용자 관리'**
  String get blockedUsersManagement;

  /// No description provided for @noBlockedUsers.
  ///
  /// In ko, this message translates to:
  /// **'차단한 사용자가 없습니다'**
  String get noBlockedUsers;

  /// No description provided for @blockedUser.
  ///
  /// In ko, this message translates to:
  /// **'차단된 사용자'**
  String get blockedUser;

  /// No description provided for @unblock.
  ///
  /// In ko, this message translates to:
  /// **'차단 해제'**
  String get unblock;

  /// No description provided for @unblockUser.
  ///
  /// In ko, this message translates to:
  /// **'차단 해제'**
  String get unblockUser;

  /// No description provided for @unblockUserConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 사용자의 차단을 해제하시겠습니까?'**
  String get unblockUserConfirm;

  /// No description provided for @userUnblocked.
  ///
  /// In ko, this message translates to:
  /// **'차단이 해제되었습니다'**
  String get userUnblocked;

  /// No description provided for @tournamentOverview.
  ///
  /// In ko, this message translates to:
  /// **'대회 개요'**
  String get tournamentOverview;

  /// No description provided for @avgGoals.
  ///
  /// In ko, this message translates to:
  /// **'평균 골'**
  String get avgGoals;

  /// No description provided for @cleanSheets.
  ///
  /// In ko, this message translates to:
  /// **'클린시트'**
  String get cleanSheets;

  /// No description provided for @penaltyShootout.
  ///
  /// In ko, this message translates to:
  /// **'승부차기'**
  String get penaltyShootout;

  /// No description provided for @highScoringMatches.
  ///
  /// In ko, this message translates to:
  /// **'다득점 경기'**
  String get highScoringMatches;

  /// No description provided for @regularTime.
  ///
  /// In ko, this message translates to:
  /// **'정규 시간'**
  String get regularTime;

  /// No description provided for @biggestWins.
  ///
  /// In ko, this message translates to:
  /// **'대승 경기'**
  String get biggestWins;

  /// No description provided for @roundStats.
  ///
  /// In ko, this message translates to:
  /// **'라운드별 통계'**
  String get roundStats;

  /// No description provided for @round.
  ///
  /// In ko, this message translates to:
  /// **'라운드'**
  String get round;

  /// No description provided for @liveGoalTeam.
  ///
  /// In ko, this message translates to:
  /// **'{team} 골!'**
  String liveGoalTeam(String team);

  /// No description provided for @liveGoalPlayer.
  ///
  /// In ko, this message translates to:
  /// **'{player} 골!'**
  String liveGoalPlayer(String player);

  /// No description provided for @liveAssist.
  ///
  /// In ko, this message translates to:
  /// **'{player} 어시스트!'**
  String liveAssist(String player);

  /// No description provided for @liveRedCard.
  ///
  /// In ko, this message translates to:
  /// **'레드카드!'**
  String get liveRedCard;

  /// No description provided for @liveGoalWithAssist.
  ///
  /// In ko, this message translates to:
  /// **'{time} {scorer} (어시스트: {assist})'**
  String liveGoalWithAssist(String time, String scorer, String assist);

  /// No description provided for @liveGoalNoAssist.
  ///
  /// In ko, this message translates to:
  /// **'{time} {scorer}'**
  String liveGoalNoAssist(String time, String scorer);

  /// No description provided for @liveEventTime.
  ///
  /// In ko, this message translates to:
  /// **'{time} {player} ({team})'**
  String liveEventTime(String time, String player, String team);

  /// No description provided for @matchVs.
  ///
  /// In ko, this message translates to:
  /// **'{home} vs {away}'**
  String matchVs(String home, String away);

  /// No description provided for @patchNotesLatest.
  ///
  /// In ko, this message translates to:
  /// **'최신'**
  String get patchNotesLatest;

  /// No description provided for @patchNote_1_1_4_1.
  ///
  /// In ko, this message translates to:
  /// **'자국 필터 추가 (일정탭, 직관일기)'**
  String get patchNote_1_1_4_1;

  /// No description provided for @patchNote_1_1_4_2.
  ///
  /// In ko, this message translates to:
  /// **'연령별 대표팀 경기 표시 (U23, U20 등)'**
  String get patchNote_1_1_4_2;

  /// No description provided for @patchNote_1_1_4_3.
  ///
  /// In ko, this message translates to:
  /// **'동일 이름 리그 국가별 분리'**
  String get patchNote_1_1_4_3;

  /// No description provided for @patchNote_1_1_4_4.
  ///
  /// In ko, this message translates to:
  /// **'실축(Missed Penalty) 골 기록 오류 수정'**
  String get patchNote_1_1_4_4;

  /// No description provided for @patchNote_1_1_4_5.
  ///
  /// In ko, this message translates to:
  /// **'패치노트 다국어 지원 (한국어/영어)'**
  String get patchNote_1_1_4_5;

  /// No description provided for @patchNote_1_1_3_1.
  ///
  /// In ko, this message translates to:
  /// **'알림 탭 시 경기 상세 화면으로 이동'**
  String get patchNote_1_1_3_1;

  /// No description provided for @patchNote_1_1_3_2.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기 팀 실시간 알림 (골/라인업/결과)'**
  String get patchNote_1_1_3_2;

  /// No description provided for @patchNote_1_1_3_3.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기 선수 이벤트 알림 (골/어시스트)'**
  String get patchNote_1_1_3_3;

  /// No description provided for @patchNote_1_1_3_4.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정 UI 개선'**
  String get patchNote_1_1_3_4;

  /// No description provided for @patchNote_1_1_3_5.
  ///
  /// In ko, this message translates to:
  /// **'탭 간 광고 유지 개선'**
  String get patchNote_1_1_3_5;

  /// No description provided for @patchNote_1_1_2_1.
  ///
  /// In ko, this message translates to:
  /// **'UEFA 컨퍼런스리그 추가'**
  String get patchNote_1_1_2_1;

  /// No description provided for @patchNote_1_1_2_2.
  ///
  /// In ko, this message translates to:
  /// **'2026 FIFA 월드컵 정보 반영'**
  String get patchNote_1_1_2_2;

  /// No description provided for @patchNote_1_1_2_3.
  ///
  /// In ko, this message translates to:
  /// **'리그 페이지 로딩 안정성 개선'**
  String get patchNote_1_1_2_3;

  /// No description provided for @patchNote_1_1_2_4.
  ///
  /// In ko, this message translates to:
  /// **'순위 페이지 통계 탭 개선'**
  String get patchNote_1_1_2_4;

  /// No description provided for @patchNote_1_1_2_5.
  ///
  /// In ko, this message translates to:
  /// **'컵대회 추가 및 개선'**
  String get patchNote_1_1_2_5;

  /// No description provided for @patchNote_1_1_2_6.
  ///
  /// In ko, this message translates to:
  /// **'성능 개선 및 버그 수정'**
  String get patchNote_1_1_2_6;

  /// No description provided for @patchNote_1_1_1_1.
  ///
  /// In ko, this message translates to:
  /// **'컵대회 필터 추가 (일정/직관기록)'**
  String get patchNote_1_1_1_1;

  /// No description provided for @patchNote_1_1_1_2.
  ///
  /// In ko, this message translates to:
  /// **'리그탭 국내컵대회 추가'**
  String get patchNote_1_1_1_2;

  /// No description provided for @patchNote_1_1_1_3.
  ///
  /// In ko, this message translates to:
  /// **'국내컵대회 토너먼트 페이지'**
  String get patchNote_1_1_1_3;

  /// No description provided for @patchNote_1_1_1_4.
  ///
  /// In ko, this message translates to:
  /// **'컵대회 토너먼트/통계 페이지 개선'**
  String get patchNote_1_1_1_4;

  /// No description provided for @patchNote_1_1_1_5.
  ///
  /// In ko, this message translates to:
  /// **'컵대회 득점/도움 통계 추가'**
  String get patchNote_1_1_1_5;

  /// No description provided for @patchNote_1_1_1_6.
  ///
  /// In ko, this message translates to:
  /// **'통계 탭 색상 수정'**
  String get patchNote_1_1_1_6;

  /// No description provided for @patchNote_1_1_1_7.
  ///
  /// In ko, this message translates to:
  /// **'동적 로드 추가'**
  String get patchNote_1_1_1_7;

  /// No description provided for @patchNote_1_1_1_8.
  ///
  /// In ko, this message translates to:
  /// **'북중미 월드컵 진출국 하드코딩'**
  String get patchNote_1_1_1_8;

  /// No description provided for @patchNote_1_1_1_9.
  ///
  /// In ko, this message translates to:
  /// **'승부차기 및 연장전 점수 표시'**
  String get patchNote_1_1_1_9;

  /// No description provided for @patchNote_1_1_0_1.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기 팀 알림 기능'**
  String get patchNote_1_1_0_1;

  /// No description provided for @patchNote_1_1_0_2.
  ///
  /// In ko, this message translates to:
  /// **'A매치에 필터 추가, 달력 수정'**
  String get patchNote_1_1_0_2;

  /// No description provided for @patchNote_1_1_0_3.
  ///
  /// In ko, this message translates to:
  /// **'팀정보 순위페이지 추가'**
  String get patchNote_1_1_0_3;

  /// No description provided for @patchNote_1_1_0_4.
  ///
  /// In ko, this message translates to:
  /// **'팀정보 이적탭 날짜 파싱 수정'**
  String get patchNote_1_1_0_4;

  /// No description provided for @patchNote_1_1_0_5.
  ///
  /// In ko, this message translates to:
  /// **'선수정보 출전경기 탭 추가'**
  String get patchNote_1_1_0_5;

  /// No description provided for @patchNote_1_1_0_6.
  ///
  /// In ko, this message translates to:
  /// **'라인업 페이지 교체 아웃 추가'**
  String get patchNote_1_1_0_6;

  /// No description provided for @patchNote_1_1_0_7.
  ///
  /// In ko, this message translates to:
  /// **'부상/결장 선수 디테일 페이지 오류 수정'**
  String get patchNote_1_1_0_7;

  /// No description provided for @patchNote_1_1_0_8.
  ///
  /// In ko, this message translates to:
  /// **'팀정보 - 일정탭 날짜 기준 수정'**
  String get patchNote_1_1_0_8;

  /// No description provided for @patchNote_1_1_0_9.
  ///
  /// In ko, this message translates to:
  /// **'라이브 데이터 자동 갱신 개선'**
  String get patchNote_1_1_0_9;

  /// No description provided for @patchNote_1_0_0_3_1.
  ///
  /// In ko, this message translates to:
  /// **'리그 일정에 라운드 표시'**
  String get patchNote_1_0_0_3_1;

  /// No description provided for @patchNote_1_0_0_3_2.
  ///
  /// In ko, this message translates to:
  /// **'하프타임(HT) 표시'**
  String get patchNote_1_0_0_3_2;

  /// No description provided for @patchNote_1_0_0_3_3.
  ///
  /// In ko, this message translates to:
  /// **'시즌 자동 감지 개선'**
  String get patchNote_1_0_0_3_3;

  /// No description provided for @patchNote_1_0_0_3_4.
  ///
  /// In ko, this message translates to:
  /// **'자국 리그 필터 자동 추가'**
  String get patchNote_1_0_0_3_4;

  /// No description provided for @patchNote_1_0_0_3_5.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기 선수 검색 개선'**
  String get patchNote_1_0_0_3_5;

  /// No description provided for @patchNote_1_0_0_2_1.
  ///
  /// In ko, this message translates to:
  /// **'Apple 로그인 지원'**
  String get patchNote_1_0_0_2_1;

  /// No description provided for @patchNote_1_0_0_2_2.
  ///
  /// In ko, this message translates to:
  /// **'회원탈퇴 기능 추가'**
  String get patchNote_1_0_0_2_2;

  /// No description provided for @patchNote_1_0_0_2_3.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티 신고/차단 기능'**
  String get patchNote_1_0_0_2_3;

  /// No description provided for @patchNote_1_0_0_2_4.
  ///
  /// In ko, this message translates to:
  /// **'국가별 리그 탐색 페이지'**
  String get patchNote_1_0_0_2_4;

  /// No description provided for @patchNote_1_0_0_2_5.
  ///
  /// In ko, this message translates to:
  /// **'라이브 경기 추가시간 표시'**
  String get patchNote_1_0_0_2_5;

  /// No description provided for @patchNote_1_0_0_2_6.
  ///
  /// In ko, this message translates to:
  /// **'성능 개선 및 버그 수정'**
  String get patchNote_1_0_0_2_6;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
