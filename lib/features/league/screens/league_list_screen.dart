import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_football_ids.dart';
import '../../../core/services/api_football_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/banner_ad_widget.dart';

/// 국가 코드 → 해당 국가 리그 ID 목록 매핑 (1부, 2부)
const Map<String, List<int>> _countryToLeagueIds = {
  'KR': [292, 293],   // K League 1, K League 2 (한국)
  'JP': [98, 99],     // J1 League, J2 League (일본)
  'CN': [169],        // Chinese Super League (중국)
  'US': [253],        // MLS (미국)
  'GB': [39, 40],     // Premier League, Championship (영국) - 5대 리그
  'ES': [140, 141],   // La Liga, La Liga 2 (스페인) - 5대 리그
  'IT': [135, 136],   // Serie A, Serie B (이탈리아) - 5대 리그
  'DE': [78, 79],     // Bundesliga, 2. Bundesliga (독일) - 5대 리그
  'FR': [61, 62],     // Ligue 1, Ligue 2 (프랑스) - 5대 리그
  'PT': [94, 95],     // Primeira Liga, Liga Portugal 2 (포르투갈)
  'NL': [88, 89],     // Eredivisie, Eerste Divisie (네덜란드)
  'BE': [144],        // Belgian Pro League (벨기에)
  'TR': [203, 204],   // Süper Lig, 1. Lig (튀르키예)
  'BR': [71, 72],     // Brasileirão Série A, Série B (브라질)
  'AR': [128, 129],   // Liga Profesional, Primera Nacional (아르헨티나)
  'MX': [262, 263],   // Liga MX, Liga de Expansión (멕시코)
  'AU': [188],        // A-League (호주)
  'SA': [307],        // Saudi Pro League (사우디아라비아)
  'AE': [305],        // UAE Pro League (UAE)
  'RU': [235, 236],   // Russian Premier League, FNL (러시아)
  'UA': [333],        // Ukrainian Premier League (우크라이나)
  'PL': [106],        // Ekstraklasa (폴란드)
  'AT': [218, 219],   // Austrian Bundesliga, 2. Liga (오스트리아)
  'CH': [207],        // Swiss Super League (스위스)
  'SE': [113],        // Allsvenskan (스웨덴)
  'NO': [103],        // Eliteserien (노르웨이)
  'DK': [119],        // Superligaen (덴마크)
  'GR': [197],        // Super League Greece (그리스)
  'CZ': [345],        // Czech First League (체코)
  'HR': [210],        // HNL (크로아티아)
  'RS': [286],        // Serbian SuperLiga (세르비아)
  'IN': [323],        // Indian Super League (인도)
  'TH': [296],        // Thai League (태국)
  'VN': [340],        // V.League 1 (베트남)
  'ID': [274],        // Liga 1 Indonesia (인도네시아)
  'MY': [302],        // Malaysia Super League (말레이시아)
  'SG': [308],        // Singapore Premier League (싱가포르)
  'EG': [233],        // Egyptian Premier League (이집트)
  'ZA': [288],        // South African Premier Division (남아공)
  'NG': [332],        // NPFL (나이지리아)
  'MA': [200],        // Botola Pro (모로코)
  'CL': [265],        // Primera División (칠레)
  'CO': [239],        // Liga BetPlay (콜롬비아)
  'PE': [281],        // Liga 1 Peru (페루)
};

/// 5대 리그 ID 목록 (중복 방지용)
const List<int> _topFiveLeagueIds = [39, 140, 135, 78, 61];

/// 사용자 국가 코드 Provider
final userCountryCodeProvider = Provider<String>((ref) {
  // 기기의 locale에서 국가 코드 가져오기
  final locale = ui.PlatformDispatcher.instance.locale;
  return locale.countryCode ?? 'KR'; // 기본값: 한국
});

/// 사용자 자국 리그 ID 목록 Provider (최대 2개)
final userLocalLeagueIdsProvider = Provider<List<int>>((ref) {
  final countryCode = ref.watch(userCountryCodeProvider);
  final leagueIds = _countryToLeagueIds[countryCode] ?? [];

  // 5대 리그 국가는 이미 표시되므로 빈 목록 반환
  if (leagueIds.isNotEmpty && _topFiveLeagueIds.contains(leagueIds.first)) {
    return [];
  }
  return leagueIds.take(2).toList(); // 최대 2개
});

