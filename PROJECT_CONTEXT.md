# MatchLog 프로젝트 컨텍스트

## 프로젝트 개요
- **앱 이름**: MatchLog (직관 일기 앱)
- **설명**: 축구 경기 직관 기록을 남기고, 커뮤니티에서 다른 팬들과 소통하는 앱
- **기술 스택**: Flutter + Firebase (Firestore, Storage, Auth)
- **상태 관리**: Riverpod (StateNotifier, Provider 패턴)
- **라우팅**: GoRouter (선언적 라우팅)
- **외부 API**: TheSportsDB (경기 정보, 팀, 선수 데이터)
- **API 키**: 869004 (Premium)

---

## 앱 구조 (5개 탭)

### 1. 홈 (Home) - 첫 번째 탭
- 즐겨찾기 팀의 다음 경기 일정 카드로 표시
- D-day 계산 (한국 시간 기준, 날짜만 비교)
- 최근 직관 기록 요약

### 2. 일정 (Schedule) - 두 번째 탭
- 리그별 경기 일정 조회
- 날짜별 경기 목록
- 경기 상세 정보 (라인업, 통계, 타임라인)

### 3. 직관 일기 (Diary) - 세 번째 탭
- 내 직관 기록 목록
- 직관 기록 추가/수정/삭제
- 사진, 좌석 정보, 평점, 기분, MVP 등 기록

### 4. 커뮤니티 (Community) - 네 번째 탭
- 게시글 목록/작성/상세
- 검색 및 경기 필터 기능
- 좋아요, 댓글 기능

### 5. 내 정보 (Profile) - 다섯 번째 탭
- 프로필 정보 표시/수정
- 즐겨찾기 팀 관리
- 설정

---

## 주요 기능 상세

### 직관 일기 (Attendance/Diary)

**파일 위치**:
- `lib/features/attendance/screens/attendance_add_screen.dart` (2800+ 줄)
- `lib/features/attendance/screens/attendance_detail_screen.dart`
- `lib/features/attendance/screens/attendance_edit_screen.dart`
- `lib/features/diary/` 폴더

**기능**:
1. 경기 선택 방식 2가지:
   - **경기 검색**: 날짜 선택 → 리그 선택 → SportsDbService.getEventsByDate() 호출 → 경기 카드 선택
   - **직접 입력**: 날짜, 경기명, 홈팀, 원정팀 직접 입력

2. 기록 정보:
   - 경기 정보 (팀, 스코어, 날짜, 리그)
   - 경기장, 좌석 정보
   - 사진 (여러 장 첨부 가능)
   - 평점 (1-5점)
   - 기분 이모지
   - MVP 선수
   - 일기 내용
   - 태그

**주요 위젯**:
- `_buildEventSearch()` - 경기 검색 UI
- `_buildDateSelector()` - 날짜 선택
- `_buildLeagueSelector()` - 리그 칩 선택
- `_EventSearchResultCard` - 검색된 경기 카드

---

### 커뮤니티 (Community)

**파일 위치**:
- `lib/features/community/screens/community_screen.dart` (1287 줄)
- `lib/features/community/screens/post_detail_screen.dart`
- `lib/features/community/screens/post_write_screen.dart`
- `lib/features/community/providers/community_provider.dart`
- `lib/features/community/services/community_service.dart`
- `lib/features/community/models/post_model.dart`

**게시글 모델 (Post)**:
```dart
class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorProfileUrl;
  final String title;
  final String content;
  final List<String> imageUrls;
  final List<String> hashtags;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;

  // 직관 기록 연결 시
  final bool hasAttendanceRecord;
  final String? homeTeamName;
  final String? awayTeamName;
  final String? stadium;
  final String? league;
  final DateTime? matchDate;
  final int? homeScore;
  final int? awayScore;
}
```

**검색 기능**:
- 텍스트 검색: 제목, 내용, 작성자, 팀명, 경기장
- 경기 필터: 날짜/리그 선택 → 경기 검색 → 특정 경기 게시글만 표시

**좋아요 동기화**:
```dart
// community_provider.dart
class LikedPostsNotifier extends StateNotifier<Map<String, bool>> {
  final CommunityService _service;

  Future<void> loadLikedStatus(List<String> postIds) async {
    final statuses = await _service.getLikedStatusForPosts(postIds);
    state = {...state, ...statuses};
  }

  void setLiked(String postId, bool isLiked) {
    state = {...state, postId: isLiked};
  }
}

final likedPostsProvider = StateNotifierProvider<LikedPostsNotifier, Map<String, bool>>(
  (ref) => LikedPostsNotifier(ref.read(communityServiceProvider)),
);
```

