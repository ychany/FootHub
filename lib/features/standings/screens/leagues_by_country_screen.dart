import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_football_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_indicator.dart';

// 모든 국가 목록 Provider
final allCountriesProvider = FutureProvider<List<ApiFootballCountry>>((ref) async {
  final service = ApiFootballService();
  return service.getAllCountries();
});

// 선택된 국가의 리그 목록 Provider
final leaguesByCountryProvider = FutureProvider.family<List<ApiFootballLeague>, String>((ref, countryCode) async {
  final service = ApiFootballService();
  return service.getLeaguesByCountry(countryCode);
});

class LeaguesByCountryScreen extends ConsumerStatefulWidget {
  const LeaguesByCountryScreen({super.key});

  @override
  ConsumerState<LeaguesByCountryScreen> createState() => _LeaguesByCountryScreenState();
}

class _LeaguesByCountryScreenState extends ConsumerState<LeaguesByCountryScreen> {
  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _background = Color(0xFFF9FAFB);

  String _searchQuery = '';
  ApiFootballCountry? _selectedCountry;

  // 주요 국가 목록 (상단에 고정)
  static const _topCountries = [
    'England',
    'Spain',
    'Germany',
    'Italy',
    'France',
    'Korea Republic',
    'Japan',
    'USA',
    'Brazil',
    'Argentina',
  ];