/// 인기 리그 목록 Provider
final popularLeaguesProvider = FutureProvider<List<ApiFootballLeague>>((ref) async {
  final service = ApiFootballService();
  final localLeagueIds = ref.watch(userLocalLeagueIdsProvider);

  // 주요 리그 ID 목록
  final popularLeagueIds = [
    // 5대 리그
    39,   // Premier League
    140,  // La Liga
    135,  // Serie A
    78,   // Bundesliga
    61,   // Ligue 1
    // 5대 리그 국내 컵 대회
    45,   // FA Cup
    48,   // EFL Cup (Carabao Cup)
    143,  // Copa del Rey
    81,   // DFB Pokal
    137,  // Coppa Italia
    66,   // Coupe de France
    // 5대 리그 슈퍼컵
    528,  // Community Shield (잉글랜드)
    556,  // Supercopa de España (스페인)
    529,  // DFL Supercup (독일)
    547,  // Supercoppa Italiana (이탈리아)
    526,  // Trophée des Champions (프랑스)
    // 유럽 클럽 대회
    2,    // UEFA Champions League
    3,    // UEFA Europa League
    848,  // UEFA Europa Conference League
    // 국가대표 대회
    4,    // Euro Championship
    1,    // World Cup
    6,    // Africa Cup of Nations
    9,    // Copa America
    17,   // AFC Asian Cup
    // 사용자 자국 리그 (최대 2개)
    ...localLeagueIds,
  ];

  // 재시도 로직이 포함된 리그 조회 함수 (최대 3회 재시도)
  Future<ApiFootballLeague?> fetchLeagueWithRetry(int id) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final result = await service.getLeagueById(id);
        if (result != null) return result;
      } catch (_) {
        // 재시도 전 대기
      }
      if (attempt < 2) {
        await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      }
    }
    return null;
  }

  // 병렬로 모든 리그 정보 조회 (재시도 포함)
  final results = await Future.wait(
    popularLeagueIds.map((id) => fetchLeagueWithRetry(id)),
  );

  // 실패한 리그 확인
  final failedIds = <int>[];
  final leagues = <ApiFootballLeague>[];
  for (int i = 0; i < popularLeagueIds.length; i++) {
    if (results[i] != null) {
      leagues.add(results[i]!);
    } else {
      failedIds.add(popularLeagueIds[i]);
    }
  }

  // 하나라도 실패하면 에러 throw (재시도 유도)
  if (failedIds.isNotEmpty) {
    throw Exception('Failed to load leagues: $failedIds');
  }

  return leagues;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _background,
      bottomNavigationBar: const BannerAdWidget(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.leagues,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // 국가별 리그 버튼
          GestureDetector(
            onTap: () => context.push('/leagues-by-country'),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.public, size: 16, color: const Color(0xFF2563EB)),
                  const SizedBox(width: 4),
                  Text(
                    l10n.byCountry,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _buildPopularLeagues(),
    );
  }

  Widget _buildPopularLeagues() {
    final l10n = AppLocalizations.of(context)!;
    final leaguesAsync = ref.watch(popularLeaguesProvider);
    final localLeagueIds = ref.watch(userLocalLeagueIdsProvider);

    return leaguesAsync.when(
      data: (leagues) {
        // 카테고리별 그룹화
        final fiveLeagues = leagues.where((l) => _topFiveLeagueIds.contains(l.id)).toList();
        final domesticCups = leagues.where((l) => LeagueIds.cupCompetitionIds.contains(l.id)).toList();
        final euroComps = leagues.where((l) => [2, 3, 848].contains(l.id)).toList();
        final nationalComps = leagues.where((l) => [1, 4, 6, 9, 17].contains(l.id)).toList();
        // 사용자 자국 리그 (최대 2개)
        final localLeagues = leagues.where((l) => localLeagueIds.contains(l.id)).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (fiveLeagues.isNotEmpty) ...[
              _buildSectionHeader(l10n.top5Leagues),
              ...fiveLeagues.map((l) => _LeagueCard(league: l)),
              const SizedBox(height: 16),
            ],
            if (domesticCups.isNotEmpty) ...[
              _buildSectionHeader(l10n.domesticCups),
              ...domesticCups.map((l) => _LeagueCard(league: l)),
              const SizedBox(height: 16),
            ],
            if (euroComps.isNotEmpty) ...[
              _buildSectionHeader(l10n.euroClubComps),
              ...euroComps.map((l) => _LeagueCard(league: l)),
              const SizedBox(height: 16),
            ],
            if (nationalComps.isNotEmpty) ...[
              _buildSectionHeader(l10n.nationalComps),
              ...nationalComps.map((l) => _LeagueCard(league: l)),
              const SizedBox(height: 16),
            ],
            if (localLeagues.isNotEmpty) ...[
              _buildSectionHeader(l10n.myLocalLeague),
              ...localLeagues.map((l) => _LeagueCard(league: l)),
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
              l10n.cannotLoadLeagues,
              style: TextStyle(color: _textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(popularLeaguesProvider),
              child: Text(l10n.retry),
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
                        Text(
                          league.countryName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                            letterSpacing: 0,
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
