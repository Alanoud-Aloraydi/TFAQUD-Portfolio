import 'package:app/features/circles/domain/entities/emergency_card.dart';
import 'package:equatable/equatable.dart';

enum EmergencyCardStatus { loading, ready, failure }

/// What the emergency card page shows: the card read from the server.
class EmergencyCardState extends Equatable {
  const EmergencyCardState({
    this.status = EmergencyCardStatus.loading,
    this.card,
    this.messageKey,
    this.sessionEnded = false,
  });

  final EmergencyCardStatus status;
  final EmergencyCard? card;

  /// Why the load failed: a key in assets/translations.
  final String? messageKey;

  /// True when the server said the sign-in ended; the page goes to sign-in.
  final bool sessionEnded;

  @override
  List<Object?> get props => [status, card, messageKey, sessionEnded];
}
