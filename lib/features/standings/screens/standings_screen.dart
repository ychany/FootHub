import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_football_ids.dart';
import '../../../core/services/api_football_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/standings_provider.dart';

class StandingsScreen extends ConsumerWidget {
  const StandingsScreen({super.key});

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _background = Color(0xFFF9FAFB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLeague = ref.watch(selectedStandingsLeagueProvider);
    final selectedSeason = ref.watch(selectedSeasonProvider);
    final currentSeason = selectedSeason ?? getCurrentSeasonForLeague(selectedLeague);
    final standingsKey = StandingsKey(selectedLeague, currentSeason);
    final standingsAsync = ref.watch(leagueStandingsProvider(standingsKey));
    final isCup = isCupCompetition(selectedLeague);
    final availableSeasons = getAvailableSeasons(selectedLeague);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Column(
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    const Text(
                      '리그 순위',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // 본문
              Expanded(
                child: Column(
                  children: [
                    // League Filter - 탭바 스타일
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: LeagueIds.supportedLeagues.map((league) {
                            final isSelected = selectedLeague == league.id;
                            return GestureDetector(
                              onTap: () {
                                ref.read(selectedStandingsLeagueProvider.notifier).state = league.id;
                                ref.read(selectedSeasonProvider.notifier).state = null;
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? _primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  league.name,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : _textSecondary,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Season Selector - 알약 버튼 스타일
                    SizedBox(
                      height: 32,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: availableSeasons.map((season) {
                          final isSelected = season == currentSeason;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                ref.read(selectedSeasonProvider.notifier).state = season;
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? _primaryLight : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? _primary : _border,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  getSeasonDisplayName(season, selectedLeague),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? _primary : _textSecondary,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Standings Table
                    Expanded(
                      child: standingsAsync.when(
                        data: (standings) {
                          if (standings.isEmpty) {
                            // UCL/UEL 등 컵 대회는 별도 안내
                            if (isCup) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.emoji_events_outlined, size: 64, color: Colors.amber.shade700),
                                    const SizedBox(height: 16),
                                    Text(
                                      LeagueIds.getLeagueInfo(selectedLeague)?.name ?? '대회',
                                      style: AppTextStyles.subtitle1,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '2024-25 시즌부터 새 리그 형식으로 변경되어',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    const Text(
                                      '순위표가 아직 제공되지 않습니다',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      '일정 탭에서 경기 일정을 확인하세요',
                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // K리그 미지원 안내 (API-Football은 K리그 지원하므로 조건 변경)
                            if (selectedLeague == LeagueIds.kLeague1 || selectedLeague == LeagueIds.kLeague2) {
                              // K리그는 이제 지원됨 - 데이터가 없으면 일반 안내 표시
                            }

                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.leaderboard_outlined, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('순위 정보가 없습니다', style: TextStyle(color: Colors.grey)),
                                  SizedBox(height: 8),
                                  Text(
                                    '해당 리그의 순위 정보를 불러올 수 없습니다',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: () async {
                              ref.invalidate(leagueStandingsProvider(standingsKey));
                            },
                            child: Column(
                              children: [
                                // 리그별 동적 범례
                                _buildLeagueLegend(selectedLeague, standings),
                                Expanded(
                                  child: _StandingsTable(standings: standings),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const LoadingIndicator(),
                        error: (e, _) => ErrorState(
                          message: e.toString(),
                          onRetry: () => ref.invalidate(leagueStandingsProvider(standingsKey)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 리그별 동적 범례 생성
  Widget _buildLeagueLegend(int leagueId, List<ApiFootballStanding> standings) {
    // standings에서 실제 description 값들 추출
    final descriptions = standings
        .where((s) => s.description != null && s.description!.isNotEmpty)
        .map((s) => s.description!.toLowerCase())
        .toSet();

    // 범례 아이템 동적 생성
    final legendItems = <Widget>[];

    // UCL 관련 - championship은 제외
    // UCL/UEL 순위표: 1/8 = 직행, 1/16 = PO
    // 일반 리그: qualification = 예선, 나머지 = 본선
    final hasUclDirect = descriptions.any((d) => d.contains('champions') && !d.contains('championship') && d.contains('1/8'));
    final hasUclPlayoff = descriptions.any((d) => d.contains('champions') && !d.contains('championship') && d.contains('1/16'));
    final hasUclQualification = descriptions.any((d) => d.contains('champions') && !d.contains('championship') && (d.contains('qualification') || d.contains('qualifying')));
    final hasUclGeneral = descriptions.any((d) => d.contains('champions') && !d.contains('championship') && !d.contains('1/8') && !d.contains('1/16') && !d.contains('qualification') && !d.contains('qualifying'));

    // UCL/UEL 순위표용 (직행 vs PO)
    if (hasUclDirect) {
      legendItems.add(_LegendItem(color: Colors.blue.shade800, label: 'UCL 직행'));
    }
    if (hasUclPlayoff) {
      legendItems.add(_LegendItem(color: Colors.cyan.shade600, label: 'UCL PO'));
    }
    // 일반 리그용 (본선 vs 예선)
    if (hasUclGeneral) {
      legendItems.add(_LegendItem(color: Colors.blue, label: 'UCL'));
    }
    if (hasUclQualification && !hasUclPlayoff) {
      legendItems.add(_LegendItem(color: Colors.cyan.shade600, label: 'UCL 예선'));
    }

    // UEL 관련
    final hasUelDirect = descriptions.any((d) => d.contains('europa') && d.contains('1/8'));
    final hasUelPlayoff = descriptions.any((d) => d.contains('europa') && d.contains('1/16'));
    final hasUelGeneral = descriptions.any((d) => d.contains('europa') && !d.contains('1/8') && !d.contains('1/16') && !d.contains('qualification') && !d.contains('qualifying') && !d.contains('relegation'));

    if (hasUelDirect) {
      legendItems.add(_LegendItem(color: Colors.orange.shade800, label: 'UEL 직행'));
    }
    if (hasUelPlayoff) {
      legendItems.add(_LegendItem(color: Colors.amber.shade700, label: 'UEL PO'));
    }
    if (hasUelGeneral) {
      legendItems.add(_LegendItem(color: Colors.orange, label: 'UEL'));
    }

    // UECL 관련 (통합) - relegation 제외
    if (descriptions.any((d) => d.contains('conference') && !d.contains('relegation'))) {
      legendItems.add(_LegendItem(color: Colors.green, label: 'UECL'));
    }

    // K리그 특수 케이스
    final hasChampionshipRound = descriptions.any((d) => d.contains('championship round'));
    final hasRelegationRound = descriptions.any((d) => d.contains('relegation round'));
    final hasPromotion = descriptions.any((d) => d.contains('promotion') && !d.contains('champions') && !d.contains('europa') && !d.contains('conference'));
    final hasPromotionPlayoff = descriptions.any((d) => d.contains('promotion') && d.contains('playoff') && !d.contains('champions') && !d.contains('europa'));

    if (hasChampionshipRound) {
      legendItems.add(_LegendItem(color: Colors.blue, label: '챔피언십'));
    }
    if (hasRelegationRound) {
      legendItems.add(_LegendItem(color: Colors.grey, label: '하위 스플릿'));
    }
    if (hasPromotion && !hasPromotionPlayoff) {
      legendItems.add(_LegendItem(color: Colors.green, label: '승격'));
    }
    if (hasPromotionPlayoff) {
      legendItems.add(_LegendItem(color: Colors.teal, label: '승격 PO'));
    }

    // 강등 관련 (통합) - K리그 Relegation Round는 제외
    if (descriptions.any((d) => d.contains('relegation') && !d.contains('europa') && !d.contains('conference') && !d.contains('round'))) {
      legendItems.add(_LegendItem(color: Colors.red, label: '강등'));
    }

    if (legendItems.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: legendItems,
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StandingsTable extends StatelessWidget {
  final List<ApiFootballStanding> standings;

  const _StandingsTable({required this.standings});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const SizedBox(width: 28, child: Text('순위', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                const SizedBox(width: 8),
                const Expanded(child: Text('팀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                _HeaderCell('경기'),
                _HeaderCell('승'),
                _HeaderCell('무'),
                _HeaderCell('패'),
                _HeaderCell('득점'),
                _HeaderCell('실점'),
                _HeaderCell('득실'),
                SizedBox(
                  width: 36,
                  child: Text(
                    '승점',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Rows
          ...standings.map((standing) => _StandingRow(
            standing: standing,
            totalTeams: standings.length,
          )),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;

  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  final ApiFootballStanding standing;
  final int totalTeams;

  const _StandingRow({required this.standing, required this.totalTeams});

  @override
  Widget build(BuildContext context) {
    final desc = standing.description?.toLowerCase() ?? '';

    // UCL/UEL 순위표용 색상 구분 (16강 직행 vs 플레이오프)
    // 1/8-finals = 16강 직행, 1/16-finals = 플레이오프 (32강전)
    final isUclDirect = desc.contains('champions') && !desc.contains('championship') && desc.contains('1/8');
    final isUclPlayoff = desc.contains('champions') && !desc.contains('championship') && (desc.contains('qualifying') || desc.contains('qualification') || desc.contains('1/16'));
    final isUelDirect = desc.contains('europa') && desc.contains('1/8');
    final isUelPlayoff = desc.contains('europa') && (desc.contains('qualifying') || desc.contains('qualification') || desc.contains('1/16'));
    final isConferenceDirect = desc.contains('conference') && desc.contains('1/8');
    final isConferencePlayoff = desc.contains('conference') && (desc.contains('qualifying') || desc.contains('qualification') || desc.contains('1/16'));

    // K리그 특수 케이스
    final isChampionshipRound = desc.contains('championship round');
    final isRelegationRound = desc.contains('relegation round');
    final isPromotion = desc.contains('promotion') && !desc.contains('champions') && !desc.contains('europa') && !desc.contains('conference');
    final isPromotionPlayoff = desc.contains('promotion') && desc.contains('playoff') && !desc.contains('champions') && !desc.contains('europa');

    // 강등권 (먼저 체크해야 championship이 champions로 잘못 인식되지 않음)
    // "Relegation", "Relegation - Serie B", "Relegation - 2. Bundesliga", "Relegation - Championship"
    // K리그 "Relegation Round"는 강등이 아니라 하위 스플릿이므로 제외
    final isRelegation = desc.contains('relegation') &&
        !desc.contains('playoff') && !desc.contains('europa') && !desc.contains('conference') && !desc.contains('round');
    // 강등 플레이오프: "Relegation Playoffs", "Bundesliga (Relegation)"
    final isRelegationPlayoff = (desc.contains('relegation') && desc.contains('playoff') && !desc.contains('round')) ||
        (desc.contains('bundesliga') && desc.contains('relegation'));

    // 일반 리그용 (UCL/UEL/Conference 진출권)
    // EPL/라리가: "Champions League", "UEFA Europa League"
    // 분데스/세리에A: "Promotion - Champions League (League phase: )"
    // 주의: "championship"이 "champions"를 포함하므로 제외
    final isChampionsLeague = desc.contains('champions') && !desc.contains('championship') &&
        !desc.contains('qualifying') && !desc.contains('qualification') && !desc.contains('1/8') && !desc.contains('1/16');
    final isEuropaLeague = desc.contains('europa') &&
        !desc.contains('qualifying') && !desc.contains('qualification') && !desc.contains('1/8') && !desc.contains('1/16') &&
        !desc.contains('relegation');
    final isConferenceLeague = desc.contains('conference') &&
        !desc.contains('qualifying') && !desc.contains('qualification') && !desc.contains('1/8') && !desc.contains('1/16') &&
        !desc.contains('relegation');
    // UCL에서 UEL로 강등
    final isToEuropa = desc.contains('relegation') && desc.contains('europa');
    // UEL에서 UECL로 강등
    final isToConference = desc.contains('relegation') && desc.contains('conference');

    Color? rowColor;
    Color rankColor = Colors.grey;

    // UCL/UEL 순위표 (직행 vs 플레이오프 구분)
    if (isUclDirect) {
      // UCL 16강 직행 - 진한 파란색
      rowColor = Colors.blue.shade800.withValues(alpha: 0.12);
      rankColor = Colors.blue.shade800;
    } else if (isUclPlayoff) {
      // UCL 플레이오프/예선 - 하늘색 (cyan)
      rowColor = Colors.cyan.shade300.withValues(alpha: 0.15);
      rankColor = Colors.cyan.shade600;
    } else if (isUelDirect) {
      // UEL 16강 직행 - 진한 주황색
      rowColor = Colors.orange.shade800.withValues(alpha: 0.12);
      rankColor = Colors.orange.shade800;
    } else if (isUelPlayoff || isToEuropa) {
      // UEL 플레이오프 또는 UCL에서 UEL로 이동 - 노란색
      rowColor = Colors.amber.shade300.withValues(alpha: 0.15);
      rankColor = Colors.amber.shade700;
    } else if (isConferenceDirect || isConferencePlayoff || isToConference) {
      // Conference 전체 통합 - 초록색
      rowColor = Colors.green.withValues(alpha: 0.08);
      rankColor = Colors.green;
    } else if (isChampionsLeague) {
      // 일반 리그 UCL 진출권
      rowColor = Colors.blue.withValues(alpha: 0.08);
      rankColor = Colors.blue;
    } else if (isEuropaLeague) {
      // 일반 리그 UEL 진출권
      rowColor = Colors.orange.withValues(alpha: 0.08);
      rankColor = Colors.orange;
    } else if (isConferenceLeague) {
      // 일반 리그 Conference 진출권
      rowColor = Colors.green.withValues(alpha: 0.08);
      rankColor = Colors.green;
    } else if (isRelegationPlayoff || isRelegation) {
      // 강등 (강등 PO + 강등 확정 통합)
      rowColor = Colors.red.withValues(alpha: 0.08);
      rankColor = Colors.red;
    } else if (isChampionshipRound) {
      // K리그 챔피언십 라운드 (상위 스플릿)
      rowColor = Colors.blue.withValues(alpha: 0.08);
      rankColor = Colors.blue;
    } else if (isRelegationRound) {
      // K리그 하위 스플릿 (강등은 아님)
      rowColor = Colors.grey.withValues(alpha: 0.08);
      rankColor = Colors.grey;
    } else if (isPromotion && !isPromotionPlayoff) {
      // K리그2 승격 (직접 승격)
      rowColor = Colors.green.withValues(alpha: 0.08);
      rankColor = Colors.green;
    } else if (isPromotionPlayoff) {
      // K리그2 승격 플레이오프
      rowColor = Colors.teal.withValues(alpha: 0.08);
      rankColor = Colors.teal;
    }

    return InkWell(
      onTap: () => context.push('/team/${standing.teamId}'),
      child: Container(
        color: rowColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
        children: [
          // Rank
          Container(
            width: 28,
            alignment: Alignment.center,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: rankColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                '${standing.rank}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: rankColor,
                ),
              ),
            ),
          ),

          // Team Badge + Name
          Expanded(
            child: Row(
              children: [
                if (standing.teamLogo != null)
                  CachedNetworkImage(
                    imageUrl: standing.teamLogo!,
                    width: 24,
                    height: 24,
                    placeholder: (_, __) => const SizedBox(width: 24, height: 24),
                    errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 24, color: Colors.grey),
                  )
                else
                  const Icon(Icons.shield, size: 24, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    standing.teamName,
                    style: AppTextStyles.body2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Stats
          _StatCell('${standing.played}'),
          _StatCell('${standing.win}', color: Colors.green),
          _StatCell('${standing.draw}'),
          _StatCell('${standing.lose}', color: Colors.red),
          _StatCell('${standing.goalsFor}'),
          _StatCell('${standing.goalsAgainst}'),
          _StatCell(
            standing.goalsDiff >= 0 ? '+${standing.goalsDiff}' : '${standing.goalsDiff}',
            color: standing.goalsDiff > 0 ? Colors.green : (standing.goalsDiff < 0 ? Colors.red : null),
          ),

          // Points
          Container(
            width: 36,
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${standing.points}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String text;
  final Color? color;

  const _StatCell(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color),
        textAlign: TextAlign.center,
      ),
    );
  }
}
