import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:equatable/equatable.dart';

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
