import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class MatchComment extends Equatable {
  final String id;
  final String matchId;
  final String authorId;
  final String authorName;
  final String? authorProfileUrl;
  final String content;
  final DateTime createdAt;

  const MatchComment({
    required this.id,
    required this.matchId,
    required this.authorId,
    required this.authorName,
    this.authorProfileUrl,
    required this.content,
    required this.createdAt,
  });

  factory MatchComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchComment(
      id: doc.id,
      matchId: data['matchId'] as String,
      authorId: data['authorId'] as String,
      authorName: data['authorName'] as String? ?? '익명',
      authorProfileUrl: data['authorProfileUrl'] as String?,
      content: data['content'] as String,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'matchId': matchId,
      'authorId': authorId,
      'authorName': authorName,
      'authorProfileUrl': authorProfileUrl,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        matchId,
        authorId,
        authorName,
        authorProfileUrl,
        content,
        createdAt,
      ];
}
