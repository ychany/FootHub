# MatchLog

축구 직관 기록 및 일정 관리 앱

## 주요 기능

### 직관 일기
- 경기 직관 기록 작성 (사진, 좌석, 평점, MVP 등)
- 날씨, 동행자, 티켓 가격 기록
- 경기장 상세 정보 (수용 인원, 잔디 종류, 주소)

### 경기 일정 및 상세
- 리그별 경기 일정 조회 (캘린더 뷰)
- 타임존 설정 지원
- 실시간 라인업 및 포메이션 피치뷰
- 선수 얼굴 사진 및 평점 표시
- 경기 통계 및 타임라인
- 교체 선수 IN/OUT 표시
- 상대전적 (Head-to-Head)
- 팀 스타일 레이더 차트 비교
- 경기 예측 및 배당률
- 골 득점자 표시
- 경기별 댓글 기능

### 라이브 경기
- 실시간 진행 중인 경기 대시보드
- 30초마다 자동 스코어 갱신
- 리그 우선순위 정렬 (5대 리그 > 유럽 대회 > K리그/국가대항전)
- 경기 시간 진행 바 표시
- 일정 탭에서 라이브 경기 경과 시간 표시

### 국가대표
- 2026 월드컵 참가국 중 원하는 국가대표팀 선택 가능
- 선택한 국가대표팀 일정/정보/선수단 조회
- 2026 월드컵 카운트다운 (황금 트로피 테마)
- 최근 폼 (W/D/L) 표시
- A대표팀 최근 경기 기반 선수단 조회
- 참가 대회 목록 (월드컵, 대륙컵 등)

### 리그 상세
- 5대 리그 빠른 접근 (홈화면)
- 리그별 순위표, 일정, 통계 탭
- 시즌 선택 드롭다운
- 우승팀/준우승팀 카드 (리그/컵 구분)
- 득점왕/어시스트왕

### 커뮤니티
- 직관 후기 공유
- 경기별 댓글 기능
- 직관 통계 자랑하기

### 순위 및 통계
- 리그별 순위표
- 득점왕/어시스트왕
- 국가별 리그 탐색
- 팀 상세 정보 (선수단, 일정, 이적 내역)
- 선수 상세 정보 (시즌 통계, 경력)
- 감독 경력 및 트로피
- 부상/결장 선수 현황

### 즐겨찾기
- 팀/선수 검색 및 등록
- 주요 리그(5대 리그 + K리그) 선수 검색 지원
- 다가오는 경기 일정 알림

## 기술 스택

- **Frontend**: Flutter 3.x
- **Backend**: Firebase (Auth, Firestore, Storage, Messaging)
- **상태 관리**: Riverpod
- **라우팅**: GoRouter
- **API**: API-Football (Pro)
- **차트**: fl_chart

## 지원 리그

- 유럽 5대 리그: EPL, 라리가, 세리에 A, 분데스리가, 리그 1
- 한국: K리그 1, K리그 2
- 유럽 대회: UEFA 챔피언스리그, 유로파리그, 컨퍼런스리그
- 국가대표: A매치, 월드컵 예선, 아시안컵, 대륙컵
- 기타: 전 세계 800+ 리그 지원

## 프로젝트 구조

```
lib/
├── core/
│   ├── constants/         # 상수 및 ID 매핑
│   └── services/          # API 서비스 (API-Football)
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

## 상세 문서

[PROJECT_CONTEXT.md](./PROJECT_CONTEXT.md)
