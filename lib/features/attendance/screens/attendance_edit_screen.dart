import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/sports_db_service.dart';
import '../../../shared/services/storage_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/attendance_record.dart';
import '../providers/attendance_provider.dart';

class AttendanceEditScreen extends ConsumerStatefulWidget {
  final String recordId;

  const AttendanceEditScreen({super.key, required this.recordId});

  @override
  ConsumerState<AttendanceEditScreen> createState() => _AttendanceEditScreenState();
}

class _AttendanceEditScreenState extends ConsumerState<AttendanceEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sportsDbService = SportsDbService();
  final _pageController = PageController();
  int _currentPage = 0;

  // 기본 정보 컨트롤러
  final _seatController = TextEditingController();
  final _homeScoreController = TextEditingController();
  final _awayScoreController = TextEditingController();
  final _stadiumController = TextEditingController();

  // 일기 컨트롤러
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final _companionController = TextEditingController();
  final _ticketPriceController = TextEditingController();
  final _foodReviewController = TextEditingController();

  // 로딩 상태
  bool _isLoading = true;
  bool _isSaving = false;
  AttendanceRecord? _originalRecord;

  // 선택된 데이터
  DateTime _selectedDate = DateTime.now();
  String _homeTeamName = '';
  String _awayTeamName = '';
  String _league = '';
  final List<File> _newPhotos = [];
  List<String> _existingPhotos = [];

  // 일기 데이터
  double _rating = 3.0;
  MatchMood? _selectedMood;
  String? _selectedWeather;
  SportsDbPlayer? _selectedMvp;
  List<String> _tags = [];

  // 응원한 팀 (승/무/패 계산용)
  String? _supportedTeamId;
  String _homeTeamId = '';
  String _awayTeamId = '';

  final List<String> _weatherOptions = ['맑음 ☀️', '흐림 ☁️', '비 🌧️', '눈 ❄️', '바람 💨'];

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    try {
      final record = await ref.read(attendanceDetailProvider(widget.recordId).future);
      if (record != null && mounted) {
        setState(() {
          _originalRecord = record;
          _selectedDate = record.date;
          _homeTeamName = record.homeTeamName;
          _awayTeamName = record.awayTeamName;
          _homeTeamId = record.homeTeamId;
          _awayTeamId = record.awayTeamId;
          _supportedTeamId = record.supportedTeamId;
          _league = record.league;
          _stadiumController.text = record.stadium;
          _seatController.text = record.seatInfo ?? '';
          _homeScoreController.text = record.homeScore?.toString() ?? '';
          _awayScoreController.text = record.awayScore?.toString() ?? '';
          _existingPhotos = List.from(record.photos);

          // 일기 데이터
          _titleController.text = record.diaryTitle ?? '';
          _contentController.text = record.diaryContent ?? '';
          _rating = record.rating ?? 3.0;
          _selectedMood = record.mood;
          _selectedWeather = record.weather;
          _companionController.text = record.companion ?? '';
          _ticketPriceController.text = record.ticketPrice?.toString() ?? '';
          _foodReviewController.text = record.foodReview ?? '';
          _tags = List.from(record.tags);

          if (record.mvpPlayerId != null && record.mvpPlayerName != null) {
            _selectedMvp = SportsDbPlayer(
              id: record.mvpPlayerId!,
              name: record.mvpPlayerName!,
            );
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('기록을 불러올 수 없습니다: $e')),
        );
        context.pop();
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _seatController.dispose();
    _homeScoreController.dispose();
    _awayScoreController.dispose();
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('직관 기록 수정')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPage == 0 ? '직관 기록 수정' : '직관 일기 수정'),
        actions: [
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
          _buildPageIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildMatchInfoPage(),
                _buildDiaryPage(),
              ],
            ),
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
            label: '일기 수정',
            isActive: _currentPage == 1,
            onTap: () => _pageController.animateToPage(1,
                duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
          ),
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
            _buildMatchCard(),
            const SizedBox(height: 24),
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
                child: const Text('일기 수정하기 →'),
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
            decoration: InputDecoration(
              hintText: '오늘 경기는 어땠나요? 자유롭게 기록해보세요.',
              hintStyle: TextStyle(color: Colors.grey.shade400),
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

  Widget _buildMatchCard() {
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
                  child: Text(_league, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                ),
                Text(
                  DateFormat('yyyy.MM.dd').format(_selectedDate),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Column(children: [
                  const Icon(Icons.sports_soccer, size: 48),
                  const SizedBox(height: 8),
                  Text(_homeTeamName, style: AppTextStyles.subtitle2, textAlign: TextAlign.center),
                ])),
                const Text('VS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Expanded(child: Column(children: [
                  const Icon(Icons.sports_soccer, size: 48),
                  const SizedBox(height: 8),
                  Text(_awayTeamName, style: AppTextStyles.subtitle2, textAlign: TextAlign.center),
                ])),
              ],
            ),
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
                decoration: InputDecoration(hintText: _homeTeamName),
              ),
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text(':', style: TextStyle(fontSize: 24))),
            Expanded(
              child: TextFormField(
                controller: _awayScoreController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(hintText: _awayTeamName),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSupportedTeamSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('내가 응원한 팀', style: AppTextStyles.subtitle1),
        const SizedBox(height: 4),
        Text('승/무/패 통계에 반영됩니다', style: AppTextStyles.caption.copyWith(color: Colors.grey)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _TeamSelectButton(
                teamName: _homeTeamName,
                isSelected: _supportedTeamId == _homeTeamId,
                onTap: () => setState(() => _supportedTeamId = _homeTeamId),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TeamSelectButton(
                teamName: _awayTeamName,
                isSelected: _supportedTeamId == _awayTeamId,
                onTap: () => setState(() => _supportedTeamId = _awayTeamId),
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
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(icon),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('티켓 가격', style: AppTextStyles.subtitle1),
        const SizedBox(height: 8),
        TextFormField(
          controller: _ticketPriceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '예: 50,000',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: const Icon(Icons.confirmation_number),
            suffixText: '원',
          ),
          onChanged: (value) {
            // 숫자만 추출
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
        if (_existingPhotos.isNotEmpty || _newPhotos.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // 기존 사진
                ..._existingPhotos.asMap().entries.map((entry) => _buildExistingPhotoThumbnail(entry.key, entry.value)),
                // 새 사진
                ..._newPhotos.asMap().entries.map((entry) => _buildNewPhotoThumbnail(entry.key)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExistingPhotoThumbnail(int index, String url) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(url, width: 100, height: 100, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 100, height: 100,
                color: Colors.grey.shade300,
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _existingPhotos.removeAt(index)),
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

  Widget _buildNewPhotoThumbnail(int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_newPhotos[index], width: 100, height: 100, fit: BoxFit.cover)),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _newPhotos.removeAt(index)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                      if (_selectedMvp!.team != null)
                        Text(_selectedMvp!.team!, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedMvp = null)),
              ],
            ),
          )
        else if (_homeTeamId.isNotEmpty || _awayTeamId.isNotEmpty)
          // 경기가 있는 경우: 두 팀 선수 중에서 선택
          OutlinedButton.icon(
            onPressed: () => _showTeamPlayersDialog(
              homeTeamId: _homeTeamId.isNotEmpty ? _homeTeamId : null,
              awayTeamId: _awayTeamId.isNotEmpty ? _awayTeamId : null,
              homeTeamName: _homeTeamName,
              awayTeamName: _awayTeamName,
            ),
            icon: const Icon(Icons.person_search),
            label: const Text('선수 선택'),
          )
        else
          TextField(
            decoration: InputDecoration(
              hintText: '선수 이름 검색',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: const Icon(Icons.person_search),
            ),
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
              label: Text('#$tag', style: const TextStyle(color: Colors.black87)),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => setState(() => _tags.remove(tag)),
            )),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: '태그 추가',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  isDense: true,
                  border: InputBorder.none,
                  prefixText: '#',
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
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['승리', '역전', '골잔치', '클린시트', '첫직관', '원정'].map((tag) {
            return ActionChip(
              label: Text('#$tag', style: AppTextStyles.caption.copyWith(color: Colors.black87)),
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
      initiallyExpanded: _selectedWeather != null || _companionController.text.isNotEmpty,
      children: [
        const SizedBox(height: 8),
        Text('날씨', style: AppTextStyles.subtitle2),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _weatherOptions.map((weather) {
            final isSelected = _selectedWeather == weather;
            return ChoiceChip(
              label: Text(weather, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
              selected: isSelected,
              onSelected: (selected) => setState(() => _selectedWeather = selected ? weather : null),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _buildTextField(controller: _companionController, label: '함께 간 사람', icon: Icons.people, hintText: '예: 친구들, 가족'),
        const SizedBox(height: 16),
        _buildTicketPriceField(),
        const SizedBox(height: 16),
        Text('경기장 음식', style: AppTextStyles.subtitle2),
        const SizedBox(height: 8),
        TextFormField(
          controller: _foodReviewController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: '먹은 음식, 맛 평가 등',
            hintStyle: TextStyle(color: Colors.grey.shade400),
          ),
        ),
      ],
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
    if (image != null) setState(() => _newPhotos.add(File(image.path)));
  }

  Future<void> _saveRecord() async {
    if (_originalRecord == null) return;

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

      // 새 사진 업로드
      List<String> allPhotoUrls = List.from(_existingPhotos);
      if (_newPhotos.isNotEmpty) {
        final storageService = StorageService();
        final newUrls = await storageService.uploadAttendancePhotos(
          userId: userId,
          recordId: _originalRecord!.id,
          files: _newPhotos,
        );
        allPhotoUrls.addAll(newUrls);
      }

      final updatedRecord = _originalRecord!.copyWith(
        stadium: _stadiumController.text.isNotEmpty ? _stadiumController.text : _originalRecord!.stadium,
        seatInfo: _seatController.text.isEmpty ? null : _seatController.text,
        homeScore: homeScore,
        awayScore: awayScore,
        photos: allPhotoUrls,
        updatedAt: DateTime.now(),
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
        supportedTeamId: _supportedTeamId,
      );

      await ref.read(attendanceNotifierProvider.notifier).updateAttendance(updatedRecord);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('수정되었습니다!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('수정 실패: $e')));
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

class _TeamSelectButton extends StatelessWidget {
  final String teamName;
  final bool isSelected;
  final VoidCallback onTap;

  const _TeamSelectButton({
    required this.teamName,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.check_circle, color: Colors.white, size: 20),
              ),
            Flexible(
              child: Text(
                teamName,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

class _TeamPlayersDialogState extends State<_TeamPlayersDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SportsDbPlayer> _homePlayers = [];
  List<SportsDbPlayer> _awayPlayers = [];
  bool _isLoading = true;
  String _searchQuery = '';

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
        futures.add(widget.sportsDbService.getPlayersByTeam(widget.homeTeamId!).then((players) {
          _homePlayers = players;
        }));
      }

      if (widget.awayTeamId != null) {
        futures.add(widget.sportsDbService.getPlayersByTeam(widget.awayTeamId!).then((players) {
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
    return players.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('MVP 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: '선수 이름 검색',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
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
      return const Center(child: Text('선수 정보가 없습니다'));
    }

    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        return ListTile(
          leading: player.thumb != null
              ? CircleAvatar(backgroundImage: NetworkImage(player.thumb!))
              : const CircleAvatar(child: Icon(Icons.person)),
          title: Text(player.name, style: const TextStyle(color: Colors.black87)),
          subtitle: Text(player.position ?? '', style: TextStyle(color: Colors.grey.shade600)),
          trailing: player.number != null ? Text('#${player.number}') : null,
          onTap: () => widget.onPlayerSelected(player),
        );
      },
    );
  }
}
