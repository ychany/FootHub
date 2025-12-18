import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/api_football_service.dart';
import '../../../shared/widgets/loading_indicator.dart';

/// 라이브 경기 Provider (30초마다 자동 갱신)
final liveMatchesProvider = StreamProvider<List<ApiFootballFixture>>((ref) async* {
  final service = ApiFootballService();

  // 초기 데이터 로드
  yield await service.getLiveFixtures();

  // 30초마다 자동 갱신
  await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
    yield await service.getLiveFixtures();
  }
});

/// 수동 새로고침용 FutureProvider
final liveMatchesRefreshProvider = FutureProvider<List<ApiFootballFixture>>((ref) async {
  final service = ApiFootballService();
  return service.getLiveFixtures();
});

class LiveMatchesScreen extends ConsumerStatefulWidget {
  const LiveMatchesScreen({super.key});

  @override
  ConsumerState<LiveMatchesScreen> createState() => _LiveMatchesScreenState();
}

class _LiveMatchesScreenState extends ConsumerState<LiveMatchesScreen> {
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
    // UI에서 마지막 업데이트 시간 갱신용 타이머
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
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
                  error: (e, _) => _buildError(e.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                      const Text(
                        '라이브 경기',
                        style: TextStyle(
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
                      ? '$timeSinceUpdate초 전 업데이트'
                      : '${timeSinceUpdate ~/ 60}분 전 업데이트',
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
                    '30초마다 자동 갱신',
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
                          league == 'all' ? '전체' : league,
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
          const Text(
            '진행 중인 경기가 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '경기가 시작되면 여기서 실시간으로 확인하세요',
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(liveMatchesProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('새로고침'),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: _live),
          const SizedBox(height: 16),
          Text(
            '오류가 발생했습니다',
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
            label: const Text('다시 시도'),
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // 리그 정보 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.03),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  // 리그 로고
                  if (fixture.league.logo != null)
                    CachedNetworkImage(
                      imageUrl: fixture.league.logo!,
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => Icon(
                        Icons.emoji_events,
                        size: 18,
                        color: _textSecondary,
                      ),
                    )
                  else
                    Icon(Icons.emoji_events, size: 18, color: _textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fixture.league.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 라이브 표시
                  _LiveBadge(status: fixture.status),
                ],
              ),
            ),

            // 경기 정보
            Padding(
              padding: const EdgeInsets.all(16),
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
                      isAway: true,
                    ),
                  ),
                ],
              ),
            ),

            // 경기장 정보
            if (fixture.venue?.name != null)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: _textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      fixture.venue!.name!,
                      style: TextStyle(
                        fontSize: 11,
                        color: _textSecondary,
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
    final displayText = _getDisplayText();
    final isHalftime = status.short == 'HT';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isHalftime
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isHalftime) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            displayText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayText() {
    switch (status.short) {
      case '1H':
        return status.elapsed != null ? "${status.elapsed}'" : '전반전';
      case '2H':
        return status.elapsed != null ? "${status.elapsed}'" : '후반전';
      case 'HT':
        return '하프타임';
      case 'ET':
        return '연장전';
      case 'P':
        return '승부차기';
      case 'BT':
        return '연장 준비';
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
  final bool isAway;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _TeamColumn({
    required this.name,
    this.logo,
    this.isWinning = false,
    this.isAway = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 팀 로고
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isWinning
                  ? const Color(0xFF10B981)
                  : const Color(0xFFE5E7EB),
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
        const SizedBox(height: 8),
        // 팀 이름
        Text(
          name,
          style: TextStyle(
            fontSize: 13,
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
      child: Icon(
        Icons.shield_outlined,
        color: Colors.grey.shade400,
        size: 28,
      ),
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
        // 스코어
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$homeGoals',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: homeGoals > awayGoals ? _primary : Colors.grey.shade700,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '-',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: _textSecondary,
                  ),
                ),
              ),
              Text(
                '$awayGoals',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: awayGoals > homeGoals ? _primary : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // 경기 시간 진행 바
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
    // 전반전: 0-45분, 후반전: 45-90분
    final progress = is2ndHalf
        ? ((elapsed - 45).clamp(0, 45) / 45)
        : (elapsed.clamp(0, 45) / 45);

    return SizedBox(
      width: 80,
      child: Column(
        children: [
          // 진행 바
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // 시간 표시
          Text(
            is2ndHalf ? '후반 ${elapsed - 45}분' : '전반 $elapsed분',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
