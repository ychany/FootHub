// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'FootHub';

  @override
  String get appTagline => 'FootHub';

  @override
  String get home => '홈';

  @override
  String get schedule => '일정';

  @override
  String get standings => '순위';

  @override
  String get tournament => '토너먼트';

  @override
  String get cannotLoadData => '데이터를 불러올 수 없습니다';

  @override
  String get leagues => '리그';

  @override
  String get community => '커뮤니티';

  @override
  String get favorites => '즐겨찾기';

  @override
  String get profile => '내 정보';

  @override
  String hello(String name) {
    return '안녕하세요, $name님';
  }

  @override
  String get footballFan => '축구팬';

  @override
  String get record => '기록하기';

  @override
  String get attendanceRecord => '직관 기록';

  @override
  String get myAttendanceRecord => '나의 직관 기록';

  @override
  String get myAttendanceDiary => '나의 직관 일기';

  @override
  String get attendanceDiary => '직관 일기';

  @override
  String get myRecords => '나의 직관 기록들';

  @override
  String get viewAll => '전체보기';

  @override
  String get manage => '관리';

  @override
  String get edit => '편집';

  @override
  String get delete => '삭제';

  @override
  String get cancel => '취소';

  @override
  String get selectYear => '연도 선택';

  @override
  String get selectMonth => '월 선택';

  @override
  String get selectDay => '일 선택';

  @override
  String get yearSuffix => '년';

  @override
  String get monthSuffix => '월';

  @override
  String get daySuffix => '일';

  @override
  String get save => '저장';

  @override
  String get select => '선택';

  @override
  String get confirm => '확인';

  @override
  String get close => '닫기';

  @override
  String get more => '더보기';

  @override
  String get refresh => '새로고침';

  @override
  String get retry => '다시 시도';

  @override
  String get totalMatches => '총 경기';

  @override
  String get matchCount => '경기';

  @override
  String get win => '승리';

  @override
  String get winShort => '승';

  @override
  String get draw => '무승부';

  @override
  String get drawShort => '무';

  @override
  String get loss => '패배';

  @override
  String get lossShort => '패';

  @override
  String get winRate => '승률';

  @override
  String get stadium => '경기장';

  @override
  String get stadiumCount => '곳';

  @override
  String get times => '회';

  @override
  String get cannotLoadStats => '통계를 불러올 수 없습니다';

  @override
  String get cannotLoadSchedule => '일정을 불러올 수 없습니다';

  @override
  String get cannotLoadRecords => '기록을 불러올 수 없습니다';

  @override
  String get cannotLoadTeamList => '팀 목록을 불러올 수 없습니다';

  @override
  String get loadFailed => '로드 실패';

  @override
  String get errorOccurred => '오류가 발생했습니다';

  @override
  String get live => '라이브 경기';

  @override
  String liveMatchCount(int count) {
    return '$count경기';
  }

  @override
  String get autoRefreshEvery30Sec => '30초마다 자동 갱신';

  @override
  String get noLiveMatches => '진행 중인 경기가 없습니다';

  @override
  String get firstHalf => '전반';

  @override
  String get secondHalf => '후반';

  @override
  String get halfTime => '하프타임';

  @override
  String get extraTime => '연장전';

  @override
  String get penalties => '승부차기';

  @override
  String get finished => '종료';

  @override
  String get upcoming => '예정';

  @override
  String get favoriteTeamSchedule => '즐겨찾기 팀 일정';

  @override
  String get addFavoriteTeam => '즐겨찾기 팀을 추가해보세요';

  @override
  String get addFavoriteTeamDesc => '팀을 추가하면 다가오는 경기 일정을 확인할 수 있어요';

  @override
  String get recentRecords => '최근 직관 기록';

  @override
  String get firstRecordPrompt => '첫 직관 기록을 남겨보세요';

  @override
  String get firstRecordDesc => '경기장에서의 특별한 순간을 기록해보세요';

  @override
  String get nextMatch => '다음 경기';

  @override
  String get noScheduledMatches => '예정된 경기가 없습니다';

  @override
  String get recent5Matches => '최근 5경기';

  @override
  String get selectNationalTeam => '응원할 국가대표팀을 선택해주세요';

  @override
  String get selectNationalTeamPrompt => '응원할 국가대표팀을 선택하세요';

  @override
  String get worldCupParticipants => '2026 월드컵 참가국';

  @override
  String get searchCountry => '국가 검색...';

  @override
  String get matchSchedule => '경기 일정';

  @override
  String get today => '오늘';

  @override
  String get monthly => '월간';

  @override
  String get twoWeeks => '2주';

  @override
  String get weekly => '주간';

  @override
  String get major => '주요';

  @override
  String get all => '전체';

  @override
  String get recordAttendance => '직관 기록하기';

  @override
  String get attendanceComplete => '직관 완료';

  @override
  String get notificationSettings => '알림 설정';

  @override
  String get matchNotification => '경기 알림 설정';

  @override
  String get kickoffNotification => '경기 시작 알림';

  @override
  String get kickoffNotificationDesc => '킥오프 30분 전에 알림';

  @override
  String get lineupNotification => '라인업 발표';

  @override
  String get lineupNotificationDesc => '선발 명단 공개 시 알림';

  @override
  String get resultNotification => '경기 결과';

  @override
  String get resultNotificationDesc => '경기 종료 후 결과 알림';

  @override
  String get notificationOff => '알림 해제';

  @override
  String get notificationSet => '알림이 설정되었습니다';

  @override
  String get notificationRemoved => '알림이 해제되었습니다';

  @override
  String get team => '팀';

  @override
  String get teams => '팀';

  @override
  String get player => '선수';

  @override
  String get players => '선수';

  @override
  String get addTeam => '팀 추가';

  @override
  String get addPlayer => '선수 추가';

  @override
  String get searchTeam => '팀 검색...';

  @override
  String get searchPlayer => '선수 검색...';

  @override
  String get removeFavorite => '해제';

  @override
  String get unfollow => '해제';

  @override
  String get unfollowTeam => '팀 팔로우 해제';

  @override
  String unfollowTeamConfirm(String name) {
    return '$name을(를) 즐겨찾기에서 제거하시겠습니까?';
  }

  @override
  String get unfollowPlayer => '선수 팔로우 해제';

  @override
  String unfollowPlayerConfirm(String name) {
    return '$name을(를) 즐겨찾기에서 제거하시겠습니까?';
  }

  @override
  String get selectLeagueOrSearch => '리그를 선택하거나 팀을 검색하세요';

  @override
  String get teamNotFound => '팀 정보를 찾을 수 없습니다';

  @override
  String get playerNotFound => '선수를 찾을 수 없습니다';

  @override
  String get searchTeamFirst => '팀 이름을 검색하세요';

  @override
  String get filterPlayers => '선수 이름으로 필터...';

  @override
  String get searchTeamToAddPlayer => '팀을 검색해서 선수를 추가하세요';

  @override
  String get national => '국가';

  @override
  String get addFavoriteTeamPrompt => '좋아하는 팀을 추가해보세요';

  @override
  String get addFavoritePlayerPrompt => '즐겨찾기 선수 추가';

  @override
  String get list => '리스트';

  @override
  String get calendar => '달력';

  @override
  String get stats => '통계';

  @override
  String get deleteRecord => '기록 삭제';

  @override
  String get deleteRecordConfirm => '이 기록을 삭제하시겠습니까?';

  @override
  String get recordDeleted => '기록이 삭제되었습니다';

  @override
  String noRecordOnDate(String date) {
    return '$date에 기록이 없습니다';
  }

  @override
  String get selectDate => '날짜를 선택해주세요';

  @override
  String get noRecordsYet => '아직 기록이 없습니다';

  @override
  String get leagueStats => '리그별 통계';

  @override
  String get stadiumVisits => '경기장 방문 현황';

  @override
  String get visitedStadiums => '방문한 경기장';

  @override
  String get user => '사용자';

  @override
  String get activeMember => '활성 회원';

  @override
  String get loginPromptTitle => '로그인하고 시작하세요';

  @override
  String get loginPromptSubtitle => '나만의 직관 기록을 저장하고 관리하세요';

  @override
  String get leagueStandings => '리그 순위';

  @override
  String get checkLeagueStandings => '각 리그 순위표 확인';

  @override
  String get upcomingMatches => '예정된 경기';

  @override
  String get matchAlertsPush => '경기 알림, 푸시 알림';

  @override
  String get timezoneSettings => '시간대 설정';

  @override
  String get matchTimeDisplay => '경기 시간 표시 기준';

  @override
  String get communityTitle => '커뮤니티';

  @override
  String get communityDesc => '직관 후기, 정보 공유';

  @override
  String get helpAndSupport => '도움말 및 지원';

  @override
  String get faqContact => 'FAQ, 문의하기';

  @override
  String get logout => '로그아웃';

  @override
  String get logoutConfirm => '정말 로그아웃하시겠습니까?';

  @override
  String get languageSettings => '언어 설정';

  @override
  String get korean => '한국어';

  @override
  String get english => 'English';

  @override
  String get systemDefault => '시스템 기본';

  @override
  String appVersion(String version) {
    return 'v$version';
  }

  @override
  String get liveMatches => '라이브 경기';

  @override
  String updatedSecondsAgo(int seconds) {
    return '$seconds초 전 업데이트';
  }

  @override
  String updatedMinutesAgo(int minutes) {
    return '$minutes분 전 업데이트';
  }

  @override
  String get autoRefresh30Sec => '30초마다 자동 갱신';

  @override
  String get noLiveMatchesTitle => '진행 중인 경기가 없습니다';

  @override
  String get noLiveMatchesDesc => '경기가 시작되면 여기서 실시간으로 확인하세요';

  @override
  String get breakPrep => '연장 준비';

  @override
  String firstHalfMinutes(int minutes) {
    return '전반 $minutes분';
  }

  @override
  String secondHalfMinutes(int minutes) {
    return '후반 $minutes분';
  }

  @override
  String get searchLeague => '리그 검색...';

  @override
  String get noSearchResults => '검색 결과가 없습니다';

  @override
  String get searchError => '검색 중 오류가 발생했습니다';

  @override
  String get top5Leagues => '5대 리그';

  @override
  String get euroClubComps => '유럽 대회';

  @override
  String get domesticCups => '국내 컵 대회';

  @override
  String get nationalComps => '국가대항전';

  @override
  String get otherLeagues => '기타 리그';

  @override
  String get myLocalLeague => '내 지역 리그';

  @override
  String get cannotLoadLeagues => '리그 목록을 불러올 수 없습니다';

  @override
  String get byCountry => '국가별';

  @override
  String get rank => '순위';

  @override
  String get goals => '득점';

  @override
  String get assists => '도움';

  @override
  String get played => '경기';

  @override
  String get won => '승';

  @override
  String get drawn => '무';

  @override
  String get lost => '패';

  @override
  String get gf => '득점';

  @override
  String get ga => '실점';

  @override
  String get gd => '득실';

  @override
  String get pts => '승점';

  @override
  String get appearances => '출전';

  @override
  String get noStandingsInfo => '순위 정보가 없습니다';

  @override
  String get cannotLoadStandings => '해당 리그의 순위 정보를 불러올 수 없습니다';

  @override
  String get noGoalRankInfo => '득점 순위 정보가 없습니다';

  @override
  String get noAssistRankInfo => '어시스트 순위 정보가 없습니다';

  @override
  String get noLeagueStats => '리그 통계 정보가 없습니다';

  @override
  String get recentForm => '최근 폼';

  @override
  String get last5Games => '최근 5경기';

  @override
  String get homeAwayStrength => '홈/원정 강자';

  @override
  String get homeStrength => '홈 강자';

  @override
  String get awayStrength => '원정 강자';

  @override
  String get bottomAnalysis => '하위권 분석';

  @override
  String get mostLosses => '최다 패배';

  @override
  String get mostConceded => '최다 실점';

  @override
  String get leagueOverview => '리그 개요';

  @override
  String get totalGoals => '총 골';

  @override
  String get goalsPerGame => '경기당 골';

  @override
  String get homeWins => '홈 승';

  @override
  String get awayWins => '원정 승';

  @override
  String get homeWin => '홈 승';

  @override
  String get awayWin => '원정 승';

  @override
  String nGames(int count) {
    return '$count경기';
  }

  @override
  String get teamRanking => '팀 순위';

  @override
  String get mostGoals => '최다 득점';

  @override
  String get mostConcededGoals => '최다 실점';

  @override
  String get mostWins => '최다 승리';

  @override
  String get mostDraws => '최다 무승부';

  @override
  String nGoals(int count) {
    return '$count골';
  }

  @override
  String nWins(int count) {
    return '$count승';
  }

  @override
  String nDraws(int count) {
    return '$count무';
  }

  @override
  String nLosses(int count) {
    return '$count패';
  }

  @override
  String nConceded(int count) {
    return '$count실점';
  }

  @override
  String get goalAnalysis => '골 분석';

  @override
  String get homeGoals => '홈 골';

  @override
  String get awayGoals => '원정 골';

  @override
  String get top5GD => '득실차 상위 5팀';

  @override
  String get cardRanking => '카드 순위';

  @override
  String get mostYellows => '최다 경고';

  @override
  String get mostReds => '최다 퇴장';

  @override
  String get noData => '데이터가 없습니다';

  @override
  String get recordNotFound => '기록을 찾을 수 없습니다';

  @override
  String get diary => '일기';

  @override
  String get details => '기록';

  @override
  String get broadcast => '중계';

  @override
  String get lineup => '라인업';

  @override
  String get h2h => '전적';

  @override
  String get matchDiary => '직관 일기';

  @override
  String get matchInfo => '경기 정보';

  @override
  String get date => '날짜';

  @override
  String get league => '리그';

  @override
  String get seat => '좌석';

  @override
  String get additionalInfo => '추가 정보';

  @override
  String get weather => '날씨';

  @override
  String get companions => '함께 간 사람';

  @override
  String get ticketPrice => '티켓 가격';

  @override
  String currencyWon(String price) {
    return '$price원';
  }

  @override
  String get stadiumFood => '경기장 음식';

  @override
  String get memo => '메모';

  @override
  String get mvpToday => '오늘의 MVP';

  @override
  String get noStatsInfo => '통계 정보가 없습니다';

  @override
  String get statsAfterMatch => '경기 종료 후 업데이트됩니다';

  @override
  String get possession => '점유율';

  @override
  String get shots => '슈팅';

  @override
  String get shotsOnTarget => '유효 슈팅';

  @override
  String get corners => '코너킥';

  @override
  String get fouls => '파울';

  @override
  String get offsides => '오프사이드';

  @override
  String get yellowCards => '경고';

  @override
  String get redCards => '퇴장';

  @override
  String get matchName => '경기명';

  @override
  String get homeTeam => '홈팀';

  @override
  String get awayTeam => '원정팀';

  @override
  String get homeShort => '홈 성적';

  @override
  String get awayShort => '원정 성적';

  @override
  String get score => '스코어';

  @override
  String get photos => '사진';

  @override
  String get camera => '카메라';

  @override
  String get gallery => '갤러리';

  @override
  String get tags => '태그';

  @override
  String get tagVictory => '승리';

  @override
  String get tagComeback => '역전';

  @override
  String get tagGoalFest => '골잔치';

  @override
  String get tagCleanSheet => '클린시트';

  @override
  String get tagFirstMatch => '첫직관';

  @override
  String get tagAway => '원정';

  @override
  String get currencyUnit => '원';

  @override
  String get switchToSearch => '검색으로';

  @override
  String get switchToManual => '직접 입력';

  @override
  String get addTag => '태그 추가';

  @override
  String get suggestedTags => '추천 태그';

  @override
  String get companionHint => '예: 친구들, 가족';

  @override
  String get foodReviewHint => '먹은 음식, 맛 평가 등';

  @override
  String get priceHint => '예: 50,000';

  @override
  String get penaltyGoal => '페널티골';

  @override
  String get ownGoal => '자책';

  @override
  String get goal => '골';

  @override
  String get yellowCard => '경고';

  @override
  String get redCard => '퇴장';

  @override
  String get card => '카드';

  @override
  String get substitution => '교체';

  @override
  String get grass => '잔디';

  @override
  String get resultWin => '승';

  @override
  String get resultDraw => '무';

  @override
  String get resultLoss => '패';

  @override
  String goalsScored(int home, int away) {
    return '득점 $home : $away';
  }

  @override
  String nMatches(int count) {
    return '$count경기';
  }

  @override
  String get capacity => '수용인원';

  @override
  String get profileTab => '프로필';

  @override
  String get careerTab => '커리어';

  @override
  String get matchesTab => '출전경기';

  @override
  String get noMatchRecords => '직관 기록이 없습니다';

  @override
  String get assist => '도움';

  @override
  String get matchesPlayed => '출전';

  @override
  String get playingTime => '출전시간';

  @override
  String get clubTeams => '소속팀';

  @override
  String get nationalTeam => '국가대표';

  @override
  String get season => '시즌';

  @override
  String get teamShort => '팀';

  @override
  String get matches => '경기';

  @override
  String get rating => '평점';

  @override
  String get started => '선발';

  @override
  String get goalkeeper => '골키퍼';

  @override
  String get defender => '수비수';

  @override
  String get midfielder => '미드필더';

  @override
  String get attacker => '공격수';

  @override
  String get nationality => '국적';

  @override
  String get birthDate => '생년월일';

  @override
  String get age => '나이';

  @override
  String ageYears(int years) {
    return '$years세';
  }

  @override
  String get height => '키';

  @override
  String get weight => '몸무게';

  @override
  String get birthPlace => '출생지';

  @override
  String get injured => '부상';

  @override
  String get suspended => '정지';

  @override
  String get other => '기타';

  @override
  String get seasonStats => '시즌 통계';

  @override
  String get playerInfo => '선수 정보';

  @override
  String get playerNotFoundDesc => '선수 정보를 찾을 수 없습니다';

  @override
  String get error => '오류';

  @override
  String get currentSeason => '현재 시즌';

  @override
  String seasonStatsSummary(String season) {
    return '$season 통계 요약';
  }

  @override
  String get noSeasonStats => '시즌 통계 정보가 없습니다';

  @override
  String get loadingSeasonStats => '시즌별 통계를 불러오는 중...';

  @override
  String get basicInfo => '기본 정보';

  @override
  String get injuryHistory => '부상/출전정지 이력';

  @override
  String nRecords(int count) {
    return '$count건';
  }

  @override
  String get currentlyOut => '현재 결장 중';

  @override
  String get recentHistory => '최근 이력';

  @override
  String get transferHistory => '이적 기록';

  @override
  String moreTransfers(int count) {
    return '외 $count건의 이적 기록';
  }

  @override
  String get trophies => '수상 경력';

  @override
  String nTrophies(int count) {
    return '$count개';
  }

  @override
  String get addedToFavorites => '즐겨찾기에 추가되었습니다';

  @override
  String get removedFromFavorites => '즐겨찾기에서 제거되었습니다';

  @override
  String get noTimelineInfo => '타임라인 정보가 없습니다';

  @override
  String get updatedAfterMatch => '경기 종료 후 업데이트됩니다';

  @override
  String assistBy(String name) {
    return '어시스트: $name';
  }

  @override
  String get noLineupInfo => '라인업 정보가 없습니다';

  @override
  String startersCount(int count) {
    return '선발 ($count)';
  }

  @override
  String get noStarterInfo => '선발 정보 없음';

  @override
  String substitutesCount(int count) {
    return '교체 ($count)';
  }

  @override
  String get noTeamInfo => '팀 정보가 없습니다';

  @override
  String get noH2HRecord => '상대전적 기록이 없습니다';

  @override
  String get recentMatches => '최근 경기';

  @override
  String get weatherSunny => '맑음 ☀️';

  @override
  String get weatherCloudy => '흐림 ☁️';

  @override
  String get weatherRainy => '비 🌧️';

  @override
  String get weatherSnowy => '눈 ❄️';

  @override
  String get weatherWindy => '바람 💨';

  @override
  String get matchRecord => '직관 기록';

  @override
  String get diaryWrite => '일기 작성';

  @override
  String get searchResults => '검색 결과';

  @override
  String get seatInfo => '좌석 정보';

  @override
  String get seatHint => '예: A블록 12열 34번';

  @override
  String get goToDiary => '일기 작성하기 →';

  @override
  String get oneLiner => '오늘의 한 줄';

  @override
  String get oneLinerHint => '경기를 한 줄로 표현한다면?';

  @override
  String get diarySection => '직관 일기';

  @override
  String get diaryHint => '오늘 경기는 어땠나요? 자유롭게 기록해보세요.';

  @override
  String get matchSearch => '경기 검색';

  @override
  String get manualInput => '직접 입력';

  @override
  String get teamSearchHint => '팀 이름으로 검색 (선택사항)';

  @override
  String get selectLeague => '리그 선택';

  @override
  String get enterMatchName => '경기명을 입력하세요';

  @override
  String get mySupportedTeam => '내가 응원한 팀';

  @override
  String get winDrawLossStats => '승/무/패 통계에 반영됩니다';

  @override
  String get searchOrEnterStadium => '경기장 검색 또는 직접 입력';

  @override
  String get todaysMatchRating => '오늘 경기 평점';

  @override
  String get ratingWorst => '최악 😢';

  @override
  String get ratingBest => '최고 🔥';

  @override
  String get todaysMood => '오늘의 기분';

  @override
  String get todaysMvp => '오늘의 MVP';

  @override
  String get selectPlayer => '선수 선택';

  @override
  String get selectMatchFirst => '먼저 경기를 선택해주세요';

  @override
  String get loginRequired => '로그인이 필요합니다';

  @override
  String get diarySaved => '직관 일기가 저장되었습니다!';

  @override
  String saveFailed(String error) {
    return '저장 실패: $error';
  }

  @override
  String get searchPlayerName => '선수 이름 검색';

  @override
  String get noPlayerInfo => '선수 정보가 없습니다';

  @override
  String get enterTeamNameDirectly => '팀 이름을 직접 입력하세요';

  @override
  String get teamName => '팀 이름';

  @override
  String searchTeamLabel(String label) {
    return '$label 검색';
  }

  @override
  String get moodExcited => '신남';

  @override
  String get moodHappy => '기쁨';

  @override
  String get moodSatisfied => '만족';

  @override
  String get moodNeutral => '보통';

  @override
  String get moodDisappointed => '아쉬움';

  @override
  String get moodSad => '슬픔';

  @override
  String get moodAngry => '분노';

  @override
  String get selectThisTeam => '이 팀으로 선택';

  @override
  String get searchByTeamName => '팀 이름으로 검색';

  @override
  String get selectLeagueOrSearchTeam => '리그를 선택하거나\n팀 이름을 검색하세요';

  @override
  String get venueSearch => '경기장 검색';

  @override
  String get enterVenueNameDirectly => '경기장 이름을 직접 입력하세요';

  @override
  String get venueName => '경기장 이름';

  @override
  String get selectThisVenue => '이 경기장으로 선택';

  @override
  String get selectCountry => '국가 선택';

  @override
  String get searchByVenueName => '경기장 이름으로 검색';

  @override
  String get selectCountryOrSearchVenue => '국가를 선택하거나\n경기장 이름을 검색하세요';

  @override
  String get noName => '이름 없음';

  @override
  String get editMatchRecord => '직관 기록 수정';

  @override
  String get editMatchDiary => '직관 일기 수정';

  @override
  String get cannotLoadRecord => '기록을 불러올 수 없습니다';

  @override
  String get saved => '수정되었습니다!';

  @override
  String get editDiary => '일기 수정';

  @override
  String get editDiaryButton => '일기 수정하기 →';

  @override
  String get addTagHint => '태그 추가';

  @override
  String get suggestedTagsLabel => '추천 태그';

  @override
  String get additionalInfoSection => '추가 정보';

  @override
  String get matchInfoNotFound => '경기 정보를 찾을 수 없습니다';

  @override
  String errorWithMessage(String message) {
    return '오류: $message';
  }

  @override
  String get tabComparison => '비교';

  @override
  String get tabStats => '기록';

  @override
  String get tabLineup => '라인업';

  @override
  String get tabRanking => '순위';

  @override
  String get tabPrediction => '예측';

  @override
  String get tabComments => '댓글';

  @override
  String get matchEnded => '경기 종료';

  @override
  String get leagueLabel => '리그';

  @override
  String get seasonLabel => '시즌';

  @override
  String get roundLabel => '라운드';

  @override
  String get dateLabel => '날짜';

  @override
  String get timeLabel => '시간';

  @override
  String get venueLabel => '경기장';

  @override
  String get statusLabel => '상태';

  @override
  String get refereeLabel => '주심';

  @override
  String get statusFinished => '경기 종료';

  @override
  String get statusHalftime => '하프타임';

  @override
  String get statusLive => '진행 중';

  @override
  String get statusScheduled => '예정';

  @override
  String get statusTBD => '시간 미정';

  @override
  String get statusPostponed => '연기';

  @override
  String get statusCancelled => '취소';

  @override
  String get statusAET => '연장 종료';

  @override
  String get statusPEN => '승부차기 종료';

  @override
  String get noPredictionInfo => '예측 정보가 없습니다';

  @override
  String get cannotLoadPrediction => '예측 정보를 불러올 수 없습니다';

  @override
  String get odds => '배당률';

  @override
  String get drawLabel => '무승부';

  @override
  String get liveOdds => '실시간 배당률';

  @override
  String get allCategory => '전체';

  @override
  String get noBettingInfo => '배팅 정보가 없습니다';

  @override
  String get categoryMainBets => '주요 배팅';

  @override
  String get categoryGoalRelated => '골 관련';

  @override
  String get categoryHandicap => '핸디캡';

  @override
  String get categoryHalfTime => '전/후반';

  @override
  String get categoryTeamRelated => '팀 관련';

  @override
  String get categoryOther => '기타';

  @override
  String initialOdd(String value) {
    return '초기 $value';
  }

  @override
  String get matchPrediction => '승부 예측';

  @override
  String get expectedWinner => '예상 승자';

  @override
  String get drawPrediction => '무승부';

  @override
  String get detailedAnalysis => '상세 분석';

  @override
  String get comparisonForm => '폼';

  @override
  String get comparisonAttack => '공격력';

  @override
  String get comparisonDefense => '수비력';

  @override
  String get comparisonH2H => '상대전적';

  @override
  String get comparisonGoals => '득점력';

  @override
  String lineupLoadError(String error) {
    return '라인업 로딩 오류: $error';
  }

  @override
  String get lineupUpdateBeforeMatch => '경기 시작 전 업데이트됩니다';

  @override
  String get substitutes => '교체 선수';

  @override
  String get substitutionRecord => '교체 기록';

  @override
  String get bench => '벤치';

  @override
  String get playerAppsLabel => '출전';

  @override
  String get playerGoalsLabel => '골';

  @override
  String get playerAssistsLabel => '어시스트';

  @override
  String get playerPassAccuracy => '패스 성공률';

  @override
  String get noMatchStats => '경기 통계가 없습니다';

  @override
  String get statsUpdateDuringMatch => '경기 중 또는 경기 후에 업데이트됩니다';

  @override
  String get attackSection => '공격';

  @override
  String get shotsLabel => '슈팅';

  @override
  String get shotsOnLabel => '유효 슈팅';

  @override
  String get offsidesLabel => '오프사이드';

  @override
  String get passSection => '패스';

  @override
  String get totalPassLabel => '총 패스';

  @override
  String get keyPassLabel => '키 패스';

  @override
  String get defenseSection => '수비';

  @override
  String get tackleLabel => '태클';

  @override
  String get interceptLabel => '인터셉트';

  @override
  String get blockLabel => '블록';

  @override
  String get duelDribbleSection => '듀얼 & 드리블';

  @override
  String get duelLabel => '듀얼';

  @override
  String get dribbleLabel => '드리블';

  @override
  String get foulCardSection => '파울 & 카드';

  @override
  String get foulLabel => '파울';

  @override
  String get foulDrawnLabel => '피파울';

  @override
  String get cardsLabel => '카드';

  @override
  String get goalkeeperSection => '골키퍼';

  @override
  String get savesLabel => '선방';

  @override
  String get concededLabel => '실점';

  @override
  String get viewPlayerDetail => '선수 상세 정보 보기';

  @override
  String get positionGoalkeeper => '골키퍼';

  @override
  String get positionDefender => '수비수';

  @override
  String get positionMidfielder => '미드필더';

  @override
  String get positionAttacker => '공격수';

  @override
  String get missingPlayers => '결장 선수';

  @override
  String get checkingMissingInfo => '결장 정보 확인 중...';

  @override
  String get injurySuspension => '정지';

  @override
  String get injuryKnee => '무릎 부상';

  @override
  String get injuryHamstring => '햄스트링 부상';

  @override
  String get injuryAnkle => '발목 부상';

  @override
  String get injuryMuscle => '근육 부상';

  @override
  String get injuryBack => '허리 부상';

  @override
  String get injuryIllness => '질병';

  @override
  String get injuryGeneral => '부상';

  @override
  String get injuryDoubtful => '불투명';

  @override
  String get injuryOut => '결장';

  @override
  String get sectionStats => '기록';

  @override
  String get sectionBroadcast => '중계';

  @override
  String get cannotLoadTimeline => '타임라인을 불러올 수 없습니다';

  @override
  String get possessionLabel => '점유율';

  @override
  String get cornersLabel => '코너킥';

  @override
  String get foulsLabel => '파울';

  @override
  String get warningsLabel => '경고';

  @override
  String get sendOffsLabel => '퇴장';

  @override
  String assistLabel(String name) {
    return '어시스트: $name';
  }

  @override
  String get goalLabel => '골';

  @override
  String get warningCard => '경고';

  @override
  String get sendOffCard => '퇴장';

  @override
  String get cardLabel => '카드';

  @override
  String get substitutionLabel => '교체';

  @override
  String get matchNotificationSettings => '경기 알림 설정';

  @override
  String get turnOffNotification => '알림 해제';

  @override
  String get cancelLabel => '취소';

  @override
  String get saveLabel => '저장';

  @override
  String get leagueRanking => '리그 순위';

  @override
  String get homeAwayRecord => '홈/원정 성적';

  @override
  String get last5Matches => '최근 5경기';

  @override
  String get goalStats => '득점/실점 통계';

  @override
  String get teamStyleComparison => '팀 스타일 비교';

  @override
  String get keyPlayers => '주요 선수';

  @override
  String get h2hRecord => '상대전적';

  @override
  String get winLabel => '승';

  @override
  String get drawShortLabel => '무';

  @override
  String goalsDisplay(int home, int away) {
    return '득점 $home : $away';
  }

  @override
  String recentNMatches(int count) {
    return '최근 $count경기';
  }

  @override
  String get noRankingInfo => '순위 정보가 없습니다';

  @override
  String get rankingLabel => '순위';

  @override
  String get pointsLabel => '승점';

  @override
  String get matchesPlayedLabel => '경기';

  @override
  String get winDrawLossLabel => '승-무-패';

  @override
  String get goalsForLabel => '득점';

  @override
  String get goalsAgainstLabel => '실점';

  @override
  String get goalDiffLabel => '득실차';

  @override
  String get dataLoadFailed => '데이터 로드 실패';

  @override
  String get noRecordInfo => '성적 정보가 없습니다';

  @override
  String get avgGoalsFor => '평균 득점';

  @override
  String get avgGoalsAgainst => '평균 실점';

  @override
  String get noStatsAvailable => '통계 정보가 없습니다';

  @override
  String get totalGoalsFor => '총 득점';

  @override
  String get totalGoalsAgainst => '총 실점';

  @override
  String get goalsPerMatch => '경기당 득점';

  @override
  String get concededPerMatch => '경기당 실점';

  @override
  String get noPlayerStats => '선수 통계 정보가 없습니다';

  @override
  String get goalLeaders => '득점 리더';

  @override
  String get assistLeaders => '도움 리더';

  @override
  String get assistDataLoadFailed => '도움 데이터 로드 실패';

  @override
  String get cannotLoadPlayerStats => '선수 통계를 불러올 수 없습니다';

  @override
  String get radarWinRate => '승률';

  @override
  String get radarAttack => '공격력';

  @override
  String get radarDefense => '수비력';

  @override
  String get radarCleanSheet => '클린시트';

  @override
  String get radarHomeRecord => '홈 성적';

  @override
  String get cleanSheetLabel => '클린시트';

  @override
  String get failedToScoreLabel => '무득점 경기';

  @override
  String get cannotLoadRanking => '순위를 불러올 수 없습니다';

  @override
  String get retryButton => '다시 시도';

  @override
  String get teamColumnHeader => '팀';

  @override
  String get matchesColumnHeader => '경기';

  @override
  String get winsColumnHeader => '승';

  @override
  String get drawsColumnHeader => '무';

  @override
  String get lossesColumnHeader => '패';

  @override
  String get goalDiffColumnHeader => '득실';

  @override
  String get pointsColumnHeader => '승점';

  @override
  String get matchTeams => '경기 팀';

  @override
  String get relegationLabel => '강등';

  @override
  String get promotionLabel => '승격';

  @override
  String get playoffLabel => '플레이오프';

  @override
  String get advanceLabel => '진출';

  @override
  String get matchGroup => '경기 조';

  @override
  String commentWriteFailed(String error) {
    return '댓글 작성 실패: $error';
  }

  @override
  String get deleteComment => '댓글 삭제';

  @override
  String get deleteCommentConfirm => '이 댓글을 삭제하시겠습니까?';

  @override
  String get deleteButton => '삭제';

  @override
  String get commentDeleted => '댓글이 삭제되었습니다';

  @override
  String deleteFailed(String error) {
    return '삭제 실패: $error';
  }

  @override
  String get liveComments => '실시간 댓글';

  @override
  String get commentsRefreshed => '댓글을 새로고침했습니다';

  @override
  String get refreshButton => '새로고침';

  @override
  String get cannotLoadComments => '댓글을 불러올 수 없습니다';

  @override
  String get noCommentsYet => '아직 댓글이 없습니다.\n첫 번째 댓글을 남겨보세요!';

  @override
  String get beFirstToComment => '첫 댓글을 남겨보세요!';

  @override
  String get commentInputHint => '댓글을 입력하세요...';

  @override
  String get justNow => '방금 전';

  @override
  String get noPlayerStatsInfo => '선수 통계 정보가 없습니다';

  @override
  String get topScorer => '득점 리더';

  @override
  String get topAssister => '도움 리더';

  @override
  String nAssists(int count) {
    return '$count도움';
  }

  @override
  String seasonWithYear(int year, int nextYear) {
    return '$year-$nextYear 시즌';
  }

  @override
  String get goalDifference => '득실';

  @override
  String get standingsErrorMessage => '순위를 불러올 수 없습니다';

  @override
  String nTimes(int count) {
    return '$count회';
  }

  @override
  String nPlayers(int count) {
    return '$count명';
  }

  @override
  String get matchTeam => '경기 팀';

  @override
  String get relegation => '강등';

  @override
  String get promotion => '승격';

  @override
  String get playoff => '플레이오프';

  @override
  String groupStageWithYear(int year) {
    return '$year 조별리그';
  }

  @override
  String get qualified => '진출';

  @override
  String get betCategoryMain => '주요 배팅';

  @override
  String get betCategoryGoal => '골 관련';

  @override
  String get betCategoryHandicap => '핸디캡';

  @override
  String get betCategoryHalf => '전/후반';

  @override
  String get betCategoryTeam => '팀 관련';

  @override
  String get betCategoryOther => '기타';

  @override
  String get betMatchWinner => '승무패';

  @override
  String get betHomeAway => '홈/원정';

  @override
  String get betDoubleChance => '더블찬스';

  @override
  String get betBothTeamsScore => '양팀 득점';

  @override
  String get betExactScore => '정확한 스코어';

  @override
  String get betGoalsOverUnder => '총 골 수';

  @override
  String get betOverUnder => '오버/언더';

  @override
  String get betAsianHandicap => '아시안 핸디캡';

  @override
  String get betHandicap => '핸디캡';

  @override
  String get betFirstHalfWinner => '전반 승패';

  @override
  String get betSecondHalfWinner => '후반 승패';

  @override
  String get betHalfTimeFullTime => '전반/후반 결과';

  @override
  String get betOddEven => '홀/짝';

  @override
  String get betTotalHome => '홈팀 총 골';

  @override
  String get betTotalAway => '원정팀 총 골';

  @override
  String get betCleanSheetHome => '홈팀 무실점';

  @override
  String get betCleanSheetAway => '원정팀 무실점';

  @override
  String get betWinToNilHome => '홈팀 완봉승';

  @override
  String get betWinToNilAway => '원정팀 완봉승';

  @override
  String get betCornersOverUnder => '코너킥 수';

  @override
  String get betCardsOverUnder => '카드 수';

  @override
  String get betFirstTeamToScore => '선제골 팀';

  @override
  String get betLastTeamToScore => '마지막 득점 팀';

  @override
  String get betHighestScoringHalf => '최다 득점 반';

  @override
  String get betToScoreInBothHalves => '양 반전 득점';

  @override
  String get betHomeWinBothHalves => '홈팀 양 반전 승리';

  @override
  String get betAwayWinBothHalves => '원정팀 양 반전 승리';

  @override
  String get cannotLoadLeagueInfo => '리그 정보를 불러올 수 없습니다';

  @override
  String get topScorersRanking => '득점 순위';

  @override
  String get topAssistsRanking => '도움 순위';

  @override
  String get noTopScorersInfo => '득점 순위 정보가 없습니다';

  @override
  String get noTopAssistsInfo => '도움 순위 정보가 없습니다';

  @override
  String get cannotLoadTopScorers => '득점 순위를 불러올 수 없습니다';

  @override
  String get cannotLoadTopAssists => '도움 순위를 불러올 수 없습니다';

  @override
  String get goalsFor => '득점';

  @override
  String get goalsAgainst => '실점';

  @override
  String get uclDirect => 'UCL 직행';

  @override
  String get uclQualification => 'UCL 예선';

  @override
  String get uelDirect => 'UEL 직행';

  @override
  String get mon => '월';

  @override
  String get tue => '화';

  @override
  String get wed => '수';

  @override
  String get thu => '목';

  @override
  String get fri => '금';

  @override
  String get sat => '토';

  @override
  String get sun => '일';

  @override
  String dateWithWeekday(Object day, Object month, Object weekday) {
    return '$month월 $day일 ($weekday)';
  }

  @override
  String get matchFinished => '종료';

  @override
  String get noMatchSchedule => '경기 일정이 없습니다';

  @override
  String get tomorrow => '내일';

  @override
  String get yesterday => '어제';

  @override
  String get champion => '우승';

  @override
  String get finalMatch => '결승전';

  @override
  String get runnerUp => '준우승';

  @override
  String get currentRank => '현재 순위';

  @override
  String get seasonEnd => '시즌 종료';

  @override
  String get winShortForm => '승';

  @override
  String get drawShortForm => '무';

  @override
  String get lossShortForm => '패';

  @override
  String xMatches(int count) {
    return '$count경기';
  }

  @override
  String xPoints(int count) {
    return '$count점';
  }

  @override
  String xGoals(int count) {
    return '$count골';
  }

  @override
  String todayWithDate(String date) {
    return '오늘 $date';
  }

  @override
  String tomorrowWithDate(String date) {
    return '내일 $date';
  }

  @override
  String yesterdayWithDate(String date) {
    return '어제 $date';
  }

  @override
  String get info => '정보';

  @override
  String get statistics => '통계';

  @override
  String get squad => '선수단';

  @override
  String get transfers => '이적';

  @override
  String get country => '국가';

  @override
  String get founded => '창단';

  @override
  String get type => '유형';

  @override
  String get code => '코드';

  @override
  String get manager => '감독';

  @override
  String get cleanSheet => '클린시트';

  @override
  String get failedToScore => '무득점';

  @override
  String get penaltyKick => '페널티킥';

  @override
  String get hamstring => '햄스트링';

  @override
  String get illness => '질병';

  @override
  String get doubtful => '불투명';

  @override
  String get absent => '결장';

  @override
  String get forward => '공격수';

  @override
  String get incoming => '영입';

  @override
  String get outgoing => '방출';

  @override
  String get loan => '임대';

  @override
  String get transfer => '이적';

  @override
  String foundedYear(int year) {
    return '창단 $year';
  }

  @override
  String foundedIn(int year) {
    return '창단 $year';
  }

  @override
  String seasonFormat(int year1, int year2) {
    return '$year1/$year2 시즌';
  }

  @override
  String averageFormat(String value) {
    return '평균 $value';
  }

  @override
  String homeAwayFormat(int home, int away) {
    return '홈 $home / 원정 $away';
  }

  @override
  String get homeAwayComparison => '홈/원정 비교';

  @override
  String get goalsByMinute => '시간대별 골 분포';

  @override
  String get injurySuspended => '정지';

  @override
  String get injuryAbsent => '결장';

  @override
  String get positionForward => '공격수';

  @override
  String get filterAll => '전체';

  @override
  String get transferIncoming => '영입';

  @override
  String get transferOutgoing => '방출';

  @override
  String get transferTypeLoan => '임대';

  @override
  String get transferTypePermanent => '이적';

  @override
  String get transferLoanReturn => '임대 복귀';

  @override
  String get freeTransfer => '프리';

  @override
  String get freeTransferLabel => '자유 이적';

  @override
  String get transferFee => '이적료';

  @override
  String get noTransferInfo => '이적 정보가 없습니다';

  @override
  String get teamInfo => '팀 정보';

  @override
  String get homeStadium => '홈 경기장';

  @override
  String careerTeamCount(int count) {
    return '경력: $count개 팀';
  }

  @override
  String get seasonRecord => '시즌 성적';

  @override
  String get seasonRecordTitle => '시즌 기록';

  @override
  String get longestWinStreak => '최다 연승';

  @override
  String get homeBiggestWin => '홈 최다 득점 승리';

  @override
  String get awayBiggestWin => '원정 최다 득점 승리';

  @override
  String get homeBiggestLoss => '홈 최다 실점 패배';

  @override
  String get awayBiggestLoss => '원정 최다 실점 패배';

  @override
  String get noSchedule => '일정이 없습니다';

  @override
  String get pastMatches => '지난 경기';

  @override
  String get injuredPlayers => '부상/결장 선수';

  @override
  String get unknownTeam => '알 수 없음';

  @override
  String transferFromTeam(String teamName) {
    return '← $teamName';
  }

  @override
  String transferToTeam(String teamName) {
    return '→ $teamName';
  }

  @override
  String yearsCount(int count) {
    return '$count년';
  }

  @override
  String winStreak(int count) {
    return '$count연승';
  }

  @override
  String currentLanguage(String language) {
    return '현재: $language';
  }

  @override
  String get languageChangeNote => '언어를 변경하면 앱의 모든 텍스트가 해당 언어로 표시됩니다.';

  @override
  String get profileEdit => '프로필 수정';

  @override
  String get name => '이름';

  @override
  String get selectFavoriteTeam => '응원팀 선택';

  @override
  String get favoriteTeamDescription => '좋아하는 팀을 선택하면 관련 경기 정보를 우선적으로 보여드려요';

  @override
  String get noFavoriteTeam => '선택한 팀 없음';

  @override
  String get profileSaved => '프로필이 저장되었습니다';

  @override
  String get pleaseEnterName => '이름을 입력해주세요';

  @override
  String get timezoneDescription => '경기 시간을 선택한 시간대에 맞춰 표시합니다';

  @override
  String get matchNotifications => '경기 알림';

  @override
  String get matchNotificationsDesc => '경기 시작 전 알림을 받습니다';

  @override
  String get liveScoreNotifications => '실시간 점수 알림';

  @override
  String get liveScoreNotificationsDesc => '골, 레드카드 등 주요 이벤트 알림';

  @override
  String get communityNotifications => '커뮤니티 알림';

  @override
  String get communityNotificationsDesc => '좋아요, 댓글 등 새 알림';

  @override
  String get marketingNotifications => '마케팅 알림';

  @override
  String get marketingNotificationsDesc => '이벤트, 프로모션 등 알림';

  @override
  String get helpSupport => '도움말 및 지원';

  @override
  String get faq => '자주 묻는 질문';

  @override
  String get contactSupport => '고객 지원 문의';

  @override
  String get enterDisplayName => '표시될 이름을 입력하세요';

  @override
  String get email => '이메일';

  @override
  String get changePassword => '비밀번호 변경';

  @override
  String get changePasswordDesc => '계정 보안을 위해 정기적으로 변경하세요';

  @override
  String get deleteAccount => '회원 탈퇴';

  @override
  String get deleteAccountDesc => '탈퇴 시 모든 데이터가 삭제됩니다';

  @override
  String get profilePhoto => '프로필 사진 변경';

  @override
  String get selectFromGallery => '갤러리에서 선택';

  @override
  String get selectFromGalleryDesc => '저장된 사진에서 선택합니다';

  @override
  String get takePhoto => '카메라로 촬영';

  @override
  String get takePhotoDesc => '새로운 사진을 촬영합니다';

  @override
  String get deletePhoto => '사진 삭제';

  @override
  String get deletePhotoDesc => '프로필 사진을 제거합니다';

  @override
  String get photoUploaded => '사진이 업로드되었습니다. 저장을 눌러 적용하세요.';

  @override
  String photoUploadFailed(String error) {
    return '사진 업로드 실패: $error';
  }

  @override
  String get photoWillBeDeleted => '사진이 삭제됩니다. 저장을 눌러 적용하세요.';

  @override
  String get profileUpdated => '프로필이 수정되었습니다';

  @override
  String updateFailed(String error) {
    return '수정 실패: $error';
  }

  @override
  String get currentPassword => '현재 비밀번호';

  @override
  String get newPassword => '새 비밀번호';

  @override
  String get confirmNewPassword => '새 비밀번호 확인';

  @override
  String get passwordMinLength => '8자 이상 입력하세요';

  @override
  String get passwordMismatch => '새 비밀번호가 일치하지 않습니다';

  @override
  String get passwordTooShort => '비밀번호는 6자 이상이어야 합니다';

  @override
  String get passwordChangePreparing => '비밀번호 변경 기능 준비 중';

  @override
  String get change => '변경';

  @override
  String get confirmDeleteAccount => '정말 탈퇴하시겠습니까?';

  @override
  String get deleteWarningRecords => '모든 직관 기록이 삭제됩니다';

  @override
  String get deleteWarningFavorites => '즐겨찾기 정보가 삭제됩니다';

  @override
  String get deleteWarningPhoto => '프로필 사진이 삭제됩니다';

  @override
  String get deleteWarningIrreversible => '이 작업은 되돌릴 수 없습니다';

  @override
  String get deleteAccountPreparing => '회원 탈퇴 기능 준비 중';

  @override
  String get timezoneSettingsTitle => '타임존 설정';

  @override
  String get searchTimezone => '타임존 검색...';

  @override
  String get currentSetting => '현재 설정';

  @override
  String timezoneChanged(String name) {
    return '타임존이 $name으로 변경되었습니다';
  }

  @override
  String get timezoneKoreaSeoul => '한국 (서울)';

  @override
  String get timezoneJapanTokyo => '일본 (도쿄)';

  @override
  String get timezoneChinaShanghai => '중국 (상하이)';

  @override
  String get timezoneSingapore => '싱가포르';

  @override
  String get timezoneHongKong => '홍콩';

  @override
  String get timezoneThailandBangkok => '태국 (방콕)';

  @override
  String get timezoneIndonesiaJakarta => '인도네시아 (자카르타)';

  @override
  String get timezoneIndiaKolkata => '인도 (콜카타)';

  @override
  String get timezoneUAEDubai => 'UAE (두바이)';

  @override
  String get timezoneUKLondon => '영국 (런던)';

  @override
  String get timezoneFranceParis => '프랑스 (파리)';

  @override
  String get timezoneGermanyBerlin => '독일 (베를린)';

  @override
  String get timezoneItalyRome => '이탈리아 (로마)';

  @override
  String get timezoneSpainMadrid => '스페인 (마드리드)';

  @override
  String get timezoneNetherlandsAmsterdam => '네덜란드 (암스테르담)';

  @override
  String get timezoneRussiaMoscow => '러시아 (모스크바)';

  @override
  String get timezoneUSEastNewYork => '미국 동부 (뉴욕)';

  @override
  String get timezoneUSWestLA => '미국 서부 (LA)';

  @override
  String get timezoneUSCentralChicago => '미국 중부 (시카고)';

  @override
  String get timezoneBrazilSaoPaulo => '브라질 (상파울루)';

  @override
  String get timezoneAustraliaSydney => '호주 (시드니)';

  @override
  String get timezoneNewZealandAuckland => '뉴질랜드 (오클랜드)';

  @override
  String get pushNotifications => '푸시 알림';

  @override
  String get receivePushNotifications => '푸시 알림 받기';

  @override
  String get masterSwitch => '모든 알림의 마스터 스위치';

  @override
  String get favoriteTeamMatchNotifications => '즐겨찾기 팀 경기 알림';

  @override
  String get favoriteTeamMatchNotificationsDesc => '즐겨찾기한 팀의 경기에 대한 알림을 설정합니다';

  @override
  String get matchStartNotification => '경기 시작 알림';

  @override
  String get matchStartNotificationDesc => '즐겨찾기 팀 경기 시작 전 미리 알림';

  @override
  String get notificationTime => '알림 시간';

  @override
  String get notificationTimeDesc => '즐겨찾기 팀 경기 시작 전 알림 시간';

  @override
  String get minutes15Before => '15분 전';

  @override
  String get minutes30Before => '30분 전';

  @override
  String get hour1Before => '1시간 전';

  @override
  String get hours2Before => '2시간 전';

  @override
  String get newMatchScheduleNotification => '새 경기 일정 알림';

  @override
  String get newMatchScheduleNotificationDesc => '즐겨찾기 팀의 새로운 경기 일정 등록 알림';

  @override
  String get favoriteTeamLiveNotifications => '즐겨찾기 팀 실시간 알림';

  @override
  String get favoriteTeamLiveNotificationsDesc => '즐겨찾기한 팀의 경기 중 실시간 알림을 설정합니다';

  @override
  String get liveScoreUpdates => '라이브 스코어 업데이트';

  @override
  String get liveScoreUpdatesDesc => '즐겨찾기 팀 경기 중 골/이벤트 실시간 알림';

  @override
  String get favoritePlayerLiveNotifications => '즐겨찾기 선수 실시간 알림';

  @override
  String get favoritePlayerLiveNotificationsDesc =>
      '즐겨찾기한 선수의 이벤트 발생 시 알림을 설정합니다';

  @override
  String get favoritePlayerEvents => '선수 이벤트 알림';

  @override
  String get favoritePlayerEventsDesc => '즐겨찾기 선수 골/어시스트/레드카드 알림';

  @override
  String get notificationPermissionGuide => '알림 권한 안내';

  @override
  String get notificationPermissionDesc =>
      '알림을 받으려면 기기 설정에서 FootHub 앱의 알림 권한을 허용해주세요.';

  @override
  String errorWithMsg(String error) {
    return '오류 발생: $error';
  }

  @override
  String get helpAndSupportTitle => '도움말 및 지원';

  @override
  String get faqTitle => '자주 묻는 질문';

  @override
  String get contactUs => '문의하기';

  @override
  String get appInfo => '앱 정보';

  @override
  String get emailInquiry => '이메일 문의';

  @override
  String get bugReport => '버그 신고';

  @override
  String get bugReportDesc => '오류나 문제점을 알려주세요';

  @override
  String get featureSuggestion => '기능 제안';

  @override
  String get featureSuggestionDesc => '새로운 아이디어를 공유해주세요';

  @override
  String get appVersionLabel => '앱 버전';

  @override
  String get buildNumber => '빌드 번호';

  @override
  String get developer => '개발자';

  @override
  String get patchNotes => '패치노트';

  @override
  String get emailCopied => '이메일 앱을 열 수 없어 주소가 복사되었습니다';

  @override
  String get bugReportHint => '발견한 버그나 문제점을 자세히 설명해주세요...';

  @override
  String get featureSuggestionHint => '원하시는 기능을 자세히 설명해주세요...';

  @override
  String get submit => '제출';

  @override
  String get legalInfo => '법적 정보';

  @override
  String get privacyPolicy => '개인정보처리방침';

  @override
  String get termsOfService => '이용약관';

  @override
  String get supportWebsite => '지원 웹사이트';

  @override
  String get faqAddRecord => '직관 기록은 어떻게 추가하나요?';

  @override
  String get faqAddRecordAnswer =>
      '홈 화면이나 직관 일기 탭에서 + 버튼을 눌러 새로운 직관 기록을 추가할 수 있습니다. 경기 일정에서 원하는 경기를 선택한 후 \"직관 기록\" 버튼을 눌러도 됩니다.';

  @override
  String get faqAddFavorite => '즐겨찾기 팀은 어떻게 추가하나요?';

  @override
  String get faqAddFavoriteAnswer =>
      '내 정보 탭에서 즐겨찾기 섹션의 \"관리\" 버튼을 누르거나, 팀 상세 페이지에서 하트 버튼을 눌러 즐겨찾기에 추가할 수 있습니다.';

  @override
  String get faqSchedule => '경기 일정은 어디서 확인하나요?';

  @override
  String get faqScheduleAnswer =>
      '하단 메뉴의 \"일정\" 탭에서 캘린더 형태로 경기 일정을 확인할 수 있습니다. 리그별로 필터링도 가능합니다.';

  @override
  String get faqNotification => '알림은 어떻게 설정하나요?';

  @override
  String get faqNotificationAnswer =>
      '내 정보 > 알림 설정에서 경기 시작 알림, 즐겨찾기 팀 경기 알림 등을 설정할 수 있습니다.';

  @override
  String get faqSupportedLeagues => '지원하는 리그는 무엇인가요?';

  @override
  String get faqSupportedLeaguesAnswer =>
      'EPL(잉글랜드), 라리가(스페인), 분데스리가(독일), 세리에A(이탈리아), 리그앙(프랑스), K리그, 챔피언스리그, 유로파리그, 컨퍼런스리그를 지원합니다.';

  @override
  String get userDefault => '사용자';

  @override
  String get emptyAttendanceTitle => '직관 기록이 없습니다';

  @override
  String get emptyAttendanceSubtitle => '첫 번째 경기 직관을 기록해보세요!';

  @override
  String get addRecord => '기록 추가';

  @override
  String get emptyDiaryTitle => '다이어리 기록이 없습니다';

  @override
  String get emptyDiarySubtitle => '경기를 보고 기록해보세요!';

  @override
  String get viewSchedule => '일정 보기';

  @override
  String get emptyScheduleTitle => '오늘 경기가 없습니다';

  @override
  String get emptyScheduleSubtitle => '다른 날짜를 선택해보세요';

  @override
  String get emptyFavoritesTitle => '즐겨찾기가 없습니다';

  @override
  String get emptyFavoritesSubtitle => '좋아하는 팀과 선수를 추가해보세요!';

  @override
  String get findTeam => '팀 찾기';

  @override
  String get emptySearchTitle => '검색 결과가 없습니다';

  @override
  String emptySearchSubtitle(String query) {
    return '\"$query\"에 대한 결과가 없습니다';
  }

  @override
  String get errorTitle => '오류가 발생했습니다';

  @override
  String get errorDefaultSubtitle => '다시 시도해주세요';

  @override
  String get anonymous => '익명';

  @override
  String get monthJan => '1월';

  @override
  String get monthFeb => '2월';

  @override
  String get monthMar => '3월';

  @override
  String get monthApr => '4월';

  @override
  String get monthMay => '5월';

  @override
  String get monthJun => '6월';

  @override
  String get monthJul => '7월';

  @override
  String get monthAug => '8월';

  @override
  String get monthSep => '9월';

  @override
  String get monthOct => '10월';

  @override
  String get monthNov => '11월';

  @override
  String get monthDec => '12월';

  @override
  String yearMonthFormat(int year, int month) {
    return '$year년 $month월';
  }

  @override
  String get post => '게시글';

  @override
  String get postDeleted => '게시글이 삭제되었습니다';

  @override
  String get deletePost => '게시글 삭제';

  @override
  String get deletePostConfirm => '이 게시글을 삭제하시겠습니까?';

  @override
  String get postNotFound => '게시글을 찾을 수 없습니다';

  @override
  String get comment => '댓글';

  @override
  String commentCount(int count) {
    return '댓글 $count';
  }

  @override
  String get enterComment => '댓글을 입력하세요';

  @override
  String loadCommentsFailed(String error) {
    return '댓글을 불러오는데 실패했습니다: $error';
  }

  @override
  String get myAttendanceStats => '나의 직관 통계';

  @override
  String get totalAttendance => '총 직관';

  @override
  String attendanceCount(int count) {
    return '$count경기';
  }

  @override
  String winRatePercent(String rate) {
    return '$rate%';
  }

  @override
  String mostVisited(String stadium, int count) {
    return '최다 방문: $stadium ($count회)';
  }

  @override
  String minutesAgo(int minutes) {
    return '$minutes분 전';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours시간 전';
  }

  @override
  String daysAgo(int days) {
    return '$days일 전';
  }

  @override
  String get attendanceStats => '직관 통계';

  @override
  String get frequentStadiums => '자주 가는 구장';

  @override
  String get noAttendanceRecordsYet => '아직 직관 기록이 없습니다';

  @override
  String get postsLabel => '게시글';

  @override
  String get attendanceLabel => '직관';

  @override
  String get championship => '챔피언십';

  @override
  String get lowerSplit => '하위 스플릿';

  @override
  String get promotionPlayoff => '승격 PO';

  @override
  String get competition => '대회';

  @override
  String get seasonFormatChanged => '2024-25 시즌부터 새 리그 형식으로 변경되어';

  @override
  String get standingsNotAvailable => '순위표가 아직 제공되지 않습니다';

  @override
  String get checkScheduleTab => '일정 탭에서 경기 일정을 확인하세요';

  @override
  String get rankHeader => '순위';

  @override
  String get playerHeader => '선수';

  @override
  String get appsHeader => '출전';

  @override
  String get goalsHeader => '득점';

  @override
  String get assistsHeader => '어시';

  @override
  String get teamHeader => '팀';

  @override
  String get matchesHeader => '경기';

  @override
  String get wonHeader => '승';

  @override
  String get drawnHeader => '무';

  @override
  String get lostHeader => '패';

  @override
  String get gfHeader => '득점';

  @override
  String get gaHeader => '실점';

  @override
  String get gdHeader => '득실';

  @override
  String get ptsHeader => '승점';

  @override
  String get recentFormTitle => '최근 폼';

  @override
  String get homeAwayStrong => '홈/원정 강자';

  @override
  String get homeStrong => '홈 강자';

  @override
  String get awayStrong => '원정 강자';

  @override
  String get bottomAnalysisTitle => '하위권 분석';

  @override
  String get mostLossesLabel => '최다 패배';

  @override
  String lossesCount(int count) {
    return '$count패';
  }

  @override
  String get mostConcededLabel => '최다 실점';

  @override
  String concededCount(int count) {
    return '$count실점';
  }

  @override
  String get leagueOverviewTitle => '리그 개요';

  @override
  String get totalGoalsLabel => '총 골';

  @override
  String get goalsPerGameLabel => '경기당 골';

  @override
  String get homeWinsLabel => '홈 승리';

  @override
  String get awayWinsLabel => '원정 승리';

  @override
  String get homeWinShort => '홈 승';

  @override
  String get awayWinShort => '원정 승';

  @override
  String gamesCount(int count) {
    return '$count경기';
  }

  @override
  String get recentMatchRecords => '최근 직관 기록';

  @override
  String totalCount(int count) {
    return '총 $count개';
  }

  @override
  String get searchTitleContentAuthor => '제목, 내용, 작성자 검색';

  @override
  String get hasMatchRecord => '직관 기록 있음';

  @override
  String get clearAll => '전체 해제';

  @override
  String get noPostsYet => '아직 게시글이 없습니다';

  @override
  String get writeFirstPost => '첫 번째 게시글을 작성해보세요!';

  @override
  String get writePost => '글쓰기';

  @override
  String get noSearchResultsForQuery => '검색 결과가 없습니다';

  @override
  String get clearSearchQuery => '검색어 지우기';

  @override
  String get reset => '초기화';

  @override
  String get showOnlyWithMatchRecord => '직관 기록이 있는 게시글만 보기';

  @override
  String get matchDate => '경기 날짜';

  @override
  String get selectLeagueFilter => '리그 선택';

  @override
  String get allLeagues => '전체';

  @override
  String get searching => '검색 중...';

  @override
  String get searchMatch => '경기 검색';

  @override
  String searchResultsCount(int count) {
    return '검색 결과 ($count)';
  }

  @override
  String get noMatchesOnDate => '해당 날짜에 경기가 없습니다';

  @override
  String moreMatchesCount(int count) {
    return '외 $count개 더 있음';
  }

  @override
  String get applySelectedMatch => '선택한 경기로 필터 적용';

  @override
  String get apply => '적용하기';

  @override
  String get selected => '선택됨';

  @override
  String get enterTitle => '제목을 입력해주세요';

  @override
  String get enterContent => '내용을 입력해주세요';

  @override
  String get postEdited => '게시글이 수정되었습니다';

  @override
  String get postCreated => '게시글이 작성되었습니다';

  @override
  String get selectMatchRecord => '직관 기록 선택';

  @override
  String get deselectRecord => '선택 해제';

  @override
  String get loadingStats => '통계를 불러오는 중...';

  @override
  String get myAttendanceStatsTitle => '나의 직관 통계';

  @override
  String totalMatchesCount(int count) {
    return '$count경기';
  }

  @override
  String winRatePercentValue(String rate) {
    return '$rate%';
  }

  @override
  String mostVisitedStadium(String stadium, int count) {
    return '최다 방문: $stadium ($count회)';
  }

  @override
  String get editPost => '글 수정';

  @override
  String get register => '등록';

  @override
  String get enterTitleHint => '제목을 입력하세요';

  @override
  String get matchRecordLabel => '직관 기록';

  @override
  String get loadMyMatchRecord => '나의 직관 기록 불러오기 (선택)';

  @override
  String get myAttendanceStatsLabel => '나의 직관 통계';

  @override
  String get showMyStats => '나의 직관 통계 자랑하기 (선택)';

  @override
  String get contentHint => '내용을 입력하세요\n\n직관 후기, 경기 정보, 꿀팁 등을 자유롭게 공유해보세요!';

  @override
  String get tagsOptional => '태그 (선택)';

  @override
  String get tagInputHint => '태그 입력 (최대 5개)';

  @override
  String get add => '추가';

  @override
  String get communityGuideline => '타인을 비방하거나 불쾌감을 주는 내용은 삭제될 수 있습니다.';

  @override
  String get postNotFoundError => '게시글을 찾을 수 없습니다';

  @override
  String get noEditPermission => '수정 권한이 없습니다';

  @override
  String get noDeletePermission => '삭제 권한이 없습니다';

  @override
  String get commentNotFoundError => '댓글을 찾을 수 없습니다';

  @override
  String get matchLog => 'FootHub';

  @override
  String get myFootballRecord => '나만의 축구 직관 기록';

  @override
  String get emailLabel => '이메일';

  @override
  String get passwordLabel => '비밀번호';

  @override
  String get enterEmail => '이메일을 입력해주세요';

  @override
  String get invalidEmailFormat => '올바른 이메일 형식을 입력해주세요';

  @override
  String get enterPasswordPlease => '비밀번호를 입력해주세요';

  @override
  String get loginAction => '로그인';

  @override
  String get signUpAction => '회원가입';

  @override
  String get noAccountSignUp => '계정이 없으신가요? 회원가입';

  @override
  String get hasAccountLogin => '이미 계정이 있으신가요? 로그인';

  @override
  String get orDivider => '또는';

  @override
  String get continueWithGoogle => 'Google로 계속하기';

  @override
  String get continueWithApple => 'Apple로 계속하기';

  @override
  String get forgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get emailAlreadyInUse => '이미 사용 중인 이메일입니다';

  @override
  String get invalidEmailError => '올바르지 않은 이메일 형식입니다';

  @override
  String get weakPasswordError => '비밀번호가 너무 약합니다';

  @override
  String get userNotFoundError => '등록되지 않은 이메일입니다';

  @override
  String get wrongPasswordError => '비밀번호가 올바르지 않습니다';

  @override
  String get authServiceUnavailable => '인증 서비스를 사용할 수 없습니다. 잠시 후 다시 시도해주세요.';

  @override
  String get genericAuthError => '오류가 발생했습니다. 다시 시도해주세요.';

  @override
  String get resetPasswordTitle => '비밀번호 재설정';

  @override
  String get enterRegisteredEmail => '가입한 이메일을 입력하세요';

  @override
  String get sendButton => '보내기';

  @override
  String get passwordResetEmailSent => '비밀번호 재설정 이메일을 보냈습니다';

  @override
  String get untilOpening => '개막까지';

  @override
  String get scheduleTab => '일정';

  @override
  String get infoTab => '정보';

  @override
  String get squadTab => '선수단';

  @override
  String get selectCountryButton => '국가 선택하기';

  @override
  String get errorPrefix => '오류';

  @override
  String get cannotLoadTeamInfo => '팀 정보를 불러올 수 없습니다';

  @override
  String get basicInfoSection => '기본 정보';

  @override
  String get countryLabel => '국가';

  @override
  String get homeStadiumLabel => '홈 경기장';

  @override
  String get capacityLabel => '수용 인원';

  @override
  String capacityValue(int count) {
    return '$count명';
  }

  @override
  String get foundedLabel => '창단';

  @override
  String get last5Form => '최근 5경기 폼';

  @override
  String get noFormInfo => '폼 정보가 없습니다';

  @override
  String get loseShort => '패';

  @override
  String get cannotLoadFormInfo => '폼 정보를 불러올 수 없습니다';

  @override
  String get competitionsSection => '참가 대회';

  @override
  String get tapForLeagueDetail => '탭하여 리그 상세';

  @override
  String get noCompetitionInfo => '참가 대회 정보가 없습니다';

  @override
  String get cannotLoadCompetitionInfo => '대회 정보를 불러올 수 없습니다';

  @override
  String get noSquadInfo => '선수단 정보가 없습니다';

  @override
  String get goalkeepersSection => '골키퍼';

  @override
  String get defendersSection => '수비수';

  @override
  String get midfieldersSection => '미드필더';

  @override
  String get attackersSection => '공격수';

  @override
  String get squadInfoNote => '국가대표 선수단 정보는\n대회별로 소집됩니다';

  @override
  String get worldCup => '월드컵';

  @override
  String get worldCupQualAfc => '월드컵 예선 (AFC)';

  @override
  String get asianCup => '아시안컵';

  @override
  String get friendlyMatch => '친선경기';

  @override
  String get matchNameHint => '예: 친선경기, 프리시즌, FA컵';

  @override
  String get leaguesByCountry => '국가별 리그';

  @override
  String get mainCountries => '주요 국가';

  @override
  String get allCountries => '전체 국가';

  @override
  String get noCountryCode => '국가 코드가 없습니다';

  @override
  String get leagueSection => '리그';

  @override
  String get cupSection => '컵 대회';

  @override
  String get otherSection => '기타';

  @override
  String get invalidLeagueId => '잘못된 리그 ID입니다';

  @override
  String get deleteAction => '삭제';

  @override
  String get justNowShort => '방금 전';

  @override
  String get noBettingInCategory => '해당 카테고리에 배팅이 없습니다';

  @override
  String get anonymousUser => '익명';

  @override
  String get cannotFindComment => '댓글을 찾을 수 없습니다';

  @override
  String get noDeletePermissionComment => '삭제 권한이 없습니다';

  @override
  String get countryKorea => '대한민국';

  @override
  String get countryEngland => '잉글랜드';

  @override
  String get countrySpain => '스페인';

  @override
  String get countryGermany => '독일';

  @override
  String get countryItaly => '이탈리아';

  @override
  String get countryFrance => '프랑스';

  @override
  String get countryJapan => '일본';

  @override
  String noLeaguesInCountry(String country) {
    return '$country에 등록된 리그가 없습니다';
  }

  @override
  String get standingsTab => '순위';

  @override
  String get scorersTab => '득점';

  @override
  String get assistsTab => '도움';

  @override
  String get statsTab => '통계';

  @override
  String get noStandingsData => '순위 정보가 없습니다';

  @override
  String get cannotLoadStandingsForSeason => '해당 시즌의 순위 정보를 불러올 수 없습니다';

  @override
  String get noGoalRankData => '득점 순위 정보가 없습니다';

  @override
  String get noAssistRankData => '어시스트 순위 정보가 없습니다';

  @override
  String get noLeagueStatsData => '리그 통계 정보가 없습니다';

  @override
  String get leagueOverviewCard => '리그 개요';

  @override
  String nGamesLabel(int count) {
    return '$count경기';
  }

  @override
  String get teamRankingCard => '팀 순위';

  @override
  String get mostScoringTeam => '최다 득점';

  @override
  String get mostConcededTeam => '최다 실점';

  @override
  String get mostWinsTeam => '최다 승리';

  @override
  String get mostDrawsTeam => '최다 무승부';

  @override
  String nGoalsLabel(int count) {
    return '$count골';
  }

  @override
  String nWinsLabel(int count) {
    return '$count승';
  }

  @override
  String nDrawsLabel(int count) {
    return '$count무';
  }

  @override
  String get goalAnalysisCard => '골 분석';

  @override
  String totalNGoals(int count) {
    return '총 $count골';
  }

  @override
  String get top5GoalDiff => '득실차 상위 5팀';

  @override
  String errorLabel(String error) {
    return '오류: $error';
  }

  @override
  String get rankColumn => '순위';

  @override
  String get teamColumn => '팀';

  @override
  String get matchesColumn => '경기';

  @override
  String get winColumn => '승';

  @override
  String get drawColumn => '무';

  @override
  String get loseColumn => '패';

  @override
  String get goalsForColumn => '득점';

  @override
  String get goalsAgainstColumn => '실점';

  @override
  String get goalDiffColumn => '득실';

  @override
  String get pointsColumn => '승점';

  @override
  String get playerColumn => '선수';

  @override
  String get appsColumn => '출전';

  @override
  String get goalsColumn => '득점';

  @override
  String get assistsColumn => '어시';

  @override
  String get dateFormatFull => 'yyyy년 M월 d일 (E)';

  @override
  String get dateFormatMedium => 'yyyy년 M월 d일';

  @override
  String get dateFormatWithTime => 'yyyy.MM.dd (E) HH:mm';

  @override
  String get dateFormatShort => 'MM.dd (E)';

  @override
  String get dateFormatHeader => 'M월 d일 EEEE';

  @override
  String get dateFormatDiary => 'yyyy.MM.dd (E)';

  @override
  String get dateFormatSlash => 'yyyy/MM/dd (E)';

  @override
  String searchAllMatchesForDate(String date) {
    return '$date 전체 경기 조회';
  }

  @override
  String searchLeagueMatchesForDate(String date, String league) {
    return '$date $league 경기 조회';
  }

  @override
  String stadiumListForCountry(String country) {
    return '$country 경기장 목록';
  }

  @override
  String get leagueEPL => 'EPL';

  @override
  String get leagueLaLiga => '라리가';

  @override
  String get leagueSerieA => '세리에 A';

  @override
  String get leagueBundesliga => '분데스리가';

  @override
  String get leagueLigue1 => '리그 1';

  @override
  String get leagueKLeague1 => 'K리그1';

  @override
  String get leagueKLeague2 => 'K리그2';

  @override
  String get leagueUCL => 'UCL';

  @override
  String get leagueUEL => 'UEL';

  @override
  String get leagueUECL => 'UECL';

  @override
  String get leagueDomesticCups => '컵대회';

  @override
  String get leagueInternational => 'A매치';

  @override
  String leagueTeamList(String league) {
    return '$league 팀 목록';
  }

  @override
  String get worldCup2026 => '2026 FIFA 월드컵';

  @override
  String get myDiaryTitle => '나의 직관일기';

  @override
  String yearlySummary(int year) {
    return '$year년 직관 요약';
  }

  @override
  String get matchUnit => '경기';

  @override
  String nMatchesUnit(int count) {
    return '$count경기';
  }

  @override
  String nYearsUnit(int count) {
    return '$count년';
  }

  @override
  String get totalViews => '총 관람';

  @override
  String get averageRating => '평균 평점';

  @override
  String get pointsUnit => '점';

  @override
  String get invalidCoachId => '잘못된 감독 ID입니다';

  @override
  String get homeGoal => '홈 골';

  @override
  String get awayGoal => '원정 골';

  @override
  String get noDataAvailable => '데이터가 없습니다';

  @override
  String get loadFailedShort => '불러오기 실패';

  @override
  String get ageLabel => '나이';

  @override
  String get birthDateLabel => '생년월일';

  @override
  String get birthPlaceLabel => '출생지';

  @override
  String get championTitle => '우승';

  @override
  String get runnerUpTitle => '준우승';

  @override
  String get careerTitle => '경력';

  @override
  String get currentLabel => '현재';

  @override
  String get suspendedLabel => '정지';

  @override
  String get worldCupShort => '월드컵';

  @override
  String get asianCupShort => '아시안컵';

  @override
  String get friendlyMatchLabel => '친선경기';

  @override
  String ageYearsValue(int age) {
    return '$age세';
  }

  @override
  String get birthCountry => '출생 국가';

  @override
  String get coachCareer => '감독 경력';

  @override
  String careerYears(int years) {
    return '$years년';
  }

  @override
  String get trophyRecord => '수상 기록';

  @override
  String andNMore(int count) {
    return '외 $count개';
  }

  @override
  String get mostWatchedTeam => '가장 많이 본 팀';

  @override
  String get selectSeason => '시즌 선택';

  @override
  String get languageSubtitle => '한국어, English';

  @override
  String get suspensionHistory => '출전정지 이력';

  @override
  String nCases(int count) {
    return '$count건';
  }

  @override
  String get currentlySuspended => '현재 출전정지 중';

  @override
  String get coachInfo => '감독 정보';

  @override
  String get errorLoginRequired => '로그인이 필요합니다';

  @override
  String get errorPostNotFound => '게시글을 찾을 수 없습니다';

  @override
  String get errorPostEditPermissionDenied => '수정 권한이 없습니다';

  @override
  String get errorPostDeletePermissionDenied => '삭제 권한이 없습니다';

  @override
  String get errorCommentNotFound => '댓글을 찾을 수 없습니다';

  @override
  String get errorCommentDeletePermissionDenied => '삭제 권한이 없습니다';

  @override
  String get errorNetworkError => '네트워크 오류가 발생했습니다';

  @override
  String get errorUnknown => '알 수 없는 오류가 발생했습니다';

  @override
  String get injuryGroin => '사타구니 부상';

  @override
  String get injuryShoulder => '어깨 부상';

  @override
  String get injuryAchilles => '아킬레스 부상';

  @override
  String get injuryCalf => '종아리 부상';

  @override
  String get injuryThigh => '허벅지 부상';

  @override
  String get injuryHip => '엉덩이 부상';

  @override
  String get injuryFracture => '골절';

  @override
  String get injuryConcussion => '뇌진탕';

  @override
  String get injuryLigament => '인대 부상';

  @override
  String get injurySurgery => '수술';

  @override
  String get statusSuspension => '출전정지';

  @override
  String get statusRedCard => '레드카드 징계';

  @override
  String get statusYellowCard => '옐로카드 누적';

  @override
  String get statusBan => '출전금지';

  @override
  String get statusDisciplinary => '징계';

  @override
  String get statusMissing => '결장';

  @override
  String get statusPersonal => '개인 사유';

  @override
  String get statusInternational => '국가대표 차출';

  @override
  String get statusRest => '휴식';

  @override
  String get statusFitness => '컨디션 조절';

  @override
  String get statusSuspended => '출전 정지';

  @override
  String get statusInjury => '부상';

  @override
  String get statusDoubtful => '출전 불투명';

  @override
  String get statusAbsent => '결장';

  @override
  String get betFirstHalfOU => '전반 오버/언더';

  @override
  String get betSecondHalfOU => '후반 오버/언더';

  @override
  String get betHalfFullTime => '전반/풀타임';

  @override
  String get betHomeTeamGoals => '홈팀 골';

  @override
  String get betAwayTeamGoals => '원정팀 골';

  @override
  String get betDrawNoBet => '무승부 제외';

  @override
  String get betResultBothScore => '결과+양팀득점';

  @override
  String get betFirstHalfExact => '전반 정확한 스코어';

  @override
  String get betGoalsDifference => '골 차이';

  @override
  String get periodOngoing => '진행 중';

  @override
  String get periodCurrent => '현재';

  @override
  String get errorNetwork => '인터넷 연결을 확인해주세요';

  @override
  String get errorTimeout => '서버 응답이 없습니다. 잠시 후 다시 시도해주세요';

  @override
  String get errorServer => '일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요';

  @override
  String get errorFirebasePermission => '접근 권한이 없습니다';

  @override
  String get errorFirebaseNotFound => '요청한 데이터를 찾을 수 없습니다';

  @override
  String get errorFirebaseUnavailable => '서비스를 일시적으로 사용할 수 없습니다';

  @override
  String get accountDeleted => '회원 탈퇴가 완료되었습니다';

  @override
  String accountDeleteFailed(String error) {
    return '회원 탈퇴 실패: $error';
  }

  @override
  String get report => '신고';

  @override
  String get reportPost => '게시글 신고';

  @override
  String get reportComment => '댓글 신고';

  @override
  String get reportUser => '사용자 신고';

  @override
  String get reportReason => '신고 사유';

  @override
  String get reportReasonSpam => '스팸/광고';

  @override
  String get reportReasonHarassment => '욕설/비방';

  @override
  String get reportReasonInappropriate => '부적절한 콘텐츠';

  @override
  String get reportReasonFalseInfo => '허위 정보';

  @override
  String get reportReasonOther => '기타';

  @override
  String get reportAdditionalInfo => '추가 설명 (선택)';

  @override
  String get reportAdditionalInfoHint => '신고 사유를 자세히 입력해주세요';

  @override
  String get reportSubmit => '신고하기';

  @override
  String get reportSubmitted => '신고가 접수되었습니다';

  @override
  String reportFailed(String error) {
    return '신고 접수 실패: $error';
  }

  @override
  String get reportAlreadySubmitted => '이미 신고한 콘텐츠입니다';

  @override
  String get reportConfirmTitle => '신고하시겠습니까?';

  @override
  String get reportConfirmMessage => '허위 신고는 제재를 받을 수 있습니다.';

  @override
  String get blockUser => '사용자 차단';

  @override
  String get blockUserConfirm => '이 사용자를 차단하시겠습니까?';

  @override
  String get blockUserDesc => '차단한 사용자 관리';

  @override
  String get userBlocked => '사용자가 차단되었습니다';

  @override
  String get blockedUsersManagement => '차단 사용자 관리';

  @override
  String get noBlockedUsers => '차단한 사용자가 없습니다';

  @override
  String get blockedUser => '차단된 사용자';

  @override
  String get unblock => '차단 해제';

  @override
  String get unblockUser => '차단 해제';

  @override
  String get unblockUserConfirm => '이 사용자의 차단을 해제하시겠습니까?';

  @override
  String get userUnblocked => '차단이 해제되었습니다';

  @override
  String get tournamentOverview => '대회 개요';

  @override
  String get avgGoals => '평균 골';

  @override
  String get cleanSheets => '클린시트';

  @override
  String get penaltyShootout => '승부차기';

  @override
  String get highScoringMatches => '다득점 경기';

  @override
  String get regularTime => '정규 시간';

  @override
  String get biggestWins => '대승 경기';

  @override
  String get roundStats => '라운드별 통계';

  @override
  String get round => '라운드';

  @override
  String liveGoalTeam(String team) {
    return '$team 골!';
  }

  @override
  String liveGoalPlayer(String player) {
    return '$player 골!';
  }

  @override
  String liveAssist(String player) {
    return '$player 어시스트!';
  }

  @override
  String get liveRedCard => '레드카드!';

  @override
  String liveGoalWithAssist(String time, String scorer, String assist) {
    return '$time $scorer (어시스트: $assist)';
  }

  @override
  String liveGoalNoAssist(String time, String scorer) {
    return '$time $scorer';
  }

  @override
  String liveEventTime(String time, String player, String team) {
    return '$time $player ($team)';
  }

  @override
  String matchVs(String home, String away) {
    return '$home vs $away';
  }
}
