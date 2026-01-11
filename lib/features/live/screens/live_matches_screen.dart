import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/api_football_service.dart';
import '../../../core/utils/error_helper.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/banner_ad_widget.dart';
import '../../profile/providers/timezone_provider.dart';
import '../../../l10n/app_localizations.dart';

/// 리그 우선순위 정의
int _getLeaguePriority(int leagueId) {
  // 1순위: 5대 리그
  const tier1 = {39, 140, 135, 78, 61}; // EPL, 라리가, 세리에A, 분데스, 리그앙
  // 2순위: 유럽 클럽 대회
  const tier2 = {2, 3, 848}; // UCL, UEL, UECL
  // 3순위: K리그, 국가대항전
  const tier3 = {292, 1, 4, 6, 9, 17}; // K리그1, 월드컵, 유로, AFCON, 코파, AFC

  if (tier1.contains(leagueId)) return 1;
  if (tier2.contains(leagueId)) return 2;
  if (tier3.contains(leagueId)) return 3;
  return 4; // 기타 리그
}

/// 리그 우선순위로 경기 정렬
List<ApiFootballFixture> _sortByLeaguePriority(List<ApiFootballFixture> fixtures) {
  fixtures.sort((a, b) {
    final priorityA = _getLeaguePriority(a.league.id);
    final priorityB = _getLeaguePriority(b.league.id);
    if (priorityA != priorityB) return priorityA.compareTo(priorityB);
    // 같은 우선순위 내에서는 리그 ID로 그룹화
    return a.league.id.compareTo(b.league.id);
  });
  return fixtures;
}

/// 라이브 경기 Provider (30초마다 자동 갱신) - 리그 우선순위 정렬
/// 캐시 유지, 화면 재진입 시 invalidate로 새 데이터 로드
final liveMatchesProvider = StreamProvider<List<ApiFootballFixture>>((ref) async* {
  final service = ApiFootballService();
  // 타임존 변경 시 자동 갱신
  ref.watch(timezoneProvider);

  // 초기 데이터 로드
  final initialFixtures = await service.getLiveFixtures();
  yield _sortByLeaguePriority(initialFixtures);

  // 30초마다 자동 갱신
  await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
    final fixtures = await service.getLiveFixtures();
    yield _sortByLeaguePriority(fixtures);
  }
});

/// 수동 새로고침용 FutureProvider - 리그 우선순위 정렬
final liveMatchesRefreshProvider = FutureProvider<List<ApiFootballFixture>>((ref) async {
  final service = ApiFootballService();
  // 타임존 변경 시 자동 갱신
  ref.watch(timezoneProvider);
  final fixtures = await service.getLiveFixtures();
  return _sortByLeaguePriority(fixtures);
});

class LiveMatchesScreen extends ConsumerStatefulWidget {
  const LiveMatchesScreen({super.key});

  @override
  ConsumerState<LiveMatchesScreen> createState() => _LiveMatchesScreenState();
}

class _LiveMatchesScreenState extends ConsumerState<LiveMatchesScreen> with WidgetsBindingObserver {
  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _background = Color(0xFFF9FAFB);
  static const _live = Color(0xFFEF4444);
  static const _success = Color(0xFF10B981);

  String _selectedLeague = 'all';
  DateTime _lastUpdate = DateTime.now();
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 화면 진입 시 라이브 데이터 자동 갱신
    _refreshData();
    // UI에서 마지막 업데이트 시간 갱신용 타이머
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 다시 포그라운드로 돌아올 때 데이터 갱신
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  @override
  void activate() {
    super.activate();
    // 화면이 다시 활성화될 때 (뒤로가기로 돌아올 때) 데이터 갱신
    _refreshData();
  }

