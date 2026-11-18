import 'package:equatable/equatable.dart';

/// One notification the phone shows at [at], even when the app is closed.
///
/// [payload] says what it is about (the app reads it when the person taps
/// it), and [thread] stacks the notifications of one person together.
class ScheduledNotification extends Equatable {
  const ScheduledNotification({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.payload,
    this.thread,
    this.snoozable = false,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;
  final String payload;
  final String? thread;

  /// Whether the notification offers «ذكّرني بعد 15 دقيقة» when pressed
  /// and held (a dose or a measurement).
  final bool snoozable;

  @override
  List<Object?> get props => [id, at, title, body, payload, thread, snoozable];
}
