import 'package:equatable/equatable.dart';

/// Tracks an invitation awaiting acceptance.
class CirclePendingInvitation extends Equatable {
  const CirclePendingInvitation({
    required this.id,
    required this.phoneNumber,
    required this.createdAt,
    this.lastSentAt,
  });

  final String id;
  final String phoneNumber;
  final DateTime createdAt;

  /// When it was last sent: later than [createdAt] after «إعادة الإرسال».
  final DateTime? lastSentAt;

  /// The time the row shows in «أُرسلت قبل ...».
  DateTime get sentAt => lastSentAt ?? createdAt;

  @override
  List<Object?> get props => [id, phoneNumber, createdAt, lastSentAt];
}
