import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/api_football_service.dart';
import '../../../core/utils/error_helper.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/banner_ad_widget.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../../l10n/app_localizations.dart';

// Providers (API-Football 사용)
final playerDetailProvider =
    FutureProvider.family<ApiFootballPlayer?, String>((ref, playerId) async {
  final service = ApiFootballService();
  final id = int.tryParse(playerId);
  if (id == null) return null;
  return service.getPlayerById(id);
});

// 여러 시즌 통계 Provider (최근 5시즌)
final playerMultiSeasonStatsProvider =
    FutureProvider.family<List<ApiFootballPlayer>, String>((ref, playerId) async {
  final service = ApiFootballService();
  final id = int.tryParse(playerId);
  if (id == null) return [];

  final currentYear = DateTime.now().year;
  final seasons = <ApiFootballPlayer>[];

  // 최근 5시즌 데이터 조회
  for (int year = currentYear; year >= currentYear - 4; year--) {
    try {
      final player = await service.getPlayerById(id, season: year);
      if (player != null && player.statistics.isNotEmpty) {
        // 출전 기록이 있는 시즌만 추가
        final hasAppearances = player.statistics.any((s) => (s.appearances ?? 0) > 0);
        if (hasAppearances) {
          seasons.add(player);
        }
      }
    } catch (_) {
      // 해당 시즌 데이터 없으면 무시
    }
  }

  return seasons;
});

final playerTeamProvider =
    FutureProvider.family<ApiFootballTeam?, String?>((ref, teamId) async {
  if (teamId == null || teamId.isEmpty) return null;
  final service = ApiFootballService();
  final id = int.tryParse(teamId);
  if (id == null) return null;
  return service.getTeamById(id);
});

// 이적 기록 Provider
final playerTransfersProvider =
    FutureProvider.family<List<ApiFootballTransfer>, String>((ref, playerId) async {
  final service = ApiFootballService();
  final id = int.tryParse(playerId);
  if (id == null) return [];
  return service.getPlayerTransfers(id);
});

// 트로피 Provider
final playerTrophiesProvider =
    FutureProvider.family<List<ApiFootballTrophy>, String>((ref, playerId) async {
  final service = ApiFootballService();
  final id = int.tryParse(playerId);
  if (id == null) return [];
  return service.getPlayerTrophies(id);
});

// 부상/출전정지 이력 Provider
final playerSidelinedProvider =
    FutureProvider.family<List<ApiFootballSidelined>, String>((ref, playerId) async {
  final service = ApiFootballService();
  final id = int.tryParse(playerId);
  if (id == null) return [];
  return service.getPlayerSidelined(id);
});

/// 선수 출전 경기 기록 (경기 + 해당 경기 스탯)
class PlayerFixtureRecord {
  final ApiFootballFixture fixture;
  final PlayerMatchStats? stats;

  PlayerFixtureRecord({required this.fixture, this.stats});
}

// 선수 출전 경기 Provider
final playerFixturesProvider =
    FutureProvider.family<List<PlayerFixtureRecord>, ({String playerId, int teamId})>((ref, params) async {
  final service = ApiFootballService();
  final playerId = int.tryParse(params.playerId);
  if (playerId == null) return [];

  final now = DateTime.now();
  final currentYear = now.year;

  // 현재 진행 중인 시즌 찾기
  List<ApiFootballFixture> fixtures = [];
  for (final season in [currentYear, currentYear - 1, currentYear - 2]) {
    final seasonFixtures = await service.getTeamSeasonFixtures(params.teamId, season);
    if (seasonFixtures.isEmpty) continue;

    final hasPast = seasonFixtures.any((f) => f.date.isBefore(now));
    final hasFuture = seasonFixtures.any((f) => f.date.isAfter(now));

    if (hasPast && hasFuture) {
      fixtures = seasonFixtures;
      break;
    }
    if (fixtures.isEmpty && seasonFixtures.isNotEmpty) {
      fixtures = seasonFixtures;
    }
  }

  // 종료된 경기만 필터링 (최근 경기순)
  final finishedFixtures = fixtures
      .where((f) => f.isFinished)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  // 최근 15경기까지만 조회
  final recentFixtures = finishedFixtures.take(15).toList();

  // 병렬로 모든 경기의 선수 스탯 조회
  final futures = recentFixtures.map((fixture) async {
    try {
      final playerStats = await service.getFixturePlayers(fixture.id);
      PlayerMatchStats? playerStat;

      for (final teamStats in playerStats) {
        final found = teamStats.players.where((p) => p.id == playerId).firstOrNull;
        if (found != null) {
          playerStat = found;
          break;
        }
      }

      // 출전한 경기만 반환 (출전 시간이 있는 경우)
      if (playerStat != null && (playerStat.minutesPlayed ?? 0) > 0) {
        return PlayerFixtureRecord(fixture: fixture, stats: playerStat);
      }
    } catch (_) {
      // 스탯 조회 실패 시 무시
    }
    return null;
  }).toList();

  // 병렬 실행 후 null 제거
  final results = await Future.wait(futures);
  final records = results.whereType<PlayerFixtureRecord>().toList();

  // 날짜순 정렬 (최근 경기 먼저)
  records.sort((a, b) => b.fixture.date.compareTo(a.fixture.date));

  return records;
});

