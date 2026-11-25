import 'package:app/core/errors/auth_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/emergency_card.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The emergency card page (CIRCLE-07, F18). The card is read-only and is built
/// by the server from the medical file, so every visit reads it again and an
/// edit of the file shows at once.
class EmergencyCardCubit extends Cubit<EmergencyCardState> {
  EmergencyCardCubit(this._circles, this.circleId)
    : super(const EmergencyCardState());

  final CirclesUseCase _circles;
  final String circleId;
  int _revision = 0;

  /// Reads the card and, at the same time, the medical file for the age
  /// line (only the file has the birth date). The card shows without the
  /// age when the file cannot be read. A read that a newer one (a retry)
  /// overtook is dropped.
  Future<void> load() async {
    final int revision = ++_revision;
    emit(const EmergencyCardState());
    final (cardResult, fileResult) = await (
      _circles.getEmergencyCard(circleId),
      _circles.getMedicalFile(circleId),
    ).wait;
    if (isClosed || revision != _revision) return;
    cardResult.when(
      (EmergencyCard card) => emit(
        EmergencyCardState(
          status: EmergencyCardStatus.ready,
          card: card,
          birthDate: fileResult.tryGetSuccess()?.patient.birthDate,
        ),
      ),
      (Failure failure) => emit(
        EmergencyCardState(
          status: EmergencyCardStatus.failure,
          messageKey: failure.messageKey,
          sessionEnded:
              failure is UnauthorizedFailure ||
              failure is SessionExpiredFailure,
        ),
      ),
    );
  }
}

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
