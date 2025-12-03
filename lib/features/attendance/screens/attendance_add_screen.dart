import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/sports_db_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/services/storage_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/attendance_record.dart';
import '../providers/attendance_provider.dart';

class AttendanceAddScreen extends ConsumerStatefulWidget {
  final String? matchId;

  const AttendanceAddScreen({super.key, this.matchId});

  @override
  ConsumerState<AttendanceAddScreen> createState() =>
      _AttendanceAddScreenState();
}

class _AttendanceAddScreenState extends ConsumerState<AttendanceAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sportsDbService = SportsDbService();
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
  SportsDbEvent? _selectedEvent;
  SportsDbTeam? _selectedHomeTeam;
  SportsDbTeam? _selectedAwayTeam;
  String? _selectedLeague;
  final List<File> _photos = [];

  // 직접 입력용 경기명 (리그명 대신 사용)
  final _matchNameController = TextEditingController();

  // 일기 데이터
  double _rating = 3.0;
  MatchMood? _selectedMood;
  String? _selectedWeather;
  SportsDbPlayer? _selectedMvp;
  final List<String> _tags = [];

  // 응원한 팀 (승/무/패 계산용)
  String? _supportedTeamId;

  // 검색 상태
  bool _isSearching = false;
  List<SportsDbEvent> _searchResults = [];
  String? _searchLeague; // 리그 필터

  // 저장 상태
  bool _isSaving = false;

  // 수동 입력 모드
  bool _isManualMode = false;

  final List<String> _weatherOptions = [
    '맑음 ☀️',
    '흐림 ☁️',
    '비 🌧️',
    '눈 ❄️',
    '바람 💨'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.matchId != null) {
      _loadMatchById(widget.matchId!);
    }
  }

  Future<void> _loadMatchById(String matchId) async {
    final event = await _sportsDbService.getEventById(matchId);
    if (event != null && mounted) {
      setState(() {
        _selectedEvent = event;
        if (event.dateTime != null) {
          _selectedDate = event.dateTime!;
        }
        if (event.homeScore != null) {
          _homeScoreController.text = event.homeScore.toString();
        }
        if (event.awayScore != null) {
          _awayScoreController.text = event.awayScore.toString();
        }
        if (event.venue != null) {
          _stadiumController.text = event.venue!;
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
          title: Text(
            _currentPage == 0 ? '직관 기록' : '직관 일기',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
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
                    : const Text(
                        '저장',
                        style: TextStyle(
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PageIndicatorDot(
            label: '경기 정보',
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
            label: '일기 작성',
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
              '검색 결과',
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
                final event = _searchResults[index];
                return _EventSearchResultCard(
                  event: event,
                  isSelected: _selectedEvent?.id == event.id,
                  onTap: () => _selectEvent(event),
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
            _buildTextField(
              controller: _stadiumController,
              label: '경기장',
              icon: Icons.stadium,
              hintText: '경기장 이름',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _seatController,
              label: '좌석 정보',
              icon: Icons.chair,
              hintText: '예: A블록 12열 34번',
            ),
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
                child: const Text(
                  '일기 작성하기 →',
                  style: TextStyle(fontWeight: FontWeight.w600),
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
          _buildTextField(
            controller: _titleController,
            label: '오늘의 한 줄',
            icon: Icons.title,
            hintText: '경기를 한 줄로 표현한다면?',
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('직관 일기'),
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
                hintText: '오늘 경기는 어땠나요? 자유롭게 기록해보세요.',
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
              label: '경기 검색',
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
              label: '직접 입력',
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
              hintText: '팀 이름으로 검색 (선택사항)',
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
                ? '${DateFormat('MM/dd').format(_selectedDate)} ${AppConstants.getLeagueDisplayName(_searchLeague!)} 경기 조회'
                : '${DateFormat('MM/dd').format(_selectedDate)} 전체 경기 조회'),
          ),
        ),
      ],
    );
  }

  Widget _buildLeagueSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '리그 선택',
          style: TextStyle(fontSize: 12, color: _textSecondary),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _LeagueFilterChip(
                label: '전체',
                isSelected: _searchLeague == null,
                onTap: () => setState(() => _searchLeague = null),
              ),
              const SizedBox(width: 8),
              ...AppConstants.supportedLeagues.map((league) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _LeagueFilterChip(
                      label: AppConstants.getLeagueDisplayName(league),
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
        _buildSectionTitle('경기명'),
        const SizedBox(height: 4),
        Text(
          '예: 친선경기, 프리시즌, FA컵 등',
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
              hintText: '경기명을 입력하세요',
              hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.6)),
              prefixIcon: const Icon(Icons.sports_soccer, color: _textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildTeamSearchWithLeagueFilter('홈팀', _selectedHomeTeam,
            (team) => setState(() => _selectedHomeTeam = team)),
        const SizedBox(height: 16),
        _buildTeamSearchWithLeagueFilter('원정팀', _selectedAwayTeam,
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
              DateFormat('yyyy년 M월 d일 (E)', 'ko').format(_selectedDate),
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
      String label, SportsDbTeam? selectedTeam, Function(SportsDbTeam?) onSelect) {
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
            label: Text('$label 검색'),
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

  void _showTeamSearchSheet(String label, Function(SportsDbTeam?) onSelect) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TeamSearchSheet(
        label: label,
        sportsDbService: _sportsDbService,
        onTeamSelected: (team) {
          onSelect(team);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildSelectedTeamChip(SportsDbTeam team, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (team.badge != null)
            CachedNetworkImage(
              imageUrl: team.badge!,
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
                if (team.league != null)
                  Text(
                    team.league!,
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
        _selectedEvent?.homeTeam ?? _selectedHomeTeam?.name ?? '';
    final awayTeam =
        _selectedEvent?.awayTeam ?? _selectedAwayTeam?.name ?? '';
    final league = _selectedEvent?.league ??
        (_isManualMode ? _matchNameController.text : _selectedLeague) ??
        '';
    final homeBadge =
        _selectedEvent?.homeTeamBadge ?? _selectedHomeTeam?.badge;
    final awayBadge =
        _selectedEvent?.awayTeamBadge ?? _selectedAwayTeam?.badge;

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
            DateFormat('yyyy년 M월 d일').format(_selectedDate),
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
              const Text(
                '스코어',
                style: TextStyle(
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
                          _selectedEvent?.homeTeam ?? _selectedHomeTeam?.name ?? '홈',
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
                          _selectedEvent?.awayTeam ?? _selectedAwayTeam?.name ?? '원정',
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
        _selectedEvent?.homeTeamId ?? _selectedHomeTeam?.id ?? '';
    final homeTeamName =
        _selectedEvent?.homeTeam ?? _selectedHomeTeam?.name ?? '홈팀';
    final awayTeamId =
        _selectedEvent?.awayTeamId ?? _selectedAwayTeam?.id ?? '';
    final awayTeamName =
        _selectedEvent?.awayTeam ?? _selectedAwayTeam?.name ?? '원정팀';

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
                  const Text(
                    '내가 응원한 팀',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  Text(
                    '승/무/패 통계에 반영됩니다',
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
              const Text(
                '사진',
                style: TextStyle(
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
                label: '카메라',
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(width: 12),
              _PhotoAddButton(
                icon: Icons.photo_library,
                label: '갤러리',
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
              const Text(
                '오늘 경기 평점',
                style: TextStyle(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('최악 😢', style: TextStyle(fontSize: 12, color: _textSecondary)),
              Text('최고 🔥', style: TextStyle(fontSize: 12, color: _textSecondary)),
            ],
          ),
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
              const Text(
                '오늘의 기분',
                style: TextStyle(
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
                        mood.label,
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
          ),
        ],
      ),
    );
  }

  Widget _buildMvpSection() {
    final homeTeamId = _selectedEvent?.homeTeamId ?? _selectedHomeTeam?.id;
    final awayTeamId = _selectedEvent?.awayTeamId ?? _selectedAwayTeam?.id;
    final homeTeamName = _selectedEvent?.homeTeam ?? _selectedHomeTeam?.name;
    final awayTeamName = _selectedEvent?.awayTeam ?? _selectedAwayTeam?.name;

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
              const Text(
                '오늘의 MVP',
                style: TextStyle(
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
                        if (_selectedMvp!.team != null)
                          Text(
                            _selectedMvp!.team!,
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
                homeTeamId: homeTeamId,
                awayTeamId: awayTeamId,
                homeTeamName: homeTeamName,
                awayTeamName: awayTeamName,
              ),
              icon: const Icon(Icons.person_search, size: 18),
              label: const Text('선수 선택'),
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
                    '먼저 경기를 선택해주세요',
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
    String? homeTeamId,
    String? awayTeamId,
    String? homeTeamName,
    String? awayTeamName,
  }) async {
    showDialog(
      context: context,
      builder: (context) => _TeamPlayersDialog(
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
        homeTeamName: homeTeamName,
        awayTeamName: awayTeamName,
        sportsDbService: _sportsDbService,
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
              const Text(
                '태그',
                style: TextStyle(
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
                    hintText: '태그 추가',
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
          Text(
            '추천 태그',
            style: TextStyle(fontSize: 12, color: _textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['승리', '역전', '골잔치', '클린시트', '첫직관', '원정'].map((tag) {
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
            const Text(
              '추가 정보',
              style: TextStyle(
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
          _buildSectionTitle('날씨'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _weatherOptions.map((weather) {
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
            label: '함께 간 사람',
            icon: Icons.people,
            hintText: '예: 친구들, 가족',
          ),
          const SizedBox(height: 16),
          _buildTicketPriceField(),
          const SizedBox(height: 16),
          _buildSectionTitle('경기장 음식'),
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
                hintText: '먹은 음식, 맛 평가 등',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('티켓 가격'),
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
              hintText: '예: 50,000',
              hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.6)),
              prefixIcon:
                  const Icon(Icons.confirmation_number, color: _textSecondary, size: 20),
              suffixText: '원',
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

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _searchEvents() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _searchEventsByDateAndLeague();
      return;
    }

    setState(() => _isSearching = true);
    try {
      final events = await _sportsDbService.getEventsByDate(
        _selectedDate,
        sport: 'Soccer',
        league: _searchLeague,
      );
      final filtered = events.where((event) {
        final searchLower = query.toLowerCase();
        return (event.homeTeam?.toLowerCase().contains(searchLower) ?? false) ||
            (event.awayTeam?.toLowerCase().contains(searchLower) ?? false);
      }).toList();

      if (filtered.isEmpty) {
        final searchEvents = await _sportsDbService.searchEvents(query);
        setState(() => _searchResults = searchEvents.take(10).toList());
      } else {
        setState(() => _searchResults = filtered);
      }
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _searchEventsByDateAndLeague() async {
    setState(() => _isSearching = true);
    try {
      final events = await _sportsDbService.getEventsByDate(
        _selectedDate,
        sport: 'Soccer',
        league: _searchLeague,
      );
      setState(() => _searchResults = events);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _selectEvent(SportsDbEvent event) {
    setState(() {
      _selectedEvent = event;
      _stadiumController.text = event.venue ?? '';
      if (event.homeScore != null) {
        _homeScoreController.text = event.homeScore.toString();
      }
      if (event.awayScore != null) {
        _awayScoreController.text = event.awayScore.toString();
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('로그인이 필요합니다')));
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
        league: _selectedEvent?.league ??
            (_isManualMode ? _matchNameController.text : _selectedLeague) ??
            '',
        homeTeamId: _selectedEvent?.homeTeamId ?? _selectedHomeTeam?.id ?? '',
        homeTeamName:
            _selectedEvent?.homeTeam ?? _selectedHomeTeam?.name ?? '',
        homeTeamLogo:
            _selectedEvent?.homeTeamBadge ?? _selectedHomeTeam?.badge,
        awayTeamId: _selectedEvent?.awayTeamId ?? _selectedAwayTeam?.id ?? '',
        awayTeamName:
            _selectedEvent?.awayTeam ?? _selectedAwayTeam?.name ?? '',
        awayTeamLogo:
            _selectedEvent?.awayTeamBadge ?? _selectedAwayTeam?.badge,
        stadium: _stadiumController.text.isNotEmpty
            ? _stadiumController.text
            : (_selectedEvent?.venue ?? _selectedHomeTeam?.stadium ?? ''),
        seatInfo: _seatController.text.isEmpty ? null : _seatController.text,
        homeScore: homeScore,
        awayScore: awayScore,
        matchId: _selectedEvent?.id,
        photos: photoUrls,
        createdAt: now,
        updatedAt: now,
        diaryTitle:
            _titleController.text.isEmpty ? null : _titleController.text,
        diaryContent:
            _contentController.text.isEmpty ? null : _contentController.text,
        rating: _rating,
        mood: _selectedMood,
        mvpPlayerId: _selectedMvp?.id,
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('직관 일기가 저장되었습니다!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('저장 실패: $e')));
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
  final SportsDbEvent event;
  final bool isSelected;
  final VoidCallback onTap;

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _EventSearchResultCard({
    required this.event,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                      event.league ?? '',
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
                  '${event.date ?? ''} ${event.time ?? ''}',
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
                      _buildBadge(event.homeTeamBadge, 32),
                      const SizedBox(height: 4),
                      Text(
                        event.homeTeam ?? '',
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
                    event.isFinished ? event.scoreDisplay : 'vs',
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
                      _buildBadge(event.awayTeamBadge, 32),
                      const SizedBox(height: 4),
                      Text(
                        event.awayTeam ?? '',
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
  final String? homeTeamId;
  final String? awayTeamId;
  final String? homeTeamName;
  final String? awayTeamName;
  final SportsDbService sportsDbService;
  final Function(SportsDbPlayer) onPlayerSelected;

  const _TeamPlayersDialog({
    this.homeTeamId,
    this.awayTeamId,
    this.homeTeamName,
    this.awayTeamName,
    required this.sportsDbService,
    required this.onPlayerSelected,
  });

  @override
  State<_TeamPlayersDialog> createState() => _TeamPlayersDialogState();
}

class _TeamPlayersDialogState extends State<_TeamPlayersDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SportsDbPlayer> _homePlayers = [];
  List<SportsDbPlayer> _awayPlayers = [];
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
      final futures = <Future>[];

      if (widget.homeTeamId != null) {
        futures.add(
            widget.sportsDbService.getPlayersByTeam(widget.homeTeamId!).then((players) {
          _homePlayers = players;
        }));
      }

      if (widget.awayTeamId != null) {
        futures.add(
            widget.sportsDbService.getPlayersByTeam(widget.awayTeamId!).then((players) {
          _awayPlayers = players;
        }));
      }

      await Future.wait(futures);
    } catch (e) {
      // 에러 무시
    }

    if (mounted) setState(() => _isLoading = false);
  }

  List<SportsDbPlayer> _filterPlayers(List<SportsDbPlayer> players) {
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
                  hintText: '선수 이름 검색',
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
                Tab(text: widget.homeTeamName ?? '홈팀'),
                Tab(text: widget.awayTeamName ?? '원정팀'),
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

  Widget _buildPlayerList(List<SportsDbPlayer> players) {
    if (players.isEmpty) {
      return Center(
        child: Text(
          '선수 정보가 없습니다',
          style: TextStyle(color: _textSecondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        return ListTile(
          leading: player.thumb != null
              ? CircleAvatar(backgroundImage: NetworkImage(player.thumb!))
              : CircleAvatar(
                  backgroundColor: _background,
                  child: const Icon(Icons.person, color: _textSecondary),
                ),
          title: Text(
            player.name,
            style: const TextStyle(color: _textPrimary),
          ),
          subtitle: Text(
            player.position ?? '',
            style: TextStyle(color: _textSecondary, fontSize: 12),
          ),
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
  final SportsDbService sportsDbService;
  final Function(SportsDbTeam) onTeamSelected;

  const _TeamSearchSheet({
    required this.label,
    required this.sportsDbService,
    required this.onTeamSelected,
  });

  @override
  State<_TeamSearchSheet> createState() => _TeamSearchSheetState();
}

class _TeamSearchSheetState extends State<_TeamSearchSheet> {
  final _searchController = TextEditingController();
  final _manualTeamNameController = TextEditingController();
  String? _selectedLeague;
  List<SportsDbTeam> _searchResults = [];
  List<SportsDbTeam> _leagueTeams = [];
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
      final teams = await widget.sportsDbService.searchTeams(query);

      final filteredTeams = _selectedLeague != null
          ? teams.where((t) => t.league == _selectedLeague).toList()
          : teams;

      if (mounted) {
        setState(() => _searchResults = filteredTeams);
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _loadLeagueTeams(String leagueId) async {
    setState(() {
      _isLoadingLeagueTeams = true;
      _leagueTeams = [];
    });

    try {
      final teams = await widget.sportsDbService.getTeamsByLeague(leagueId);
      if (mounted) {
        setState(() => _leagueTeams = teams);
      }
    } finally {
      if (mounted) setState(() => _isLoadingLeagueTeams = false);
    }
  }

  void _createManualTeam() {
    final teamName = _manualTeamNameController.text.trim();
    if (teamName.isEmpty) return;

    final manualTeam = SportsDbTeam(
      id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      name: teamName,
      league: _selectedLeague,
      badge: null,
      stadium: null,
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
                    _showManualEntry ? '검색으로' : '직접 입력',
                    style: const TextStyle(color: _primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_showManualEntry) ...[
              Text(
                '팀 이름을 직접 입력하세요',
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
                    hintText: '팀 이름',
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
                  child: const Text('이 팀으로 선택'),
                ),
              ),
            ] else ...[
              Text(
                '리그 선택',
                style: TextStyle(fontSize: 12, color: _textSecondary),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: AppConstants.supportedLeagues.map((league) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _LeagueFilterChip(
                          label: AppConstants.getLeagueDisplayName(league),
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
                    hintText: '팀 이름으로 검색',
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
            '검색 결과',
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
            '${AppConstants.getLeagueDisplayName(_selectedLeague!)} 팀 목록',
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
            '리그를 선택하거나\n팀 이름을 검색하세요',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamTile(SportsDbTeam team) {
    return ListTile(
      leading: team.badge != null
          ? CachedNetworkImage(
              imageUrl: team.badge!,
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
        team.league ?? '',
        style: TextStyle(color: _textSecondary, fontSize: 12),
      ),
      onTap: () => widget.onTeamSelected(team),
    );
  }
}
