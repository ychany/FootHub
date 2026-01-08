import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/error_helper.dart';
import '../models/post_model.dart';
import '../providers/community_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/banner_ad_widget.dart';

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
  List<String> _blockedUserIds = [];

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
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    try {
      final service = ref.read(communityServiceProvider);
      final blockedIds = await service.getBlockedUserIds();
      if (mounted) {
        setState(() => _blockedUserIds = blockedIds);
      }
    } catch (_) {
      // 차단 목록 로드 실패 시 무시
    }
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
          SnackBar(content: Text(ErrorHelper.getLocalizedErrorMessage(context, e))),
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
          SnackBar(content: Text(ErrorHelper.getLocalizedErrorMessage(context, e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _deletePost(Post post) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePost),
        content: Text(l10n.deletePostConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
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
            SnackBar(content: Text(l10n.postDeleted)),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ErrorHelper.getLocalizedErrorMessage(context, e))),
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
        bottomNavigationBar: const BottomBannerAdWidget(),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text(
            AppLocalizations.of(context)!.post,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            postAsync.whenOrNull(
              data: (post) {
                if (post == null) return const SizedBox.shrink();

                final isOwner = currentUser?.uid == post.authorId;
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
                    } else if (value == 'report') {
                      _showReportDialog(post);
                    } else if (value == 'block') {
                      _blockUser(post.authorId, post.authorName);
                    }
                  },
                  itemBuilder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    if (isOwner) {
                      return [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(l10n.edit),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                        ),
                      ];
                    } else {
                      return [
                        PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              const Icon(Icons.report_outlined, size: 20, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(l10n.reportPost),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              const Icon(Icons.block, size: 20, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(l10n.blockUser, style: const TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ];
                    }
                  },
                );
              },
            ) ?? const SizedBox.shrink(),
          ],
        ),
        body: postAsync.when(
          data: (post) {
            if (post == null) {
              return Center(child: Text(AppLocalizations.of(context)!.postNotFound));
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

                              // 직관 통계 카드
                              if (post.hasStats) ...[
                                const SizedBox(height: 16),
                                _buildStatsCard(post),
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
                                AppLocalizations.of(context)!.commentCount(post.commentCount),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              commentsAsync.when(
                                data: (allComments) {
                                  // 차단된 사용자의 댓글 필터링
                                  final comments = allComments
                                      .where((c) => !_blockedUserIds.contains(c.authorId))
                                      .toList();
                                  if (comments.isEmpty) {
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Text(
                                          AppLocalizations.of(context)!.noCommentsYet,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: _textSecondary),
                                        ),
                                      ),
                                    );
                                  }
                                  return Column(
                                    children: comments.map((comment) => _CommentItem(
                                      comment: comment,
                                      onDelete: () => _deleteComment(comment),
                                      onReport: () => _showCommentReportDialog(comment),
                                      onBlock: () => _blockCommentAuthor(comment),
                                      isOwner: currentUser?.uid == comment.authorId,
                                    )).toList(),
                                  );
                                },
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (e, _) => Text(ErrorHelper.getLocalizedErrorMessage(context, e)),
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
                            hintText: AppLocalizations.of(context)!.enterComment,
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
          error: (e, _) => Center(child: Text(ErrorHelper.getLocalizedErrorMessage(context, e))),
        ),
      ),
    );
  }

  Future<void> _deleteComment(Comment comment) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteComment),
        content: Text(l10n.deleteCommentConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
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
            SnackBar(content: Text(ErrorHelper.getLocalizedErrorMessage(context, e))),
          );
        }
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showReportDialog(Post post) {
    final l10n = AppLocalizations.of(context)!;
    String? selectedReason;
    final additionalController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.report_outlined, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    l10n.reportPost,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                l10n.reportReason,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              ...[
                ('spam', l10n.reportReasonSpam),
                ('harassment', l10n.reportReasonHarassment),
                ('inappropriate', l10n.reportReasonInappropriate),
                ('false_info', l10n.reportReasonFalseInfo),
                ('other', l10n.reportReasonOther),
              ].map((item) => RadioListTile<String>(
                value: item.$1,
                groupValue: selectedReason,
                onChanged: (value) => setModalState(() => selectedReason = value),
                title: Text(item.$2),
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
              const SizedBox(height: 12),
              TextField(
                controller: additionalController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.reportAdditionalInfo,
                  hintText: l10n.reportAdditionalInfoHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: selectedReason == null
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await _submitReport(
                            contentType: 'post',
                            contentId: post.id,
                            reason: selectedReason!,
                            additionalInfo: additionalController.text.trim(),
                            reportedUserId: post.authorId,
                          );
                        },
                  child: Text(l10n.reportSubmit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitReport({
    required String contentType,
    required String contentId,
    required String reason,
    String? additionalInfo,
    String? reportedUserId,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final service = ref.read(communityServiceProvider);
      await service.reportContent(
        contentType: contentType,
        contentId: contentId,
        reason: reason,
        additionalInfo: additionalInfo,
        reportedUserId: reportedUserId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reportSubmitted)),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().contains('ALREADY_REPORTED')
            ? l10n.reportAlreadySubmitted
            : l10n.reportFailed(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _blockCommentAuthor(Comment comment) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.blockUser),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.blockUserConfirm),
            const SizedBox(height: 8),
            Text(
              l10n.blockUserDesc,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.blockUser),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // blockedUsersNotifierProvider를 통해 차단 (관리 페이지와 연동)
        await ref
            .read(blockedUsersNotifierProvider.notifier)
            .block(comment.authorId, comment.authorName);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.userBlocked)),
          );
          // 차단 목록 새로고침 후 댓글 다시 로드
          await _loadBlockedUsers();
          ref.invalidate(commentsProvider(widget.postId));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showCommentReportDialog(Comment comment) {
    final l10n = AppLocalizations.of(context)!;
    String? selectedReason;
    final additionalController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.report_outlined, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    l10n.reportComment,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                l10n.reportReason,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              ...[
                ('spam', l10n.reportReasonSpam),
                ('harassment', l10n.reportReasonHarassment),
                ('inappropriate', l10n.reportReasonInappropriate),
                ('false_info', l10n.reportReasonFalseInfo),
                ('other', l10n.reportReasonOther),
              ].map((item) => RadioListTile<String>(
                value: item.$1,
                groupValue: selectedReason,
                onChanged: (value) => setModalState(() => selectedReason = value),
                title: Text(item.$2),
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
              const SizedBox(height: 12),
              TextField(
                controller: additionalController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.reportAdditionalInfo,
                  hintText: l10n.reportAdditionalInfoHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: selectedReason == null
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await _submitReport(
                            contentType: 'comment',
                            contentId: comment.id,
                            reason: selectedReason!,
                            additionalInfo: additionalController.text.trim(),
                            reportedUserId: comment.authorId,
                          );
                        },
                  child: Text(l10n.reportSubmit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _blockUser(String userId, String userName) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.blockUser),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.blockUserConfirm),
            const SizedBox(height: 8),
            Text(
              l10n.blockUserDesc,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.blockUser),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // blockedUsersNotifierProvider를 통해 차단 (관리 페이지와 연동)
        await ref
            .read(blockedUsersNotifierProvider.notifier)
            .block(userId, userName);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.userBlocked)),
          );
          // 커뮤니티 목록 새로고침 후 돌아가기
          ref.read(postsNotifierProvider.notifier).refresh();
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildStatsCard(Post post) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 상단 타이틀
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sports_soccer, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.myAttendanceStats,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 통계 그리드
          Row(
            children: [
              Expanded(
                child: _buildStatItem(AppLocalizations.of(context)!.totalAttendance, AppLocalizations.of(context)!.attendanceCount(post.statsTotalMatches ?? 0)),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _buildStatItem(AppLocalizations.of(context)!.winRate, AppLocalizations.of(context)!.winRatePercent((post.statsWinRate ?? 0).toStringAsFixed(1))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildResultItem(AppLocalizations.of(context)!.winShort, post.statsWins ?? 0, const Color(0xFF3B82F6)),
                _buildResultItem(AppLocalizations.of(context)!.drawShort, post.statsDraws ?? 0, const Color(0xFF9CA3AF)),
                _buildResultItem(AppLocalizations.of(context)!.lossShort, post.statsLosses ?? 0, const Color(0xFFEF4444)),
              ],
            ),
          ),
          if (post.statsTopStadium != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      AppLocalizations.of(context)!.mostVisited(post.statsTopStadium!, post.statsTopStadiumCount ?? 0),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildResultItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label $count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
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
              Text(
                AppLocalizations.of(context)!.matchRecord,
                style: const TextStyle(
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
  final VoidCallback onReport;
  final VoidCallback onBlock;
  final bool isOwner;

  const _CommentItem({
    required this.comment,
    required this.onDelete,
    required this.onReport,
    required this.onBlock,
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
                      _formatTime(context, comment.createdAt),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 16, color: _textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onSelected: (value) {
              if (value == 'delete') {
                onDelete();
              } else if (value == 'report') {
                onReport();
              } else if (value == 'block') {
                onBlock();
              }
            },
            itemBuilder: (context) {
              final l10n = AppLocalizations.of(context)!;
              if (isOwner) {
                return [
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                  ),
                ];
              } else {
                return [
                  PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        const Icon(Icons.report_outlined, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(l10n.report),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        const Icon(Icons.block, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(l10n.blockUser, style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ];
              }
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(BuildContext context, DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    final l10n = AppLocalizations.of(context)!;

    if (diff.inMinutes < 1) {
      return l10n.justNow;
    } else if (diff.inMinutes < 60) {
      return l10n.minutesAgo(diff.inMinutes);
    } else if (diff.inHours < 24) {
      return l10n.hoursAgo(diff.inHours);
    } else if (diff.inDays < 7) {
      return l10n.daysAgo(diff.inDays);
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}