**경기 필터 모달** (`_MatchFilterModal`):
- 날짜 선택 (DatePicker)
- 리그 선택 (AppConstants.supportedLeagues 기반 칩)
- 경기 검색 버튼 → SportsDbService.getEventsByDate() 호출
- 경기 카드 표시 및 선택
- 선택된 경기로 게시글 필터링

---

### 사용자 프로필 (Profile)

**파일 위치**:
- `lib/features/profile/screens/profile_screen.dart` - 내 정보 화면
- `lib/features/profile/screens/user_profile_screen.dart` - 다른 사용자 프로필

**기능**:
- 프로필 카드 클릭 → `/user/{userId}` 페이지로 이동
- 사용자별 직관 기록 조회
- 통계 (총 직관 횟수, 승률 등)

**라우팅**:
```dart
// 프로필 카드 클릭 시
context.push('/user/$userId?name=${Uri.encodeComponent(displayName)}');
```

---

### 홈 화면 (Home)

**파일 위치**:
- `lib/features/home/screens/home_screen.dart`

**D-day 계산 (수정됨)**:
```dart
// 한국 시간 기준으로 날짜만 비교
int _calculateDaysUntil(DateTime eventDateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final eventDate = DateTime(eventDateTime.year, eventDateTime.month, eventDateTime.day);
  return eventDate.difference(today).inDays;
}
```

**경기 카드 위젯** (`_ScheduleCard`):
- 즐겨찾기 팀의 다음 경기 표시
- D-0(TODAY), D-1, D-2... 표시
- 클릭 시 경기 상세 페이지로 이동

---

## 핵심 서비스

### SportsDbService (`lib/core/services/sports_db_service.dart`)

**API 기본 정보**:
```dart
static const String _baseUrlV1 = 'https://www.thesportsdb.com/api/v1/json';
static const String _baseUrlV2 = 'https://www.thesportsdb.com/api/v2/json';
static const String _apiKey = '869004';
```

**주요 메서드**:
```dart
// 날짜별 경기 조회 (한국 시간 기준 필터링 포함)
Future<List<SportsDbEvent>> getEventsByDate(DateTime date, {String? sport, String? league})

// 팀 검색
Future<List<SportsDbTeam>> searchTeams(String teamName)

// 팀의 다음 경기들
Future<List<SportsDbEvent>> getNextTeamEvents(String teamId)

// 팀의 지난 경기들
Future<List<SportsDbEvent>> getPastTeamEvents(String teamId)

// 리그 순위표
Future<List<SportsDbStanding>> getLeagueStandings(String leagueId, {String? season})

// 경기 상세
Future<SportsDbEvent?> getEventById(String eventId)

// 경기 라인업
Future<SportsDbLineup?> getEventLineup(String eventId)

// 경기 통계
Future<SportsDbEventStats?> getEventStats(String eventId)

// 경기 타임라인
Future<List<SportsDbTimeline>> getEventTimeline(String eventId)
```

**주요 모델 클래스**:
- `SportsDbEvent` - 경기 정보
- `SportsDbTeam` - 팀 정보
- `SportsDbPlayer` - 선수 정보
- `SportsDbLeague` - 리그 정보
- `SportsDbStanding` - 순위표
- `SportsDbLineup` - 라인업
- `SportsDbEventStats` - 경기 통계
- `SportsDbTimeline` - 경기 타임라인 (골, 카드 등)

---

### CommunityService (`lib/features/community/services/community_service.dart`)

**주요 메서드**:
```dart
// 게시글 목록 조회
Future<List<Post>> getPosts()

// 게시글 작성
Future<String> createPost(Post post)

// 좋아요 토글 (반환: 새로운 좋아요 상태)
Future<bool> toggleLike(String postId)

// 여러 게시글의 좋아요 상태 일괄 조회
Future<Map<String, bool>> getLikedStatusForPosts(List<String> postIds)

// 댓글 작성
Future<void> addComment(String postId, String content)
```

---

## 상수 및 설정

### AppConstants (`lib/core/constants/app_constants.dart`)

