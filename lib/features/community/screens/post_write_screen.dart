import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../providers/community_provider.dart';
import '../models/post_model.dart';
import '../../attendance/models/attendance_record.dart';
import '../../attendance/providers/attendance_provider.dart';

class PostWriteScreen extends ConsumerStatefulWidget {
  final Post? editPost;

  const PostWriteScreen({super.key, this.editPost});

  @override
  ConsumerState<PostWriteScreen> createState() => _PostWriteScreenState();
}

class _PostWriteScreenState extends ConsumerState<PostWriteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final List<String> _tags = [];
  bool _isLoading = false;
  AttendanceRecord? _selectedRecord;

  // 수정 모드에서 직관 기록 정보를 직접 저장
  String? _attendanceId;
  String? _homeTeamName;
  String? _awayTeamName;
  String? _homeTeamLogo;
  String? _awayTeamLogo;
  int? _homeScore;
  int? _awayScore;
  DateTime? _matchDate;
  String? _stadium;
  String? _league;

  bool get isEditMode => widget.editPost != null;
  bool get hasAttendanceData => _attendanceId != null || _selectedRecord != null;

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _background = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    if (widget.editPost != null) {
      final post = widget.editPost!;
      _titleController.text = post.title;
      _contentController.text = post.content;
      _tags.addAll(post.tags);

      // 직관 기록 정보 복원
      if (post.hasAttendanceRecord) {
        _attendanceId = post.attendanceId;
        _homeTeamName = post.homeTeamName;
        _awayTeamName = post.awayTeamName;
        _homeTeamLogo = post.homeTeamLogo;
        _awayTeamLogo = post.awayTeamLogo;
        _homeScore = post.homeScore;
        _awayScore = post.awayScore;
        _matchDate = post.matchDate;
        _stadium = post.stadium;
        _league = post.league;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요')),
      );
      return;
    }

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ref.read(communityServiceProvider);

      // 직관 기록 데이터 결정 (새로 선택한 것 우선, 없으면 기존 데이터 사용)
      final attendanceId = _selectedRecord?.id ?? _attendanceId;
      final homeTeamName = _selectedRecord?.homeTeamName ?? _homeTeamName;
      final awayTeamName = _selectedRecord?.awayTeamName ?? _awayTeamName;
      final homeTeamLogo = _selectedRecord?.homeTeamLogo ?? _homeTeamLogo;
      final awayTeamLogo = _selectedRecord?.awayTeamLogo ?? _awayTeamLogo;
      final homeScore = _selectedRecord?.homeScore ?? _homeScore;
      final awayScore = _selectedRecord?.awayScore ?? _awayScore;
      final matchDate = _selectedRecord?.date ?? _matchDate;
      final stadium = _selectedRecord?.stadium ?? _stadium;
      final league = _selectedRecord?.league ?? _league;

      if (isEditMode) {
        await service.updatePost(
          postId: widget.editPost!.id,
          title: title,
          content: content,
          tags: _tags,
          attendanceId: attendanceId,
          homeTeamName: homeTeamName,
          awayTeamName: awayTeamName,
          homeTeamLogo: homeTeamLogo,
          awayTeamLogo: awayTeamLogo,
          homeScore: homeScore,
          awayScore: awayScore,
          matchDate: matchDate,
          stadium: stadium,
          league: league,
          clearAttendance: !hasAttendanceData && widget.editPost!.hasAttendanceRecord,
        );
      } else {
        await service.createPost(
          title: title,
          content: content,
          tags: _tags,
          attendanceId: attendanceId,
          homeTeamName: homeTeamName,
          awayTeamName: awayTeamName,
          homeTeamLogo: homeTeamLogo,
          awayTeamLogo: awayTeamLogo,
          homeScore: homeScore,
          awayScore: awayScore,
          matchDate: matchDate,
          stadium: stadium,
          league: league,
        );
      }

      ref.read(postsNotifierProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditMode ? '게시글이 수정되었습니다' : '게시글이 작성되었습니다')),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag) && _tags.length < 5) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _showAttendanceSelector() {
    final attendanceAsync = ref.read(attendanceListProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 핸들
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 헤더
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text(
                      '직관 기록 선택',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedRecord != null)
                      TextButton(
                        onPressed: () {
                          setState(() => _selectedRecord = null);
                          Navigator.pop(context);
                        },
                        child: const Text('선택 해제'),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 리스트
              Expanded(
                child: attendanceAsync.when(
                  data: (records) {
                    if (records.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.stadium_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              '직관 기록이 없습니다',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final record = records[index];
                        final isSelected = _selectedRecord?.id == record.id;
                        return _AttendanceItem(
                          record: record,
                          isSelected: isSelected,
                          onTap: () {
                            _selectAttendance(record);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('오류: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectAttendance(AttendanceRecord record) {
    setState(() {
      _selectedRecord = record;
      // 기존 직관 기록 정보 초기화
      _attendanceId = null;
      _homeTeamName = null;
      _awayTeamName = null;
      _homeTeamLogo = null;
      _awayTeamLogo = null;
      _homeScore = null;
      _awayScore = null;
      _matchDate = null;
      _stadium = null;
      _league = null;
    });
  }

  void _clearAttendance() {
    setState(() {
      _selectedRecord = null;
      _attendanceId = null;
      _homeTeamName = null;
      _awayTeamName = null;
      _homeTeamLogo = null;
      _awayTeamLogo = null;
      _homeScore = null;
      _awayScore = null;
      _matchDate = null;
      _stadium = null;
      _league = null;
    });
  }

  // 현재 표시할 직관 기록 정보 헬퍼
  String get _displayHomeTeamName => _selectedRecord?.homeTeamName ?? _homeTeamName ?? '';
  String get _displayAwayTeamName => _selectedRecord?.awayTeamName ?? _awayTeamName ?? '';
  String? get _displayHomeTeamLogo => _selectedRecord?.homeTeamLogo ?? _homeTeamLogo;
  String? get _displayAwayTeamLogo => _selectedRecord?.awayTeamLogo ?? _awayTeamLogo;
  String get _displayScoreDisplay {
    final home = _selectedRecord?.homeScore ?? _homeScore;
    final away = _selectedRecord?.awayScore ?? _awayScore;
    if (home == null || away == null) return '-';
    return '$home : $away';
  }
  DateTime? get _displayMatchDate => _selectedRecord?.date ?? _matchDate;
  String get _displayStadium => _selectedRecord?.stadium ?? _stadium ?? '';

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: _textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text(
            isEditMode ? '글 수정' : '글쓰기',
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _isLoading ? null : _submitPost,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        '등록',
                        style: TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목 입력
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: '제목을 입력하세요',
                    hintStyle: TextStyle(color: _textSecondary),
                    border: InputBorder.none,
                  ),
                  maxLength: 100,
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                ),
              ),

              Divider(height: 1, color: _border),

              // 직관 기록 카드 (선택된 경우)
              if (hasAttendanceData) ...[
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.stadium_rounded, color: _primary, size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            '직관 기록',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _textSecondary,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _clearAttendance,
                            child: const Icon(Icons.close, size: 18, color: _textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primary, _primary.withValues(alpha: 0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            // 팀 vs 팀
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      if (_displayHomeTeamLogo != null)
                                        CachedNetworkImage(
                                          imageUrl: _displayHomeTeamLogo!,
                                          width: 40,
                                          height: 40,
                                          placeholder: (_, __) => const Icon(Icons.shield, color: Colors.white54, size: 40),
                                          errorWidget: (_, __, ___) => const Icon(Icons.shield, color: Colors.white54, size: 40),
                                        )
                                      else
                                        const Icon(Icons.shield, color: Colors.white54, size: 40),
                                      const SizedBox(height: 6),
                                      Text(
                                        _displayHomeTeamName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // 스코어
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _displayScoreDisplay,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      if (_displayAwayTeamLogo != null)
                                        CachedNetworkImage(
                                          imageUrl: _displayAwayTeamLogo!,
                                          width: 40,
                                          height: 40,
                                          placeholder: (_, __) => const Icon(Icons.shield, color: Colors.white54, size: 40),
                                          errorWidget: (_, __, ___) => const Icon(Icons.shield, color: Colors.white54, size: 40),
                                        )
                                      else
                                        const Icon(Icons.shield, color: Colors.white54, size: 40),
                                      const SizedBox(height: 6),
                                      Text(
                                        _displayAwayTeamName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // 날짜, 경기장
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    _displayMatchDate != null
                                        ? DateFormat('yyyy.MM.dd').format(_displayMatchDate!)
                                        : '-',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.location_on, color: Colors.white70, size: 14),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      _displayStadium,
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: _border),
              ],

              // 직관 기록 불러오기 버튼 (선택 안된 경우)
              if (!hasAttendanceData) ...[
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: GestureDetector(
                    onTap: _showAttendanceSelector,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stadium_outlined, color: _textSecondary, size: 20),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              '나의 직관 기록 불러오기 (선택)',
                              style: TextStyle(fontSize: 14, color: _textSecondary),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: _textSecondary, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                Divider(height: 1, color: _border),
              ],

              // 내용 입력
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                constraints: const BoxConstraints(minHeight: 300),
                child: TextField(
                  controller: _contentController,
                  style: const TextStyle(
                    fontSize: 15,
                    color: _textPrimary,
                    height: 1.6,
                  ),
                  decoration: const InputDecoration(
                    hintText: '내용을 입력하세요\n\n직관 후기, 경기 정보, 꿀팁 등을 자유롭게 공유해보세요!',
                    hintStyle: TextStyle(color: _textSecondary, height: 1.6),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
              ),

              const SizedBox(height: 12),

              // 태그 입력
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '태그 (선택)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagController,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: '태그 입력 (최대 5개)',
                              hintStyle: const TextStyle(color: _textSecondary),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: _border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: _border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: _primary),
                              ),
                            ),
                            onSubmitted: (_) => _addTag(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _tags.length < 5 ? _addTag : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('추가'),
                        ),
                      ],
                    ),
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.only(left: 12, right: 4),
                            decoration: BoxDecoration(
                              color: _primaryLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '#$tag',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, size: 16, color: _primary),
                                  onPressed: () => _removeTag(tag),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 28,
                                    minHeight: 28,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 안내 메시지
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: _primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '타인을 비방하거나 불쾌감을 주는 내용은 삭제될 수 있습니다.',
                        style: TextStyle(
                          color: _primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceItem extends StatelessWidget {
  final AttendanceRecord record;
  final bool isSelected;
  final VoidCallback onTap;

  const _AttendanceItem({
    required this.record,
    required this.isSelected,
    required this.onTap,
  });

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primary : _border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 팀 로고 또는 아이콘
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: record.homeTeamLogo != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: record.homeTeamLogo!,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Icon(Icons.shield, color: Colors.grey),
                        errorWidget: (_, __, ___) => const Icon(Icons.shield, color: Colors.grey),
                      ),
                    )
                  : const Icon(Icons.stadium, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            // 경기 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${record.homeTeamName} vs ${record.awayTeamName}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? _primary : _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('yyyy.MM.dd').format(record.date)} · ${record.stadium}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? _primary.withValues(alpha: 0.7) : _textSecondary,
                    ),
                  ),
                  if (record.scoreDisplay != '-') ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? _primary.withValues(alpha: 0.1) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        record.scoreDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? _primary : _textPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // 선택 표시
            if (isSelected)
              Icon(Icons.check_circle, color: _primary, size: 24),
          ],
        ),
      ),
    );
  }
}
