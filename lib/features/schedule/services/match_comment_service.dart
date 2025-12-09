import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/match_comment.dart';

class MatchCommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _commentsCollection =>
      _firestore.collection('match_comments');

  /// 실시간 댓글 스트림 - 자동 새로고침용
  Stream<List<MatchComment>> getCommentsStream(String matchId) {
    return _commentsCollection
        .where('matchId', isEqualTo: matchId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MatchComment.fromFirestore(doc))
          .toList();
    });
  }

  /// 댓글 목록 조회 (수동 새로고침용)
  Future<List<MatchComment>> getComments(String matchId) async {
    final snapshot = await _commentsCollection
        .where('matchId', isEqualTo: matchId)
        .orderBy('createdAt', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => MatchComment.fromFirestore(doc))
        .toList();
  }

  /// 댓글 작성
  Future<String> createComment({
    required String matchId,
    required String content,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다');

    final comment = MatchComment(
      id: '',
      matchId: matchId,
      authorId: user.uid,
      authorName: user.displayName ?? '익명',
      authorProfileUrl: user.photoURL,
      content: content,
      createdAt: DateTime.now(),
    );

    final commentData = comment.toFirestore();
    final docRef = await _commentsCollection.add(commentData);
    return docRef.id;
  }

  /// 댓글 삭제
  Future<void> deleteComment(String commentId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다');

    final commentDoc = await _commentsCollection.doc(commentId).get();
    if (!commentDoc.exists) throw Exception('댓글을 찾을 수 없습니다');

    final comment = MatchComment.fromFirestore(commentDoc);
    if (comment.authorId != user.uid) throw Exception('삭제 권한이 없습니다');

    await _commentsCollection.doc(commentId).delete();
  }

  /// 댓글 개수 조회
  Future<int> getCommentCount(String matchId) async {
    final snapshot = await _commentsCollection
        .where('matchId', isEqualTo: matchId)
        .count()
        .get();

    return snapshot.count ?? 0;
  }
}
