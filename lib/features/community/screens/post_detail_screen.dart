import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/post_model.dart';
import '../providers/community_provider.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isLiked = false;
  bool _isSubmitting = false;

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _background = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _checkLikeStatus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkLikeStatus() async {
    final service = ref.read(communityServiceProvider);
    final isLiked = await service.isLiked(widget.postId);
    if (mounted) {
      setState(() => _isLiked = isLiked);
    }
  }

  Future<void> _toggleLike() async {
    try {
      final service = ref.read(communityServiceProvider);
      final newState = await service.toggleLike(widget.postId);
      setState(() => _isLiked = newState);

      // 목록 좋아요 상태 업데이트
      ref.read(likedPostsProvider.notifier).setLiked(widget.postId, newState);

      // 목록 좋아요 수 업데이트
      ref.read(postsNotifierProvider.notifier).updateLikeCount(
        widget.postId,
        newState ? 1 : -1,
      );

      ref.invalidate(postProvider(widget.postId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(communityServiceProvider);
      await service.createComment(postId: widget.postId, content: content);
      _commentController.clear();
      ref.invalidate(commentsProvider(widget.postId));
      ref.invalidate(postProvider(widget.postId));
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _deletePost(Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('이 게시글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = ref.read(communityServiceProvider);
        await service.deletePost(widget.postId);
        ref.read(postsNotifierProvider.notifier).refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('게시글이 삭제되었습니다')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류가 발생했습니다: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postProvider(widget.postId));
    final commentsAsync = ref.watch(commentsProvider(widget.postId));
    final currentUser = FirebaseAuth.instance.currentUser;

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
            icon: const Icon(Icons.arrow_back, color: _textPrimary),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            '게시글',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            postAsync.whenOrNull(
              data: (post) {
                if (post != null && currentUser?.uid == post.authorId) {
                  return PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: _textPrimary),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final result = await context.push('/community/write', extra: post);
                        if (result == true) {
                          ref.invalidate(postProvider(widget.postId));
                        }
                      } else if (value == 'delete') {
                        _deletePost(post);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('수정'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('삭제', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ) ?? const SizedBox.shrink(),
          ],
        ),
        body: postAsync.when(
          data: (post) {
            if (post == null) {
              return const Center(child: Text('게시글을 찾을 수 없습니다'));
            }
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 게시글 내용
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 작성자 정보
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => context.push('/user/${post.authorId}?name=${Uri.encodeComponent(post.authorName)}'),
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: _border,
                                      backgroundImage: post.authorProfileUrl != null
                                          ? CachedNetworkImageProvider(post.authorProfileUrl!)
                                          : null,
                                      child: post.authorProfileUrl == null
                                          ? const Icon(Icons.person, size: 24, color: Colors.grey)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
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
                                              fontSize: 15,
                                              color: _textPrimary,
                                            ),
                                          ),
                                          Text(
                                            _formatDateTime(post.createdAt),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: _textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // 제목
                              Text(
                                post.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // 내용
                              Text(
                                post.content,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: _textPrimary,
                                  height: 1.7,
                                ),
                              ),

                              // 직관 기록 카드
                              if (post.hasAttendanceRecord) ...[
                                const SizedBox(height: 16),
                                _buildAttendanceCard(post),
                              ],

                              // 이미지
                              if (post.imageUrls.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                ...post.imageUrls.map((url) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: url,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        height: 200,
                                        color: _border,
                                        child: const Center(child: CircularProgressIndicator()),
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        height: 200,
                                        color: _border,
                                        child: const Icon(Icons.image_not_supported),
                                      ),
                                    ),
                                  ),
                                )),
                              ],

                              // 태그
                              if (post.tags.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: post.tags.map((tag) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _primaryLight,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        '#$tag',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: _primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],

                              const SizedBox(height: 20),

                              // 좋아요, 댓글 수
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: _toggleLike,
                                    child: Row(
                                      children: [
                                        Icon(
                                          _isLiked ? Icons.favorite : Icons.favorite_border,
                                          size: 22,
                                          color: _isLiked ? Colors.red : _textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${post.likeCount}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _isLiked ? Colors.red : _textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Row(
                                    children: [
                                      const Icon(Icons.chat_bubble_outline, size: 20, color: _textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${post.commentCount}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: _textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // 댓글 섹션
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '댓글 ${post.commentCount}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              commentsAsync.when(
                                data: (comments) {
                                  if (comments.isEmpty) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Text(
                                          '아직 댓글이 없습니다.\n첫 번째 댓글을 남겨보세요!',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: _textSecondary),
                                        ),
                                      ),
                                    );
                                  }
                                  return Column(
                                    children: comments.map((comment) => _CommentItem(
                                      comment: comment,
                                      onDelete: () => _deleteComment(comment),
                                      isOwner: currentUser?.uid == comment.authorId,
                                    )).toList(),
                                  );
                                },
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (e, _) => Text('댓글을 불러오는데 실패했습니다: $e'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 댓글 입력
                Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: MediaQuery.of(context).padding.bottom + 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: _border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: '댓글을 입력하세요',
                            hintStyle: const TextStyle(color: _textSecondary),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: _border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: _border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: _primary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isSubmitting ? null : _submitComment,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send, color: _primary),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('오류가 발생했습니다: $e')),
        ),
      ),
    );
  }

  Future<void> _deleteComment(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('이 댓글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = ref.read(communityServiceProvider);
        await service.deleteComment(comment.id, widget.postId);
        ref.invalidate(commentsProvider(widget.postId));
        ref.invalidate(postProvider(widget.postId));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류가 발생했습니다: $e')),
          );
        }
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildAttendanceCard(Post post) {
    return Container(
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
          // 직관 기록 라벨
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stadium_rounded, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              const Text(
                '직관 기록',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 팀 vs 팀
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    if (post.homeTeamLogo != null)
                      CachedNetworkImage(
                        imageUrl: post.homeTeamLogo!,
                        width: 40,
                        height: 40,
                        placeholder: (_, __) => const Icon(Icons.shield, color: Colors.white54, size: 40),
                        errorWidget: (_, __, ___) => const Icon(Icons.shield, color: Colors.white54, size: 40),
                      )
                    else
                      const Icon(Icons.shield, color: Colors.white54, size: 40),
                    const SizedBox(height: 6),
                    Text(
                      post.homeTeamName ?? '',
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
                  post.scoreDisplay,
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
                    if (post.awayTeamLogo != null)
                      CachedNetworkImage(
                        imageUrl: post.awayTeamLogo!,
                        width: 40,
                        height: 40,
                        placeholder: (_, __) => const Icon(Icons.shield, color: Colors.white54, size: 40),
                        errorWidget: (_, __, ___) => const Icon(Icons.shield, color: Colors.white54, size: 40),
                      )
                    else
                      const Icon(Icons.shield, color: Colors.white54, size: 40),
                    const SizedBox(height: 6),
                    Text(
                      post.awayTeamName ?? '',
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
                  post.matchDate != null
                      ? DateFormat('yyyy.MM.dd').format(post.matchDate!)
                      : '-',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.location_on, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    post.stadium ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final Comment comment;
  final VoidCallback onDelete;
  final bool isOwner;

  const _CommentItem({
    required this.comment,
    required this.onDelete,
    required this.isOwner,
  });

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.push('/user/${comment.authorId}?name=${Uri.encodeComponent(comment.authorName)}'),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: _border,
              backgroundImage: comment.authorProfileUrl != null
                  ? CachedNetworkImageProvider(comment.authorProfileUrl!)
                  : null,
              child: comment.authorProfileUrl == null
                  ? const Icon(Icons.person, size: 18, color: Colors.grey)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/user/${comment.authorId}?name=${Uri.encodeComponent(comment.authorName)}'),
                      child: Text(
                        comment.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(comment.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: _textSecondary),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
        ],
      ),
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