  void _refreshData() {
    Future.microtask(() {
      if (mounted) {
        ref.invalidate(liveMatchesProvider);
        ref.invalidate(liveMatchesRefreshProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final liveMatchesAsync = ref.watch(liveMatchesProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _background,
        bottomNavigationBar: const BottomBannerAdWidget(),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: liveMatchesAsync.when(
                  data: (fixtures) {
                    _lastUpdate = DateTime.now();
                    return _buildContent(fixtures);
                  },
                  loading: () => const LoadingIndicator(),
                  error: (e, _) => _buildError(ErrorHelper.getLocalizedErrorMessage(context, e)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timeSinceUpdate = DateTime.now().difference(_lastUpdate).inSeconds;

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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 라이브 표시 (깜빡이는 효과)
                      _PulsingDot(),
                      const SizedBox(width: 8),
                      Text(
                        l10n.liveMatches,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                // 새로고침 버튼
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                  color: _textSecondary,
                  onPressed: () {
                    ref.invalidate(liveMatchesProvider);
                  },
                ),
              ],
            ),
          ),
          // 마지막 업데이트 시간
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _background,
              border: Border(top: BorderSide(color: _border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 14, color: _textSecondary),
                const SizedBox(width: 6),
                Text(
                  timeSinceUpdate < 60
                      ? l10n.updatedSecondsAgo(timeSinceUpdate)
                      : l10n.updatedMinutesAgo(timeSinceUpdate ~/ 60),
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.autoRefresh30Sec,
                    style: TextStyle(
                      fontSize: 10,
                      color: _success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<ApiFootballFixture> fixtures) {
    // 라이브 경기만 필터링
    final liveFixtures = fixtures.where((f) => f.isLive).toList();

    if (liveFixtures.isEmpty) {
      return _buildEmptyState();
    }

    // 리그별로 그룹화
    final groupedByLeague = <String, List<ApiFootballFixture>>{};
    for (final fixture in liveFixtures) {
      final leagueName = fixture.league.name;
      groupedByLeague.putIfAbsent(leagueName, () => []);
      groupedByLeague[leagueName]!.add(fixture);
    }

    // 리그 목록 (필터용)
    final leagues = ['all', ...groupedByLeague.keys.toList()..sort()];

    // 선택된 리그 필터링
    final filteredFixtures = _selectedLeague == 'all'
        ? liveFixtures
        : groupedByLeague[_selectedLeague] ?? [];

    return Column(
      children: [
        // 리그 필터 (가로 스크롤)
        Container(
          height: 44,
          color: Colors.white,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: leagues.length,
            itemBuilder: (context, index) {
              final league = leagues[index];
              final isSelected = _selectedLeague == league;
              final count = league == 'all'
                  ? liveFixtures.length
                  : groupedByLeague[league]?.length ?? 0;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedLeague = league),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? _primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? _primary : _border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          league == 'all' ? AppLocalizations.of(context)!.all : league,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : _textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.2)
                                : _background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : _textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1, color: _border),

        // 경기 목록
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredFixtures.length,
            itemBuilder: (context, index) {
              return _LiveMatchCard(fixture: filteredFixtures[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _textSecondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sports_soccer_outlined,
              size: 64,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noLiveMatchesTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noLiveMatchesDesc,
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(liveMatchesProvider),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.refresh),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: _live),
          const SizedBox(height: 16),
          Text(
            l10n.errorOccurred,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 12, color: _textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(liveMatchesProvider),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// 깜빡이는 빨간 점 위젯
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: _animation.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: _animation.value * 0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 라이브 경기 카드
class _LiveMatchCard extends StatelessWidget {
  final ApiFootballFixture fixture;

  static const _primary = Color(0xFF2563EB);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _LiveMatchCard({required this.fixture});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/match/${fixture.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // 리그 정보 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.03),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  if (fixture.league.logo != null)
                    CachedNetworkImage(
                      imageUrl: fixture.league.logo!,
                      width: 16,
                      height: 16,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => Icon(Icons.emoji_events, size: 14, color: _textSecondary),
                    )
                  else
                    Icon(Icons.emoji_events, size: 14, color: _textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      fixture.league.name,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _LiveBadge(status: fixture.status),
                ],
              ),
            ),

            // 경기 정보
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 홈팀
                  Expanded(
                    child: _TeamColumn(
                      name: fixture.homeTeam.name,
                      logo: fixture.homeTeam.logo,
                      isWinning: (fixture.homeGoals ?? 0) > (fixture.awayGoals ?? 0),
                    ),
                  ),

                  // 스코어
                  _ScoreDisplay(
                    homeGoals: fixture.homeGoals ?? 0,
                    awayGoals: fixture.awayGoals ?? 0,
                    elapsed: fixture.status.elapsed,
                    statusShort: fixture.status.short,
                  ),

                  // 어웨이팀
                  Expanded(
                    child: _TeamColumn(
                      name: fixture.awayTeam.name,
                      logo: fixture.awayTeam.logo,
                      isWinning: (fixture.awayGoals ?? 0) > (fixture.homeGoals ?? 0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 라이브 배지
class _LiveBadge extends StatelessWidget {
  final ApiFootballFixtureStatus status;

  const _LiveBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayText = _getDisplayText(l10n);
    final isHalftime = status.short == 'HT';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isHalftime ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isHalftime) ...[
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            displayText,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  String _getDisplayText(AppLocalizations l10n) {
    switch (status.short) {
      case '1H':
        return status.elapsed != null ? "${status.elapsed}'" : l10n.firstHalf;
      case '2H':
        return status.elapsed != null ? "${status.elapsed}'" : l10n.secondHalf;
      case 'HT':
        return l10n.halfTime;
      case 'ET':
        return l10n.extraTime;
      case 'P':
        return l10n.penalties;
      case 'BT':
        return l10n.breakPrep;
      default:
        return status.elapsed != null ? "${status.elapsed}'" : 'LIVE';
    }
  }
}

/// 팀 컬럼
class _TeamColumn extends StatelessWidget {
  final String name;
  final String? logo;
  final bool isWinning;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _TeamColumn({
    required this.name,
    this.logo,
    this.isWinning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isWinning ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
              width: isWinning ? 2 : 1,
            ),
            color: Colors.grey.shade50,
          ),
          child: ClipOval(
            child: logo != null
                ? CachedNetworkImage(
                    imageUrl: logo!,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => _buildPlaceholder(),
                    errorWidget: (_, __, ___) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isWinning ? FontWeight.w700 : FontWeight.w500,
            color: isWinning ? _textPrimary : _textSecondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Icon(Icons.shield_outlined, color: Colors.grey.shade400, size: 22),
    );
  }
}

/// 스코어 표시
class _ScoreDisplay extends StatelessWidget {
  final int homeGoals;
  final int awayGoals;
  final int? elapsed;
  final String statusShort;

  static const _primary = Color(0xFF2563EB);
  static const _textSecondary = Color(0xFF6B7280);

  const _ScoreDisplay({
    required this.homeGoals,
    required this.awayGoals,
    this.elapsed,
    required this.statusShort,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$homeGoals',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: homeGoals > awayGoals ? _primary : Colors.grey.shade700,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('-', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: _textSecondary)),
              ),
              Text(
                '$awayGoals',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: awayGoals > homeGoals ? _primary : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (elapsed != null && (statusShort == '1H' || statusShort == '2H'))
          _ProgressBar(elapsed: elapsed!, is2ndHalf: statusShort == '2H'),
      ],
    );
  }
}

/// 경기 진행 바
class _ProgressBar extends StatelessWidget {
  final int elapsed;
  final bool is2ndHalf;

  const _ProgressBar({required this.elapsed, required this.is2ndHalf});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = is2ndHalf
        ? ((elapsed - 45).clamp(0, 45) / 45)
        : (elapsed.clamp(0, 45) / 45);

    return SizedBox(
      width: 60,
      child: Column(
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            is2ndHalf ? l10n.secondHalfMinutes(elapsed - 45) : l10n.firstHalfMinutes(elapsed),
            style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

