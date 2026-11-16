import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the circle tab is bound to, shared by everything it does.
mixin CircleOverviewScope on Cubit<CircleOverviewState> {
  CirclesUseCase get circles;

  /// The circle shown.
  String get circleId;

  /// How many files were saved elsewhere since this tab opened, and the
  /// last one. A read that was on its way during a save is older than it.
  int saveCount = 0;
  MedicalFile? lastSaved;

  /// Counts the reads of the circle; only the newest one is shown.
  int revision = 0;
}
