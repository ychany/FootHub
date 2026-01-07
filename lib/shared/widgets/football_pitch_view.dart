import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_football_service.dart';
import '../../l10n/app_localizations.dart';

/// 축구 피치 뷰 위젯 (라인업 표시)
class FootballPitchView extends StatelessWidget {
  final ApiFootballLineup? homeLineup;
  final ApiFootballLineup? awayLineup;
  final ApiFootballFixtureTeam homeTeam;
  final ApiFootballFixtureTeam awayTeam;
  final FixturePlayerStats? homePlayerStats;
  final FixturePlayerStats? awayPlayerStats;
  final List<ApiFootballEvent> substitutions;
  final Map<int, List<ApiFootballEvent>> playerEvents;

  static const _pitchGreen = Color(0xFF2E7D32);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const FootballPitchView({
    super.key,
    required this.homeLineup,
    required this.awayLineup,
    required this.homeTeam,
    required this.awayTeam,
    this.homePlayerStats,
    this.awayPlayerStats,
    this.substitutions = const [],
    this.playerEvents = const {},
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 포메이션 헤더
          _buildFormationHeader(),
          const SizedBox(height: 12),

          // 축구 피치
          Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 0.7,
              child: CustomPaint(
                painter: FootballPitchPainter(),
                child: Stack(
                  children: [
                    // 홈팀 (위쪽 절반)
                    if (homeLineup != null)
                      ..._buildTeamPlayers(
                        homeLineup!,
                        homePlayerStats,
                        isHome: true,
                      ),
                    // 어웨이팀 (아래쪽 절반)
                    if (awayLineup != null)
                      ..._buildTeamPlayers(
                        awayLineup!,
                        awayPlayerStats,
                        isHome: false,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 교체 선수 섹션
        _buildSubstitutesSection(context),
      ],
      ),
    );
  }

  Widget _buildFormationHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // 홈팀
          Expanded(
            child: Row(
              children: [
                if (homeTeam.logo != null)
                  CachedNetworkImage(
                    imageUrl: homeTeam.logo!,
                    width: 24,
                    height: 24,
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.sports_soccer, size: 24),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        homeTeam.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (homeLineup?.formation != null)
                        Text(
                          homeLineup!.formation!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _pitchGreen,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // VS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
          ),

          // 어웨이팀
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        awayTeam.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                      if (awayLineup?.formation != null)
                        Text(
                          awayLineup!.formation!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _pitchGreen,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (awayTeam.logo != null)
                  CachedNetworkImage(
                    imageUrl: awayTeam.logo!,
                    width: 24,
                    height: 24,
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.sports_soccer, size: 24),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTeamPlayers(
    ApiFootballLineup lineup,
    FixturePlayerStats? playerStats, {
    required bool isHome,
  }) {
    final players = lineup.startXI;
    final formation = lineup.formation;

    if (formation == null || players.isEmpty) return [];

    // 포메이션 파싱 (예: "4-3-3" -> [4, 3, 3])
    final lines =
        formation.split('-').map((e) => int.tryParse(e) ?? 0).toList();
    if (lines.isEmpty) return [];

    // 골키퍼 + 필드 플레이어 라인 구성
    final allLines = [1, ...lines]; // 골키퍼 1명 추가
    final totalLines = allLines.length;

    final widgets = <Widget>[];
    int playerIndex = 0;

    // 각 라인의 Y 위치를 미리 계산 (골키퍼부터 공격수까지 균등 분배)
    // 홈팀: 상단(골키퍼) -> 하단(공격수), 어웨이팀: 하단(골키퍼) -> 상단(공격수)
    final lineYPositions = <double>[];
    for (int i = 0; i < totalLines; i++) {
      if (isHome) {
        // 홈팀: 5% ~ 45% 범위 (상단 절반)
        lineYPositions.add(0.05 + (i / (totalLines - 1)) * 0.40);
      } else {
        // 어웨이팀: 95% ~ 55% 범위 (하단 절반)
        lineYPositions.add(0.95 - (i / (totalLines - 1)) * 0.40);
      }
    }

    for (int lineIndex = 0; lineIndex < allLines.length; lineIndex++) {
      final playersInLine = allLines[lineIndex];

      for (int posIndex = 0; posIndex < playersInLine; posIndex++) {
        if (playerIndex >= players.length) break;

        final player = players[playerIndex];
        final stats = _findPlayerStats(player.id, playerStats);

        // Y 위치
        final yPercent = lineYPositions[lineIndex];

        // X 위치 계산 (선수 분포) - 더 넓게 분포
        double xPercent;
        if (playersInLine == 1) {
          xPercent = 0.5;
        } else if (playersInLine == 2) {
          // 2명: 30%, 70%
          xPercent = 0.30 + posIndex * 0.40;
        } else if (playersInLine == 3) {
          // 3명: 20%, 50%, 80%
          xPercent = 0.20 + posIndex * 0.30;
        } else if (playersInLine == 4) {
          // 4명: 12%, 37%, 63%, 88%
          xPercent = 0.12 + posIndex * 0.25;
        } else if (playersInLine == 5) {
          // 5명: 10%, 30%, 50%, 70%, 90%
          xPercent = 0.10 + posIndex * 0.20;
        } else {
          // 그 외
          final spacing = 0.80 / (playersInLine - 1);
          xPercent = 0.10 + posIndex * spacing;
        }

        widgets.add(
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 마커 중심 위치 계산 (마커 크기 약 36x50 정도)
                final markerCenterX = constraints.maxWidth * xPercent;
                final markerCenterY = constraints.maxHeight * yPercent;

                // 마커 컨테이너 너비 (이름 박스 maxWidth: 56 기준으로 중앙 정렬)
                const markerContainerWidth = 56.0;
                return Stack(
                  children: [
                    Positioned(
                      left: markerCenterX - (markerContainerWidth / 2),
                      top: markerCenterY - 25, // 마커 높이 고려
                      child: SizedBox(
                        width: markerContainerWidth,
                        child: PlayerMarker(
                          player: player,
                          stats: stats,
                          isHome: isHome,
                          events: playerEvents[player.id] ?? [],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );

        playerIndex++;
      }
    }

    return widgets;
  }

  PlayerMatchStats? _findPlayerStats(
      int playerId, FixturePlayerStats? teamStats) {
    if (teamStats == null) return null;
    try {
      return teamStats.players.firstWhere((p) => p.id == playerId);
    } catch (_) {
      return null;
    }
  }

  Widget _buildSubstitutesSection(BuildContext context) {
    final homeSubs = homeLineup?.substitutes ?? [];
    final awaySubs = awayLineup?.substitutes ?? [];

    if (homeSubs.isEmpty && awaySubs.isEmpty) return const SizedBox.shrink();

    // 홈팀/어웨이팀 교체 이벤트 분리
    final homeSubEvents =
        substitutions.where((e) => e.teamId == homeTeam.id).toList();
    final awaySubEvents =
        substitutions.where((e) => e.teamId == awayTeam.id).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Icon(Icons.swap_horiz, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.substitutes,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const Spacer(),
              // 교체 횟수
              if (substitutions.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.nTimes(substitutions.length),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
            ],
          ),

          // 실제 교체 이벤트 (발생한 경우)
          if (substitutions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.substitutionRecord,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            // 홈팀 교체
            if (homeSubEvents.isNotEmpty) ...[
              _buildTeamSubstitutions(homeTeam.name, homeSubEvents, true),
              if (awaySubEvents.isNotEmpty) const SizedBox(height: 12),
            ],
            // 어웨이팀 교체
            if (awaySubEvents.isNotEmpty)
              _buildTeamSubstitutions(awayTeam.name, awaySubEvents, false),
          ],

          // 벤치 선수 (아직 투입되지 않은 선수)
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.bench,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 홈팀 벤치
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: homeSubs.take(7).map((p) {
                    final stats = _findPlayerStats(p.id, homePlayerStats);
                    final subEvent = _findSubstitutionEvent(p.id, homeSubEvents);
                    return SubstituteRow(
                      player: p,
                      stats: stats,
                      substitutionEvent: subEvent,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 16),
              // 어웨이팀 벤치
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: awaySubs.take(7).map((p) {
                    final stats = _findPlayerStats(p.id, awayPlayerStats);
                    final subEvent = _findSubstitutionEvent(p.id, awaySubEvents);
                    return SubstituteRow(
                      player: p,
                      stats: stats,
                      substitutionEvent: subEvent,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSubstitutions(
      String teamName, List<ApiFootballEvent> events, bool isHome) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          teamName,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isHome ? const Color(0xFF1E40AF) : const Color(0xFFDC2626),
          ),
        ),
        const SizedBox(height: 6),
        ...events.map((event) => _buildSubstitutionEventRow(event)),
      ],
    );
  }

  Widget _buildSubstitutionEventRow(ApiFootballEvent event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // 시간
          Container(
            width: 36,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              event.timeDisplay,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          // IN 선수
          Expanded(
            child: Row(
              children: [
                Icon(Icons.arrow_upward, size: 12, color: Colors.green.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.assistName ?? '-', // assistName이 IN 선수
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // OUT 선수
          Expanded(
            child: Row(
              children: [
                Icon(Icons.arrow_downward, size: 12, color: Colors.red.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.playerName ?? '-', // playerName이 OUT 선수
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ApiFootballEvent? _findSubstitutionEvent(
      int playerId, List<ApiFootballEvent> events) {
    // 해당 선수가 IN된 이벤트 찾기 (assistId가 IN 선수)
    try {
      return events.firstWhere((e) => e.assistId == playerId);
    } catch (_) {
      return null;
    }
  }
}

/// 축구장 배경 페인터
class FootballPitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // 잔디 배경 (줄무늬)
    final stripeCount = 12;
    final stripeHeight = size.height / stripeCount;
    for (int i = 0; i < stripeCount; i++) {
      paint.color =
          i % 2 == 0 ? const Color(0xFF2E7D32) : const Color(0xFF388E3C);
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight),
        paint,
      );
    }

    // 외곽선
    canvas.drawRect(
      Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
      linePaint,
    );

    // 중앙선
    canvas.drawLine(
      Offset(4, size.height / 2),
      Offset(size.width - 4, size.height / 2),
      linePaint,
    );

    // 센터 서클
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.15,
      linePaint,
    );

    // 센터 점
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      4,
      dotPaint,
    );

    // 페널티 박스 (위)
    _drawPenaltyBox(canvas, size, linePaint, isTop: true);
    // 페널티 박스 (아래)
    _drawPenaltyBox(canvas, size, linePaint, isTop: false);

    // 골 에어리어 (위)
    _drawGoalArea(canvas, size, linePaint, isTop: true);
    // 골 에어리어 (아래)
    _drawGoalArea(canvas, size, linePaint, isTop: false);
  }

  void _drawPenaltyBox(Canvas canvas, Size size, Paint paint,
      {required bool isTop}) {
    final boxWidth = size.width * 0.6;
    final boxHeight = size.height * 0.14;
    final left = (size.width - boxWidth) / 2;

    if (isTop) {
      canvas.drawRect(
        Rect.fromLTWH(left, 4, boxWidth, boxHeight),
        paint,
      );
      // 페널티 아크
      final arcRect = Rect.fromCircle(
        center: Offset(size.width / 2, boxHeight + 4),
        radius: size.width * 0.12,
      );
      canvas.drawArc(arcRect, 0.2, 2.74, false, paint);
    } else {
      canvas.drawRect(
        Rect.fromLTWH(left, size.height - boxHeight - 4, boxWidth, boxHeight),
        paint,
      );
      // 페널티 아크
      final arcRect = Rect.fromCircle(
        center: Offset(size.width / 2, size.height - boxHeight - 4),
        radius: size.width * 0.12,
      );
      canvas.drawArc(arcRect, 3.34, 2.74, false, paint);
    }
  }

  void _drawGoalArea(Canvas canvas, Size size, Paint paint,
      {required bool isTop}) {
    final boxWidth = size.width * 0.3;
    final boxHeight = size.height * 0.05;
    final left = (size.width - boxWidth) / 2;

    if (isTop) {
      canvas.drawRect(
        Rect.fromLTWH(left, 4, boxWidth, boxHeight),
        paint,
      );
    } else {
      canvas.drawRect(
        Rect.fromLTWH(left, size.height - boxHeight - 4, boxWidth, boxHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 선수 마커 위젯
class PlayerMarker extends StatelessWidget {
  final ApiFootballLineupPlayer player;
  final PlayerMatchStats? stats;
  final bool isHome;
  final List<ApiFootballEvent> events;

  const PlayerMarker({
    super.key,
    required this.player,
    this.stats,
    required this.isHome,
    this.events = const [],
  });

  @override
  Widget build(BuildContext context) {
    final rating = stats?.ratingValue;
    final ratingColor = _getRatingColor(rating);
    final hasPhoto = stats?.photo != null;

    return GestureDetector(
      onTap: () => _showPlayerDetail(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 선수 얼굴/등번호
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasPhoto
                      ? Colors.white
                      : (isHome
                          ? const Color(0xFF1E40AF)
                          : const Color(0xFFDC2626)),
                  border: Border.all(
                    color: isHome
                        ? const Color(0xFF1E40AF)
                        : const Color(0xFFDC2626),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: hasPhoto
                      ? CachedNetworkImage(
                          imageUrl: stats!.photo!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Center(
                            child: Text(
                              player.number?.toString() ?? '-',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            player.number?.toString() ?? '-',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
              // 평점 뱃지 (우측 하단)
              if (rating != null)
                Positioned(
                  right: -4,
                  bottom: -2,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: ratingColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              // 골/어시스트 아이콘 (좌측 상단)
              if (_hasGoalOrAssist())
                Positioned(
                  left: -6,
                  top: -6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildGoalAssistIcons(),
                  ),
                ),
              // 카드 아이콘 (우측 상단)
              if (_hasCards())
                Positioned(
                  right: -4,
                  top: -6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildCardIcons(),
                  ),
                ),
              // 교체 아이콘 (좌측 하단)
              if (_wasSubstituted())
                Positioned(
                  left: -6,
                  bottom: -4,
                  child: _buildSubstitutionIcon(),
                ),
            ],
          ),

          const SizedBox(height: 2),

          // 선수 이름
          Container(
            constraints: const BoxConstraints(maxWidth: 56),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              _getShortName(player.name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _getShortName(String fullName) {
    final parts = fullName.split(' ');
    if (parts.length <= 1) return fullName;
    // 성만 반환 (또는 마지막 단어)
    return parts.last.length <= 8 ? parts.last : parts.last.substring(0, 8);
  }

  Color _getRatingColor(double? rating) {
    if (rating == null) return Colors.grey;
    if (rating >= 7.5) return const Color(0xFF22C55E);
    if (rating >= 7.0) return const Color(0xFF84CC16);
    if (rating >= 6.5) return const Color(0xFFF59E0B);
    if (rating >= 6.0) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  // 골 또는 어시스트 여부
  bool _hasGoalOrAssist() {
    return events.any((e) => e.type == 'Goal' || e.type == 'Assist');
  }

  // 카드 여부
  bool _hasCards() {
    return events.any((e) => e.type == 'Card');
  }

  // 교체 아웃 여부
  bool _wasSubstituted() {
    return events.any((e) => e.isSubstitution);
  }

  // 골/어시스트 아이콘 (좌측 상단)
  List<Widget> _buildGoalAssistIcons() {
    final icons = <Widget>[];

    final goals =
        events.where((e) => e.type == 'Goal' && e.detail != 'Own Goal').length;
    final ownGoals =
        events.where((e) => e.type == 'Goal' && e.detail == 'Own Goal').length;
    final assists = events.where((e) => e.type == 'Assist').length;

    // 골 아이콘
    for (int i = 0; i < goals; i++) {
      icons.add(Container(
        width: 16,
        height: 16,
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: const Icon(Icons.sports_soccer, size: 11, color: Colors.black),
      ));
    }

    // 자책골 아이콘
    for (int i = 0; i < ownGoals; i++) {
      icons.add(Container(
        width: 16,
        height: 16,
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.red, width: 1),
        ),
        child: const Icon(Icons.sports_soccer, size: 11, color: Colors.red),
      ));
    }

    // 어시스트 아이콘 (축구화)
    for (int i = 0; i < assists; i++) {
      icons.add(Container(
        width: 16,
        height: 16,
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.green, width: 1),
        ),
        child: const Center(child: Text('👟', style: TextStyle(fontSize: 10))),
      ));
    }

    return icons;
  }

  // 카드 아이콘 (우측 상단)
  List<Widget> _buildCardIcons() {
    final icons = <Widget>[];

    final yellowCards =
        events.where((e) => e.type == 'Card' && e.detail == 'Yellow Card').length;
    final redCards =
        events.where((e) => e.type == 'Card' && e.detail == 'Red Card').length;

    // 옐로카드 아이콘
    for (int i = 0; i < yellowCards; i++) {
      icons.add(Container(
        width: 10,
        height: 12,
        margin: const EdgeInsets.only(right: 1),
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(1),
          border: Border.all(color: Colors.white, width: 0.5),
        ),
      ));
    }

    // 레드카드 아이콘
    for (int i = 0; i < redCards; i++) {
      icons.add(Container(
        width: 10,
        height: 12,
        margin: const EdgeInsets.only(right: 1),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(1),
          border: Border.all(color: Colors.white, width: 0.5),
        ),
      ));
    }

    return icons;
  }

  // 교체 아이콘 (좌측 하단)
  Widget _buildSubstitutionIcon() {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.red.shade400, width: 1),
      ),
      child: Icon(Icons.arrow_downward, size: 11, color: Colors.red.shade600),
    );
  }

  void _showPlayerDetail(BuildContext context) {
    if (player.id <= 0) return;
    showPlayerStatsModal(context, player, stats);
  }
}

/// 선수 경기 스탯 모달 표시
void showPlayerStatsModal(
  BuildContext context,
  ApiFootballLineupPlayer player,
  PlayerMatchStats? stats,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PlayerStatsModal(player: player, stats: stats),
  );
}

/// 선수 경기 스탯 모달
class PlayerStatsModal extends StatelessWidget {
  final ApiFootballLineupPlayer player;
  final PlayerMatchStats? stats;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _success = Color(0xFF22C55E);

  const PlayerStatsModal({super.key, required this.player, this.stats});

  @override
  Widget build(BuildContext context) {
    final rating = stats?.ratingValue;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더 영역 (선수 정보)
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // 핸들
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // 선수 프로필
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    children: [
                      // 선수 사진 + 평점
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: _border, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: stats?.photo != null
                                  ? CachedNetworkImage(
                                      imageUrl: stats!.photo!,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Icon(
                                        Icons.person,
                                        size: 36,
                                        color: _textSecondary,
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 36,
                                      color: _textSecondary,
                                    ),
                            ),
                          ),
                          // 평점 뱃지
                          if (rating != null)
                            Positioned(
                              right: -8,
                              bottom: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRatingColor(rating),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getRatingColor(rating)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),

                      // 이름 + 포지션 + 등번호
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 이름 (탭하면 상세 페이지로)
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                if (player.id > 0) {
                                  context.push('/player/${player.id}');
                                }
                              },
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      player.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: _primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 10,
                                      color: _primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (player.number != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '#${player.number}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (stats?.position != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getPositionColor(stats!.position!)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getPositionName(context, stats!.position!),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            _getPositionColor(stats!.position!),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 주요 스탯 요약 (출전/골/어시스트)
                if (stats != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildKeyStatItem(
                          context,
                          icon: Icons.timer_outlined,
                          label:
                              AppLocalizations.of(context)!.playerAppsLabel,
                          value: stats!.minutesPlayed != null
                              ? "${stats!.minutesPlayed}'"
                              : '-',
                        ),
                        _buildVerticalDivider(),
                        _buildKeyStatItem(
                          context,
                          icon: Icons.sports_soccer,
                          label:
                              AppLocalizations.of(context)!.playerGoalsLabel,
                          value: '${stats!.goals ?? 0}',
                          highlight: (stats!.goals ?? 0) > 0,
                        ),
                        _buildVerticalDivider(),
                        _buildKeyStatItem(
                          context,
                          icon: Icons.assistant_outlined,
                          label:
                              AppLocalizations.of(context)!.playerAssistsLabel,
                          value: '${stats!.assists ?? 0}',
                          highlight: (stats!.assists ?? 0) > 0,
                        ),
                        _buildVerticalDivider(),
                        _buildKeyStatItem(
                          context,
                          icon: Icons.check_circle_outline,
                          label:
                              AppLocalizations.of(context)!.playerPassAccuracy,
                          value: stats!.passAccuracyText,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // 스탯 상세 영역
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: stats != null
                  ? _buildStatsContent(context)
                  : _buildNoStatsContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 18,
            color: highlight ? _success : _textSecondary,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: highlight ? _success : _textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 36,
      color: _border,
    );
  }

  Widget _buildNoStatsContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.sports_soccer, size: 48, color: _textSecondary),
          const SizedBox(height: 16),
          Text(
            l10n.noMatchStats,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.statsUpdateDuringMatch,
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 공격 카드
        _buildStatCard(
          context,
          title: l10n.attackSection,
          icon: Icons.sports_soccer,
          iconColor: const Color(0xFFEF4444),
          stats: [
            StatRow(label: l10n.shotsLabel, value: '${stats!.shotsTotal ?? 0}'),
            StatRow(label: l10n.shotsOnLabel, value: '${stats!.shotsOn ?? 0}'),
            StatRow(label: l10n.offsidesLabel, value: '${stats!.offsides ?? 0}'),
          ],
        ),

        // 패스 카드
        _buildStatCard(
          context,
          title: l10n.passSection,
          icon: Icons.swap_calls,
          iconColor: const Color(0xFF3B82F6),
          stats: [
            StatRow(
                label: l10n.totalPassLabel, value: '${stats!.passesTotal ?? 0}'),
            StatRow(label: l10n.keyPassLabel, value: '${stats!.passesKey ?? 0}'),
          ],
        ),

        // 수비 카드
        _buildStatCard(
          context,
          title: l10n.defenseSection,
          icon: Icons.shield_outlined,
          iconColor: const Color(0xFF22C55E),
          stats: [
            StatRow(
                label: l10n.tackleLabel, value: '${stats!.tacklesTotal ?? 0}'),
            StatRow(
                label: l10n.interceptLabel,
                value: '${stats!.tacklesInterceptions ?? 0}'),
            StatRow(
                label: l10n.blockLabel, value: '${stats!.tacklesBlocks ?? 0}'),
          ],
        ),

        // 듀얼 & 드리블 카드
        _buildStatCard(
          context,
          title: l10n.duelDribbleSection,
          icon: Icons.directions_run,
          iconColor: const Color(0xFF8B5CF6),
          stats: [
            StatRow(
              label: l10n.duelLabel,
              value: '${stats!.duelsWon ?? 0}/${stats!.duelsTotal ?? 0}',
              subValue: stats!.duelWinRateText,
            ),
            StatRow(
              label: l10n.dribbleLabel,
              value:
                  '${stats!.dribblesSuccess ?? 0}/${stats!.dribblesAttempts ?? 0}',
            ),
          ],
        ),

        // 파울 & 카드
        _buildStatCard(
          context,
          title: l10n.foulCardSection,
          icon: Icons.warning_amber_outlined,
          iconColor: const Color(0xFFF59E0B),
          stats: [
            StatRow(
                label: l10n.foulLabel, value: '${stats!.foulsCommitted ?? 0}'),
            StatRow(
                label: l10n.foulDrawnLabel, value: '${stats!.foulsDrawn ?? 0}'),
            if ((stats!.yellowCards ?? 0) > 0 || (stats!.redCards ?? 0) > 0)
              StatRow(
                label: l10n.cardsLabel,
                value: '',
                customWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if ((stats!.yellowCards ?? 0) > 0)
                      Container(
                        width: 14,
                        height: 18,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Center(
                          child: Text(
                            '${stats!.yellowCards}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    if ((stats!.redCards ?? 0) > 0)
                      Container(
                        width: 14,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Center(
                          child: Text(
                            '${stats!.redCards}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),

        // 골키퍼 전용
        if (stats!.position == 'G')
          _buildStatCard(
            context,
            title: l10n.goalkeeperSection,
            icon: Icons.sports_handball,
            iconColor: Colors.orange,
            stats: [
              StatRow(label: l10n.savesLabel, value: '${stats!.saves ?? 0}'),
              StatRow(
                  label: l10n.concededLabel,
                  value: '${stats!.goalsConceded ?? 0}'),
            ],
          ),

        const SizedBox(height: 8),

        // 선수 상세 페이지 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              if (player.id > 0) {
                context.push('/player/${player.id}');
              }
            },
            icon: const Icon(Icons.person_outline, size: 18),
            label: Text(AppLocalizations.of(context)!.viewPlayerDetail),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<StatRow> stats,
  }) {
    // 값이 모두 0이거나 없으면 표시하지 않음
    final hasValue = stats.any((stat) =>
        stat.value != '0' &&
            stat.value != '-' &&
            stat.value != '0/0' &&
            stat.value.isNotEmpty ||
        stat.customWidget != null);
    if (!hasValue) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _border),
          // 스탯 목록
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              children: stats.map((stat) {
                if (stat.value == '0' && stat.customWidget == null) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        stat.label,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                        ),
                      ),
                      stat.customWidget ??
                          Row(
                            children: [
                              Text(
                                stat.value,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _textPrimary,
                                ),
                              ),
                              if (stat.subValue != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    stat.subValue!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getPositionName(BuildContext context, String pos) {
    final l10n = AppLocalizations.of(context)!;
    switch (pos.toUpperCase()) {
      case 'G':
        return l10n.positionGoalkeeper;
      case 'D':
        return l10n.positionDefender;
      case 'M':
        return l10n.positionMidfielder;
      case 'F':
        return l10n.positionAttacker;
      default:
        return pos;
    }
  }

  Color _getRatingColor(double rating) {
    if (rating >= 7.5) return const Color(0xFF22C55E);
    if (rating >= 7.0) return const Color(0xFF84CC16);
    if (rating >= 6.5) return const Color(0xFFF59E0B);
    if (rating >= 6.0) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  Color _getPositionColor(String position) {
    switch (position.toUpperCase()) {
      case 'G':
        return Colors.orange;
      case 'D':
        return Colors.blue;
      case 'M':
        return Colors.green;
      case 'F':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

/// 스탯 행 데이터
class StatRow {
  final String label;
  final String value;
  final String? subValue;
  final Widget? customWidget;

  const StatRow({
    required this.label,
    required this.value,
    this.subValue,
    this.customWidget,
  });
}

/// 교체 선수 행
class SubstituteRow extends StatelessWidget {
  final ApiFootballLineupPlayer player;
  final PlayerMatchStats? stats;
  final ApiFootballEvent? substitutionEvent;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const SubstituteRow({
    super.key,
    required this.player,
    this.stats,
    this.substitutionEvent,
  });

  bool get isSubbedIn => substitutionEvent != null;

  @override
  Widget build(BuildContext context) {
    final rating = stats?.ratingValue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () {
          showPlayerStatsModal(context, player, stats);
        },
        child: Row(
          children: [
            // 투입 표시 (IN 뱃지)
            if (isSubbedIn) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_upward,
                        size: 8, color: Colors.green.shade700),
                    Text(
                      substitutionEvent!.timeDisplay,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
            ],
            // 등번호
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSubbedIn ? Colors.green.shade50 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
                border: isSubbedIn
                    ? Border.all(color: Colors.green.shade300, width: 1)
                    : null,
              ),
              child: Center(
                child: Text(
                  player.number?.toString() ?? '-',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSubbedIn ? Colors.green.shade700 : _textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // 이름
            Expanded(
              child: Text(
                player.name,
                style: TextStyle(
                  fontSize: 11,
                  color: isSubbedIn ? Colors.green.shade800 : _textPrimary,
                  fontWeight: isSubbedIn ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 평점
            if (rating != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _getRatingColor(rating).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _getRatingColor(rating),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 7.5) return const Color(0xFF22C55E);
    if (rating >= 7.0) return const Color(0xFF84CC16);
    if (rating >= 6.5) return const Color(0xFFF59E0B);
    if (rating >= 6.0) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }
}
