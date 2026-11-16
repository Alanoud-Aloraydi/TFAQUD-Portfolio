import 'dart:async';

import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medications_loading.dart';
import 'package:app/features/medications/presentation/cubit/medications_refresh.dart';
import 'package:app/features/medications/presentation/cubit/medications_revising.dart';
import 'package:app/features/medications/presentation/cubit/medications_scope.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/cubit/medications_stopping.dart';
import 'package:app/features/medications/presentation/cubit/medications_writing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The medicines of one circle, and their changes.
///
/// The home tabs hold one; the medicine pages hold their own. A cubit that
/// read the list ([load]) or one medicine ([loadPlan]) reads it again
/// whenever [MedicationsUseCase.changes] says the circle's medicines
/// changed, wherever the change was saved, so they never disagree. A cubit
/// that only [bind]s a circle (the new-medicine form) shows what it saved
/// and follows nothing.
class MedicationsCubit extends Cubit<MedicationsState>
    with
        MedicationsScope,
        MedicationsLoading,
        MedicationsRefresh,
        MedicationsWriting,
        MedicationsRevising,
        MedicationsStopping {
  MedicationsCubit(this.medications) : super(MedicationsState()) {
    _changes = medications.changes.listen(_onChanged);
  }

  @override
  final MedicationsUseCase medications;

  late final StreamSubscription<String> _changes;

  void _onChanged(String circleId) {
    if (reads && circleId == this.circleId) unawaited(reread());
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
