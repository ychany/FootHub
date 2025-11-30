import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/sports_db_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/attendance_record.dart';
import '../providers/attendance_provider.dart';

class AttendanceAddScreen extends ConsumerStatefulWidget {
  final String? matchId;

  const AttendanceAddScreen({super.key, this.matchId});

  @override
  ConsumerState<AttendanceAddScreen> createState() => _AttendanceAddScreenState();
}

class _AttendanceAddScreenState extends ConsumerState<AttendanceAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sportsDbService = SportsDbService();
  final _pageController = PageController();
  int _currentPage = 0;

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

  // 일기 데이터
  double _rating = 3.0;
  MatchMood? _selectedMood;
  String? _selectedWeather;
  SportsDbPlayer? _selectedMvp;
  final List<String> _tags = [];

  // 검색 상태
  bool _isSearching = false;
  List<SportsDbEvent> _searchResults = [];

  // 저장 상태
  bool _isSaving = false;

  // 수동 입력 모드
  bool _isManualMode = false;

  final List<String> _weatherOptions = ['맑음 ☀️', '흐림 ☁️', '비 🌧️', '눈 ❄️', '바람 💨'];

  @override
  void initState() {
    super.initState();
    // matchId가 전달되면 경기 정보를 로드
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMatchInfo = _selectedEvent != null ||
        (_isManualMode && _selectedHomeTeam != null && _selectedAwayTeam != null);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPage == 0 ? '직관 기록' : '직관 일기'),
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
                  : const Text('저장'),
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
                    onPageChanged: (page) => setState(() => _currentPage = page),
                    children: [
                      _buildMatchInfoPage(),
                      _buildDiaryPage(),
                    ],
                  )
                : _buildMatchSelectionPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PageIndicatorDot(
            label: '경기 정보',
            isActive: _currentPage == 0,
            onTap: () => _pageController.animateToPage(0,
                duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
          ),
          Container(width: 40, height: 2, color: Colors.grey.shade300),
          _PageIndicatorDot(
            label: '일기 작성',
            isActive: _currentPage == 1,
            onTap: () => _pageController.animateToPage(1,
                duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
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
          if (_isManualMode) _buildManualEntryForm() else _buildEventSearch(),
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('검색 결과', style: AppTextStyles.subtitle2),
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
            const SizedBox(height: 24),
            _buildScoreInput(),
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
                child: const Text('일기 작성하기 →'),
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
          Text('직관 일기', style: AppTextStyles.subtitle1),
          const SizedBox(height: 8),
          TextFormField(
            controller: _contentController,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: '오늘 경기는 어땠나요? 자유롭게 기록해보세요.',
              alignLabelWithHint: true,
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

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child: _ModeButton(
            icon: Icons.search,
            label: '경기 검색',
            isSelected: !_isManualMode,
            onTap: () => setState(() => _isManualMode = false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ModeButton(
            icon: Icons.edit,
            label: '직접 입력',
            isSelected: _isManualMode,
            onTap: () => setState(() => _isManualMode = true),
          ),
        ),
      ],
    );
  }

  Widget _buildEventSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateSelector(),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '팀 이름으로 검색',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(icon: const Icon(Icons.search), onPressed: _searchEvents),
          ),
          onSubmitted: (_) => _searchEvents(),
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
        Text('리그', style: AppTextStyles.subtitle1),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedLeague,
          decoration: const InputDecoration(hintText: '리그 선택'),
          items: const [
            DropdownMenuItem(value: 'English Premier League', child: Text('프리미어리그')),
            DropdownMenuItem(value: 'Spanish La Liga', child: Text('라리가')),
            DropdownMenuItem(value: 'German Bundesliga', child: Text('분데스리가')),
            DropdownMenuItem(value: 'Italian Serie A', child: Text('세리에 A')),
            DropdownMenuItem(value: 'French Ligue 1', child: Text('리그 1')),
            DropdownMenuItem(value: 'Korean K League 1', child: Text('K리그 1')),
            DropdownMenuItem(value: 'UEFA Champions League', child: Text('챔피언스리그')),
          ],
          onChanged: (value) => setState(() => _selectedLeague = value),
        ),
        const SizedBox(height: 16),
        _buildTeamSearchSection('홈팀', _selectedHomeTeam, (team) => setState(() => _selectedHomeTeam = team)),
        const SizedBox(height: 16),
        _buildTeamSearchSection('원정팀', _selectedAwayTeam, (team) => setState(() => _selectedAwayTeam = team)),
      ],
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: 12),
            Text(DateFormat('yyyy년 M월 d일 (E)', 'ko').format(_selectedDate), style: AppTextStyles.body1),
            const Spacer(),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSearchSection(String label, SportsDbTeam? selectedTeam, Function(SportsDbTeam?) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.subtitle1),
        const SizedBox(height: 8),
        if (selectedTeam != null)
          _buildSelectedTeamChip(selectedTeam, () => onSelect(null))
        else
          TextField(
            decoration: InputDecoration(hintText: '$label 검색', prefixIcon: const Icon(Icons.search)),
            onChanged: (value) async {
              if (value.length >= 2) {
                final teams = await _sportsDbService.searchTeams(value);
                if (mounted && teams.isNotEmpty) _showTeamSelectionDialog(teams, onSelect);
              }
            },
          ),
      ],
    );
  }

  Widget _buildSelectedTeamChip(SportsDbTeam team, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        children: [
          if (team.badge != null)
            Image.network(team.badge!, width: 40, height: 40, errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer, size: 40))
          else
            const Icon(Icons.sports_soccer, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team.name, style: AppTextStyles.subtitle2),
                if (team.league != null) Text(team.league!, style: AppTextStyles.caption),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: onRemove),
        ],
      ),
    );
  }

  Widget _buildSelectedMatchCard() {
    final homeTeam = _selectedEvent?.homeTeam ?? _selectedHomeTeam?.name ?? '';
    final awayTeam = _selectedEvent?.awayTeam ?? _selectedAwayTeam?.name ?? '';
    final league = _selectedEvent?.league ?? _selectedLeague ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(league, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
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
                Expanded(child: Column(children: [
                  const Icon(Icons.sports_soccer, size: 48),
                  const SizedBox(height: 8),
                  Text(homeTeam, style: AppTextStyles.subtitle2, textAlign: TextAlign.center),
                ])),
                const Text('VS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Expanded(child: Column(children: [
                  const Icon(Icons.sports_soccer, size: 48),
                  const SizedBox(height: 8),
                  Text(awayTeam, style: AppTextStyles.subtitle2, textAlign: TextAlign.center),
                ])),
              ],
            ),
            const SizedBox(height: 12),
            Text(DateFormat('yyyy년 M월 d일').format(_selectedDate), style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('스코어', style: AppTextStyles.subtitle1),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _homeScoreController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(hintText: _selectedEvent?.homeTeam ?? _selectedHomeTeam?.name ?? '홈'),
              ),
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text(':', style: TextStyle(fontSize: 24))),
            Expanded(
              child: TextFormField(
                controller: _awayScoreController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(hintText: _selectedEvent?.awayTeam ?? _selectedAwayTeam?.name ?? '원정'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, required String hintText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.subtitle1),
        const SizedBox(height: 8),
        TextFormField(controller: controller, decoration: InputDecoration(hintText: hintText, prefixIcon: Icon(icon))),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('사진', style: AppTextStyles.subtitle1),
        const SizedBox(height: 8),
        Row(
          children: [
            _PhotoAddButton(icon: Icons.camera_alt, label: '카메라', onTap: () => _pickImage(ImageSource.camera)),
            const SizedBox(width: 12),
            _PhotoAddButton(icon: Icons.photo_library, label: '갤러리', onTap: () => _pickImage(ImageSource.gallery)),
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
    );
  }

  Widget _buildPhotoThumbnail(int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_photos[index], width: 100, height: 100, fit: BoxFit.cover)),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _photos.removeAt(index)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('오늘 경기 평점', style: AppTextStyles.subtitle1),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _rating,
                min: 1,
                max: 5,
                divisions: 8,
                label: _rating.toStringAsFixed(1),
                onChanged: (value) => setState(() => _rating = value),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
              child: Text(_rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('최악 😢', style: AppTextStyles.caption),
          Text('최고 🔥', style: AppTextStyles.caption),
        ]),
      ],
    );
  }

  Widget _buildMoodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('오늘의 기분', style: AppTextStyles.subtitle1),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MatchMood.values.map((mood) {
            final isSelected = _selectedMood == mood;
            return GestureDetector(
              onTap: () => setState(() => _selectedMood = mood),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(mood.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 4),
                    Text(mood.label, style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMvpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('오늘의 MVP', style: AppTextStyles.subtitle1),
        const SizedBox(height: 8),
        if (_selectedMvp != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Colors.amber),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedMvp!.name, style: AppTextStyles.subtitle2),
                      Text(_selectedMvp!.team ?? '', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedMvp = null)),
              ],
            ),
          )
        else
          TextField(
            decoration: const InputDecoration(hintText: '선수 이름 검색', prefixIcon: Icon(Icons.person_search)),
            onChanged: (value) async {
              if (value.length >= 2) {
                final players = await _sportsDbService.searchPlayers(value);
                if (mounted && players.isNotEmpty) _showPlayerSelectionDialog(players);
              }
            },
          ),
      ],
    );
  }

  Widget _buildTagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('태그', style: AppTextStyles.subtitle1),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._tags.map((tag) => Chip(
              label: Text('#$tag'),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => setState(() => _tags.remove(tag)),
            )),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _tagController,
                decoration: const InputDecoration(hintText: '태그 추가', isDense: true, border: InputBorder.none, prefixText: '#'),
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
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['승리', '역전', '골잔치', '클린시트', '첫직관', '원정'].map((tag) {
            return ActionChip(
              label: Text('#$tag', style: AppTextStyles.caption),
              onPressed: () {
                if (!_tags.contains(tag)) setState(() => _tags.add(tag));
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoSection() {
    return ExpansionTile(
      title: const Text('추가 정보'),
      tilePadding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 8),
        Text('날씨', style: AppTextStyles.subtitle2),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _weatherOptions.map((weather) {
            final isSelected = _selectedWeather == weather;
            return ChoiceChip(label: Text(weather), selected: isSelected, onSelected: (selected) => setState(() => _selectedWeather = selected ? weather : null));
          }).toList(),
        ),
        const SizedBox(height: 16),
        _buildTextField(controller: _companionController, label: '함께 간 사람', icon: Icons.people, hintText: '예: 친구들, 가족'),
        const SizedBox(height: 16),
        _buildTextField(controller: _ticketPriceController, label: '티켓 가격', icon: Icons.confirmation_number, hintText: '원'),
        const SizedBox(height: 16),
        Text('경기장 음식', style: AppTextStyles.subtitle2),
        const SizedBox(height: 8),
        TextFormField(controller: _foodReviewController, maxLines: 2, decoration: const InputDecoration(hintText: '먹은 음식, 맛 평가 등')),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime.now());
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _searchEvents() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);
    try {
      final events = await _sportsDbService.getEventsByDate(_selectedDate, sport: 'Soccer');
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

  void _selectEvent(SportsDbEvent event) {
    setState(() {
      _selectedEvent = event;
      _stadiumController.text = event.venue ?? '';
      if (event.homeScore != null) _homeScoreController.text = event.homeScore.toString();
      if (event.awayScore != null) _awayScoreController.text = event.awayScore.toString();
      _searchResults = [];
    });
  }

  void _showTeamSelectionDialog(List<SportsDbTeam> teams, Function(SportsDbTeam?) onSelect) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(padding: const EdgeInsets.all(16), child: Text('팀 선택', style: AppTextStyles.headline3)),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: teams.length,
                itemBuilder: (context, index) {
                  final team = teams[index];
                  return ListTile(
                    leading: team.badge != null ? Image.network(team.badge!, width: 40, height: 40, errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer)) : const Icon(Icons.sports_soccer),
                    title: Text(team.name),
                    subtitle: Text(team.league ?? ''),
                    onTap: () {
                      onSelect(team);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlayerSelectionDialog(List<SportsDbPlayer> players) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(padding: const EdgeInsets.all(16), child: Text('MVP 선택', style: AppTextStyles.headline3)),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final player = players[index];
                  return ListTile(
                    leading: player.photo != null ? CircleAvatar(backgroundImage: NetworkImage(player.photo!)) : CircleAvatar(child: Text(player.name.substring(0, 1))),
                    title: Text(player.name),
                    subtitle: Text(player.team ?? ''),
                    onTap: () {
                      setState(() => _selectedMvp = player);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image != null) setState(() => _photos.add(File(image.path)));
  }

  Future<void> _saveRecord() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final homeScore = int.tryParse(_homeScoreController.text);
      final awayScore = int.tryParse(_awayScoreController.text);
      final ticketPrice = int.tryParse(_ticketPriceController.text);
      final now = DateTime.now();

      final record = AttendanceRecord(
        id: '',
        userId: userId,
        date: _selectedDate,
        league: _selectedEvent?.league ?? _selectedLeague ?? '',
        homeTeamId: _selectedEvent?.homeTeamId ?? _selectedHomeTeam?.id ?? '',
        homeTeamName: _selectedEvent?.homeTeam ?? _selectedHomeTeam?.name ?? '',
        homeTeamLogo: _selectedEvent?.homeTeamBadge ?? _selectedHomeTeam?.badge,
        awayTeamId: _selectedEvent?.awayTeamId ?? _selectedAwayTeam?.id ?? '',
        awayTeamName: _selectedEvent?.awayTeam ?? _selectedAwayTeam?.name ?? '',
        awayTeamLogo: _selectedEvent?.awayTeamBadge ?? _selectedAwayTeam?.badge,
        stadium: _stadiumController.text.isNotEmpty ? _stadiumController.text : (_selectedEvent?.venue ?? _selectedHomeTeam?.stadium ?? ''),
        seatInfo: _seatController.text.isEmpty ? null : _seatController.text,
        homeScore: homeScore,
        awayScore: awayScore,
        matchId: _selectedEvent?.id,
        photos: [],
        createdAt: now,
        updatedAt: now,
        diaryTitle: _titleController.text.isEmpty ? null : _titleController.text,
        diaryContent: _contentController.text.isEmpty ? null : _contentController.text,
        rating: _rating,
        mood: _selectedMood,
        mvpPlayerId: _selectedMvp?.id,
        mvpPlayerName: _selectedMvp?.name,
        tags: _tags,
        weather: _selectedWeather,
        companion: _companionController.text.isEmpty ? null : _companionController.text,
        ticketPrice: ticketPrice,
        foodReview: _foodReviewController.text.isEmpty ? null : _foodReviewController.text,
      );

      await ref.read(attendanceNotifierProvider.notifier).addAttendance(record);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('직관 일기가 저장되었습니다!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _PageIndicatorDot extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _PageIndicatorDot({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? AppColors.primary : Colors.grey.shade300),
            child: Icon(isActive ? Icons.check : Icons.circle, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: isActive ? AppColors.primary : Colors.grey, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
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

  const _ModeButton({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: isSelected ? AppColors.primary : Colors.grey.shade100, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.w600)),
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

  const _EventSearchResultCard({required this.event, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      event.league ?? '',
                      style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${event.date ?? ''} ${event.time ?? ''}', style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text(event.homeTeam ?? '', style: AppTextStyles.subtitle2, textAlign: TextAlign.center)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(event.isFinished ? event.scoreDisplay : 'vs', style: AppTextStyles.subtitle1)),
                  Expanded(child: Text(event.awayTeam ?? '', style: AppTextStyles.subtitle2, textAlign: TextAlign.center)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoAddButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoAddButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Column(children: [Icon(icon, color: Colors.grey.shade600), const SizedBox(height: 4), Text(label, style: TextStyle(color: Colors.grey.shade600))]),
        ),
      ),
    );
  }
}
