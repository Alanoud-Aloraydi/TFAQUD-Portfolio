import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_earlier.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What a doses cubit is pointed at: the circle, the range of the patient's
/// days it shows, the one medicine when it shows only one, and the counters
/// that tell its own answers and its newest reading apart.
mixin MedicationOccurrencesScope on Cubit<MedicationOccurrencesState> {
  /// The use case the cubit was made with.
  MedicationsUseCase get medications;

  /// The real moment now, for a dose taken now; tests give their own.
  DateTime Function() get clock;

  String? circleId;
  DateTime? from;
  DateTime? to;
  String? planId;

  /// The circles of this cubit's answers being saved, one entry each. The
  /// use case announces each accepted answer on its changes, whenever that
  /// reaches the listener, and that announcement is not read again.
  final List<String> ownSaves = <String>[];

  /// Goes up at each load, so an older reading that ends later is dropped.
  int revision = 0;
}
