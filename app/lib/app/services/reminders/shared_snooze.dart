import 'package:equatable/equatable.dart';

export 'package:app/app/services/reminders/snooze_share.dart';

/// A dose or reading time someone in the circle put off with «ذكّرني
/// لاحقًا», as the server keeps it for everyone: when it comes again
/// ([remindAt]), for how many [minutes], and who put it off. Every member's
/// card shows it; at [remindAt] the server reminds every member but the one
/// who put it off (their own phone does).
class SharedSnooze extends Equatable {
  const SharedSnooze({
    required this.remindAt,
    required this.minutes,
    this.byAccountId,
    this.byName,
    this.byAvatarCode,
  });

  /// In UTC.
  final DateTime remindAt;
  final int minutes;

  /// Who put it off; null once that account was deleted.
  final String? byAccountId;
  final String? byName;
  final String? byAvatarCode;

  /// The `snooze` of an occurrence; null when the task is not put off.
  static SharedSnooze? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final Object? remindAt = json['remind_at'];
    final Object? minutes = json['minutes'];
    if (remindAt is! String || minutes is! int) return null;
    final DateTime? at = DateTime.tryParse(remindAt);
    if (at == null) return null;
    final Object? by = json['snoozed_by'];
    return SharedSnooze(
      remindAt: at.toUtc(),
      minutes: minutes,
      byAccountId: by is Map<String, dynamic>
          ? by['account_id'] as String?
          : null,
      byName: by is Map<String, dynamic> ? by['name'] as String? : null,
      byAvatarCode: by is Map<String, dynamic>
          ? by['avatar_code'] as String?
          : null,
    );
  }

  /// Whether it still waits at [now].
  bool waitsAt(DateTime now) => remindAt.isAfter(now.toUtc());

  @override
  List<Object?> get props => [
    remindAt,
    minutes,
    byAccountId,
    byName,
    byAvatarCode,
  ];
}