  @override
  Widget build(BuildContext context) {
    final countriesAsync = ref.watch(allCountriesProvider);

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
                child: _selectedCountry == null
                    ? _buildCountryList(countriesAsync)
                    : _buildLeagueList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                  icon: Icon(
                    _selectedCountry == null ? Icons.arrow_back_ios : Icons.close,
                    size: 20,
                  ),
                  color: _textPrimary,
                  onPressed: () {
                    if (_selectedCountry == null) {
                      context.pop();
                    } else {
                      setState(() {
                        _selectedCountry = null;
                      });
                    }
                  },
                ),
                Expanded(
                  child: Text(
                    _selectedCountry == null
                        ? AppLocalizations.of(context)!.leaguesByCountry
                        : _selectedCountry!.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // 검색바 (국가 선택 전에만 표시)
          if (_selectedCountry == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchCountry,
                  hintStyle: const TextStyle(color: _textSecondary),
                  prefixIcon: const Icon(Icons.search, color: _textSecondary),
                  filled: true,
                  fillColor: _background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCountryList(AsyncValue<List<ApiFootballCountry>> countriesAsync) {
    return countriesAsync.when(
      data: (countries) {
        // World 제외 및 검색 필터링
        var filteredCountries = countries.where((c) => c.name != 'World').toList();
        if (_searchQuery.isNotEmpty) {
          filteredCountries = filteredCountries
              .where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
        }

        // 검색 중이면 모든 국가를 알파벳순으로 표시
        if (_searchQuery.isNotEmpty) {
          filteredCountries.sort((a, b) => a.name.compareTo(b.name));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: filteredCountries.map((country) => _buildCountryTile(country)).toList(),
          );
        }

        // 검색 중이 아니면 주요 국가와 나머지 국가 분리
        final topCountryList = <ApiFootballCountry>[];
        final otherCountryList = <ApiFootballCountry>[];

        for (final country in filteredCountries) {
          if (_topCountries.contains(country.name)) {
            topCountryList.add(country);
          } else {
            otherCountryList.add(country);
          }
        }

        // 주요 국가 정렬 (지정된 순서대로)
        topCountryList.sort((a, b) {
          final aIndex = _topCountries.indexOf(a.name);
          final bIndex = _topCountries.indexOf(b.name);
          return aIndex.compareTo(bIndex);
        });

        // 나머지 국가 알파벳순 정렬
        otherCountryList.sort((a, b) => a.name.compareTo(b.name));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 주요 국가 섹션
            if (topCountryList.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  AppLocalizations.of(context)!.mainCountries,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                ),
              ),
              _buildCountryGrid(topCountryList),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  AppLocalizations.of(context)!.allCountries,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                ),
              ),
            ],

            // 전체 국가 리스트
            ...otherCountryList.map((country) => _buildCountryTile(country)),
          ],
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(
        child: Text('${AppLocalizations.of(context)!.errorPrefix}: $e', style: const TextStyle(color: _textSecondary)),
      ),
    );
  }

  Widget _buildCountryGrid(List<ApiFootballCountry> countries) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: countries.length,
      itemBuilder: (context, index) {
        final country = countries[index];
        return _buildCountryCard(country);
      },
    );
  }

  Widget _buildCountryCard(ApiFootballCountry country) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCountry = country;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 국기
              _buildFlagWidget(country.flag, 32, 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  country.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: _textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountryTile(ApiFootballCountry country) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCountry = country;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 국기
                _buildFlagWidget(country.flag, 36, 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    country.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary,
                    ),
                  ),
                ),
                if (country.code != null)
                  Text(
                    country.code!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _textSecondary,
                    ),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 20, color: _textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // SVG 국기 위젯
  Widget _buildFlagWidget(String? flagUrl, double width, double height) {
    // SizedBox로 감싸서 로딩 중에도 크기 고정
    return SizedBox(
      width: width,
      height: height,
      child: _buildFlagContent(flagUrl, width, height),
    );
  }

  Widget _buildFlagContent(String? flagUrl, double width, double height) {
    if (flagUrl == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.flag, size: 16, color: _textSecondary),
      );
    }

    // SVG 파일인 경우
    if (flagUrl.toLowerCase().endsWith('.svg')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SvgPicture.network(
          flagUrl,
          width: width,
          height: height,
          fit: BoxFit.cover,
          placeholderBuilder: (_) => Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      );
    }

    // 일반 이미지인 경우
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CachedNetworkImage(
        imageUrl: flagUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.flag, size: 16),
        ),
      ),
    );
  }

  Widget _buildLeagueList() {
    if (_selectedCountry?.code == null) {
      return Center(
        child: Text(AppLocalizations.of(context)!.noCountryCode),
      );
    }

    final leaguesAsync = ref.watch(leaguesByCountryProvider(_selectedCountry!.code!));

    return leaguesAsync.when(
      data: (leagues) {
        final l10n = AppLocalizations.of(context)!;
        if (leagues.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_soccer, size: 64, color: _textSecondary),
                const SizedBox(height: 16),
                Text(
                  l10n.noLeaguesInCountry(_selectedCountry!.name),
                  style: const TextStyle(color: _textSecondary, fontSize: 16),
                ),
              ],
            ),
          );
        }

        // 리그 타입별 분류
        final leagueType = leagues.where((l) => l.type == 'League').toList();
        final cupType = leagues.where((l) => l.type == 'Cup').toList();
        final otherType = leagues.where((l) => l.type != 'League' && l.type != 'Cup').toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 리그
            if (leagueType.isNotEmpty) ...[
              _buildLeagueSection(l10n.leagueSection, leagueType),
              const SizedBox(height: 16),
            ],
            // 컵 대회
            if (cupType.isNotEmpty) ...[
              _buildLeagueSection(l10n.cupSection, cupType),
              const SizedBox(height: 16),
            ],
            // 기타
            if (otherType.isNotEmpty) ...[
              _buildLeagueSection(l10n.otherSection, otherType),
            ],
          ],
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(
        child: Text('${AppLocalizations.of(context)!.errorPrefix}: $e', style: const TextStyle(color: _textSecondary)),
      ),
    );
  }

  Widget _buildLeagueSection(String title, List<ApiFootballLeague> leagues) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${leagues.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...leagues.map((league) => _buildLeagueTile(league)),
      ],
    );
  }

  Widget _buildLeagueTile(ApiFootballLeague league) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          // 순위표 화면으로 이동 (외부 리그 상세 화면)
          context.push('/league/${league.id}/standings');
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 리그 로고
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _border),
                    color: Colors.grey.shade100,
                  ),
                  child: ClipOval(
                    child: league.logo != null
                        ? CachedNetworkImage(
                            imageUrl: league.logo!,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => Icon(
                              Icons.emoji_events,
                              size: 22,
                              color: _textSecondary,
                            ),
                            errorWidget: (_, __, ___) => Icon(
                              Icons.emoji_events,
                              size: 22,
                              color: _textSecondary,
                            ),
                          )
                        : Icon(
                            Icons.emoji_events,
                            size: 22,
                            color: _textSecondary,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        league.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        league.type,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20, color: _textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
