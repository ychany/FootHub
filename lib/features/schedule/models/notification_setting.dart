import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class NotificationSetting extends Equatable {
  final String id;
  final String userId;
  final String matchId;
  final bool notifyKickoff;
  final bool notifyResult;
  final DateTime? createdAt;

  const NotificationSetting({
    required this.id,
    required this.userId,
    required this.matchId,
    this.notifyKickoff = true,
    this.notifyResult = true,
    this.createdAt,
  });

  factory NotificationSetting.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationSetting(
      id: doc.id,
      userId: data['userId'] as String,
      matchId: data['matchId'] as String,
      notifyKickoff: data['notifyKickoff'] as bool? ?? true,
      notifyResult: data['notifyResult'] as bool? ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'matchId': matchId,
      'notifyKickoff': notifyKickoff,
      'notifyResult': notifyResult,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  NotificationSetting copyWith({
    String? id,
    String? userId,
    String? matchId,
    bool? notifyKickoff,
    bool? notifyResult,
    DateTime? createdAt,
  }) {
    return NotificationSetting(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      matchId: matchId ?? this.matchId,
      notifyKickoff: notifyKickoff ?? this.notifyKickoff,
      notifyResult: notifyResult ?? this.notifyResult,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get hasAnyNotification => notifyKickoff || notifyResult;

  @override
  List<Object?> get props => [
        id,
        userId,
        matchId,
        notifyKickoff,
        notifyResult,
      ];
}