class PlayerDetailScreen extends ConsumerWidget {
  final String playerId;
  final int? teamId;

  static const _textSecondary = Color(0xFF6B7280);
  static const _background = Color(0xFFF9FAFB);

  const PlayerDetailScreen({super.key, required this.playerId, this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(playerDetailProvider(playerId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _background,
        bottomNavigationBar: const BottomBannerAdWidget(),
        body: playerAsync.when(
          data: (player) {
            if (player == null) {
              return SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(context),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off,
                                size: 64, color: _textSecondary),
                            const SizedBox(height: 16),
                            Builder(builder: (context) => Text(
                              AppLocalizations.of(context)!.playerNotFoundDesc,
                              style:
                                  TextStyle(color: _textSecondary, fontSize: 16),
                            )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return _PlayerDetailContent(player: player, playerId: playerId, teamId: teamId);
          },
          loading: () => const LoadingIndicator(),
          error: (e, _) => SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: Center(
                    child: Builder(builder: (ctx) => Text(
                      '${AppLocalizations.of(ctx)!.error}: $e',
                      style: const TextStyle(color: _textSecondary)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            color: const Color(0xFF111827),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Builder(builder: (ctx) => Text(
              AppLocalizations.of(ctx)!.playerInfo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            )),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _PlayerDetailContent extends ConsumerStatefulWidget {
  final ApiFootballPlayer player;
  final String playerId;
  final int? teamId;

  const _PlayerDetailContent({required this.player, required this.playerId, this.teamId});

  @override
  ConsumerState<_PlayerDetailContent> createState() => _PlayerDetailContentState();
}

class _PlayerDetailContentState extends ConsumerState<_PlayerDetailContent>
    with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF2563EB);
  static const _textSecondary = Color(0xFF6B7280);

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // 고정 헤더
          _PlayerHeader(player: widget.player, playerId: widget.playerId),
          // 고정 탭바
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: _primary,
              unselectedLabelColor: _textSecondary,
              indicatorColor: _primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(text: AppLocalizations.of(context)!.profileTab),
                Tab(text: AppLocalizations.of(context)!.matchesTab),
                Tab(text: AppLocalizations.of(context)!.seasonStats),
                Tab(text: AppLocalizations.of(context)!.careerTab),
              ],
            ),
          ),
          // 스크롤되는 탭 내용
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 프로필 탭
                _ProfileTab(player: widget.player, playerId: widget.playerId),
                // 출전 경기 탭
                _MatchesTab(player: widget.player, playerId: widget.playerId, teamId: widget.teamId),
                // 시즌 통계 탭
                _SeasonStatsTab(player: widget.player, playerId: widget.playerId),
                // 커리어 탭 (이적, 트로피)
                _CareerTab(playerId: widget.playerId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 프로필 탭
class _ProfileTab extends ConsumerWidget {
  final ApiFootballPlayer player;
  final String playerId;

  const _ProfileTab({required this.player, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _BasicInfoCard(player: player),
          const SizedBox(height: 12),
          // 현재 시즌 통계 요약
          if (player.statistics.isNotEmpty)
            _CurrentSeasonSummary(player: player),
          const SizedBox(height: 12),
          // 부상/출전정지 이력
          _SidelinedSection(playerId: playerId),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// 현재 시즌 요약 카드
class _CurrentSeasonSummary extends StatelessWidget {
  final ApiFootballPlayer player;

  static const _primary = Color(0xFF2563EB);
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);
  static const _error = Color(0xFFEF4444);
  static const _textPrimary = Color(0xFF111827);
  static const _border = Color(0xFFE5E7EB);

  const _CurrentSeasonSummary({required this.player});

  @override
  Widget build(BuildContext context) {
    // 모든 리그 통계 합산
    int totalGoals = 0;
    int totalAssists = 0;
    int totalAppearances = 0;
    int totalMinutes = 0;
    int totalYellowCards = 0;
    int totalRedCards = 0;

    for (final stats in player.statistics) {
      totalGoals += stats.goals ?? 0;
      totalAssists += stats.assists ?? 0;
      totalAppearances += stats.appearances ?? 0;
      totalMinutes += stats.minutes ?? 0;
      totalYellowCards += stats.yellowCards ?? 0;
      totalRedCards += stats.redCards ?? 0;
    }

    if (totalAppearances == 0) return const SizedBox.shrink();

    final season = player.statistics.first.season;
    final l10n = AppLocalizations.of(context)!;
    final seasonText = season != null ? '$season/${season + 1}' : l10n.currentSeason;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.bar_chart, color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.seasonStatsSummary(seasonText),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 주요 통계 그리드
          Row(
            children: [
              Builder(builder: (context) => _SummaryStatBox(
                icon: Icons.sports_soccer,
                label: AppLocalizations.of(context)!.goal,
                value: '$totalGoals',
                color: _success,
              )),
              const SizedBox(width: 12),
              Builder(builder: (context) => _SummaryStatBox(
                icon: Icons.handshake_outlined,
                label: AppLocalizations.of(context)!.assist,
                value: '$totalAssists',
                color: _primary,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Row(
                children: [
                  _SummaryStatBox(
                    icon: Icons.timer_outlined,
                    label: l10n.matchesPlayed,
                    value: l10n.nMatches(totalAppearances),
                    color: Colors.purple,
                  ),
                  const SizedBox(width: 12),
                  _SummaryStatBox(
                    icon: Icons.schedule,
                    label: l10n.playingTime,
                    value: '${totalMinutes}m',
                    color: Colors.teal,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // 카드 통계
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CardStatItem(
                      color: _warning,
                      value: totalYellowCards,
                      label: l10n.yellowCard,
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: _border,
                    ),
                    _CardStatItem(
                      color: _error,
                      value: totalRedCards,
                      label: l10n.redCard,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryStatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryStatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 시즌 통계 탭
class _SeasonStatsTab extends ConsumerWidget {
  final ApiFootballPlayer player;
  final String playerId;

  static const _textSecondary = Color(0xFF6B7280);

  const _SeasonStatsTab({required this.player, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final multiSeasonAsync = ref.watch(playerMultiSeasonStatsProvider(playerId));

    return multiSeasonAsync.when(
      data: (seasons) {
        if (seasons.isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 64, color: _textSecondary),
                const SizedBox(height: 16),
                Text(
                  l10n.noSeasonStats,
                  style: TextStyle(color: _textSecondary, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 소속팀 / 국가대표팀 분리된 확장 가능한 테이블
              _SeasonStatsTable(seasons: seasons),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Builder(builder: (ctx) => Text(AppLocalizations.of(ctx)!.loadingSeasonStats)),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Builder(builder: (ctx) => Text(
          '${AppLocalizations.of(ctx)!.error}: $e',
          style: TextStyle(color: _textSecondary),
        )),
      ),
    );
  }
}

// 시즌별 통계 테이블 (소속팀 / 국가대표팀 분리, 확장 가능)
class _SeasonStatsTable extends StatefulWidget {
  final List<ApiFootballPlayer> seasons;

  const _SeasonStatsTable({required this.seasons});

  @override
  State<_SeasonStatsTable> createState() => _SeasonStatsTableState();
}

class _SeasonStatsTableState extends State<_SeasonStatsTable> {
  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  // 국가대표 관련 리그 ID (클럽 유럽대회 제외: 2=UCL, 3=UEL, 848=UECL)
  static const _nationalTeamLeagues = {
    1,  // World Cup
    4, 5, 6, 7, 8, 9, 10,  // Euro, Nations League, Asian Cup, Friendlies 등
    11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
    21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34,  // World Cup 예선 등
  };

  // 확장된 행 추적 (섹션_시즌인덱스)
  final Set<String> _expandedRows = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        // 소속팀 통계
        _buildSectionTable(context, l10n.clubTeams, isClub: true),
        const SizedBox(height: 16),
        // 국가대표팀 통계
        _buildSectionTable(context, l10n.nationalTeam, isClub: false),
      ],
    );
  }

  Widget _buildSectionTable(BuildContext context, String title, {required bool isClub}) {
    final sectionKey = isClub ? 'club' : 'national';

    // 해당 섹션의 데이터가 있는지 확인
    final hasData = widget.seasons.any((player) => player.statistics.any((stats) {
      final isNational = _nationalTeamLeagues.contains(stats.leagueId);
      final hasAppearance = (stats.appearances ?? 0) > 0;
      return hasAppearance && (isClub ? !isNational : isNational);
    }));

    if (!hasData) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // 섹션 타이틀
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isClub ? _primary.withValues(alpha: 0.08) : const Color(0xFFEF4444).withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(
                  isClub ? Icons.sports_soccer : Icons.flag,
                  size: 16,
                  color: isClub ? _primary : const Color(0xFFEF4444),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isClub ? _primary : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
          // 헤더
          Builder(builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 20), // 화살표 아이콘 공간
                  SizedBox(width: 48, child: Text(l10n.season, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  SizedBox(width: 48, child: Text(l10n.teamShort, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center)),
                  Expanded(child: Text(l10n.matches, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center)),
                  Expanded(child: Text(l10n.goal, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center)),
                  Expanded(child: Text(l10n.assist, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center)),
                  Expanded(child: Text(l10n.rating, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center)),
                ],
              ),
            );
          }),
          // 데이터 행
          ...widget.seasons.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            final rowKey = '${sectionKey}_$index';
            final isExpanded = _expandedRows.contains(rowKey);

            // 해당 섹션의 통계만 필터링
            final filteredStats = player.statistics.where((stats) {
              final isNational = _nationalTeamLeagues.contains(stats.leagueId);
              final hasAppearance = (stats.appearances ?? 0) > 0;
              return hasAppearance && (isClub ? !isNational : isNational);
            }).toList();

            if (filteredStats.isEmpty) return const SizedBox.shrink();

            // 해당 시즌 통계 합산
            int totalAppearances = 0;
            int totalGoals = 0;
            int totalAssists = 0;
            double avgRating = 0;
            int ratingCount = 0;

            // 팀 정보
            final teamInfos = <int, String>{}; // teamId -> teamLogo
            for (final stats in filteredStats) {
              totalAppearances += stats.appearances ?? 0;
              totalGoals += stats.goals ?? 0;
              totalAssists += stats.assists ?? 0;
              if (stats.rating != null) {
                final r = double.tryParse(stats.rating!);
                if (r != null) {
                  avgRating += r;
                  ratingCount++;
                }
              }
              if (stats.teamId != null && stats.teamLogo != null) {
                teamInfos[stats.teamId!] = stats.teamLogo!;
              }
            }

            if (ratingCount > 0) avgRating /= ratingCount;

            final season = filteredStats.first.season;
            // 소속팀은 시즌제 (24/25), 국가대표는 연도 (2024)
            final seasonText = season != null
                ? (isClub ? '${season.toString().substring(2)}/${(season + 1).toString().substring(2)}' : '$season')
                : '-';

            return Column(
              children: [
                // 요약 행 (터치 가능)
                InkWell(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedRows.remove(rowKey);
                      } else {
                        _expandedRows.add(rowKey);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? (isClub ? _primary.withValues(alpha: 0.05) : const Color(0xFFEF4444).withValues(alpha: 0.05))
                          : (index.isOdd ? Colors.grey.shade50 : Colors.white),
                      border: Border(top: BorderSide(color: _border)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 14,
                          color: _textSecondary,
                        ),
                        SizedBox(
                          width: 56,
                          child: Text(
                            seasonText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 48,
                          child: Center(
                            child: teamInfos.isNotEmpty
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: teamInfos.entries.take(3).map((teamEntry) => Padding(
                                      padding: const EdgeInsets.only(right: 2),
                                      child: GestureDetector(
                                        onTap: () => context.push('/team/${teamEntry.key}'),
                                        child: CachedNetworkImage(
                                          imageUrl: teamEntry.value,
                                          width: 20,
                                          height: 20,
                                          errorWidget: (_, __, ___) => Icon(Icons.shield, size: 20, color: _textSecondary),
                                        ),
                                      ),
                                    )).toList(),
                                  )
                                : Icon(Icons.shield, size: 20, color: _textSecondary),
                          ),
                        ),
                        Expanded(child: Text('$totalAppearances', style: const TextStyle(fontSize: 13), textAlign: TextAlign.center)),
                        Expanded(child: Text('$totalGoals', style: TextStyle(fontSize: 13, fontWeight: totalGoals > 0 ? FontWeight.w600 : FontWeight.normal, color: totalGoals > 0 ? const Color(0xFF10B981) : _textPrimary), textAlign: TextAlign.center)),
                        Expanded(child: Text('$totalAssists', style: TextStyle(fontSize: 13, fontWeight: totalAssists > 0 ? FontWeight.w600 : FontWeight.normal, color: totalAssists > 0 ? _primary : _textPrimary), textAlign: TextAlign.center)),
                        Expanded(
                          child: Text(
                            avgRating > 0 ? avgRating.toStringAsFixed(2) : '-',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _getRatingColor(avgRating),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 확장된 상세 내용
                if (isExpanded)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(top: BorderSide(color: _border)),
                    ),
                    child: Column(
                      children: filteredStats.map((stats) => _LeagueStatsRow(stats: stats)).toList(),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 8.0) return const Color(0xFF10B981);
    if (rating >= 7.0) return _primary;
    if (rating >= 6.0) return const Color(0xFFF59E0B);
    if (rating > 0) return const Color(0xFFEF4444);
    return _textSecondary;
  }
}

// 리그별 통계 행
class _LeagueStatsRow extends StatelessWidget {
  final ApiFootballPlayerStats stats;

  static const _primary = Color(0xFF2563EB);
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);
  static const _error = Color(0xFFEF4444);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _LeagueStatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 리그 헤더
          Row(
            children: [
              if (stats.teamLogo != null)
                GestureDetector(
                  onTap: stats.teamId != null ? () => context.push('/team/${stats.teamId}') : null,
                  child: CachedNetworkImage(
                    imageUrl: stats.teamLogo!,
                    width: 20,
                    height: 20,
                    errorWidget: (_, __, ___) => Icon(Icons.shield, size: 20, color: _textSecondary),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.leagueName ?? AppLocalizations.of(context)!.league,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    if (stats.teamName != null)
                      Text(
                        stats.teamName!,
                        style: TextStyle(fontSize: 11, color: _textSecondary),
                      ),
                  ],
                ),
              ),
              // 평점
              if (stats.rating != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRatingColor(double.tryParse(stats.rating!) ?? 0).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 10, color: _getRatingColor(double.tryParse(stats.rating!) ?? 0)),
                      const SizedBox(width: 4),
                      Text(
                        double.tryParse(stats.rating!)?.toStringAsFixed(2) ?? '-',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _getRatingColor(double.tryParse(stats.rating!) ?? 0),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // 통계 행
          Builder(builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Row(
              children: [
                _MiniStatChip(label: l10n.matches, value: '${stats.appearances ?? 0}'),
                _MiniStatChip(label: l10n.started, value: '${stats.lineups ?? 0}'),
                _MiniStatChip(label: l10n.goal, value: '${stats.goals ?? 0}', highlight: (stats.goals ?? 0) > 0, highlightColor: _success),
                _MiniStatChip(label: l10n.assist, value: '${stats.assists ?? 0}', highlight: (stats.assists ?? 0) > 0, highlightColor: _primary),
                _MiniStatChip(label: l10n.yellowCard, value: '${stats.yellowCards ?? 0}', highlight: (stats.yellowCards ?? 0) > 0, highlightColor: _warning),
                _MiniStatChip(label: l10n.redCard, value: '${stats.redCards ?? 0}', highlight: (stats.redCards ?? 0) > 0, highlightColor: _error),
              ],
            );
          }),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 8.0) return _success;
    if (rating >= 7.0) return _primary;
    if (rating >= 6.0) return _warning;
    if (rating > 0) return _error;
    return _textSecondary;
  }
}

class _MiniStatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final Color? highlightColor;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _MiniStatChip({
    required this.label,
    required this.value,
    this.highlight = false,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
              color: highlight && highlightColor != null ? highlightColor : _textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: _textSecondary),
          ),
        ],
      ),
    );
  }
}

// 커리어 탭 (이적, 트로피)
class _CareerTab extends StatelessWidget {
  final String playerId;

  const _CareerTab({required this.playerId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _TransfersSection(playerId: playerId),
          _TrophiesSection(playerId: playerId),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _PlayerHeader extends ConsumerWidget {
  final ApiFootballPlayer player;
  final String playerId;

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _PlayerHeader({required this.player, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = player.statistics.isNotEmpty ? player.statistics.first : null;
    final teamId = stats?.teamId?.toString();
    final teamAsync = ref.watch(playerTeamProvider(teamId));
    final teamLogo = teamAsync.valueOrNull?.logo;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 앱바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  color: _textPrimary,
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.playerInfo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                _PlayerFavoriteButton(playerId: playerId),
              ],
            ),
          ),

          // 선수 사진
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _border, width: 3),
              color: Colors.grey.shade100,
            ),
            child: ClipOval(
              child: player.photo != null
                  ? CachedNetworkImage(
                      imageUrl: player.photo!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Icon(
                        Icons.person,
                        size: 50,
                        color: _textSecondary,
                      ),
                      errorWidget: (_, __, ___) => Icon(
                        Icons.person,
                        size: 50,
                        color: _textSecondary,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 50,
                      color: _textSecondary,
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // 선수 이름
          Text(
            player.name,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // 팀 & 포지션
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (teamLogo != null) ...[
                CachedNetworkImage(
                  imageUrl: teamLogo,
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF6B7280)),
                  ),
                  errorWidget: (_, __, ___) =>
                      Icon(Icons.shield, size: 20, color: _textSecondary),
                ),
                const SizedBox(width: 6),
              ] else if (teamAsync.isLoading) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF6B7280)),
                ),
                const SizedBox(width: 6),
              ],
              if (stats?.teamName != null)
                Text(
                  stats!.teamName!,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                  ),
                ),
              if (stats?.teamName != null && stats?.position != null)
                Text(
                  ' · ',
                  style: TextStyle(color: _textSecondary.withValues(alpha: 0.5)),
                ),
              if (stats?.position != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getPositionText(context, stats!.position!),
                    style: TextStyle(
                      color: _primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getPositionText(BuildContext context, String position) {
    final l10n = AppLocalizations.of(context)!;
    switch (position.toLowerCase()) {
      case 'goalkeeper':
        return l10n.goalkeeper;
      case 'defender':
        return l10n.defender;
      case 'midfielder':
        return l10n.midfielder;
      case 'attacker':
      case 'forward':
        return l10n.attacker;
      default:
        return position;
    }
  }
}

class _BasicInfoCard extends StatelessWidget {
  final ApiFootballPlayer player;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _border = Color(0xFFE5E7EB);

  const _BasicInfoCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Builder(builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.person_outline, color: _primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.basicInfo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(icon: Icons.flag_outlined, label: l10n.nationality, value: player.nationality ?? '-'),
            _InfoRow(icon: Icons.cake_outlined, label: l10n.birthDate, value: player.birthDate ?? '-'),
            if (player.age != null)
              _InfoRow(icon: Icons.calendar_today_outlined, label: l10n.age, value: l10n.ageYears(player.age!)),
            _InfoRow(icon: Icons.height, label: l10n.height, value: player.height ?? '-'),
            _InfoRow(icon: Icons.fitness_center_outlined, label: l10n.weight, value: player.weight ?? '-'),
            if (player.birthPlace != null)
              _InfoRow(icon: Icons.location_on_outlined, label: l10n.birthPlace, value: player.birthPlace!),
          ],
        );
      }),
    );
  }
}

class _CardStatItem extends StatelessWidget {
  final Color color;
  final int value;
  final String label;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _CardStatItem({
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: _textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransfersSection extends ConsumerWidget {
  final String playerId;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _TransfersSection({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfersAsync = ref.watch(playerTransfersProvider(playerId));

    return transfersAsync.when(
      data: (transfers) {
        if (transfers.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.swap_horiz, color: _primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.transferHistory,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 12),
              ...transfers.take(5).map((transfer) => _TransferItem(transfer: transfer)),
              if (transfers.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Builder(builder: (context) => Text(
                    AppLocalizations.of(context)!.moreTransfers(transfers.length - 5),
                    style: TextStyle(fontSize: 12, color: _textSecondary),
                  )),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _TransferItem extends StatelessWidget {
  final ApiFootballTransfer transfer;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _TransferItem({required this.transfer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          // From Team
          Expanded(
            child: GestureDetector(
              onTap: transfer.teamOutId != null ? () => context.push('/team/${transfer.teamOutId}') : null,
              child: Row(
                children: [
                  if (transfer.teamOutLogo != null)
                    CachedNetworkImage(
                      imageUrl: transfer.teamOutLogo!,
                      width: 24,
                      height: 24,
                      errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 24),
                    )
                  else
                    const Icon(Icons.shield, size: 24, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      transfer.teamOutName ?? '-',
                      style: const TextStyle(fontSize: 11, color: _textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Arrow
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, size: 16, color: _textSecondary),
          ),
          // To Team
          Expanded(
            child: GestureDetector(
              onTap: transfer.teamInId != null ? () => context.push('/team/${transfer.teamInId}') : null,
              child: Row(
                children: [
                  if (transfer.teamInLogo != null)
                    CachedNetworkImage(
                      imageUrl: transfer.teamInLogo!,
                      width: 24,
                      height: 24,
                      errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 24),
                    )
                  else
                    const Icon(Icons.shield, size: 24, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      transfer.teamInName ?? '-',
                      style: const TextStyle(fontSize: 11, color: _textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrophiesSection extends ConsumerWidget {
  final String playerId;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _warning = Color(0xFFF59E0B);

  const _TrophiesSection({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trophiesAsync = ref.watch(playerTrophiesProvider(playerId));

    return trophiesAsync.when(
      data: (trophies) {
        if (trophies.isEmpty) return const SizedBox.shrink();

        // Winner만 필터링
        final winnerTrophies = trophies.where((t) => t.place == 'Winner').toList();
        if (winnerTrophies.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.emoji_events, color: _warning, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.trophies,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l10n.nTrophies(winnerTrophies.length),
                        style: TextStyle(
                          color: _warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 12),
              ...winnerTrophies.take(10).map((trophy) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.star, size: 14, color: _warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trophy.league ?? '-',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                    if (trophy.season != null)
                      Text(
                        trophy.season!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _textSecondary,
                        ),
                      ),
                  ],
                ),
              )),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PlayerFavoriteButton extends ConsumerWidget {
  final String playerId;

  static const _error = Color(0xFFEF4444);

  const _PlayerFavoriteButton({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowedAsync = ref.watch(isPlayerFollowedProvider(playerId));

    return isFollowedAsync.when(
      data: (isFollowed) => IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isFollowed
                ? _error.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isFollowed ? Icons.favorite : Icons.favorite_border,
            color: isFollowed ? _error : Colors.grey,
            size: 20,
          ),
        ),
        onPressed: () async {
          await ref
              .read(favoritesNotifierProvider.notifier)
              .togglePlayerFollow(playerId);
          if (context.mounted) {
            final l10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    isFollowed ? l10n.removedFromFavorites : l10n.addedToFavorites),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
      ),
      loading: () => Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.grey.shade400),
        ),
      ),
      error: (_, __) => IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.favorite_border,
            color: Colors.grey,
            size: 20,
          ),
        ),
        onPressed: () async {
          await ref
              .read(favoritesNotifierProvider.notifier)
              .togglePlayerFollow(playerId);
        },
      ),
    );
  }
}

// 부상/출전정지 이력 섹션
class _SidelinedSection extends ConsumerWidget {
  final String playerId;

  static const _error = Color(0xFFEF4444);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _SidelinedSection({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sidelinedAsync = ref.watch(playerSidelinedProvider(playerId));

    return sidelinedAsync.when(
      data: (records) {
        if (records.isEmpty) return const SizedBox.shrink();

        // 현재 진행 중인 부상/출전정지
        final ongoingRecords = records.where((r) => r.isOngoing).toList();
        // 과거 기록 (최근 5개)
        final pastRecords = records.where((r) => !r.isOngoing).take(5).toList();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.healing, color: _error, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.injuryHistory,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _textSecondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l10n.nRecords(records.length),
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),

              // 현재 진행 중인 부상/출전정지
              if (ongoingRecords.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _error.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _error,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Builder(builder: (context) => Text(
                                  AppLocalizations.of(context)!.currentlyOut,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...ongoingRecords.map((record) => _SidelinedItem(
                            record: record,
                            isOngoing: true,
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 과거 기록
              if (pastRecords.isNotEmpty) ...[
                Builder(builder: (context) => Text(
                  AppLocalizations.of(context)!.recentHistory,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                )),
                const SizedBox(height: 8),
                ...pastRecords.map((record) => _SidelinedItem(
                      record: record,
                      isOngoing: false,
                    )),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// 부상/출전정지 개별 항목
class _SidelinedItem extends StatelessWidget {
  final ApiFootballSidelined record;
  final bool isOngoing;

  static const _error = Color(0xFFEF4444);
  static const _warning = Color(0xFFF59E0B);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _SidelinedItem({
    required this.record,
    required this.isOngoing,
  });

  @override
  Widget build(BuildContext context) {
    final color = record.isInjury
        ? _error
        : record.isSuspension
            ? _warning
            : _textSecondary;
    final icon = record.isInjury
        ? Icons.personal_injury
        : record.isSuspension
            ? Icons.gavel
            : Icons.event_busy;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOngoing ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ErrorHelper.getLocalizedInjuryType(context, record.typeKey),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ErrorHelper.getLocalizedPeriodText(context, record.periodDisplay),
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // 타입 뱃지
          Builder(builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                record.isInjury
                    ? l10n.injured
                    : record.isSuspension
                        ? l10n.suspended
                        : l10n.other,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// 출전 경기 탭
class _MatchesTab extends ConsumerWidget {
  final ApiFootballPlayer player;
  final String playerId;
  final int? teamId;

  static const _textSecondary = Color(0xFF6B7280);

  const _MatchesTab({required this.player, required this.playerId, this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 전달받은 teamId가 있으면 우선 사용, 없으면 선수 통계에서 가져옴
    final effectiveTeamId = teamId ?? (player.statistics.isNotEmpty
        ? player.statistics.first.teamId
        : null);

    if (effectiveTeamId == null) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noMatchRecords,
          style: const TextStyle(color: _textSecondary),
        ),
      );
    }

    final fixturesAsync = ref.watch(
      playerFixturesProvider((playerId: playerId, teamId: effectiveTeamId)),
    );

    return fixturesAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_soccer, size: 48, color: _textSecondary),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noMatchRecords,
                  style: const TextStyle(color: _textSecondary, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return _MatchRecordCard(record: record);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          '${AppLocalizations.of(context)!.error}: $e',
          style: const TextStyle(color: _textSecondary),
        ),
      ),
    );
  }
}

// 경기 기록 카드
class _MatchRecordCard extends StatelessWidget {
  final PlayerFixtureRecord record;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);
  static const _primary = Color(0xFF2563EB);

  const _MatchRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final fixture = record.fixture;
    final stats = record.stats;

    return GestureDetector(
      onTap: () => context.push('/match/${fixture.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 리그 + 날짜
            Row(
              children: [
                if (fixture.league.logo != null)
                  CachedNetworkImage(
                    imageUrl: fixture.league.logo!,
                    width: 16,
                    height: 16,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fixture.league.name,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatDate(fixture.date),
                  style: const TextStyle(
                    fontSize: 11,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 경기 정보
            Row(
              children: [
                // 홈팀
                Expanded(
                  child: Row(
                    children: [
                      if (fixture.homeTeam.logo != null)
                        CachedNetworkImage(
                          imageUrl: fixture.homeTeam.logo!,
                          width: 24,
                          height: 24,
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.sports_soccer, size: 24),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fixture.homeTeam.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // 스코어
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${fixture.homeGoals ?? 0} - ${fixture.awayGoals ?? 0}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                ),
                // 어웨이팀
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          fixture.awayTeam.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (fixture.awayTeam.logo != null)
                        CachedNetworkImage(
                          imageUrl: fixture.awayTeam.logo!,
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
            // 선수 스탯
            if (stats != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: _border),
              const SizedBox(height: 10),
              Row(
                children: [
                  // 출전 시간
                  _buildStatChip(
                    icon: Icons.timer_outlined,
                    value: "${stats.minutesPlayed ?? 0}'",
                    color: _primary,
                  ),
                  const SizedBox(width: 8),
                  // 평점
                  if (stats.ratingValue != null)
                    _buildStatChip(
                      icon: Icons.star,
                      value: stats.ratingValue!.toStringAsFixed(1),
                      color: _getRatingColor(stats.ratingValue!),
                    ),
                  const SizedBox(width: 8),
                  // 골
                  if ((stats.goals ?? 0) > 0)
                    _buildStatChip(
                      icon: Icons.sports_soccer,
                      value: '${stats.goals}',
                      color: _success,
                    ),
                  if ((stats.goals ?? 0) > 0) const SizedBox(width: 8),
                  // 어시스트
                  if ((stats.assists ?? 0) > 0)
                    _buildStatChip(
                      icon: Icons.assistant,
                      value: '${stats.assists}',
                      color: _primary,
                    ),
                  if ((stats.assists ?? 0) > 0) const SizedBox(width: 8),
                  // 옐로카드
                  if ((stats.yellowCards ?? 0) > 0)
                    Container(
                      width: 12,
                      height: 16,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: _warning,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  // 레드카드
                  if ((stats.redCards ?? 0) > 0)
                    Container(
                      width: 12,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