```dart
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

  // 지원 리그 (TheSportsDB API 기준 이름)
  static const List<String> supportedLeagues = [
    'English Premier League',
    'Spanish La Liga',
    'Italian Serie A',
    'German Bundesliga',
    'French Ligue 1',
    'South Korean K League 1',
    'UEFA Champions League',
    'UEFA Europa League',
  ];

  // 리그 한국어 표시 이름
  static const Map<String, String> leagueDisplayNames = {
    'English Premier League': 'EPL',
    'Spanish La Liga': '라리가',
    'Italian Serie A': '세리에 A',
    'German Bundesliga': '분데스리가',
    'French Ligue 1': '리그 1',
    'South Korean K League 1': 'K리그',
    'UEFA Champions League': 'UCL',
    'UEFA Europa League': 'UEL',
  };

  static String getLeagueDisplayName(String league) {
    return leagueDisplayNames[league] ?? league;
  }
}
```

---

## 디자인 시스템

### 색상 팔레트 (대부분의 화면에서 공통 사용)
```dart
static const _primary = Color(0xFF2563EB);      // 메인 파란색
static const _primaryLight = Color(0xFFDBEAFE); // 연한 파란색 (선택된 항목 배경)
static const _textPrimary = Color(0xFF111827);  // 거의 검정 (제목, 본문)
static const _textSecondary = Color(0xFF6B7280); // 회색 (부가 정보)
static const _background = Color(0xFFF9FAFB);   // 밝은 회색 (화면 배경)
static const _border = Color(0xFFE5E7EB);       // 테두리, 구분선
```

### 공통 스타일
- BorderRadius: 12~16px (카드, 버튼)
- 카드 그림자: 없음 (border로 구분)
- 폰트: 기본 시스템 폰트
- 아이콘: Material Icons

---

## 폴더 구조 상세

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart          # 앱 상수
│   ├── services/
│   │   └── sports_db_service.dart      # TheSportsDB API 서비스
│   └── utils/                          # 유틸리티 함수
│
├── features/
│   ├── attendance/                     # 직관 기록
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   │   ├── attendance_add_screen.dart    # 직관 기록 추가 (2800줄)
│   │   │   ├── attendance_detail_screen.dart # 직관 기록 상세
│   │   │   └── attendance_edit_screen.dart   # 직관 기록 수정
│   │   └── services/
│   │
│   ├── community/                      # 커뮤니티
│   │   ├── models/
│   │   │   └── post_model.dart         # 게시글 모델
│   │   ├── providers/
│   │   │   └── community_provider.dart # 게시글, 좋아요 상태 관리
│   │   ├── screens/
│   │   │   ├── community_screen.dart   # 게시글 목록 (1287줄)
│   │   │   ├── post_detail_screen.dart # 게시글 상세
│   │   │   └── post_write_screen.dart  # 게시글 작성
│   │   └── services/
│   │       └── community_service.dart  # 커뮤니티 Firebase 서비스
│   │
│   ├── diary/                          # 일기 (attendance와 연결)
│   │   ├── models/
│   │   │   └── diary_entry.dart
│   │   └── services/
│   │       └── diary_service.dart
│   │
│   ├── favorites/                      # 즐겨찾기
│   │   ├── screens/
│   │   │   └── favorites_screen.dart
│   │   └── services/
│   │       └── favorites_service.dart
│   │
│   ├── home/                           # 홈
│   │   └── screens/
│   │       └── home_screen.dart
│   │
│   ├── profile/                        # 프로필
│   │   └── screens/
│   │       ├── profile_screen.dart     # 내 정보
│   │       └── user_profile_screen.dart # 다른 사용자 프로필
│   │
│   ├── schedule/                       # 경기 일정
│   │   ├── providers/
│   │   ├── screens/
│   │   │   ├── schedule_screen.dart    # 일정 목록
│   │   │   ├── match_detail_screen.dart # 경기 상세
│   │   │   └── player_detail_screen.dart # 선수 상세
│   │   └── services/
│   │       └── schedule_service.dart
│   │
│   ├── standings/                      # 순위표
│   │   ├── providers/
│   │   │   └── standings_provider.dart
│   │   └── screens/
│   │       └── standings_screen.dart
│   │
│   └── team/                           # 팀 정보
│       ├── providers/
│       │   └── team_provider.dart
│       └── screens/
│
└── shared/                             # 공유 컴포넌트
    ├── models/
    │   ├── team_model.dart
    │   └── match_model.dart
    └── widgets/
        ├── stadium_info_tile.dart
        ├── match_stat_chip.dart
        ├── photo_carousel.dart
        └── favorite_toggle_button.dart
