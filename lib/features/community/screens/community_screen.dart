import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_model.dart';
import '../providers/community_provider.dart';
import '../../../core/services/api_football_service.dart';
import '../../../core/constants/api_football_ids.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _background = Color(0xFFF9FAFB);
  static const _border = Color(0xFFE5E7EB);

  final _searchController = TextEditingController();
  String _searchQuery = '';

  // 경기 필터 - 선택된 경기 정보
  ApiFootballFixture? _selectedMatchFilter;
  bool _onlyWithMatch = false; // 직관 기록이 있는 게시글만

  @override
  void initState() {
    super.initState();
    // 첫 로드 시 좋아요 상태 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLikedStatus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLikedStatus() async {
    final posts = ref.read(postsNotifierProvider).valueOrNull;
    if (posts != null && posts.isNotEmpty) {
      final postIds = posts.map((p) => p.id).toList();
      await ref.read(likedPostsProvider.notifier).loadLikedStatus(postIds);
    }
  }

  bool get _hasActiveFilter =>
      _onlyWithMatch ||
      _selectedMatchFilter != null;

  void _clearAllFilters() {
    setState(() {
      _onlyWithMatch = false;
      _selectedMatchFilter = null;
    });
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: _primary),
          ),
        ],
      ),
    );
  }

  void _showMatchFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MatchFilterModal(
        selectedEvent: _selectedMatchFilter,
        onlyWithMatch: _onlyWithMatch,
        onApply: (event, onlyMatch) {
          setState(() {
            _selectedMatchFilter = event;
            _onlyWithMatch = onlyMatch;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsNotifierProvider);

    // 게시글이 로드되면 좋아요 상태도 로드
    ref.listen(postsNotifierProvider, (previous, next) {
      next.whenData((posts) {
        if (posts.isNotEmpty) {
          final postIds = posts.map((p) => p.id).toList();
          ref.read(likedPostsProvider.notifier).loadLikedStatus(postIds);
        }
      });
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Column(
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '커뮤니티',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push('/community/write'),
                      icon: const Icon(Icons.edit_outlined, color: _primary),
                    ),
                  ],
                ),
              ),

              // 검색바 + 필터 버튼
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.trim().toLowerCase();
                          });
                        },
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '제목, 내용, 작성자 검색',
                          hintStyle: TextStyle(color: _textSecondary, fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: _textSecondary, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                  child: Icon(Icons.close, color: _textSecondary, size: 18),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _primary, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 필터 버튼
                    GestureDetector(
                      onTap: () => _showMatchFilterModal(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _hasActiveFilter ? _primary : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _hasActiveFilter ? _primary : _border),
                        ),
                        child: Icon(
                          Icons.tune,
                          color: _hasActiveFilter ? Colors.white : _textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 활성 필터 표시
              if (_hasActiveFilter)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_onlyWithMatch) _buildFilterChip('직관 기록 있음', () {
                          setState(() => _onlyWithMatch = false);
                        }),
                        if (_selectedMatchFilter != null) _buildFilterChip(
                          '${_selectedMatchFilter!.homeTeam.name} vs ${_selectedMatchFilter!.awayTeam.name}',
                          () => setState(() => _selectedMatchFilter = null),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: _clearAllFilters,
                          child: Text(
                            '전체 해제',
                            style: TextStyle(
                              fontSize: 12,
                              color: _primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 게시글 목록
              Expanded(
                child: postsAsync.when(
                  data: (posts) {
                    // 검색 + 경기 필터링
                    var filteredPosts = posts.where((post) {
                      // 텍스트 검색 필터
                      if (_searchQuery.isNotEmpty) {
                        final titleMatch = post.title.toLowerCase().contains(_searchQuery);
                        final contentMatch = post.content.toLowerCase().contains(_searchQuery);
                        final authorMatch = post.authorName.toLowerCase().contains(_searchQuery);
                        final teamMatch = (post.homeTeamName?.toLowerCase().contains(_searchQuery) ?? false) ||
                            (post.awayTeamName?.toLowerCase().contains(_searchQuery) ?? false);
                        final stadiumMatch = post.stadium?.toLowerCase().contains(_searchQuery) ?? false;
                        if (!(titleMatch || contentMatch || authorMatch || teamMatch || stadiumMatch)) {
                          return false;
                        }
                      }

                      // 직관 기록 있는 게시글만 필터
                      if (_onlyWithMatch && !post.hasAttendanceRecord) {
                        return false;
                      }

                      // 선택된 경기 필터
                      if (_selectedMatchFilter != null) {
                        // 홈팀과 원정팀이 일치하는 게시글만 표시
                        final matchHome = _selectedMatchFilter!.homeTeam.name;
                        final matchAway = _selectedMatchFilter!.awayTeam.name;
                        final matchDate = _selectedMatchFilter!.dateKST;

                        // 팀 이름 매칭 (홈 vs 원정 또는 원정 vs 홈)
                        final teamsMatch =
                            (post.homeTeamName == matchHome && post.awayTeamName == matchAway) ||
                            (post.homeTeamName == matchAway && post.awayTeamName == matchHome);

                        // 날짜도 같은지 확인 (같은 날짜의 경기)
                        bool dateMatch = true;
                        if (post.matchDate != null) {
                          dateMatch = post.matchDate!.year == matchDate.year &&
                              post.matchDate!.month == matchDate.month &&
                              post.matchDate!.day == matchDate.day;
                        }

                        if (!teamsMatch || !dateMatch) {
                          return false;
                        }
                      }

                      return true;
                    }).toList();

                    if (posts.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    if (filteredPosts.isEmpty && (_searchQuery.isNotEmpty || _hasActiveFilter)) {
                      return _buildNoSearchResultState();
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.read(postsNotifierProvider.notifier).refresh();
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredPosts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _PostCard(post: filteredPosts[index]);
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('오류가 발생했습니다\n$e', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(postsNotifierProvider.notifier).refresh(),
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/community/write'),
          backgroundColor: _primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.forum_outlined,
              size: 48,
              color: _primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '아직 게시글이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '첫 번째 게시글을 작성해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/community/write'),
            icon: const Icon(Icons.edit),
            label: const Text('글쓰기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResultState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off,
              size: 48,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '검색 결과가 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"$_searchQuery"에 대한 결과를 찾을 수 없습니다',
            style: const TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
            child: const Text('검색어 지우기'),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  final Post post;

  const _PostCard({required this.post});

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedPosts = ref.watch(likedPostsProvider);
    final isLiked = likedPosts[post.id] ?? false;

    return GestureDetector(
      onTap: () => context.push('/community/post/${post.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 작성자 정보
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.push('/user/${post.authorId}?name=${Uri.encodeComponent(post.authorName)}'),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: _border,
                      backgroundImage: post.authorProfileUrl != null
                          ? CachedNetworkImageProvider(post.authorProfileUrl!)
                          : null,
                      child: post.authorProfileUrl == null
                          ? const Icon(Icons.person, size: 20, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/user/${post.authorId}?name=${Uri.encodeComponent(post.authorName)}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _textPrimary,
                            ),
                          ),
                          Text(
                            _formatTime(post.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 제목
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 8),

            // 내용 미리보기
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 직관 기록 미니 카드 (있을 경우)
            if (post.hasAttendanceRecord) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sports_soccer, size: 14, color: _primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${post.homeTeamName ?? ''} ${post.scoreDisplay} ${post.awayTeamName ?? ''}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: _primary.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Text(
                            post.matchDate != null
                                ? '${post.matchDate!.year}.${post.matchDate!.month.toString().padLeft(2, '0')}.${post.matchDate!.day.toString().padLeft(2, '0')}'
                                : '-',
                            style: TextStyle(
                              fontSize: 11,
                              color: _primary.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.location_on, size: 12, color: _primary.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              post.stadium ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: _primary.withValues(alpha: 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // 직관 통계 미니 카드 (있을 경우)
            if (post.hasStats) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bar_chart_rounded, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Text(
                        '${post.statsTotalMatches ?? 0}경기',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 1,
                        height: 12,
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      ),
                      Text(
                        '${(post.statsWinRate ?? 0).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 1,
                        height: 12,
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      ),
                      Text(
                        '${post.statsWins ?? 0}승 ${post.statsDraws ?? 0}무 ${post.statsLosses ?? 0}패',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF10B981).withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // 이미지 미리보기 (있을 경우)
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: post.imageUrls.length > 3 ? 3 : post.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: post.imageUrls[index],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: _border,
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: _border,
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 12),

            // 좋아요, 댓글 수
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  _buildLikeItem(isLiked, post.likeCount),
                  const SizedBox(width: 16),
                  _buildStatItem(Icons.chat_bubble_outline, '${post.commentCount}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikeItem(bool isLiked, int count) {
    return Row(
      children: [
        Icon(
          isLiked ? Icons.favorite : Icons.favorite_border,
          size: 18,
          color: isLiked ? Colors.red : _textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 13,
            color: isLiked ? Colors.red : _textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _textSecondary),
        const SizedBox(width: 4),
        Text(
          count,
          style: const TextStyle(
            fontSize: 13,
            color: _textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return '방금 전';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}

// ============================================================================
// 경기 필터 모달 - 날짜/리그/경기 선택
// ============================================================================
class _MatchFilterModal extends StatefulWidget {
  final ApiFootballFixture? selectedEvent;
  final bool onlyWithMatch;
  final Function(ApiFootballFixture?, bool) onApply;

  const _MatchFilterModal({
    this.selectedEvent,
    required this.onlyWithMatch,
    required this.onApply,
  });

  @override
  State<_MatchFilterModal> createState() => _MatchFilterModalState();
}

class _MatchFilterModalState extends State<_MatchFilterModal> {
  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  final ApiFootballService _apiFootballService = ApiFootballService();

  late DateTime _selectedDate;
  int? _selectedLeagueId;
  late bool _onlyWithMatch;
  ApiFootballFixture? _selectedEvent;

  List<ApiFootballFixture> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _onlyWithMatch = widget.onlyWithMatch;
    _selectedEvent = widget.selectedEvent;
  }

  Future<void> _searchEvents() async {
    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final fixtures = await _apiFootballService.getFixturesByDate(_selectedDate);
      // 선택한 리그 필터링
      final filtered = _selectedLeagueId != null
          ? fixtures.where((f) => f.league.id == _selectedLeagueId).toList()
          : fixtures;
      setState(() {
        _searchResults = filtered;
      });
    } catch (e) {
      // 에러 처리
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.year}년 ${date.month}월 ${date.day}일 ($weekday)';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _searchResults = [];
        _hasSearched = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '경기 검색',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEvent = null;
                      _onlyWithMatch = false;
                      _searchResults = [];
                      _hasSearched = false;
                    });
                  },
                  child: const Text(
                    '초기화',
                    style: TextStyle(
                      fontSize: 14,
                      color: _textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 직관 기록 있는 게시글만
                  GestureDetector(
                    onTap: () => setState(() => _onlyWithMatch = !_onlyWithMatch),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _onlyWithMatch ? _primaryLight : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _onlyWithMatch ? _primary : _border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sports_soccer,
                            color: _onlyWithMatch ? _primary : _textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '직관 기록이 있는 게시글만 보기',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _onlyWithMatch ? _primary : _textPrimary,
                              ),
                            ),
                          ),
                          Icon(
                            _onlyWithMatch ? Icons.check_circle : Icons.circle_outlined,
                            color: _onlyWithMatch ? _primary : _border,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 날짜 선택
                  const Text(
                    '경기 날짜',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: _primary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _formatDate(_selectedDate),
                            style: const TextStyle(
                              fontSize: 14,
                              color: _textPrimary,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right, color: _textSecondary),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 리그 선택
                  const Text(
                    '리그 선택',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildLeagueChip('전체', null),
                        const SizedBox(width: 8),
                        ...LeagueIds.supportedLeagues.map((league) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildLeagueChip(
                                league.name,
                                league.id,
                              ),
                            )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 검색 버튼
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isSearching ? null : _searchEvents,
                      icon: _isSearching
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search, size: 18),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primary,
                        side: const BorderSide(color: _primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      label: Text(
                        _isSearching ? '검색 중...' : '경기 검색',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 검색 결과
                  if (_hasSearched) ...[
                    Text(
                      '검색 결과 (${_searchResults.length})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_searchResults.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(Icons.sports_soccer_outlined, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            const Text(
                              '해당 날짜에 경기가 없습니다',
                              style: TextStyle(color: _textSecondary),
                            ),
                          ],
                        ),
                      )
                    else
                      ...(_searchResults.take(10).map((event) => _buildEventCard(event))),

                    if (_searchResults.length > 10)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '외 ${_searchResults.length - 10}개 더 있음',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                          ),
                        ),
                      ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // 적용 버튼
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: _border)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_selectedEvent, _onlyWithMatch);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _selectedEvent != null
                      ? '선택한 경기로 필터 적용'
                      : '적용하기',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueChip(String label, int? leagueId) {
    final isSelected = _selectedLeagueId == leagueId;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLeagueId = leagueId;
          _searchResults = [];
          _hasSearched = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? _primary : _border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : _textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(ApiFootballFixture fixture) {
    final isSelected = _selectedEvent?.id == fixture.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEvent = isSelected ? null : fixture;
        });
      },
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
                  '${fixture.dateKST.hour.toString().padLeft(2, '0')}:${fixture.dateKST.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11, color: _textSecondary),
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
            if (isSelected) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      '선택됨',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
