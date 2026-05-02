# FootHub ⚽

**나만의 축구 직관 다이어리** - 경기장에서의 특별한 순간을 기록하세요!

<p align="center">
  <a href="https://apps.apple.com/kr/app/foothub/id6757123385">
    <img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83" alt="Download on the App Store" height="60">
  </a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS-lightgrey?logo=apple" alt="iOS">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/License-Proprietary-red" alt="License">
</p>

## 주요 기능

- **직관 일기**: 사진·좌석·평점·MVP·날씨·티켓 가격 기록, 경기장 정보 제공
- **경기 상세**: 라인업 피치뷰, 통계·타임라인, 상대전적, 팀 비교, 예측·배당률
- **라이브 경기**: 30초 자동 갱신, 리그 우선순위 정렬, 경기 진행 바
- **국가대표**: 2026 월드컵 카운트다운, 응원팀 일정·선수단·최근 폼
- **리그/컵**: 순위표·통계, 득점왕·어시스트왕, 토너먼트 대진표
- **커뮤니티**: 직관 후기, 경기별 댓글, 신고/차단
- **즐겨찾기 & 알림**: 팀/선수 즐겨찾기, 킥오프·시작 전 푸시 알림
- **인증**: 이메일 / Google / Apple 로그인
- **다국어**: 한국어 / 영어 지원

## 기술 스택

- **Frontend**: Flutter 3.x
- **Backend**: Firebase (Auth, Firestore, Storage, Messaging)
- **상태 관리**: Riverpod
- **라우팅**: GoRouter
- **API**: API-Football (Pro)
- **차트**: fl_chart
- **로컬 저장**: SharedPreferences
- **다국어**: flutter_localizations, intl
- **알림**: flutter_local_notifications, timezone

## 지원 리그

- 유럽 5대 리그: EPL, 라리가, 세리에 A, 분데스리가, 리그 1
- 한국: K리그 1, K리그 2
- 유럽 대회: UEFA 챔피언스리그, 유로파리그, 컨퍼런스리그
- 5대 국가 컵대회: FA컵, EFL컵, 코파 델 레이, DFB 포칼, 코파 이탈리아, 쿠프 드 프랑스
- 국가대표: A매치, 월드컵 예선, 아시안컵, 대륙컵
- 기타: 전 세계 800+ 리그 지원 (국가별 리그 탐색)
- 자국 리그 자동 감지 (50+ 국가 지원)

## 프로젝트 구조

```
lib/
├── core/
│   ├── constants/         # 상수 및 ID 매핑
│   ├── errors/            # 에러 코드 및 예외
│   ├── providers/         # 전역 Provider (언어 설정 등)
│   ├── services/          # API 서비스 (API-Football)
│   └── utils/             # 헬퍼 (ErrorHelper 등)
├── l10n/                  # 다국어 리소스 (ARB 파일)
├── features/
│   ├── attendance/        # 직관 일기
│   ├── auth/              # 인증
│   ├── community/         # 커뮤니티
│   ├── diary/             # 경기 일기
│   ├── favorites/         # 즐겨찾기
│   ├── home/              # 홈 화면
│   ├── league/            # 리그 상세
│   ├── live/              # 라이브 경기
│   ├── national_team/     # 국가대표
│   ├── profile/           # 프로필 및 설정
│   ├── schedule/          # 경기 일정 및 상세
│   ├── standings/         # 순위표
│   └── team/              # 팀/선수/감독 상세
└── shared/
    ├── models/            # 공통 모델
    └── widgets/           # 공통 위젯
        ├── football_pitch_view.dart    # 라인업 피치뷰
        ├── team_comparison_widget.dart # 팀 비교 분석
        └── standings_table.dart        # 리그 순위표
```

## 설치 및 실행

```bash
# 의존성 설치
flutter pub get

# iOS 설정
cd ios && pod install && cd ..

# 개발 모드 실행
flutter run

# 릴리즈 빌드
flutter build ios --release
flutter build apk --release
```

## 환경 설정

`.env` 파일에 API 키 설정:
```
API_FOOTBALL_KEY=your_api_key
API_FOOTBALL_BASE_URL=https://v3.football.api-sports.io
```