```

---

## 최근 작업 내역 (2025-12-09)

### 1. 국가대표 팀 화면 구현
- **변경 파일**:
  - `lib/features/national_team/screens/national_team_screen.dart` (신규)
  - `lib/features/national_team/providers/national_team_provider.dart` (신규)
  - `lib/app_router.dart` (라우트 추가)
- **내용**:
  - 대한민국 축구 국가대표팀 전용 화면 (`/national-team`)
  - 3개 탭: 일정, 정보, 선수단
  - 2026 월드컵 D-day 카운트다운 표시
  - 대회별 일정 조회 (월드컵 본선/예선, 아시안컵, 친선경기)

### 2. TheSportsDB API 확장
- **변경 파일**: `lib/core/services/sports_db_service.dart`
- **내용**:
  - `getLeagueEventsBySeason()` - 리그 시즌별 경기 조회
  - `getTeamFullSchedule()` - 팀 전체 시즌 일정 (V2 API 우선, V1 fallback)
  - `getPlayersByTeam()` - 팀 선수단 조회

### 3. 즐겨찾기 화면 리그 표시 수정
- **변경 파일**: `lib/features/favorites/screens/favorites_screen.dart`
- **내용**:
  - 팀 추가 모달에서 "International Friendlies" → "국가" 표시
  - 리그 필터 칩에도 한국어 표시 적용
  - `_getLeagueDisplayName()` 헬퍼 함수 추가

### 4. AppConstants 업데이트
- **변경 파일**: `lib/core/constants/app_constants.dart`
- **내용**:
  - `supportedLeagues`에 `International Friendlies` 추가
  - `leaguesWithStandings` 리스트 추가 (순위표가 있는 리그만)
  - `leagueDisplayNames`에 `'International Friendlies': 'A매치'` 추가

---

## TheSportsDB API 한계 및 참고사항 (2025-12-09)

### 리그 ID 정보
| 대회명 | 리그 ID | 비고 |
|--------|---------|------|
| FIFA 월드컵 | 4429 | 본선 + 예선 통합 (시즌으로 구분) |
| AFC 아시안컵 | 4866 | |
| 친선경기 | 4562 | International Friendlies |
| 월드컵 예선 AFC | 5513 | **데이터 없음** (빈 응답) |
| 아시안컵 예선 | 5521 | |

### API 한계점

1. **월드컵 조별 순위 (lookuptable.php)**
   - `lookuptable.php?l=4429&s=2022` 조회 시 **한국이 속한 조(Group H)만** 반환
   - 그룹 파라미터(`g=A`, `group=A`) 작동하지 않음
   - 전체 8개 조 데이터를 한 번에 가져올 수 없음

2. **국가대표 선수단 (lookup_all_players.php)**
   - `lookup_all_players.php?id=134517` (대한민국)
   - 웹사이트에는 28명 표시되지만 API는 **1명만 반환** (Paulo Bento)
   - 국가대표팀 선수단 데이터는 API로 완전히 제공되지 않음

3. **월드컵 예선 데이터**
   - 별도 리그 ID(5513)가 존재하지만 **이벤트 데이터 없음**
   - 실제 예선 경기는 FIFA World Cup(4429) 리그에서 시즌(2023-2024 등)으로 구분
   - 앱에서는 가상 ID(`4429_qualifying`)로 본선/예선 구분 처리

### 월드컵 본선/예선 구분 로직
```dart
// national_team_provider.dart
class NationalTeamLeagues {
  static const String worldCup = '4429';           // 본선
  static const String worldCupQualifying = '4429_qualifying'; // 예선 (가상 ID)

  // 본선 시즌 목록
  static const List<String> worldCupFinalSeasons = ['2022', '2026', '2030'];

