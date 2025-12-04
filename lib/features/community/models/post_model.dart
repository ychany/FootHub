import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorProfileUrl;
  final String title;
  final String content;
  final List<String> imageUrls;
  final List<String> tags;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // 직관 기록 관련 필드
  final String? attendanceId;
  final String? homeTeamName;
  final String? awayTeamName;
  final String? homeTeamLogo;
  final String? awayTeamLogo;
  final int? homeScore;
  final int? awayScore;
  final DateTime? matchDate;
  final String? stadium;
  final String? league;

  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorProfileUrl,
    required this.title,
    required this.content,
    this.imageUrls = const [],
    this.tags = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.attendanceId,
    this.homeTeamName,
    this.awayTeamName,
    this.homeTeamLogo,
    this.awayTeamLogo,
    this.homeScore,
    this.awayScore,
    this.matchDate,
    this.stadium,
    this.league,
  });

  bool get hasAttendanceRecord => attendanceId != null;

  String get scoreDisplay {
    if (homeScore == null || awayScore == null) return '-';
    return '$homeScore : $awayScore';
  }

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '익명',
      authorProfileUrl: data['authorProfileUrl'],
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      attendanceId: data['attendanceId'],
      homeTeamName: data['homeTeamName'],
      awayTeamName: data['awayTeamName'],
      homeTeamLogo: data['homeTeamLogo'],
      awayTeamLogo: data['awayTeamLogo'],
      homeScore: data['homeScore'],
      awayScore: data['awayScore'],
      matchDate: (data['matchDate'] as Timestamp?)?.toDate(),
      stadium: data['stadium'],
      league: data['league'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorProfileUrl': authorProfileUrl,
      'title': title,
      'content': content,
      'imageUrls': imageUrls,
      'tags': tags,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      if (attendanceId != null) 'attendanceId': attendanceId,
      if (homeTeamName != null) 'homeTeamName': homeTeamName,
      if (awayTeamName != null) 'awayTeamName': awayTeamName,
      if (homeTeamLogo != null) 'homeTeamLogo': homeTeamLogo,
      if (awayTeamLogo != null) 'awayTeamLogo': awayTeamLogo,
      if (homeScore != null) 'homeScore': homeScore,
      if (awayScore != null) 'awayScore': awayScore,
      if (matchDate != null) 'matchDate': Timestamp.fromDate(matchDate!),
      if (stadium != null) 'stadium': stadium,
      if (league != null) 'league': league,
    };
  }

  Post copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorProfileUrl,
    String? title,
    String? content,
    List<String>? imageUrls,
    List<String>? tags,
    int? likeCount,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
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
  }) {
    return Post(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorProfileUrl: authorProfileUrl ?? this.authorProfileUrl,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      tags: tags ?? this.tags,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attendanceId: attendanceId ?? this.attendanceId,
      homeTeamName: homeTeamName ?? this.homeTeamName,
      awayTeamName: awayTeamName ?? this.awayTeamName,
      homeTeamLogo: homeTeamLogo ?? this.homeTeamLogo,
      awayTeamLogo: awayTeamLogo ?? this.awayTeamLogo,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      matchDate: matchDate ?? this.matchDate,
      stadium: stadium ?? this.stadium,
      league: league ?? this.league,
    );
  }
}

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorProfileUrl;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorProfileUrl,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '익명',
      authorProfileUrl: data['authorProfileUrl'],
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorProfileUrl': authorProfileUrl,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
