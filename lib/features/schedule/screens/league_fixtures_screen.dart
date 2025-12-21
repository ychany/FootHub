import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_football_service.dart';
import '../../../core/constants/api_football_ids.dart';

/// 리그 경기 목록 Provider
final leagueFixturesProvider = FutureProvider.family<List<ApiFootballFixture>, int>((ref, leagueId) async {
  final service = ApiFootballService();
  final season = LeagueIds.getCurrentSeason();
  return service.getFixturesByLeague(leagueId, season);
});

class LeagueFixturesScreen extends ConsumerStatefulWidget {
  final String leagueId;

  const LeagueFixturesScreen({super.key, required this.leagueId});

  @override
  ConsumerState<LeagueFixturesScreen> createState() => _LeagueFixturesScreenState();
}

class _LeagueFixturesScreenState extends ConsumerState<LeagueFixturesScreen> {
  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _background = Color(0xFFF9FAFB);

  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _roundKeys = {};
  final Map<int, GlobalKey> _fixtureKeys = {};
  bool _hasScrolled = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leagueIdInt = int.tryParse(widget.leagueId) ?? 0;
    final fixturesAsync = ref.watch(leagueFixturesProvider(leagueIdInt));

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textPrimary),
          onPressed: () => context.pop(),
        ),
        title: fixturesAsync.when(
          data: (fixtures) {
            if (fixtures.isEmpty) return const Text('리그 경기');
            final league = fixtures.first.league;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (league.logo != null)
                  CachedNetworkImage(
                    imageUrl: league.logo!,
                    width: 24,
                    height: 24,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    league.name,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
          loading: () => const Text('로딩 중...'),
          error: (_, __) => const Text('리그 경기'),
        ),
      ),
      body: fixturesAsync.when(
        data: (fixtures) => _buildRoundView(fixtures),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: _textSecondary),
              const SizedBox(height: 16),
              Text('경기 목록을 불러올 수 없습니다', style: TextStyle(color: _textSecondary)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(leagueFixturesProvider(leagueIdInt)),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 오늘과 가장 가까운 경기 찾기
  ApiFootballFixture? _findClosestFixture(List<ApiFootballFixture> fixtures) {
    if (fixtures.isEmpty) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 오늘 날짜와의 차이로 정렬
    final sorted = List<ApiFootballFixture>.from(fixtures);
    sorted.sort((a, b) {
      final aDate = DateTime(a.date.year, a.date.month, a.date.day);
      final bDate = DateTime(b.date.year, b.date.month, b.date.day);
      final aDiff = (aDate.difference(today).inDays).abs();
      final bDiff = (bDate.difference(today).inDays).abs();
      return aDiff.compareTo(bDiff);
    });

    return sorted.first;
  }

  int _extractRoundNumber(String round) {
    final match = RegExp(r'\d+').firstMatch(round);
    return match != null ? int.parse(match.group(0)!) : 0;
  }

  String _formatRoundName(String round) {
    // "Regular Season - 1" -> "1R"
    // "Round of 16" -> "16강"
    if (round.contains('Regular Season')) {
      final num = _extractRoundNumber(round);
      return '${num}R';
    }
    if (round.contains('Round of 16')) return '16강';
    if (round.contains('Quarter')) return '8강';
    if (round.contains('Semi')) return '4강';
    if (round.contains('Final') && !round.contains('Quarter') && !round.contains('Semi')) {
      return '결승';
    }
    if (round.contains('Group')) {
      return round.replaceAll('Group ', '조별 ');
    }

    // 그 외는 라운드 번호만 표시
    final num = _extractRoundNumber(round);
    if (num > 0) return '${num}R';

    return round;
  }

  Widget _buildRoundView(List<ApiFootballFixture> fixtures) {
    if (fixtures.isEmpty) {
      return _buildEmptyState();
    }

    // 라운드 목록 추출
    final rounds = fixtures
        .map((f) => f.league.round)
        .where((r) => r != null)
        .cast<String>()
        .toSet()
        .toList();

    // 라운드 정렬 (숫자 기준)
    rounds.sort((a, b) {
      final aNum = _extractRoundNumber(a);
      final bNum = _extractRoundNumber(b);
      return aNum.compareTo(bNum);
    });

    if (rounds.isEmpty) {
      return _buildEmptyState();
    }

    // 라운드별로 그룹화
    final groupedByRound = <String, List<ApiFootballFixture>>{};
    for (final fixture in fixtures) {
      final round = fixture.league.round;
      if (round != null) {
        _roundKeys.putIfAbsent(round, () => GlobalKey());
        groupedByRound.putIfAbsent(round, () => []).add(fixture);
      }
    }

    // 각 라운드 내에서 날짜순 정렬
    for (final fixtureList in groupedByRound.values) {
      fixtureList.sort((a, b) => a.date.compareTo(b.date));
    }

    // 오늘과 가장 가까운 경기 찾기
    final closestFixture = _findClosestFixture(fixtures);
    if (closestFixture != null) {
      _fixtureKeys.putIfAbsent(closestFixture.id, () => GlobalKey());
    }

    // 가장 가까운 경기로 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToClosestFixture(closestFixture?.id);
    });

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rounds.asMap().entries.map((entry) {
          final index = entry.key;
          final round = entry.value;
          final roundFixtures = groupedByRound[round]!;

          return Column(
            key: _roundKeys[round],
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 라운드 헤더
              Container(
                margin: EdgeInsets.only(bottom: 8, top: index > 0 ? 8 : 0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      _formatRoundName(round),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${roundFixtures.length}경기',
                      style: TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // 해당 라운드 경기들 (날짜별로 그룹화)
              _buildRoundFixtures(roundFixtures),
              const SizedBox(height: 12),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRoundFixtures(List<ApiFootballFixture> fixtures) {
    // 날짜별로 그룹화
    final groupedByDate = <String, List<ApiFootballFixture>>{};
    for (final fixture in fixtures) {
      final dateKey = DateFormat('yyyy-MM-dd').format(fixture.date);
      groupedByDate.putIfAbsent(dateKey, () => []).add(fixture);
    }

    final dateKeys = groupedByDate.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: dateKeys.map((dateKey) {
        final dateFixtures = groupedByDate[dateKey]!;
        final date = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 서브헤더
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
              child: Text(
                _formatDateHeader(date),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _textSecondary,
                ),
              ),
            ),
            // 경기 카드들
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: dateFixtures.asMap().entries.map((entry) {
                  final i = entry.key;
                  final fixture = entry.value;
                  final hasKey = _fixtureKeys.containsKey(fixture.id);
                  return Column(
                    key: hasKey ? _fixtureKeys[fixture.id] : null,
                    children: [
                      if (i > 0) Divider(height: 1, color: _border, indent: 14, endIndent: 14),
                      _FixtureCard(fixture: fixture),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  void _scrollToClosestFixture(int? fixtureId) {
    if (_hasScrolled || fixtureId == null) return;

    if (_fixtureKeys[fixtureId]?.currentContext != null) {
      Scrollable.ensureVisible(
        _fixtureKeys[fixtureId]!.currentContext!,
        duration: Duration.zero,
        alignment: 0.5, // 화면 중앙에 위치
      );
      _hasScrolled = true;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer, size: 48, color: _textSecondary),
          const SizedBox(height: 16),
          Text(
            '경기가 없습니다',
            style: TextStyle(color: _textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    final dateStr = '${date.month}월 ${date.day}일 ($weekday)';

    if (targetDate == today) {
      return '오늘 $dateStr';
    } else if (targetDate == tomorrow) {
      return '내일 $dateStr';
    } else if (targetDate == yesterday) {
      return '어제 $dateStr';
    }

    return dateStr;
  }
}

class _FixtureCard extends StatelessWidget {
  final ApiFootballFixture fixture;

  static const _primary = Color(0xFF2563EB);
  static const _error = Color(0xFFEF4444);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _FixtureCard({required this.fixture});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/match/${fixture.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // 시간/상태
            SizedBox(
              width: 50,
              child: _buildTimeOrStatus(),
            ),
            const SizedBox(width: 12),
            // 팀 정보
            Expanded(
              child: Column(
                children: [
                  _buildTeamRow(fixture.homeTeam.name, fixture.homeTeam.logo, fixture.homeGoals, true),
                  const SizedBox(height: 6),
                  _buildTeamRow(fixture.awayTeam.name, fixture.awayTeam.logo, fixture.awayGoals, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeOrStatus() {
    if (fixture.isLive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: _error,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          fixture.status.elapsed != null ? "${fixture.status.elapsed}'" : 'LIVE',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      );
    } else if (fixture.isFinished) {
      return Text(
        '종료',
        style: TextStyle(
          color: _textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      );
    } else {
      return Text(
        DateFormat('HH:mm').format(fixture.date),
        style: TextStyle(
          color: _primary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      );
    }
  }

  Widget _buildTeamRow(String teamName, String? teamLogo, int? goals, bool isHome) {
    final isWinner = fixture.isFinished && goals != null &&
        ((isHome && goals > (fixture.awayGoals ?? 0)) ||
         (!isHome && goals > (fixture.homeGoals ?? 0)));

    return Row(
      children: [
        if (teamLogo != null)
          CachedNetworkImage(
            imageUrl: teamLogo,
            width: 20,
            height: 20,
            errorWidget: (_, __, ___) => const Icon(Icons.sports_soccer, size: 20),
          )
        else
          const Icon(Icons.sports_soccer, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            teamName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isWinner ? FontWeight.w600 : FontWeight.w400,
              color: isWinner ? _textPrimary : _textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (goals != null)
          Text(
            goals.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isWinner ? _textPrimary : _textSecondary,
            ),
          ),
      ],
    );
  }
}
