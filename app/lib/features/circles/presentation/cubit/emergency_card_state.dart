import 'package:app/features/circles/domain/entities/emergency_card.dart';
import 'package:equatable/equatable.dart';

/// Defines the supported emergency card status values.
enum EmergencyCardStatus { loading, ready, failure }

/// What the emergency card page shows: the card read from the server.
class EmergencyCardState extends Equatable {
  const EmergencyCardState({
    this.status = EmergencyCardStatus.loading,
    this.card,
    this.messageKey,
    this.sessionEnded = false,
    this.birthDate,
  });

  final EmergencyCardStatus status;
  final EmergencyCard? card;

  /// Why the load failed: a key in assets/translations.
  final String? messageKey;

  /// True when the server said the sign-in ended; the page goes to sign-in.
  final bool sessionEnded;

  /// From the medical file, for the age line under the name. The card itself
  /// leaves out the birth date; null when the file could not be read.
  final DateTime? birthDate;

  @override
  List<Object?> get props => [
    status,
    card,
    messageKey,
    sessionEnded,
    birthDate,
  ];
}
