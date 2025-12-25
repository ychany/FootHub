import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/api_football_service.dart';
import '../../../core/utils/error_helper.dart';
import '../../../shared/services/storage_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/attendance_record.dart';
import '../providers/attendance_provider.dart';

class AttendanceEditScreen extends ConsumerStatefulWidget {
  final String recordId;

  const AttendanceEditScreen({super.key, required this.recordId});

  @override
  ConsumerState<AttendanceEditScreen> createState() =>
      _AttendanceEditScreenState();
}

class _AttendanceEditScreenState extends ConsumerState<AttendanceEditScreen> {
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
  static const _error = Color(0xFFEF4444);

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
  String? _homeTeamLogo;
  String? _awayTeamLogo;
  String _league = '';
  final List<File> _newPhotos = [];
  List<String> _existingPhotos = [];

  // 일기 데이터
  double _rating = 3.0;
  MatchMood? _selectedMood;
  String? _selectedWeather;
  ApiFootballSquadPlayer? _selectedMvp;
  List<String> _tags = [];

  // 응원한 팀 (승/무/패 계산용)
  String? _supportedTeamId;
  String _homeTeamId = '';
  String _awayTeamId = '';

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

  List<String> _getSuggestedTags(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.tagVictory,
      l10n.tagComeback,
      l10n.tagGoalFest,
      l10n.tagCleanSheet,
      l10n.tagFirstMatch,
      l10n.tagAway,
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    try {
      final record =
          await ref.read(attendanceDetailProvider(widget.recordId).future);
      if (record != null && mounted) {
        setState(() {
          _originalRecord = record;
          _selectedDate = record.date;
          _homeTeamName = record.homeTeamName;
          _awayTeamName = record.awayTeamName;
          _homeTeamLogo = record.homeTeamLogo;
          _awayTeamLogo = record.awayTeamLogo;
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
          _ticketPriceController.text = record.ticketPrice != null
              ? NumberFormat('#,###').format(record.ticketPrice)
              : '';
          _foodReviewController.text = record.foodReview ?? '';
          _tags = List.from(record.tags);

          if (record.mvpPlayerId != null && record.mvpPlayerName != null) {
            final mvpId = int.tryParse(record.mvpPlayerId!);
            if (mvpId != null) {
              _selectedMvp = ApiFootballSquadPlayer(
                id: mvpId,
                name: record.mvpPlayerName!,
                position: null,
                number: null,
                photo: null,
                age: null,
              );
            }
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.cannotLoadRecord}: $e')),
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
              AppLocalizations.of(context)!.editMatchRecord,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

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
          title: Builder(builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Text(
              _currentPage == 0 ? l10n.editMatchRecord : l10n.editMatchDiary,
              style: const TextStyle(fontWeight: FontWeight.w600),
            );
          }),
          actions: [
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
            label: AppLocalizations.of(context)!.matchInfo,
            isActive: _currentPage == 0,
            onTap: () => _pageController.animateToPage(0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut),
          ),
          Container(width: 40, height: 2, color: _border),
          _PageIndicatorDot(
            label: AppLocalizations.of(context)!.editDiary,
            isActive: _currentPage == 1,
            onTap: () => _pageController.animateToPage(1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchInfoPage() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMatchCard(),
            const SizedBox(height: 20),
            _buildScoreInput(),
            const SizedBox(height: 16),
            _buildSupportedTeamSelector(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _stadiumController,
              label: l10n.stadium,
              icon: Icons.stadium,
              hintText: l10n.venueName,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _seatController,
              label: l10n.seatInfo,
              icon: Icons.chair,
              hintText: l10n.seatHint,
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
                child: Text(
                  l10n.editDiaryButton,
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
    final l10n = AppLocalizations.of(context)!;
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
            label: l10n.oneLiner,
            icon: Icons.title,
            hintText: l10n.oneLinerHint,
          ),
          const SizedBox(height: 16),
          _buildSectionTitle(l10n.diarySection),
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
                hintText: l10n.diaryHint,
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

  Widget _buildMatchCard() {
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _league,
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                DateFormat('yyyy.MM.dd').format(_selectedDate),
                style: const TextStyle(fontSize: 13, color: _textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLogo(_homeTeamLogo, 48),
                    const SizedBox(height: 8),
                    Text(
                      _homeTeamName,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    _buildTeamLogo(_awayTeamLogo, 48),
                    const SizedBox(height: 8),
                    Text(
                      _awayTeamName,
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
        ],
      ),
    );
  }

  Widget _buildTeamLogo(String? logoUrl, double size) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: logoUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholder: (_, __) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.shield, size: size * 0.5, color: _textSecondary),
        ),
        errorWidget: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.shield, size: size * 0.5, color: _textSecondary),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.shield, size: size * 0.5, color: _textSecondary),
    );
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
                      hintText: _homeTeamName,
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
                      hintText: _awayTeamName,
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
                    AppLocalizations.of(context)!.mySupportedTeam,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.winDrawLossStats,
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
                  teamName: _homeTeamName,
                  teamLogo: _homeTeamLogo,
                  isSelected: _supportedTeamId == _homeTeamId,
                  onTap: () => setState(() => _supportedTeamId = _homeTeamId),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TeamSelectButton(
                  teamName: _awayTeamName,
                  teamLogo: _awayTeamLogo,
                  isSelected: _supportedTeamId == _awayTeamId,
                  onTap: () => setState(() => _supportedTeamId = _awayTeamId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                child:
                    const Icon(Icons.photo_library, size: 18, color: _warning),
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
          if (_existingPhotos.isNotEmpty || _newPhotos.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._existingPhotos.asMap().entries.map(
                      (entry) => _buildExistingPhotoThumbnail(entry.key, entry.value)),
                  ..._newPhotos.asMap().entries
                      .map((entry) => _buildNewPhotoThumbnail(entry.key)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExistingPhotoThumbnail(int index, String url) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: url,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 100,
                height: 100,
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
                decoration:
                    const BoxDecoration(color: _error, shape: BoxShape.circle),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_newPhotos[index],
                width: 100, height: 100, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _newPhotos.removeAt(index)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration:
                    const BoxDecoration(color: _error, shape: BoxShape.circle),
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
                color: _success,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              Text(AppLocalizations.of(context)!.ratingWorst,
                  style: TextStyle(fontSize: 12, color: _textSecondary)),
              Text(AppLocalizations.of(context)!.ratingBest,
                  style: TextStyle(fontSize: 12, color: _textSecondary)),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MatchMood.values.map((mood) {
              final isSelected = _selectedMood == mood;
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = mood),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    decoration: const BoxDecoration(
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
                            style: TextStyle(
                                fontSize: 12, color: _textSecondary),
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
          else if (_homeTeamId.isNotEmpty || _awayTeamId.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => _showTeamPlayersDialog(
                homeTeamId: _homeTeamId.isNotEmpty ? _homeTeamId : null,
                awayTeamId: _awayTeamId.isNotEmpty ? _awayTeamId : null,
                homeTeamName: _homeTeamName,
                awayTeamName: _awayTeamName,
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
                    AppLocalizations.of(context)!.noTeamInfo,
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
    final homeId = homeTeamId != null ? int.tryParse(homeTeamId) : null;
    final awayId = awayTeamId != null ? int.tryParse(awayTeamId) : null;

    showDialog(
      context: context,
      builder: (context) => _TeamPlayersDialog(
        homeTeamId: homeId,
        awayTeamId: awayId,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: _success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '#$tag',
                          style:
                              const TextStyle(color: _success, fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(() => _tags.remove(tag)),
                          child: const Icon(Icons.close,
                              size: 16, color: _success),
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
                    hintText: AppLocalizations.of(context)!.addTagHint,
                    hintStyle: TextStyle(
                        color: _textSecondary.withValues(alpha: 0.6), fontSize: 13),
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
            AppLocalizations.of(context)!.suggestedTagsLabel,
            style: TextStyle(fontSize: 12, color: _textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _getSuggestedTags(context).map((tag) {
              return GestureDetector(
                onTap: () {
                  if (!_tags.contains(tag)) {
                    setState(() => _tags.add(tag));
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              child:
                  const Icon(Icons.more_horiz, size: 18, color: _textSecondary),
            ),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)!.additionalInfoSection,
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
        initiallyExpanded:
            _selectedWeather != null || _companionController.text.isNotEmpty,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        _buildSectionTitle(AppLocalizations.of(context)!.ticketPrice),
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
              hintText: AppLocalizations.of(context)!.priceHint,
              hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.6)),
              prefixIcon: const Icon(Icons.confirmation_number,
                  color: _textSecondary, size: 20),
              suffixText: AppLocalizations.of(context)!.currencyUnit,
              suffixStyle: const TextStyle(color: _textSecondary),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() => _newPhotos.add(File(image.path)));
    }
  }

  Future<void> _saveRecord() async {
    if (_originalRecord == null) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.loginRequired)));
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
        stadium: _stadiumController.text.isNotEmpty
            ? _stadiumController.text
            : _originalRecord!.stadium,
        seatInfo: _seatController.text.isEmpty ? null : _seatController.text,
        homeScore: homeScore,
        awayScore: awayScore,
        photos: allPhotoUrls,
        updatedAt: DateTime.now(),
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

      await ref
          .read(attendanceNotifierProvider.notifier)
          .updateAttendance(updatedRecord);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.saved)));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.saveFailed(ErrorHelper.getLocalizedErrorMessage(context, e)))));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
              Text(label,
                  style: TextStyle(color: _textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamSelectButton extends StatelessWidget {
  final String teamName;
  final String? teamLogo;
  final bool isSelected;
  final VoidCallback onTap;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _background = Color(0xFFF9FAFB);

  const _TeamSelectButton({
    required this.teamName,
    this.teamLogo,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? _primary : _background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _primary : _border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            if (teamLogo != null && teamLogo!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: teamLogo!,
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                placeholder: (_, __) => Icon(
                  Icons.shield,
                  size: 32,
                  color: isSelected ? Colors.white70 : _textSecondary,
                ),
                errorWidget: (_, __, ___) => Icon(
                  Icons.shield,
                  size: 32,
                  color: isSelected ? Colors.white70 : _textSecondary,
                ),
              )
            else
              Icon(
                Icons.shield,
                size: 32,
                color: isSelected ? Colors.white70 : _textSecondary,
              ),
            const SizedBox(height: 8),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
            const SizedBox(height: 4),
            Text(
              teamName,
              style: TextStyle(
                color: isSelected ? Colors.white : _textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamPlayersDialog extends StatefulWidget {
  final int? homeTeamId;
  final int? awayTeamId;
  final String? homeTeamName;
  final String? awayTeamName;
  final ApiFootballService apiFootballService;
  final Function(ApiFootballSquadPlayer) onPlayerSelected;

  const _TeamPlayersDialog({
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
      final futures = <Future>[];

      if (widget.homeTeamId != null) {
        futures.add(widget.apiFootballService
            .getTeamSquad(widget.homeTeamId!)
            .then((players) {
          _homePlayers = players;
        }));
      }

      if (widget.awayTeamId != null) {
        futures.add(widget.apiFootballService
            .getTeamSquad(widget.awayTeamId!)
            .then((players) {
          _awayPlayers = players;
        }));
      }

      await Future.wait(futures);
    } catch (e) {
      // 에러 무시
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
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
                  hintStyle:
                      TextStyle(color: _textSecondary.withValues(alpha: 0.6)),
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
                Tab(text: widget.homeTeamName ?? AppLocalizations.of(context)!.homeShort),
                Tab(text: widget.awayTeamName ?? AppLocalizations.of(context)!.awayShort),
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

  Widget _buildPlayerList(List<ApiFootballSquadPlayer> players) {
    if (players.isEmpty) {
      return Center(
        child: Builder(
          builder: (context) => Text(
            AppLocalizations.of(context)!.noPlayerInfo,
            style: TextStyle(color: _textSecondary),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        return ListTile(
          leading: player.photo != null
              ? CircleAvatar(backgroundImage: NetworkImage(player.photo!))
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
