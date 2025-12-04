import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../services/community_service.dart';

final communityServiceProvider = Provider((ref) => CommunityService());

// 게시글 목록 Provider
final postsProvider = FutureProvider<List<Post>>((ref) async {
  final service = ref.read(communityServiceProvider);
  return service.getPosts();
});

// 게시글 목록 Notifier (페이지네이션, 새로고침 지원)
class PostsNotifier extends StateNotifier<AsyncValue<List<Post>>> {
  final CommunityService _service;
  bool _hasMore = true;
  bool _isLoading = false;

  PostsNotifier(this._service) : super(const AsyncValue.loading()) {
    loadPosts();
  }

  Future<void> loadPosts() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final posts = await _service.getPosts();
      _hasMore = posts.length >= 20;
      state = AsyncValue.data(posts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    _hasMore = true;
    await loadPosts();
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    final currentPosts = state.valueOrNull ?? [];
    if (currentPosts.isEmpty) return;

    _isLoading = true;

    try {
      // 실제 구현시 lastDocument를 전달해야 함
      // 여기서는 간단히 처리
      final morePosts = await _service.getPosts(limit: 20);
      _hasMore = morePosts.length >= 20;
      state = AsyncValue.data([...currentPosts, ...morePosts]);
    } catch (e) {
      // 에러 발생해도 기존 데이터 유지
    } finally {
      _isLoading = false;
    }
  }

  bool get hasMore => _hasMore;
}

final postsNotifierProvider = StateNotifierProvider<PostsNotifier, AsyncValue<List<Post>>>((ref) {
  final service = ref.read(communityServiceProvider);
  return PostsNotifier(service);
});

// 특정 게시글 Provider
final postProvider = FutureProvider.family<Post?, String>((ref, postId) async {
  final service = ref.read(communityServiceProvider);
  return service.getPost(postId);
});

// 댓글 목록 Provider
final commentsProvider = FutureProvider.family<List<Comment>, String>((ref, postId) async {
  final service = ref.read(communityServiceProvider);
  return service.getComments(postId);
});

// 좋아요 여부 Provider
final isLikedProvider = FutureProvider.family<bool, String>((ref, postId) async {
  final service = ref.read(communityServiceProvider);
  return service.isLiked(postId);
});

// 내 게시글 목록 Provider
final myPostsProvider = FutureProvider<List<Post>>((ref) async {
  final service = ref.read(communityServiceProvider);
  return service.getMyPosts();
});