  // 예선인지 확인 (본선 시즌이 아니면 예선)
  static bool isQualifyingSeason(String? season) {
    if (season == null) return false;
    return !worldCupFinalSeasons.contains(season) &&
           !worldCupFinalSeasons.any((s) => season.contains(s));
  }
}
```

### 한국 대표팀 ID
- **팀 ID**: `134517`
- **팀명 필터링**: "South Korea" 또는 "Korea" 포함, "North Korea" 제외

---

## 최근 작업 내역 (2025-12-07)

### 1. 커뮤니티 좋아요 기능 개선
- **변경 파일**: community_screen.dart, community_provider.dart, community_service.dart, post_detail_screen.dart
- **내용**:
  - 목록에서 좋아요한 게시글은 빨간 하트(filled)로 표시
  - 상세 화면에서 좋아요 토글 시 목록에도 즉시 반영
  - `LikedPostsNotifier` 추가로 상태 공유

### 2. 커뮤니티 검색 기능 추가
- **변경 파일**: community_screen.dart
- **내용**:
  - 헤더 아래 검색바 추가
  - 제목, 내용, 작성자, 팀명, 경기장으로 검색
  - 검색어 없을 때 검색 결과 없음 UI

### 3. 커뮤니티 경기 필터 모달 구현
- **변경 파일**: community_screen.dart
- **내용**:
  - 필터 버튼(tune 아이콘) 추가
  - `_MatchFilterModal` 위젯 구현:
    - "직관 기록이 있는 게시글만 보기" 토글
    - 날짜 선택 (DatePicker)
    - 리그 선택 (가로 스크롤 칩)
    - 경기 검색 버튼 → API 호출
    - 경기 카드 목록 및 선택
  - 선택된 경기로 게시글 필터링 (팀명 + 날짜 매칭)

### 4. 프로필 카드 네비게이션
- **변경 파일**: profile_screen.dart
- **내용**:
  - '내정보' 화면 상단 프로필 카드를 GestureDetector로 감싸기
  - 클릭 시 `/user/{userId}` 페이지로 이동
  - chevron_right 아이콘 추가

### 5. D-day 계산 수정 (한국 시간 기준)
- **변경 파일**: home_screen.dart
- **내용**:
  - 기존: `event.dateTime!.difference(DateTime.now()).inDays` (시간 포함 계산)
  - 수정: 날짜만 비교하도록 `_calculateDaysUntil()` 함수 추가
  - 오늘 날짜와 경기 날짜만 비교해서 D-day 계산

### 6. iOS 폴더 gitignore
- **변경 파일**: .gitignore
- **내용**: `ios/` 폴더 추가
- **주의**: 이미 커밋된 파일은 `git rm -r --cached ios/` 실행 필요

---

## 알려진 이슈 및 참고사항

### 1. 한국어 로케일 오류
- `DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR')` 사용 시 `MaterialLocalizations` 오류 발생
- **해결**: 직접 포맷팅 함수 사용
```dart
String _formatDate(DateTime date) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  final weekday = weekdays[date.weekday - 1];
  return '${date.year}년 ${date.month}월 ${date.day}일 ($weekday)';
}
```

### 2. iOS 빌드
- `ios/` 폴더가 gitignore에 추가됨
- 새 환경에서는 `flutter create .` 또는 수동으로 iOS 프로젝트 재생성 필요
- CocoaPods 설치: `cd ios && pod install`

### 3. API 시간대
- TheSportsDB API는 UTC 시간 반환
- `SportsDbEvent.dateTime`은 자동으로 로컬 시간(한국 시간)으로 변환됨
- `getEventsByDate()`는 UTC 기준 여러 날짜를 조회 후 로컬 시간으로 필터링

### 4. 경기 필터 매칭 로직
- 팀명 매칭: 홈/원정 순서 무관하게 양쪽 모두 확인
- 날짜 매칭: 연/월/일만 비교 (시간 무시)
```dart
final teamsMatch =
    (post.homeTeamName == matchHome && post.awayTeamName == matchAway) ||
    (post.homeTeamName == matchAway && post.awayTeamName == matchHome);
```

---

## Git 현황

**브랜치**: main

**최근 커밋** (최신순):
1. 경기 D-DAY 계산 로직 수정
2. 커뮤니티 경기 검색기능 추가
3. gitignore
4. 프로필 카드 클릭 시 사용자 ID에 따라 프로필 페이지로 이동하도록 수정
5. 커뮤니티 좋아요 기능 개선

---

## 새 환경에서 시작하기

```bash
# 1. 의존성 설치
flutter pub get

# 2. iOS 설정 (필요시)
cd ios && pod install && cd ..

# 3. 실행
flutter run
```

---

## 자주 사용하는 명령어

```bash
# 분석
dart analyze lib/

# 포맷팅
dart format lib/

# 빌드
flutter build apk
flutter build ios

# 테스트
flutter test
```

---

*마지막 업데이트: 2025-12-09*
*작성자: Claude (이전 세션에서 작업한 내용 기반)*
