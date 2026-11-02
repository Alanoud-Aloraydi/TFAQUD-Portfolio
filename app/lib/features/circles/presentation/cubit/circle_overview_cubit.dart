import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum CircleOverviewStatus { loading, ready, failure }

class CircleOverviewState extends Equatable {
  const CircleOverviewState({
    this.status = CircleOverviewStatus.loading,
    this.overview,
    this.medicalFile,
    this.errorKey,
  });

  final CircleOverviewStatus status;
  final CircleOverview? overview;
  final MedicalFile? medicalFile;
  final String? errorKey;

  @override
  List<Object?> get props => [status, overview, medicalFile, errorKey];
}

/// Loads the selected circle independently of the home shell.
class CircleOverviewCubit extends Cubit<CircleOverviewState> {
  CircleOverviewCubit(this._circles, this.circleId)
    : super(const CircleOverviewState());

  final CirclesUseCase _circles;
  final String circleId;

  Future<void> load() async {
    final result = await _circles.getCircleOverview(circleId);
    if (isClosed) return;
    if (result.isError()) {
      emit(
        CircleOverviewState(
          status: CircleOverviewStatus.failure,
          errorKey: result.tryGetError()!.messageKey,
        ),
      );
      return;
    }
    final overview = result.tryGetSuccess()!;
    // The medical file only adds the facts on the patient card. When it
    // cannot be read, the tab still shows the circle and its members, and
    // the medical file page says why when it is opened.
    final fileResult = await _circles.getMedicalFile(circleId);
    if (isClosed) return;
    emit(
      CircleOverviewState(
        status: CircleOverviewStatus.ready,
        overview: overview,
        medicalFile: fileResult.tryGetSuccess(),
      ),
    );
  }

  /// Returns an error key, or null after the invitation is saved.
  Future<String?> invite(String nationalNumber) async {
    if (!RegExp(r'^5[0-9]{8}$').hasMatch(nationalNumber)) {
      return 'circle_overview.phone_invalid';
    }
    final result = await _circles.inviteManager(
      circleId,
      '+966$nationalNumber',
    );
    if (isClosed) return null;
    String? errorKey;
    result.when((_) {}, (Failure failure) => errorKey = failure.messageKey);
    if (errorKey != null) return errorKey;
    await load();
    return null;
  }

  Future<String?> resendInvitation(String invitationId) async {
    final result = await _circles.resendManagerInvitation(
      circleId,
      invitationId,
    );
    if (isClosed) return null;
    if (result.isError()) return result.tryGetError()!.messageKey;
    await load();
    return null;
  }

  Future<String?> cancelInvitation(String invitationId) async {
    final result = await _circles.cancelManagerInvitation(
      circleId,
      invitationId,
    );
    if (isClosed) return null;
    if (result.isError()) return result.tryGetError()!.messageKey;
    await load();
    return null;
  }

  Future<String?> leave({required bool confirmDelete}) async {
    final result = await _circles.leaveCircle(
      circleId,
      confirmDelete: confirmDelete,
    );
    if (isClosed) return null;
    return result.isError() ? result.tryGetError()!.messageKey : null;
  }
}
