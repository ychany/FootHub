import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _postsCollection => _firestore.collection('posts');
  CollectionReference get _commentsCollection => _firestore.collection('comments');
  CollectionReference get _likesCollection => _firestore.collection('likes');

  // 게시글 목록 조회 (페이지네이션)
  Future<List<Post>> getPosts({
    DocumentSnapshot? lastDocument,
    int limit = 20,
    String? tag,
  }) async {
    Query query = _postsCollection.orderBy('createdAt', descending: true).limit(limit);

    if (tag != null && tag.isNotEmpty) {
      query = query.where('tags', arrayContains: tag);
    }

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
  }

  // 게시글 상세 조회
  Future<Post?> getPost(String postId) async {
    final doc = await _postsCollection.doc(postId).get();
    if (doc.exists) {
      return Post.fromFirestore(doc);
    }
    return null;
  }

  // 게시글 작성
  Future<String> createPost({
    required String title,
    required String content,
    List<String> imageUrls = const [],
    List<String> tags = const [],
    String? attendanceId,
    String? homeTeamName,
    String? awayTeamName,
    String? homeTeamLogo,
    String? awayTeamLogo,
    int? homeScore,
    int? awayScore,
    DateTime? matchDate,
    String? stadium,
    String? league,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다');

    final post = Post(
      id: '',
      authorId: user.uid,
      authorName: user.displayName ?? '익명',
      authorProfileUrl: user.photoURL,
      title: title,
      content: content,
      imageUrls: imageUrls,
      tags: tags,
      createdAt: DateTime.now(),
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

    final docRef = await _postsCollection.add(post.toFirestore());
    return docRef.id;
  }

  // 게시글 수정
  Future<void> updatePost({
    required String postId,
    required String title,
    required String content,
    List<String>? imageUrls,
    List<String>? tags,
    String? attendanceId,
    String? homeTeamName,
    String? awayTeamName,
    String? homeTeamLogo,
    String? awayTeamLogo,
    int? homeScore,
    int? awayScore,
    DateTime? matchDate,
    String? stadium,
    String? league,
    bool clearAttendance = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다');

    final post = await getPost(postId);
    if (post == null) throw Exception('게시글을 찾을 수 없습니다');
    if (post.authorId != user.uid) throw Exception('수정 권한이 없습니다');

    final updateData = <String, dynamic>{
      'title': title,
      'content': content,
      'updatedAt': Timestamp.now(),
    };

    if (imageUrls != null) updateData['imageUrls'] = imageUrls;
    if (tags != null) updateData['tags'] = tags;

    if (clearAttendance) {
      updateData['attendanceId'] = FieldValue.delete();
      updateData['homeTeamName'] = FieldValue.delete();
      updateData['awayTeamName'] = FieldValue.delete();
      updateData['homeTeamLogo'] = FieldValue.delete();
      updateData['awayTeamLogo'] = FieldValue.delete();
      updateData['homeScore'] = FieldValue.delete();
      updateData['awayScore'] = FieldValue.delete();
      updateData['matchDate'] = FieldValue.delete();
      updateData['stadium'] = FieldValue.delete();
      updateData['league'] = FieldValue.delete();
    } else if (attendanceId != null) {
      updateData['attendanceId'] = attendanceId;
      if (homeTeamName != null) updateData['homeTeamName'] = homeTeamName;
      if (awayTeamName != null) updateData['awayTeamName'] = awayTeamName;
      if (homeTeamLogo != null) updateData['homeTeamLogo'] = homeTeamLogo;
      if (awayTeamLogo != null) updateData['awayTeamLogo'] = awayTeamLogo;
      if (homeScore != null) updateData['homeScore'] = homeScore;
      if (awayScore != null) updateData['awayScore'] = awayScore;
      if (matchDate != null) updateData['matchDate'] = Timestamp.fromDate(matchDate);
      if (stadium != null) updateData['stadium'] = stadium;
      if (league != null) updateData['league'] = league;
    }

    await _postsCollection.doc(postId).update(updateData);
  }

  // 게시글 삭제
  Future<void> deletePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다');

    final post = await getPost(postId);
    if (post == null) throw Exception('게시글을 찾을 수 없습니다');
    if (post.authorId != user.uid) throw Exception('삭제 권한이 없습니다');

    // 댓글 삭제
    final comments = await _commentsCollection.where('postId', isEqualTo: postId).get();
    for (final doc in comments.docs) {
      await doc.reference.delete();
    }

    // 좋아요 삭제
    final likes = await _likesCollection.where('postId', isEqualTo: postId).get();
    for (final doc in likes.docs) {
      await doc.reference.delete();
    }

    // 게시글 삭제
    await _postsCollection.doc(postId).delete();
  }

  // 좋아요 토글
  Future<bool> toggleLike(String postId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다');

    final likeId = '${user.uid}_$postId';
    final likeDoc = _likesCollection.doc(likeId);
    final likeSnapshot = await likeDoc.get();

    if (likeSnapshot.exists) {
      // 좋아요 취소
      await likeDoc.delete();
      await _postsCollection.doc(postId).update({
        'likeCount': FieldValue.increment(-1),
      });
      return false;
    } else {
      // 좋아요 추가
      await likeDoc.set({
        'userId': user.uid,
        'postId': postId,
        'createdAt': Timestamp.now(),
      });
      await _postsCollection.doc(postId).update({
        'likeCount': FieldValue.increment(1),
      });
      return true;
    }
  }

  // 좋아요 여부 확인
  Future<bool> isLiked(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final likeId = '${user.uid}_$postId';
    final likeDoc = await _likesCollection.doc(likeId).get();
    return likeDoc.exists;
  }

  // 댓글 목록 조회
  Future<List<Comment>> getComments(String postId) async {
    final snapshot = await _commentsCollection
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .get();
    return snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
  }

  // 댓글 작성
  Future<String> createComment({
    required String postId,
    required String content,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다');

    final comment = Comment(
      id: '',
      postId: postId,
      authorId: user.uid,
      authorName: user.displayName ?? '익명',
      authorProfileUrl: user.photoURL,
      content: content,
      createdAt: DateTime.now(),
    );

    final docRef = await _commentsCollection.add(comment.toFirestore());

    // 댓글 수 증가
    await _postsCollection.doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });

    return docRef.id;
  }

  // 댓글 삭제
  Future<void> deleteComment(String commentId, String postId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다');

    final commentDoc = await _commentsCollection.doc(commentId).get();
    if (!commentDoc.exists) throw Exception('댓글을 찾을 수 없습니다');

    final comment = Comment.fromFirestore(commentDoc);
    if (comment.authorId != user.uid) throw Exception('삭제 권한이 없습니다');

    await _commentsCollection.doc(commentId).delete();

    // 댓글 수 감소
    await _postsCollection.doc(postId).update({
      'commentCount': FieldValue.increment(-1),
    });
  }

  // 내 게시글 목록
  Future<List<Post>> getMyPosts() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _postsCollection
        .where('authorId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
  }
}
