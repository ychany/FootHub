import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_football_service.dart';

/// 인기 리그 목록 Provider
final popularLeaguesProvider = FutureProvider<List<ApiFootballLeague>>((ref) async {
  final service = ApiFootballService();

  // 주요 리그 ID 목록
  const popularLeagueIds = [
    // 5대 리그
    39,   // Premier League
    140,  // La Liga
    135,  // Serie A
    78,   // Bundesliga
    61,   // Ligue 1
    // 기타 인기 리그
    2,    // UEFA Champions League
    3,    // UEFA Europa League
    848,  // UEFA Europa Conference League
    292,  // K League 1
    4,    // Euro Championship
    1,    // World Cup
    6,    // Africa Cup of Nations
    9,    // Copa America
    17,   // AFC Asian Cup
  ];

  // 재시도 로직이 포함된 리그 조회 함수
  Future<ApiFootballLeague?> fetchLeagueWithRetry(int id) async {
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final result = await service.getLeagueById(id);
        if (result != null) return result;
      } catch (_) {
        if (attempt < 1) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    }
    return null;
  }

  // 병렬로 모든 리그 정보 조회 (재시도 포함)
  final results = await Future.wait(
    popularLeagueIds.map((id) => fetchLeagueWithRetry(id)),
  );

  // null이 아닌 결과만 필터링하고 원래 순서 유지
  final leagues = <ApiFootballLeague>[];
  for (int i = 0; i < popularLeagueIds.length; i++) {
    if (results[i] != null) {
      leagues.add(results[i]!);
    }
  }

  return leagues;
});

/// 리그 검색 Provider
final leagueSearchProvider = FutureProvider.family<List<ApiFootballLeague>, String>((ref, query) async {
  if (query.isEmpty) return [];

  final service = ApiFootballService();
  return service.searchLeagues(query);
});

class LeagueListScreen extends ConsumerStatefulWidget {
  const LeagueListScreen({super.key});

  @override
  ConsumerState<LeagueListScreen> createState() => _LeagueListScreenState();
}

class _LeagueListScreenState extends ConsumerState<LeagueListScreen> {
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _background = Color(0xFFF9FAFB);

  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '리그 검색...',
                  hintStyle: TextStyle(color: _textSecondary, fontSize: 16),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: _textPrimary, fontSize: 16),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              )
            : const Text(
                '리그',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: _textPrimary,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
        ],
      ),
      body: _searchQuery.isNotEmpty
          ? _buildSearchResults()
          : _buildPopularLeagues(),
    );
  }

  Widget _buildSearchResults() {
    final searchAsync = ref.watch(leagueSearchProvider(_searchQuery));

    return searchAsync.when(
      data: (leagues) {
        if (leagues.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 48, color: _textSecondary),
                const SizedBox(height: 16),
                Text(
                  '검색 결과가 없습니다',
                  style: TextStyle(color: _textSecondary, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: leagues.length,
          itemBuilder: (context, index) => _LeagueCard(league: leagues[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text('검색 중 오류가 발생했습니다', style: TextStyle(color: _textSecondary)),
      ),
    );
  }

  Widget _buildPopularLeagues() {
    final leaguesAsync = ref.watch(popularLeaguesProvider);

    return leaguesAsync.when(
      data: (leagues) {
        // 카테고리별 그룹화
        final fiveLeagues = leagues.where((l) => [39, 140, 135, 78, 61].contains(l.id)).toList();
        final euroComps = leagues.where((l) => [2, 3, 848].contains(l.id)).toList();
        final nationalComps = leagues.where((l) => [1, 4, 6, 9, 17].contains(l.id)).toList();
        final otherLeagues = leagues.where((l) => [292].contains(l.id)).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (fiveLeagues.isNotEmpty) ...[
              _buildSectionHeader('5대 리그'),
              ...fiveLeagues.map((l) => _LeagueCard(league: l)),
              const SizedBox(height: 16),
            ],
            if (euroComps.isNotEmpty) ...[
              _buildSectionHeader('유럽 클럽 대회'),
              ...euroComps.map((l) => _LeagueCard(league: l)),
              const SizedBox(height: 16),
            ],
            if (nationalComps.isNotEmpty) ...[
              _buildSectionHeader('국가대항전'),
              ...nationalComps.map((l) => _LeagueCard(league: l)),
              const SizedBox(height: 16),
            ],
            if (otherLeagues.isNotEmpty) ...[
              _buildSectionHeader('기타 리그'),
              ...otherLeagues.map((l) => _LeagueCard(league: l)),
            ],
            const SizedBox(height: 20),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: _textSecondary),
            const SizedBox(height: 16),
            Text(
              '리그 목록을 불러올 수 없습니다',
              style: TextStyle(color: _textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(popularLeaguesProvider),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _textSecondary,
        ),
      ),
    );
  }
}

class _LeagueCard extends StatelessWidget {
  final ApiFootballLeague league;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _LeagueCard({required this.league});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/league/${league.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            // 리그 로고
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: league.logo != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: league.logo!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => _buildPlaceholder(),
                      ),
                    )
                  : _buildPlaceholder(),
            ),
            const SizedBox(width: 14),
            // 리그 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    league.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  if (league.countryName != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (league.countryFlag != null) ...[
                          CachedNetworkImage(
                            imageUrl: league.countryFlag!,
                            width: 14,
                            height: 10,
                            errorWidget: (_, __, ___) => const SizedBox.shrink(),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          league.countryName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // 화살표
            Icon(Icons.chevron_right, color: _textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(Icons.sports_soccer, color: _textSecondary, size: 22),
    );
  }
}
