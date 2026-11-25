import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum CircleOverviewStatus { loading, ready, failure }

/// What the circle tab shows: the circle, the facts of its medical file, and
/// whether a change of the members is on its way.
class CircleOverviewState extends Equatable {
  const CircleOverviewState({
    this.status = CircleOverviewStatus.loading,
    this.overview,
    this.medicalFile,
    this.errorKey,
    this.acting = false,
  });

  final CircleOverviewStatus status;
  final CircleOverview? overview;

  /// Null when the file could not be read: the card leaves its facts out.
  final MedicalFile? medicalFile;

  /// Why the load failed: a key in assets/translations.
  final String? errorKey;

  /// True while an invitation, a resend, a cancel, a change of a member or
  /// the leave is on its way; another one is refused until it ends.
  final bool acting;

  CircleOverviewState copyWith({
    CircleOverviewStatus? status,
    CircleOverview? overview,
    MedicalFile? medicalFile,
    String? errorKey,
    bool? acting,
  }) {
    return CircleOverviewState(
      status: status ?? this.status,
      overview: overview ?? this.overview,
      medicalFile: medicalFile ?? this.medicalFile,
      errorKey: errorKey ?? this.errorKey,
      acting: acting ?? this.acting,
    );
  }

  @override
  List<Object?> get props => [status, overview, medicalFile, errorKey, acting];
}

/// Reading the circle and its medical file together.
mixin CircleOverviewLoading on Cubit<CircleOverviewState>, CircleOverviewScope {
  /// Reads the circle and its medical file. The first read and a retry
  /// after a failure show the loading state; a later read keeps the tab on
  /// screen.
  Future<void> load() async {
    final int revision = ++this.revision;
    final int saves = saveCount;
    if (state.status == CircleOverviewStatus.failure) {
      emit(const CircleOverviewState());
    }
    // The circle and its medical file are read at the same time. The file
    // only adds the facts on the patient card: when it cannot be read, the
    // tab still shows the circle and its members, and the medical file page
    // says why when it is opened.
    final (result, fileResult) = await (
      circles.getCircleOverview(circleId),
      circles.getMedicalFile(circleId),
    ).wait;
    if (isClosed || revision != this.revision) return;
    if (result.isError()) {
      emit(
        CircleOverviewState(
          status: CircleOverviewStatus.failure,
          errorKey: result.tryGetError()!.messageKey,
        ),
      );
      return;
    }
    emit(
      CircleOverviewState(
        status: CircleOverviewStatus.ready,
        overview: result.tryGetSuccess()!,
        medicalFile: saves == saveCount
            ? fileResult.tryGetSuccess()
            : lastSaved,
        acting: state.acting,
      ),
    );
  }
}
