import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/emergency_card.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/emergency_card_state.dart';
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
