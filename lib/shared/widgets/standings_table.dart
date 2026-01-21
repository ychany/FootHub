import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_football_service.dart';
import '../../l10n/app_localizations.dart';
import 'loading_indicator.dart';
import '../../features/standings/providers/standings_provider.dart';

/// 순위 탭 위젯
class StandingsTab extends ConsumerWidget {
  final int leagueId;
  final int season;
  final int homeTeamId;
  final int awayTeamId;
  final String leagueName;
  final String? leagueLogo;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _highlight = Color(0xFFFEF3C7);

  const StandingsTab({
    super.key,
    required this.leagueId,
    required this.season,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.leagueName,
    this.leagueLogo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsKey = StandingsKey(leagueId, season);

    // 조별 리그 여부 확인
    final isGroupStageAsync = ref.watch(isGroupStageProvider(standingsKey));
    final isGroupStage = isGroupStageAsync.valueOrNull ?? false;

    // 조별 리그면 그룹별 데이터, 아니면 일반 순위 데이터
    if (isGroupStage) {
      return _buildGroupStageView(context, ref, standingsKey);
    }

    final standingsAsync = ref.watch(leagueStandingsProvider(standingsKey));

    return standingsAsync.when(
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.standingsErrorMessage,
                style: TextStyle(color: _textSecondary)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.invalidate(leagueStandingsProvider(standingsKey)),
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
      data: (standings) {
        if (standings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.leaderboard_outlined,
                    size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(AppLocalizations.of(context)!.noStandingsInfo,
                    style: TextStyle(color: _textSecondary)),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 리그 헤더
              _buildLeagueHeader(context),
              const SizedBox(height: 16),

              // 순위 테이블
              _buildStandingsTable(context, standings),
              const SizedBox(height: 16),

              // 범례 (동적으로 생성)
              _buildLegend(context, standings),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeagueHeader(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/league/$leagueId'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            if (leagueLogo != null)
              CachedNetworkImage(
                imageUrl: leagueLogo!,
                width: 32,
                height: 32,
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.emoji_events, size: 32),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    leagueName,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary),
                  ),
                  Text(
                    AppLocalizations.of(context)!.seasonWithYear(season, season + 1),
                    style: TextStyle(fontSize: 12, color: _textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStandingsTable(
      BuildContext context, List<ApiFootballStanding> standings) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // 테이블 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                const SizedBox(
                    width: 28,
                    child: Text('#',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _textSecondary),
                        textAlign: TextAlign.center)),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(AppLocalizations.of(context)!.team,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _textSecondary))),
                _buildHeaderCell(AppLocalizations.of(context)!.matches),
                _buildHeaderCell(AppLocalizations.of(context)!.winShort),
                _buildHeaderCell(AppLocalizations.of(context)!.drawShort),
                _buildHeaderCell(AppLocalizations.of(context)!.lossShort),
                _buildHeaderCell(AppLocalizations.of(context)!.goalDifference),
                _buildHeaderCell(AppLocalizations.of(context)!.pts),
              ],
            ),
          ),
          // 순위 행
          ...standings.map((team) => _buildTeamRow(context, team)),
        ],
      ),
    );
  }

  Widget _buildTeamRow(BuildContext context, ApiFootballStanding team) {
    final isHomeTeam = team.teamId == homeTeamId;
    final isAwayTeam = team.teamId == awayTeamId;
    final isHighlighted = isHomeTeam || isAwayTeam;
    final zoneColor = _getZoneColor(team.description);

    return Container(
      decoration: BoxDecoration(
        color: isHighlighted ? _highlight : Colors.white,
        border: Border(
          top: BorderSide(color: _border, width: 0.5),
          left: isHighlighted
              ? BorderSide(color: _primary, width: 3)
              : BorderSide.none,
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/team/${team.teamId}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        zoneColor?.withValues(alpha: 0.15) ?? Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${team.rank}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: zoneColor ?? _textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (team.teamLogo != null)
                CachedNetworkImage(
                  imageUrl: team.teamLogo!,
                  width: 22,
                  height: 22,
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.shield, size: 22),
                )
              else
                const Icon(Icons.shield, size: 22, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        team.teamName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isHighlighted ? FontWeight.w700 : FontWeight.w500,
                          color: _textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isHomeTeam) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text('H',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: _primary)),
                      ),
                    ],
                    if (isAwayTeam) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text('A',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.orange)),
                      ),
                    ],
                  ],
                ),
              ),
              _buildDataCell('${team.played}'),
              _buildDataCell('${team.win}',
                  color: team.win > 0 ? const Color(0xFF10B981) : null),
              _buildDataCell('${team.draw}'),
              _buildDataCell('${team.lose}',
                  color: team.lose > 0 ? const Color(0xFFEF4444) : null),
              _buildDataCell(
                  '${team.goalsDiff >= 0 ? '+' : ''}${team.goalsDiff}',
                  color: team.goalsDiff > 0
                      ? const Color(0xFF10B981)
                      : (team.goalsDiff < 0 ? const Color(0xFFEF4444) : null)),
              _buildDataCell('${team.points}', isBold: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(
      BuildContext context, List<ApiFootballStanding> standings) {
    final zones = _getUniqueZones(context, standings);
    if (zones.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(_highlight, AppLocalizations.of(context)!.matchTeam),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _buildLegendItem(_highlight, AppLocalizations.of(context)!.matchTeam),
          ...zones.map((z) => _buildLegendItem(z.color.withValues(alpha: 0.15), z.label)),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return SizedBox(
      width: 32,
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: _textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(String text, {Color? color, bool isBold = false}) {
    return SizedBox(
      width: 32,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: color ?? _textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSmallHeaderCell(String text) {
    return SizedBox(
      width: 26,
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: _textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSmallDataCell(String text, {Color? color, bool isBold = false}) {
    return SizedBox(
      width: 26,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: color ?? _textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // description 필드를 기반으로 존 색상 반환 (standings_screen.dart와 동일한 색상 체계)
  Color? _getZoneColor(String? description) {
    if (description == null || description.isEmpty) return null;
    final desc = description.toLowerCase();

    // 챔피언스리그 16강 직행 (진한 파랑)
    if ((desc.contains('champions league') || desc.contains('ucl')) &&
        (desc.contains('round of 16') || desc.contains('1/8'))) {
      return Colors.blue.shade800;
    }
    // 챔피언스리그 플레이오프 (청록)
    if ((desc.contains('champions league') || desc.contains('ucl')) &&
        (desc.contains('playoff') || desc.contains('play-off') || desc.contains('1/16'))) {
      return Colors.cyan.shade600;
    }
    // 챔피언스리그 일반 (파랑)
    if (desc.contains('champions league') || desc.contains('ucl')) {
      return Colors.blue;
    }
    // 유로파리그 16강 직행 (진한 주황)
    if (desc.contains('europa league') && (desc.contains('round of 16') || desc.contains('1/8'))) {
      return Colors.orange.shade800;
    }
    // 유로파리그 플레이오프 (황색)
    if (desc.contains('europa league') && (desc.contains('playoff') || desc.contains('play-off') || desc.contains('1/16'))) {
      return Colors.amber.shade700;
    }
    // 유로파리그 일반 (주황)
    if (desc.contains('europa league') || desc.contains('uel')) {
      return Colors.orange;
    }
    // 컨퍼런스리그 (녹색)
    if (desc.contains('conference league') || desc.contains('uecl')) {
      return Colors.green;
    }
    // 승격 (녹색)
    if (desc.contains('promotion')) {
      return Colors.green;
    }
    // 플레이오프 (주황)
    if (desc.contains('playoff') || desc.contains('play-off')) {
      return Colors.amber.shade700;
    }
    // 강등/탈락 (빨강)
    if (desc.contains('relegation') || desc.contains('elimination')) {
      return Colors.red;
    }
    // 다음 라운드 진출 (녹색) - 컵 대회용
    if (desc.contains('next round') ||
        desc.contains('knockout') ||
        desc.contains('qualification')) {
      return Colors.green;
    }

    return null;
  }

  // 범례에 사용할 존 목록 추출
  List<({Color color, String label})> _getUniqueZones(
      BuildContext context, List<ApiFootballStanding> standings) {
    final l10n = AppLocalizations.of(context)!;
    final zones = <String, Color>{};

    for (final team in standings) {
      final desc = team.description;
      if (desc == null || desc.isEmpty) continue;

      final color = _getZoneColor(desc);
      if (color != null && !zones.containsKey(desc)) {
        zones[desc] = color;
      }
    }

    // 간략화된 레이블로 변환 (중복 제거를 위해 label 기준으로 그룹화)
    final labelColorMap = <String, Color>{};

    for (final e in zones.entries) {
      final desc = e.key.toLowerCase();
      String label;

      if (desc.contains('champions league') || desc.contains('ucl')) {
        if (desc.contains('round of 16') || desc.contains('1/8')) {
          label = l10n.uclRoundOf16;
        } else if (desc.contains('playoff') || desc.contains('play-off') || desc.contains('1/16')) {
          label = l10n.uclPlayoff;
        } else {
          label = 'UCL';
        }
      } else if (desc.contains('europa league') || desc.contains('uel')) {
        if (desc.contains('round of 16') || desc.contains('1/8')) {
          label = l10n.uelRoundOf16;
        } else if (desc.contains('playoff') || desc.contains('play-off') || desc.contains('1/16')) {
          label = l10n.uelPlayoff;
        } else {
          label = 'UEL';
        }
      } else if (desc.contains('conference league') || desc.contains('uecl')) {
        if (desc.contains('round of 16') || desc.contains('1/8')) {
          label = l10n.ueclRoundOf16;
        } else if (desc.contains('playoff') || desc.contains('play-off') || desc.contains('1/16')) {
          label = l10n.ueclPlayoff;
        } else {
          label = 'UECL';
        }
      } else if (desc.contains('relegation') || desc.contains('elimination')) {
        label = l10n.relegation;
      } else if (desc.contains('promotion')) {
        label = l10n.promotion;
      } else if (desc.contains('playoff') || desc.contains('play-off')) {
        label = l10n.playoff;
      } else if (e.key.length > 15) {
        label = '${e.key.substring(0, 12)}...';
      } else {
        label = e.key;
      }

      // 같은 레이블이 없을 때만 추가 (중복 방지)
      if (!labelColorMap.containsKey(label)) {
        labelColorMap[label] = e.value;
      }
    }

    return labelColorMap.entries
        .map((e) => (color: e.value, label: e.key))
        .toList();
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: _border),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 11, color: _textSecondary)),
      ],
    );
  }

  // 조별 리그 뷰 (그룹별 순위 표시)
  Widget _buildGroupStageView(
      BuildContext context, WidgetRef ref, StandingsKey standingsKey) {
    final groupedAsync =
        ref.watch(leagueStandingsGroupedProvider(standingsKey));

    return groupedAsync.when(
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.standingsErrorMessage,
                style: TextStyle(color: _textSecondary)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.invalidate(leagueStandingsGroupedProvider(standingsKey)),
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
      data: (groupedStandings) {
        if (groupedStandings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.leaderboard_outlined,
                    size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(AppLocalizations.of(context)!.noStandingsInfo,
                    style: TextStyle(color: _textSecondary)),
              ],
            ),
          );
        }

        // 두 팀이 속한 그룹 찾기
        String? teamGroup;
        for (final entry in groupedStandings.entries) {
          for (final team in entry.value) {
            if (team.teamId == homeTeamId || team.teamId == awayTeamId) {
              teamGroup = entry.key;
              break;
            }
          }
          if (teamGroup != null) break;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 리그 헤더
              GestureDetector(
                onTap: () => context.push('/league/$leagueId'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      if (leagueLogo != null)
                        CachedNetworkImage(
                          imageUrl: leagueLogo!,
                          width: 32,
                          height: 32,
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.emoji_events, size: 32),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              leagueName,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _textPrimary),
                            ),
                            Text(
                              AppLocalizations.of(context)!
                                  .groupStageWithYear(season),
                              style: TextStyle(
                                  fontSize: 12, color: _textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: _textSecondary, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 두 팀이 속한 그룹 먼저 표시
              if (teamGroup != null &&
                  groupedStandings.containsKey(teamGroup)) ...[
                _buildGroupTable(
                    context, teamGroup, groupedStandings[teamGroup]!,
                    isTeamGroup: true),
                const SizedBox(height: 16),
              ],

              // 나머지 그룹 표시
              ...groupedStandings.entries
                  .where((e) => e.key != teamGroup)
                  .map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child:
                            _buildGroupTable(context, entry.key, entry.value),
                      )),

              // 범례
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(
                        _highlight, AppLocalizations.of(context)!.matchTeam),
                    const SizedBox(width: 16),
                    _buildLegendItem(
                        const Color(0xFF10B981).withValues(alpha: 0.15),
                        AppLocalizations.of(context)!.qualified),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 그룹별 테이블 위젯
  Widget _buildGroupTable(
    BuildContext context,
    String groupName,
    List<ApiFootballStanding> standings, {
    bool isTeamGroup = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isTeamGroup ? _primary.withValues(alpha: 0.3) : _border),
      ),
      child: Column(
        children: [
          // 그룹 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isTeamGroup
                  ? _primary.withValues(alpha: 0.05)
                  : Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Text(
                  groupName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isTeamGroup ? _primary : _textPrimary,
                  ),
                ),
                if (isTeamGroup) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.matchGroup,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _primary),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // 테이블 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(top: BorderSide(color: _border, width: 0.5)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 24),
                const SizedBox(width: 6),
                const SizedBox(width: 20),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(AppLocalizations.of(context)!.team,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _textSecondary))),
                _buildSmallHeaderCell(AppLocalizations.of(context)!.matches),
                _buildSmallHeaderCell(AppLocalizations.of(context)!.winShort),
                _buildSmallHeaderCell(AppLocalizations.of(context)!.drawShort),
                _buildSmallHeaderCell(AppLocalizations.of(context)!.lossShort),
                _buildSmallHeaderCell(
                    AppLocalizations.of(context)!.goalDifference),
                _buildSmallHeaderCell(AppLocalizations.of(context)!.pts),
              ],
            ),
          ),
          // 순위 행
          ...standings.map((team) {
            final isHomeTeam = team.teamId == homeTeamId;
            final isAwayTeam = team.teamId == awayTeamId;
            final isHighlighted = isHomeTeam || isAwayTeam;
            final zoneColor = _getZoneColor(team.description);

            return Container(
              decoration: BoxDecoration(
                color: isHighlighted ? _highlight : Colors.white,
                border: Border(
                  top: BorderSide(color: _border, width: 0.5),
                  left: isHighlighted
                      ? BorderSide(color: _primary, width: 3)
                      : BorderSide.none,
                ),
              ),
              child: InkWell(
                onTap: () => context.push('/team/${team.teamId}'),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: zoneColor?.withValues(alpha: 0.15) ??
                                Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${team.rank}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: zoneColor ?? _textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (team.teamLogo != null)
                        CachedNetworkImage(
                          imageUrl: team.teamLogo!,
                          width: 20,
                          height: 20,
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.shield, size: 20),
                        )
                      else
                        const Icon(Icons.shield, size: 20, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                team.teamName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isHighlighted
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: _textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isHomeTeam) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 3, vertical: 1),
                                decoration: BoxDecoration(
                                  color: _primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text('H',
                                    style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: _primary)),
                              ),
                            ],
                            if (isAwayTeam) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 3, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text('A',
                                    style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.orange)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      _buildSmallDataCell('${team.played}'),
                      _buildSmallDataCell('${team.win}',
                          color:
                              team.win > 0 ? const Color(0xFF10B981) : null),
                      _buildSmallDataCell('${team.draw}'),
                      _buildSmallDataCell('${team.lose}',
                          color:
                              team.lose > 0 ? const Color(0xFFEF4444) : null),
                      _buildSmallDataCell(
                          '${team.goalsDiff >= 0 ? '+' : ''}${team.goalsDiff}',
                          color: team.goalsDiff > 0
                              ? const Color(0xFF10B981)
                              : (team.goalsDiff < 0
                                  ? const Color(0xFFEF4444)
                                  : null)),
                      _buildSmallDataCell('${team.points}', isBold: true),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
