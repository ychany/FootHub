import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/services/api_football_service.dart';
import '../../../core/constants/api_football_ids.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/error_helper.dart';
import '../../../core/utils/auth_utils.dart';
import '../../../shared/services/storage_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/attendance_record.dart';
import '../providers/attendance_provider.dart';
import '../../league/screens/league_list_screen.dart' show userLocalLeagueIdsProvider;

class AttendanceAddScreen extends ConsumerStatefulWidget {
  final String? matchId;

  const AttendanceAddScreen({super.key, this.matchId});

  @override
  ConsumerState<AttendanceAddScreen> createState() =>
      _AttendanceAddScreenState();
}

class _AttendanceAddScreenState extends ConsumerState<AttendanceAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiFootballService = ApiFootballService();
  final _pageController = PageController();
  int _currentPage = 0;

  // 색상 상수
  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _background = Color(0xFFF9FAFB);
  static const _warning = Color(0xFFF59E0B);
  static const _success = Color(0xFF10B981);

  // 기본 정보 컨트롤러
  final _seatController = TextEditingController();
  final _homeScoreController = TextEditingController();
  final _awayScoreController = TextEditingController();
  final _searchController = TextEditingController();
  final _stadiumController = TextEditingController();

  // 일기 컨트롤러
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final _companionController = TextEditingController();
  final _ticketPriceController = TextEditingController();
  final _foodReviewController = TextEditingController();

  // 선택된 데이터
  DateTime _selectedDate = DateTime.now();
  ApiFootballFixture? _selectedEvent;
  ApiFootballTeam? _selectedHomeTeam;
  ApiFootballTeam? _selectedAwayTeam;
  String? _selectedLeague;
  final List<File> _photos = [];

  // 직접 입력용 경기명 (리그명 대신 사용)
  final _matchNameController = TextEditingController();

  // 일기 데이터
  double _rating = 3.0;
  MatchMood? _selectedMood;
  String? _selectedWeather;
  ApiFootballSquadPlayer? _selectedMvp;
  final List<String> _tags = [];

  // 응원한 팀 (승/무/패 계산용)
  String? _supportedTeamId;

  // 검색 상태
  bool _isSearching = false;
  List<ApiFootballFixture> _searchResults = [];
  String? _searchLeague; // 리그 필터

  // 저장 상태
  bool _isSaving = false;

  // 수동 입력 모드
  bool _isManualMode = false;

  List<String> _getWeatherOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.weatherSunny,
      l10n.weatherCloudy,
      l10n.weatherRainy,
      l10n.weatherSnowy,
      l10n.weatherWindy,
    ];
  }

  @override
  void initState() {
    super.initState();
    if (widget.matchId != null) {
      _loadMatchById(widget.matchId!);
    }
  }

  Future<void> _loadMatchById(String matchId) async {
    final fixtureId = int.tryParse(matchId);
    if (fixtureId == null) return;

    final fixture = await _apiFootballService.getFixtureById(fixtureId);
    if (fixture != null && mounted) {
      setState(() {
        _selectedEvent = fixture;
        _selectedDate = fixture.dateKST;
        if (fixture.homeGoals != null) {
          _homeScoreController.text = fixture.homeGoals.toString();
        }
        if (fixture.awayGoals != null) {
          _awayScoreController.text = fixture.awayGoals.toString();
        }
        if (fixture.venue?.name != null) {
          _stadiumController.text = fixture.venue!.name!;
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _seatController.dispose();
    _homeScoreController.dispose();
    _awayScoreController.dispose();
    _searchController.dispose();
    _stadiumController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _companionController.dispose();
    _ticketPriceController.dispose();
    _foodReviewController.dispose();
    _matchNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMatchInfo = _selectedEvent != null ||
        (_isManualMode &&
            _selectedHomeTeam != null &&
            _selectedAwayTeam != null);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Builder(builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Text(
              _currentPage == 0 ? l10n.matchRecord : l10n.attendanceDiary,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            );
          }),
          actions: [
            if (hasMatchInfo)
              TextButton(
                onPressed: _isSaving ? null : _saveRecord,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        AppLocalizations.of(context)!.save,
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
          ],
        ),
        body: Column(
          children: [
            // 페이지 인디케이터
            if (hasMatchInfo) _buildPageIndicator(),

            // 페이지 뷰
            Expanded(
              child: hasMatchInfo
                  ? PageView(
                      controller: _pageController,
                      onPageChanged: (page) =>
                          setState(() => _currentPage = page),
                      children: [
                        _buildMatchInfoPage(),
                        _buildDiaryPage(),
                      ],
                    )
                  : _buildMatchSelectionPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PageIndicatorDot(
            label: l10n.matchInfo,
            isActive: _currentPage == 0,
            onTap: () => _pageController.animateToPage(0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut),
          ),
          Container(
            width: 40,
            height: 2,
            color: _border,
          ),
          _PageIndicatorDot(
            label: l10n.diaryWrite,
            isActive: _currentPage == 1,
            onTap: () => _pageController.animateToPage(1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchSelectionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModeSelector(),
          const SizedBox(height: 16),
          if (_isManualMode)
            _buildManualEntryForm()
          else
            _buildEventSearch(),
          if (!_isManualMode && _searchResults.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.searchResults,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final fixture = _searchResults[index];
                return _EventSearchResultCard(
                  fixture: fixture,
                  isSelected: _selectedEvent?.id == fixture.id,
                  onTap: () => _selectEvent(fixture),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelectedMatchCard(),
            const SizedBox(height: 20),
            _buildScoreInput(),
            const SizedBox(height: 16),
            _buildSupportedTeamSelector(),
            const SizedBox(height: 16),
            _buildStadiumField(),
            const SizedBox(height: 16),
            Builder(builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return _buildTextField(
                controller: _seatController,
                label: l10n.seatInfo,
                icon: Icons.chair,
                hintText: l10n.seatHint,
              );
            }),
            const SizedBox(height: 16),
            _buildPhotoSection(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.goToDiary,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiaryPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRatingSection(),
          const SizedBox(height: 24),
          _buildMoodSection(),
          const SizedBox(height: 24),
          Builder(builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return _buildTextField(
              controller: _titleController,
              label: l10n.oneLiner,
              icon: Icons.title,
              hintText: l10n.oneLinerHint,
            );
          }),
          const SizedBox(height: 16),
          _buildSectionTitle(AppLocalizations.of(context)!.diarySection),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: TextFormField(
              controller: _contentController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.diaryHint,
                hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.6)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildMvpSection(),
          const SizedBox(height: 24),
          _buildTagSection(),
          const SizedBox(height: 24),
          _buildAdditionalInfoSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              icon: Icons.search,
              label: AppLocalizations.of(context)!.matchSearch,
              isSelected: !_isManualMode,
              onTap: () => setState(() {
                _isManualMode = false;
                _selectedHomeTeam = null;
                _selectedAwayTeam = null;
                _matchNameController.clear();
              }),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ModeButton(
              icon: Icons.edit,
              label: AppLocalizations.of(context)!.manualInput,
              isSelected: _isManualMode,
              onTap: () => setState(() {
                _isManualMode = true;
                _searchResults = [];
                _searchController.clear();
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateSelector(),
        const SizedBox(height: 12),
        _buildLeagueSelector(),
        const SizedBox(height: 12),
        // 팀 이름 검색
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.teamSearchHint,
              hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.6)),
              prefixIcon: const Icon(Icons.search, color: _textSecondary),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : IconButton(
                      icon: const Icon(Icons.search, color: _primary),
                      onPressed: _searchEvents),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onSubmitted: (_) => _searchEvents(),
          ),
        ),
        const SizedBox(height: 12),
        // 날짜/리그로 조회 버튼
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isSearching ? null : _searchEventsByDateAndLeague,
            icon: const Icon(Icons.calendar_today, size: 18),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: const BorderSide(color: _primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            label: Text(_searchLeague != null
                ? AppLocalizations.of(context)!.searchLeagueMatchesForDate(
                    DateFormat('MM/dd').format(_selectedDate),
                    AppConstants.getLocalizedLeagueName(context, _searchLeague!))
                : AppLocalizations.of(context)!.searchAllMatchesForDate(
                    DateFormat('MM/dd').format(_selectedDate))),
          ),
        ),
      ],
    );
  }

  Widget _buildLeagueSelector() {
    // 사용자 자국 리그 ID 가져오기
    final localLeagueIds = ref.watch(userLocalLeagueIdsProvider);

    // 자국 리그 이름 목록 생성
    final localLeagueNames = localLeagueIds
        .map((id) => AppConstants.getLeagueNameById(id))
        .where((name) => name != null)
        .cast<String>()
        .toList();

    // 기본 리그 + 자국 리그 (중복 제거)
    final allLeagues = [
      ...AppConstants.supportedLeagues,
      ...localLeagueNames.where((name) => !AppConstants.supportedLeagues.contains(name)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.selectLeague,
          style: TextStyle(fontSize: 12, color: _textSecondary),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _LeagueFilterChip(
                label: AppLocalizations.of(context)!.all,
                isSelected: _searchLeague == null,
                onTap: () => setState(() => _searchLeague = null),
              ),
              const SizedBox(width: 8),
              ...allLeagues.map((league) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _LeagueFilterChip(
                      label: AppConstants.getLocalizedLeagueName(context, league),
                      isSelected: _searchLeague == league,
                      onTap: () => setState(() => _searchLeague = league),
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManualEntryForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateSelector(),
        const SizedBox(height: 16),
        _buildSectionTitle(AppLocalizations.of(context)!.matchName),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.of(context)!.matchNameHint,
          style: TextStyle(fontSize: 12, color: _textSecondary),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: TextFormField(
            controller: _matchNameController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.enterMatchName,
              hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.6)),
              prefixIcon: const Icon(Icons.sports_soccer, color: _textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildTeamSearchWithLeagueFilter(AppLocalizations.of(context)!.homeTeam, _selectedHomeTeam,
            (team) => setState(() => _selectedHomeTeam = team)),
        const SizedBox(height: 16),
        _buildTeamSearchWithLeagueFilter(AppLocalizations.of(context)!.awayTeam, _selectedAwayTeam,
            (team) => setState(() => _selectedAwayTeam = team)),
      ],
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20, color: _primary),
            const SizedBox(width: 12),
            Text(
              DateFormat(AppLocalizations.of(context)!.dateFormatFull, Localizations.localeOf(context).toString()).format(_selectedDate),
              style: const TextStyle(
                fontSize: 15,
                color: _textPrimary,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: _textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSearchWithLeagueFilter(
      String label, ApiFootballTeam? selectedTeam, Function(ApiFootballTeam?) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label),
        const SizedBox(height: 8),
        if (selectedTeam != null)
          _buildSelectedTeamChip(selectedTeam, () => onSelect(null))
        else
          OutlinedButton.icon(
            onPressed: () => _showTeamSearchSheet(label, onSelect),
            icon: const Icon(Icons.search, size: 18),
            label: Text(AppLocalizations.of(context)!.searchTeamLabel(label)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: const BorderSide(color: _border),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
    );
  }

  void _showTeamSearchSheet(String label, Function(ApiFootballTeam?) onSelect) {
    // 사용자 자국 리그 ID 가져오기
    final localLeagueIds = ref.read(userLocalLeagueIdsProvider);

    // 자국 리그 이름 목록 생성
    final localLeagueNames = localLeagueIds
        .map((id) => AppConstants.getLeagueNameById(id))
        .where((name) => name != null)
        .cast<String>()
        .toList();

    // 기본 리그 + 자국 리그 (중복 제거)
    final allLeagues = [
      ...AppConstants.supportedLeagues,
      ...localLeagueNames.where((name) => !AppConstants.supportedLeagues.contains(name)),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TeamSearchSheet(
        label: label,
        apiFootballService: _apiFootballService,
        availableLeagues: allLeagues,
        onTeamSelected: (team) {
          onSelect(team);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildSelectedTeamChip(ApiFootballTeam team, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (team.logo != null)
            CachedNetworkImage(
              imageUrl: team.logo!,
              width: 40,
              height: 40,
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.sports_soccer, size: 40, color: _primary),
            )
          else
            const Icon(Icons.sports_soccer, size: 40, color: _primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                if (team.country != null)
                  Text(
                    team.country!,
                    style: TextStyle(fontSize: 12, color: _textSecondary),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: _textSecondary),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedMatchCard() {
    final homeTeam =
        _selectedEvent?.homeTeam.name ?? _selectedHomeTeam?.name ?? '';
    final awayTeam =
        _selectedEvent?.awayTeam.name ?? _selectedAwayTeam?.name ?? '';
    final league = _selectedEvent?.league.name ??
        (_isManualMode ? _matchNameController.text : _selectedLeague) ??
        '';
    final homeBadge =
        _selectedEvent?.homeTeam.logo ?? _selectedHomeTeam?.logo;
    final awayBadge =
        _selectedEvent?.awayTeam.logo ?? _selectedAwayTeam?.logo;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  league,
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: _textSecondary),
                onPressed: () => setState(() {
                  _selectedEvent = null;
                  _selectedHomeTeam = null;
                  _selectedAwayTeam = null;
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildTeamBadge(homeBadge, 48),
                    const SizedBox(height: 8),
                    Text(
                      homeTeam,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _textPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildTeamBadge(awayBadge, 48),
                    const SizedBox(height: 8),
                    Text(
                      awayTeam,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            DateFormat(AppLocalizations.of(context)!.dateFormatMedium, Localizations.localeOf(context).toString()).format(_selectedDate),
            style: TextStyle(fontSize: 13, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamBadge(String? badgeUrl, double size) {
    if (badgeUrl != null && badgeUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: badgeUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholder: (_, __) =>
            Icon(Icons.shield, size: size, color: _textSecondary),
        errorWidget: (_, __, ___) =>
            Icon(Icons.shield, size: size, color: _textSecondary),
      );
    }
    return Icon(Icons.shield, size: size, color: _textSecondary);
  }

  Widget _buildScoreInput() {
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
                  color: _success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.scoreboard, size: 18, color: _success),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.score,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextFormField(
                    controller: _homeScoreController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          _selectedEvent?.homeTeam.name ?? _selectedHomeTeam?.name ?? AppLocalizations.of(context)!.homeShort,
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: _textSecondary.withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextFormField(
                    controller: _awayScoreController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          _selectedEvent?.awayTeam.name ?? _selectedAwayTeam?.name ?? AppLocalizations.of(context)!.awayShort,
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: _textSecondary.withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportedTeamSelector() {
    final homeTeamId =
        (_selectedEvent?.homeTeam.id ?? _selectedHomeTeam?.id)?.toString() ?? '';
    final l10n = AppLocalizations.of(context)!;
    final homeTeamName =
        _selectedEvent?.homeTeam.name ?? _selectedHomeTeam?.name ?? l10n.homeTeam;
    final awayTeamId =
        (_selectedEvent?.awayTeam.id ?? _selectedAwayTeam?.id)?.toString() ?? '';
    final awayTeamName =
        _selectedEvent?.awayTeam.name ?? _selectedAwayTeam?.name ?? l10n.awayTeam;

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
                child: const Icon(Icons.favorite, size: 18, color: _primary),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.mySupportedTeam,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  Text(
                    l10n.winDrawLossStats,
                    style: TextStyle(fontSize: 11, color: _textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TeamSelectButton(
                  teamName: homeTeamName,
                  isSelected: _supportedTeamId == homeTeamId,
                  onTap: () => setState(() => _supportedTeamId = homeTeamId),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TeamSelectButton(
                  teamName: awayTeamName,
                  isSelected: _supportedTeamId == awayTeamId,
                  onTap: () => setState(() => _supportedTeamId = awayTeamId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      required String hintText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.6)),
              prefixIcon: Icon(icon, color: _textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStadiumField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(AppLocalizations.of(context)!.stadium),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showVenueSearchSheet(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Icon(Icons.stadium, color: _textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _stadiumController.text.isNotEmpty
                        ? _stadiumController.text
                        : AppLocalizations.of(context)!.searchOrEnterStadium,
                    style: TextStyle(
                      color: _stadiumController.text.isNotEmpty
                          ? _textPrimary
                          : _textSecondary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Icon(Icons.search, color: _textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showVenueSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VenueSearchSheet(
        apiFootballService: _apiFootballService,
        onVenueSelected: (venue) {
          setState(() {
            _stadiumController.text = venue.name ?? '';
          });
          Navigator.pop(context);
        },
        onManualEntry: (venueName) {
          setState(() {
            _stadiumController.text = venueName;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildPhotoSection() {
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
                  color: _warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library, size: 18, color: _warning),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.photos,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _PhotoAddButton(
                icon: Icons.camera_alt,
                label: AppLocalizations.of(context)!.camera,
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(width: 12),
              _PhotoAddButton(
                icon: Icons.photo_library,
                label: AppLocalizations.of(context)!.gallery,
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
          if (_photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _photos.length,
                itemBuilder: (context, index) => _buildPhotoThumbnail(index),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnail(int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_photos[index],
                width: 100, height: 100, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _photos.removeAt(index)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Color(0xFFEF4444), shape: BoxShape.circle),
                child:
                    const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
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
                  color: _warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star, size: 18, color: _warning),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.todaysMatchRating,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _warning,
                    inactiveTrackColor: _warning.withValues(alpha: 0.2),
                    thumbColor: _warning,
                    overlayColor: _warning.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _rating,
                    min: 1,
                    max: 5,
                    divisions: 8,
                    label: _rating.toStringAsFixed(1),
                    onChanged: (value) => setState(() => _rating = value),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _warning,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          Builder(builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.ratingWorst, style: TextStyle(fontSize: 12, color: _textSecondary)),
                Text(l10n.ratingBest, style: TextStyle(fontSize: 12, color: _textSecondary)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMoodSection() {
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
                child: const Icon(Icons.mood, size: 18, color: _primary),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.todaysMood,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Builder(builder: (context) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MatchMood.values.map((mood) {
                final isSelected = _selectedMood == mood;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = mood),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? _primary : _background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? _primary : _border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(mood.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          mood.getLocalizedLabel(context),
                          style: TextStyle(
                            color: isSelected ? Colors.white : _textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMvpSection() {
    final homeTeamId = _selectedEvent?.homeTeam.id ?? _selectedHomeTeam?.id;
    final awayTeamId = _selectedEvent?.awayTeam.id ?? _selectedAwayTeam?.id;
    final homeTeamName = _selectedEvent?.homeTeam.name ?? _selectedHomeTeam?.name;
    final awayTeamName = _selectedEvent?.awayTeam.name ?? _selectedAwayTeam?.name;

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
                  color: _warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.emoji_events, size: 18, color: _warning),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.todaysMvp,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedMvp != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _warning,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emoji_events,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedMvp!.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                        if (_selectedMvp!.position != null)
                          Text(
                            _selectedMvp!.position!,
                            style: TextStyle(fontSize: 12, color: _textSecondary),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: _textSecondary),
                    onPressed: () => setState(() => _selectedMvp = null),
                  ),
                ],
              ),
            )
          else if (homeTeamId != null || awayTeamId != null)
            OutlinedButton.icon(
              onPressed: () => _showTeamPlayersDialog(
                fixtureId: _selectedEvent?.id,
                homeTeamId: homeTeamId,
                awayTeamId: awayTeamId,
                homeTeamName: homeTeamName,
                awayTeamName: awayTeamName,
              ),
              icon: const Icon(Icons.person_search, size: 18),
              label: Text(AppLocalizations.of(context)!.selectPlayer),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: _border),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: _textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.selectMatchFirst,
                    style: TextStyle(color: _textSecondary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showTeamPlayersDialog({
    int? fixtureId,
    int? homeTeamId,
    int? awayTeamId,
    String? homeTeamName,
    String? awayTeamName,
  }) async {
    showDialog(
      context: context,
      builder: (context) => _TeamPlayersDialog(
        fixtureId: fixtureId,
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
        homeTeamName: homeTeamName,
        awayTeamName: awayTeamName,
        apiFootballService: _apiFootballService,
        onPlayerSelected: (player) {
          setState(() => _selectedMvp = player);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildTagSection() {
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
                  color: _success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tag, size: 18, color: _success),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.tags,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '#$tag',
                          style: const TextStyle(color: _success, fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(() => _tags.remove(tag)),
                          child: const Icon(Icons.close, size: 16, color: _success),
                        ),
                      ],
                    ),
                  )),
              Container(
                width: 120,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _tagController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.addTag,
                    hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.6), fontSize: 13),
                    isDense: true,
                    border: InputBorder.none,
                    prefixText: '#',
                    prefixStyle: const TextStyle(color: _success),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty && !_tags.contains(value)) {
                      setState(() {
                        _tags.add(value);
                        _tagController.clear();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.suggestedTags,
                    style: TextStyle(fontSize: 12, color: _textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [l10n.tagVictory, l10n.tagComeback, l10n.tagGoalFest, l10n.tagCleanSheet, l10n.tagFirstMatch, l10n.tagAway].map((tag) {
              return GestureDetector(
                onTap: () {
                  if (!_tags.contains(tag)) setState(() => _tags.add(tag));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Text(
                    '#$tag',
                    style: TextStyle(color: _textSecondary, fontSize: 12),
                  ),
                ),
              );
            }).toList(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.more_horiz, size: 18, color: _textSecondary),
            ),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)!.additionalInfo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const RoundedRectangleBorder(),
        collapsedShape: const RoundedRectangleBorder(),
        children: [
          const SizedBox(height: 8),
          _buildSectionTitle(AppLocalizations.of(context)!.weather),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _getWeatherOptions(context).map((weather) {
              final isSelected = _selectedWeather == weather;
              return GestureDetector(
                onTap: () => setState(
                    () => _selectedWeather = isSelected ? null : weather),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? _primary : _background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? _primary : _border,
                    ),
                  ),
                  child: Text(
                    weather,
                    style: TextStyle(
                      color: isSelected ? Colors.white : _textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _buildInlineTextField(
            controller: _companionController,
            label: AppLocalizations.of(context)!.companions,
            icon: Icons.people,
            hintText: AppLocalizations.of(context)!.companionHint,
          ),
          const SizedBox(height: 16),
          _buildTicketPriceField(),
          const SizedBox(height: 16),
          _buildSectionTitle(AppLocalizations.of(context)!.stadiumFood),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextFormField(
              controller: _foodReviewController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.foodReviewHint,
                hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.6)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.6)),
              prefixIcon: Icon(icon, color: _textSecondary, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketPriceField() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.ticketPrice),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            controller: _ticketPriceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: l10n.priceHint,
              hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.6)),
              prefixIcon:
                  const Icon(Icons.confirmation_number, color: _textSecondary, size: 20),
              suffixText: l10n.currencyUnit,
              suffixStyle: const TextStyle(color: _textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              final numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
              if (numericValue.isNotEmpty) {
                final number = int.parse(numericValue);
                final formatted = NumberFormat('#,###').format(number);
                if (formatted != value) {
                  _ticketPriceController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }
              }
            },
          ),
        ),
      ],
    );
  }

  void _selectDate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DatePickerBottomSheet(
        initialDate: _selectedDate,
        lastDate: DateTime.now(),
        onDateSelected: (date) {
          setState(() => _selectedDate = date);
        },
      ),
    );
  }

  Future<void> _searchEvents() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _searchEventsByDateAndLeague();
      return;
    }

    setState(() => _isSearching = true);
    try {
      // 날짜로 경기 조회
      final fixtures = await _apiFootballService.getFixturesByDate(_selectedDate);
      final filtered = fixtures.where((fixture) {
        final searchLower = query.toLowerCase();
        return fixture.homeTeam.name.toLowerCase().contains(searchLower) ||
            fixture.awayTeam.name.toLowerCase().contains(searchLower);
      }).toList();

      setState(() => _searchResults = filtered);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _searchEventsByDateAndLeague() async {
    setState(() => _isSearching = true);
    try {
      final fixtures = await _apiFootballService.getFixturesByDate(_selectedDate);
      if (_searchLeague != null) {
        // A매치 필터 선택 시 모든 국제대회 표시
        if (_searchLeague == 'International Friendlies') {
          final filtered = fixtures.where((f) =>
            LeagueIds.internationalLeagueIds.contains(f.league.id)
          ).toList();
          setState(() => _searchResults = filtered);
        }
        // 컵대회 (5대 국가) 필터
        else if (_searchLeague == AppConstants.domesticCups) {
          final filtered = fixtures.where((f) =>
            LeagueIds.cupCompetitionIds.contains(f.league.id)
          ).toList();
          setState(() => _searchResults = filtered);
        }
        else {
          final leagueId = AppConstants.getLeagueIdByName(_searchLeague!);
          final filtered = fixtures.where((f) {
            if (leagueId != null) {
              return f.league.id == leagueId;
            }
            return AppConstants.isLeagueMatch(f.league.name, _searchLeague!);
          }).toList();
          setState(() => _searchResults = filtered);
        }
      } else {
        setState(() => _searchResults = fixtures);
      }
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _selectEvent(ApiFootballFixture fixture) {
    setState(() {
      _selectedEvent = fixture;
      _stadiumController.text = fixture.venue?.name ?? '';
      if (fixture.homeGoals != null) {
        _homeScoreController.text = fixture.homeGoals.toString();
      }
      if (fixture.awayGoals != null) {
        _awayScoreController.text = fixture.awayGoals.toString();
      }
      _searchResults = [];
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image != null) setState(() => _photos.add(File(image.path)));
  }

  Future<void> _saveRecord() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      showLoginRequiredDialog(context);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final homeScore = int.tryParse(_homeScoreController.text);
      final awayScore = int.tryParse(_awayScoreController.text);
      final ticketPriceText =
          _ticketPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final ticketPrice =
          ticketPriceText.isNotEmpty ? int.tryParse(ticketPriceText) : null;
      final now = DateTime.now();

      final tempRecordId = DateTime.now().millisecondsSinceEpoch.toString();

      List<String> photoUrls = [];
      if (_photos.isNotEmpty) {
        final storageService = StorageService();
        photoUrls = await storageService.uploadAttendancePhotos(
          userId: userId,
          recordId: tempRecordId,
          files: _photos,
        );
      }

      final record = AttendanceRecord(
        id: '',
        userId: userId,
        date: _selectedDate,
        league: _selectedEvent?.league.name ??
            (_isManualMode ? _matchNameController.text : _selectedLeague) ??
            '',
        homeTeamId: (_selectedEvent?.homeTeam.id ?? _selectedHomeTeam?.id)?.toString() ?? '',
        homeTeamName:
            _selectedEvent?.homeTeam.name ?? _selectedHomeTeam?.name ?? '',
        homeTeamLogo:
            _selectedEvent?.homeTeam.logo ?? _selectedHomeTeam?.logo,
        awayTeamId: (_selectedEvent?.awayTeam.id ?? _selectedAwayTeam?.id)?.toString() ?? '',
        awayTeamName:
            _selectedEvent?.awayTeam.name ?? _selectedAwayTeam?.name ?? '',
        awayTeamLogo:
            _selectedEvent?.awayTeam.logo ?? _selectedAwayTeam?.logo,
        stadium: _stadiumController.text.isNotEmpty
            ? _stadiumController.text
            : (_selectedEvent?.venue?.name ?? _selectedHomeTeam?.venue?.name ?? ''),
        seatInfo: _seatController.text.isEmpty ? null : _seatController.text,
        homeScore: homeScore,
        awayScore: awayScore,
        matchId: _selectedEvent?.id.toString(),
        photos: photoUrls,
        createdAt: now,
        updatedAt: now,
        diaryTitle:
            _titleController.text.isEmpty ? null : _titleController.text,
        diaryContent:
            _contentController.text.isEmpty ? null : _contentController.text,
        rating: _rating,
        mood: _selectedMood,
        mvpPlayerId: _selectedMvp?.id.toString(),
        mvpPlayerName: _selectedMvp?.name,
        tags: _tags,
        weather: _selectedWeather,
        companion: _companionController.text.isEmpty
            ? null
            : _companionController.text,
        ticketPrice: ticketPrice,
        foodReview: _foodReviewController.text.isEmpty
            ? null
            : _foodReviewController.text,
        supportedTeamId: _supportedTeamId,
      );

      await ref.read(attendanceNotifierProvider.notifier).addAttendance(record);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.diarySaved)));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.saveFailed(ErrorHelper.getLocalizedErrorMessage(context, e)))));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ============ Helper Widgets ============

class _PageIndicatorDot extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  static const _primary = Color(0xFF2563EB);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _PageIndicatorDot({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? _primary : _border,
            ),
            child: Icon(
              isActive ? Icons.check : Icons.circle,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? _primary : _textSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : _textPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : _textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventSearchResultCard extends StatelessWidget {
  final ApiFootballFixture fixture;
  final bool isSelected;
  final VoidCallback onTap;

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _EventSearchResultCard({
    required this.fixture,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateKST = fixture.dateKST;
    final dateStr = '${dateKST.month}/${dateKST.day}';
    final timeStr = '${dateKST.hour.toString().padLeft(2, '0')}:${dateKST.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primary : _border,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      fixture.league.name,
                      style: const TextStyle(
                        color: _primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$dateStr $timeStr',
                  style: TextStyle(fontSize: 11, color: _textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildBadge(fixture.homeTeam.logo, 32),
                      const SizedBox(height: 4),
                      Text(
                        fixture.homeTeam.name,
                        style: const TextStyle(fontSize: 12, color: _textPrimary),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    fixture.isFinished ? fixture.scoreDisplay : 'vs',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _buildBadge(fixture.awayTeam.logo, 32),
                      const SizedBox(height: 4),
                      Text(
                        fixture.awayTeam.name,
                        style: const TextStyle(fontSize: 12, color: _textPrimary),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String? badgeUrl, double size) {
    if (badgeUrl != null && badgeUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: badgeUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholder: (_, __) =>
            Icon(Icons.shield, size: size, color: _textSecondary),
        errorWidget: (_, __, ___) =>
            Icon(Icons.shield, size: size, color: _textSecondary),
      );
    }
    return Icon(Icons.shield, size: size, color: _textSecondary);
  }
}

class _PhotoAddButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _PhotoAddButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: _textSecondary),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: _textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeagueFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const _primary = Color(0xFF2563EB);
  static const _textSecondary = Color(0xFF6B7280);
  static const _background = Color(0xFFF9FAFB);

  const _LeagueFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _primary : _background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _primary : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _TeamSelectButton extends StatelessWidget {
  final String teamName;
  final bool isSelected;
  final VoidCallback onTap;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _border = Color(0xFFE5E7EB);
  static const _background = Color(0xFFF9FAFB);

  const _TeamSelectButton({
    required this.teamName,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? _primary : _background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _primary : _border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.check_circle, color: Colors.white, size: 18),
              ),
            Flexible(
              child: Text(
                teamName,
                style: TextStyle(
                  color: isSelected ? Colors.white : _textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamPlayersDialog extends StatefulWidget {
  final int? fixtureId;
  final int? homeTeamId;
  final int? awayTeamId;
  final String? homeTeamName;
  final String? awayTeamName;
  final ApiFootballService apiFootballService;
  final Function(ApiFootballSquadPlayer) onPlayerSelected;

  const _TeamPlayersDialog({
    this.fixtureId,
    this.homeTeamId,
    this.awayTeamId,
    this.homeTeamName,
    this.awayTeamName,
    required this.apiFootballService,
    required this.onPlayerSelected,
  });

  @override
  State<_TeamPlayersDialog> createState() => _TeamPlayersDialogState();
}

class _TeamPlayersDialogState extends State<_TeamPlayersDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ApiFootballSquadPlayer> _homePlayers = [];
  List<ApiFootballSquadPlayer> _awayPlayers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _background = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlayers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    setState(() => _isLoading = true);

    try {
      // 1. 먼저 라인업에서 가져오기 시도 (fixtureId가 있는 경우)
      if (widget.fixtureId != null) {
        final lineups = await widget.apiFootballService.getFixtureLineups(widget.fixtureId!);

        if (lineups.isNotEmpty) {
          // 라인업 선수들의 사진을 위해 스쿼드도 병렬로 가져오기
          final squadFutures = <Future<List<ApiFootballSquadPlayer>>>[];
          final teamIds = <int>[];

          for (final lineup in lineups) {
            squadFutures.add(widget.apiFootballService.getTeamSquad(lineup.teamId));
            teamIds.add(lineup.teamId);
          }

          final squads = await Future.wait(squadFutures);

          // 스쿼드에서 선수 ID -> 사진 URL 매핑 생성
          final photoMap = <int, String>{};
          for (final squad in squads) {
            for (final player in squad) {
              if (player.photo != null) {
                photoMap[player.id] = player.photo!;
              }
            }
          }

          for (final lineup in lineups) {
            final players = <ApiFootballSquadPlayer>[];

            // 선발 + 교체 선수 모두 포함 (사진 정보 병합)
            for (final p in lineup.startXI) {
              players.add(ApiFootballSquadPlayer(
                id: p.id,
                name: p.name,
                position: p.pos,
                number: p.number,
                photo: photoMap[p.id],
              ));
            }
            for (final p in lineup.substitutes) {
              players.add(ApiFootballSquadPlayer(
                id: p.id,
                name: p.name,
                position: p.pos,
                number: p.number,
                photo: photoMap[p.id],
              ));
            }

            if (lineup.teamId == widget.homeTeamId) {
              _homePlayers = players;
            } else if (lineup.teamId == widget.awayTeamId) {
              _awayPlayers = players;
            }
          }

          // 라인업에서 선수를 가져왔으면 종료
          if (_homePlayers.isNotEmpty || _awayPlayers.isNotEmpty) {
            if (mounted) setState(() => _isLoading = false);
            return;
          }
        }
      }

      // 2. 라인업이 없으면 팀 스쿼드에서 가져오기
      final futures = <Future>[];

      if (widget.homeTeamId != null && _homePlayers.isEmpty) {
        futures.add(
            widget.apiFootballService.getTeamSquad(widget.homeTeamId!).then((players) {
          _homePlayers = players;
        }));
      }

      if (widget.awayTeamId != null && _awayPlayers.isEmpty) {
        futures.add(
            widget.apiFootballService.getTeamSquad(widget.awayTeamId!).then((players) {
          _awayPlayers = players;
        }));
      }

      await Future.wait(futures);
    } catch (e) {
      // 에러 무시
    }

    if (mounted) setState(() => _isLoading = false);
  }

  List<ApiFootballSquadPlayer> _filterPlayers(List<ApiFootballSquadPlayer> players) {
    if (_searchQuery.isEmpty) return players;
    return players
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MVP 선택',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: _textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchPlayerName,
                  hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.6)),
                  prefixIcon: const Icon(Icons.search, color: _textSecondary),
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              labelColor: _primary,
              unselectedLabelColor: _textSecondary,
              indicatorColor: _primary,
              tabs: [
                Tab(text: widget.homeTeamName ?? AppLocalizations.of(context)!.homeTeam),
                Tab(text: widget.awayTeamName ?? AppLocalizations.of(context)!.awayTeam),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPlayerList(_filterPlayers(_homePlayers)),
                        _buildPlayerList(_filterPlayers(_awayPlayers)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 포지션 약자를 전체 이름으로 변환
  String _getFullPositionName(String? position) {
    if (position == null || position.isEmpty) return '';
    switch (position.toUpperCase()) {
      case 'G':
        return 'Goalkeeper';
      case 'D':
        return 'Defender';
      case 'M':
        return 'Midfielder';
      case 'F':
        return 'Forward';
      case 'GK':
        return 'Goalkeeper';
      case 'DF':
        return 'Defender';
      case 'MF':
        return 'Midfielder';
      case 'FW':
        return 'Forward';
      default:
        return position;
    }
  }

  Widget _buildPlayerList(List<ApiFootballSquadPlayer> players) {
    if (players.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noPlayerInfo,
          style: TextStyle(color: _textSecondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final positionText = _getFullPositionName(player.position);

        return ListTile(
          leading: player.photo != null && player.photo!.isNotEmpty
              ? CircleAvatar(
                  backgroundImage: NetworkImage(player.photo!),
                  backgroundColor: _background,
                )
              : CircleAvatar(
                  backgroundColor: _background,
                  child: Text(
                    player.number?.toString() ?? '',
                    style: const TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
          title: Text(
            player.name,
            style: const TextStyle(color: _textPrimary),
          ),
          subtitle: positionText.isNotEmpty
              ? Text(
                  positionText,
                  style: TextStyle(color: _textSecondary, fontSize: 12),
                )
              : null,
          trailing: player.number != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#${player.number}',
                    style: const TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                )
              : null,
          onTap: () => widget.onPlayerSelected(player),
        );
      },
    );
  }
}

class _TeamSearchSheet extends StatefulWidget {
  final String label;
  final ApiFootballService apiFootballService;
  final Function(ApiFootballTeam) onTeamSelected;
  final List<String> availableLeagues;

  const _TeamSearchSheet({
    required this.label,
    required this.apiFootballService,
    required this.onTeamSelected,
    required this.availableLeagues,
  });

  @override
  State<_TeamSearchSheet> createState() => _TeamSearchSheetState();
}

class _TeamSearchSheetState extends State<_TeamSearchSheet> {
  final _searchController = TextEditingController();
  final _manualTeamNameController = TextEditingController();
  String? _selectedLeague;
  List<ApiFootballTeam> _searchResults = [];
  List<ApiFootballTeam> _leagueTeams = [];
  bool _isSearching = false;
  bool _isLoadingLeagueTeams = false;
  bool _showManualEntry = false;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _background = Color(0xFFF9FAFB);

  @override
  void dispose() {
    _searchController.dispose();
    _manualTeamNameController.dispose();
    super.dispose();
  }

  Future<void> _searchTeams(String query) async {
    if (query.length < 2) return;

    setState(() => _isSearching = true);
    try {
      final teams = await widget.apiFootballService.searchTeams(query);

      final filteredTeams = _selectedLeague != null
          ? teams.where((t) => t.country?.toLowerCase() == _selectedLeague?.toLowerCase()).toList()
          : teams;

      if (mounted) {
        setState(() => _searchResults = filteredTeams);
      }
    } catch (e) {
      // 검색 오류 무시
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _loadLeagueTeams(String leagueName) async {
    setState(() {
      _isLoadingLeagueTeams = true;
      _leagueTeams = [];
    });

    try {
      // 리그 이름으로 API-Football 리그 ID 가져오기
      final leagueId = AppConstants.getLeagueIdByName(leagueName);

      if (leagueId != null) {
        // 현재 시즌 계산 (8월 이후면 현재년도, 아니면 전년도)
        final now = DateTime.now();
        final season = now.month >= 8 ? now.year : now.year - 1;

        final teams = await widget.apiFootballService.getTeamsByLeague(leagueId, season);

        if (mounted) {
          setState(() => _leagueTeams = teams);
        }
      }
    } catch (e) {
      // 로드 오류 무시
    } finally {
      if (mounted) setState(() => _isLoadingLeagueTeams = false);
    }
  }

  void _createManualTeam() {
    final teamName = _manualTeamNameController.text.trim();
    if (teamName.isEmpty) return;

    // 수동 입력된 팀 생성 (임시 ID 사용)
    final manualTeam = ApiFootballTeam(
      id: DateTime.now().millisecondsSinceEpoch,
      name: teamName,
      national: false,
      country: _selectedLeague,
      logo: null,
      venue: null,
    );

    widget.onTeamSelected(manualTeam);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.label} 검색',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _showManualEntry = !_showManualEntry),
                  icon: Icon(
                    _showManualEntry ? Icons.search : Icons.edit,
                    size: 18,
                    color: _primary,
                  ),
                  label: Text(
                    _showManualEntry ? AppLocalizations.of(context)!.switchToSearch : AppLocalizations.of(context)!.switchToManual,
                    style: const TextStyle(color: _primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_showManualEntry) ...[
              Text(
                AppLocalizations.of(context)!.enterTeamNameDirectly,
                style: TextStyle(fontSize: 12, color: _textSecondary),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _manualTeamNameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.teamName,
                    hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.6)),
                    prefixIcon: const Icon(Icons.shield, color: _textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _manualTeamNameController.text.trim().isNotEmpty
                      ? _createManualTeam
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.selectThisTeam),
                ),
              ),
            ] else ...[
              Text(
                AppLocalizations.of(context)!.selectLeague,
                style: TextStyle(fontSize: 12, color: _textSecondary),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.availableLeagues.map((league) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _LeagueFilterChip(
                          label: AppConstants.getLocalizedLeagueName(context, league),
                          isSelected: _selectedLeague == league,
                          onTap: () {
                            setState(() {
                              _selectedLeague = league;
                              _searchController.clear();
                              _searchResults = [];
                            });
                            _loadLeagueTeams(league);
                          },
                        ),
                      )).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.searchByTeamName,
                    hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.6)),
                    prefixIcon: const Icon(Icons.search, color: _textSecondary),
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (value) {
                    if (value.length >= 2) {
                      _searchTeams(value);
                    } else {
                      setState(() => _searchResults = []);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildTeamList(scrollController),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamList(ScrollController scrollController) {
    if (_searchResults.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.searchResults,
            style: TextStyle(fontSize: 12, color: _primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) =>
                  _buildTeamTile(_searchResults[index]),
            ),
          ),
        ],
      );
    }

    if (_isLoadingLeagueTeams) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_leagueTeams.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.leagueTeamList(AppConstants.getLocalizedLeagueName(context, _selectedLeague!)),
            style: TextStyle(fontSize: 12, color: _primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: _leagueTeams.length,
              itemBuilder: (context, index) =>
                  _buildTeamTile(_leagueTeams[index]),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer, size: 48, color: _textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.selectLeagueOrSearchTeam,
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamTile(ApiFootballTeam team) {
    return ListTile(
      leading: team.logo != null
          ? CachedNetworkImage(
              imageUrl: team.logo!,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.shield, size: 40, color: _textSecondary),
            )
          : const Icon(Icons.shield, size: 40, color: _textSecondary),
      title: Text(
        team.name,
        style: const TextStyle(color: _textPrimary),
      ),
      subtitle: Text(
        team.country ?? '',
        style: TextStyle(color: _textSecondary, fontSize: 12),
      ),
      onTap: () => widget.onTeamSelected(team),
    );
  }
}

/// 경기장 검색 시트
class _VenueSearchSheet extends StatefulWidget {
  final ApiFootballService apiFootballService;
  final Function(ApiFootballVenue) onVenueSelected;
  final Function(String) onManualEntry;

  const _VenueSearchSheet({
    required this.apiFootballService,
    required this.onVenueSelected,
    required this.onManualEntry,
  });

  @override
  State<_VenueSearchSheet> createState() => _VenueSearchSheetState();
}

class _VenueSearchSheetState extends State<_VenueSearchSheet> {
  final _searchController = TextEditingController();
  final _manualVenueController = TextEditingController();
  String? _selectedCountry;
  List<ApiFootballVenue> _searchResults = [];
  List<ApiFootballVenue> _countryVenues = [];
  bool _isSearching = false;
  bool _isLoadingCountryVenues = false;
  bool _showManualEntry = false;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _background = Color(0xFFF9FAFB);

  // 주요 국가 목록 (API-Football 국가명 기준) - locale-aware
  List<Map<String, String>> _getCountries(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      {'code': 'South-Korea', 'name': l10n.countryKorea, 'flag': '🇰🇷'},
      {'code': 'England', 'name': l10n.countryEngland, 'flag': '🏴󠁧󠁢󠁥󠁮󠁧󠁿'},
      {'code': 'Spain', 'name': l10n.countrySpain, 'flag': '🇪🇸'},
      {'code': 'Germany', 'name': l10n.countryGermany, 'flag': '🇩🇪'},
      {'code': 'Italy', 'name': l10n.countryItaly, 'flag': '🇮🇹'},
      {'code': 'France', 'name': l10n.countryFrance, 'flag': '🇫🇷'},
      {'code': 'Japan', 'name': l10n.countryJapan, 'flag': '🇯🇵'},
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    _manualVenueController.dispose();
    super.dispose();
  }

  Future<void> _searchVenues(String query) async {
    if (query.length < 2) return;

    setState(() => _isSearching = true);
    try {
      final venues = await widget.apiFootballService.searchVenues(query);
      if (mounted) {
        setState(() => _searchResults = venues);
      }
    } catch (e) {
      // 검색 오류 무시
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _loadCountryVenues(String country) async {
    setState(() {
      _isLoadingCountryVenues = true;
      _countryVenues = [];
    });

    try {
      final venues = await widget.apiFootballService.getVenuesByCountry(country);
      if (mounted) {
        setState(() => _countryVenues = venues);
      }
    } catch (e) {
      // 로드 오류 무시
    } finally {
      if (mounted) setState(() => _isLoadingCountryVenues = false);
    }
  }

  void _submitManualEntry() {
    final venueName = _manualVenueController.text.trim();
    if (venueName.isEmpty) return;
    widget.onManualEntry(venueName);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.venueSearch,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _showManualEntry = !_showManualEntry),
                  icon: Icon(
                    _showManualEntry ? Icons.search : Icons.edit,
                    size: 18,
                    color: _primary,
                  ),
                  label: Text(
                    _showManualEntry ? AppLocalizations.of(context)!.switchToSearch : AppLocalizations.of(context)!.switchToManual,
                    style: const TextStyle(color: _primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_showManualEntry) ...[
              Text(
                AppLocalizations.of(context)!.enterVenueNameDirectly,
                style: TextStyle(fontSize: 12, color: _textSecondary),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _manualVenueController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.venueName,
                    hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.6)),
                    prefixIcon: const Icon(Icons.stadium, color: _textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _manualVenueController.text.trim().isNotEmpty
                      ? _submitManualEntry
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.selectThisVenue),
                ),
              ),
            ] else ...[
              Text(
                AppLocalizations.of(context)!.selectCountry,
                style: TextStyle(fontSize: 12, color: _textSecondary),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _getCountries(context).map((country) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CountryFilterChip(
                      flag: country['flag']!,
                      name: country['name']!,
                      isSelected: _selectedCountry == country['code'],
                      onTap: () {
                        setState(() {
                          _selectedCountry = country['code'];
                          _searchController.clear();
                          _searchResults = [];
                        });
                        _loadCountryVenues(country['code']!);
                      },
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.searchByVenueName,
                    hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.6)),
                    prefixIcon: const Icon(Icons.search, color: _textSecondary),
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (value) {
                    if (value.length >= 2) {
                      _searchVenues(value);
                    } else {
                      setState(() => _searchResults = []);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildVenueList(scrollController),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVenueList(ScrollController scrollController) {
    if (_searchResults.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.searchResults,
            style: TextStyle(fontSize: 12, color: _primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) =>
                  _buildVenueTile(_searchResults[index]),
            ),
          ),
        ],
      );
    }

    if (_isLoadingCountryVenues) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_countryVenues.isNotEmpty) {
      final countryInfo = _getCountries(context).firstWhere(
        (c) => c['code'] == _selectedCountry,
        orElse: () => {'name': _selectedCountry ?? ''},
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.stadiumListForCountry(countryInfo['name'] ?? ''),
            style: TextStyle(fontSize: 12, color: _primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: _countryVenues.length,
              itemBuilder: (context, index) =>
                  _buildVenueTile(_countryVenues[index]),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stadium, size: 48, color: _textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.selectCountryOrSearchVenue,
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueTile(ApiFootballVenue venue) {
    return ListTile(
      leading: venue.image != null
          ? CachedNetworkImage(
              imageUrl: venue.image!,
              width: 50,
              height: 40,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.stadium, size: 40, color: _textSecondary),
            )
          : const Icon(Icons.stadium, size: 40, color: _textSecondary),
      title: Text(
        venue.name ?? AppLocalizations.of(context)!.noName,
        style: const TextStyle(color: _textPrimary),
      ),
      subtitle: venue.city != null
          ? Text(
              venue.city!,
              style: TextStyle(color: _textSecondary, fontSize: 12),
            )
          : null,
      trailing: venue.capacity != null
          ? Text(
              '${venue.capacity}석',
              style: TextStyle(color: _textSecondary, fontSize: 12),
            )
          : null,
      onTap: () => widget.onVenueSelected(venue),
    );
  }
}

class _CountryFilterChip extends StatelessWidget {
  final String flag;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _CountryFilterChip({
    required this.flag,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  static const _primary = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _primary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 날짜 선택 바텀시트 (일정 화면과 동일한 스타일)
class _DatePickerBottomSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateSelected;

  const _DatePickerBottomSheet({
    required this.initialDate,
    required this.lastDate,
    required this.onDateSelected,
  });

  @override
  State<_DatePickerBottomSheet> createState() => _DatePickerBottomSheetState();
}

enum _PickerMode { year, month, day }

class _DatePickerBottomSheetState extends State<_DatePickerBottomSheet> {
  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;
  _PickerMode _mode = _PickerMode.day;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
    _selectedDay = widget.initialDate.day;
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  String _getMonthName(BuildContext context, int month) {
    final l10n = AppLocalizations.of(context)!;
    final months = [
      l10n.monthJan, l10n.monthFeb, l10n.monthMar, l10n.monthApr,
      l10n.monthMay, l10n.monthJun, l10n.monthJul, l10n.monthAug,
      l10n.monthSep, l10n.monthOct, l10n.monthNov, l10n.monthDec,
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 드래그 핸들
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // 헤더 (현재 선택된 날짜 표시 + 모드 전환)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _mode = _PickerMode.year;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.yearMonthFormat(_selectedYear, _selectedMonth),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _mode == _PickerMode.day ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: _textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 1,
                color: _border,
                margin: const EdgeInsets.symmetric(vertical: 12),
              ),
              // 그리드 선택 영역
              SizedBox(
                height: 280,
                child: _buildPickerContent(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: _border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: const TextStyle(
                          color: _textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onSelect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.select,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerContent() {
    switch (_mode) {
      case _PickerMode.year:
        return _buildYearPicker();
      case _PickerMode.month:
        return _buildMonthPicker();
      case _PickerMode.day:
        return _buildDayPicker();
    }
  }

  Widget _buildYearPicker() {
    final currentYear = widget.lastDate.year;
    final years = List.generate(currentYear - 2000 + 1, (i) => currentYear - i); // 현재년도 ~ 2000 (최신순)
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: years.length,
      itemBuilder: (context, index) {
        final year = years[index];
        final isSelected = year == _selectedYear;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedYear = year;
              _mode = _PickerMode.month;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? _primary : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: Text(
              '$year',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : _textPrimary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthPicker() {
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final isSelected = month == _selectedMonth;
        // 미래 월은 비활성화
        final isDisabled = _selectedYear == widget.lastDate.year && month > widget.lastDate.month;
        return GestureDetector(
          onTap: isDisabled ? null : () {
            setState(() {
              _selectedMonth = month;
              // 선택된 일자가 해당 월의 최대 일수보다 크면 조정
              final maxDay = _getDaysInMonth(_selectedYear, _selectedMonth);
              if (_selectedDay > maxDay) _selectedDay = maxDay;
              _mode = _PickerMode.day;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? _primary : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: Text(
              _getMonthName(context, month),
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isDisabled
                    ? _textSecondary.withValues(alpha: 0.4)
                    : (isSelected ? Colors.white : _textPrimary),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayPicker() {
    final daysInMonth = _getDaysInMonth(_selectedYear, _selectedMonth);
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: daysInMonth,
      itemBuilder: (context, index) {
        final day = index + 1;
        final isSelected = day == _selectedDay;
        final isToday = _selectedYear == DateTime.now().year &&
            _selectedMonth == DateTime.now().month &&
            day == DateTime.now().day;
        // 미래 일은 비활성화
        final isDisabled = _selectedYear == widget.lastDate.year &&
            _selectedMonth == widget.lastDate.month &&
            day > widget.lastDate.day;
        return GestureDetector(
          onTap: isDisabled ? null : () {
            setState(() {
              _selectedDay = day;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? _primary
                  : isToday
                      ? _primary.withValues(alpha: 0.2)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.w400,
                color: isDisabled
                    ? _textSecondary.withValues(alpha: 0.4)
                    : (isSelected ? Colors.white : _textPrimary),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onSelect() {
    final selected = DateTime(_selectedYear, _selectedMonth, _selectedDay);
    Navigator.pop(context);
    widget.onDateSelected(selected);
  }
}
