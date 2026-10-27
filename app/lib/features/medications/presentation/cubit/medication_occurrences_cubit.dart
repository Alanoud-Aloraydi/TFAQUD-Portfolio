import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MedicationOccurrencesCubit extends Cubit<MedicationOccurrencesState> {
  MedicationOccurrencesCubit(this._medications)
    : super(MedicationOccurrencesState());

  final MedicationsUseCase _medications;
  String? _circleId;
  DateTime? _from;
  DateTime? _to;
  String? _planId;
  int _revision = 0;

  Future<void> load(
    String circleId,
    DateTime from,
    DateTime to, {
    String? planId,
  }) async {
    _circleId = circleId;
    _from = from;
    _to = to;
    _planId = planId;
    final revision = ++_revision;
    emit(MedicationOccurrencesState());
    final result = await _medications.getOccurrences(
      circleId,
      from,
      to,
      planId: planId,
    );
    if (isClosed || revision != _revision) return;
    result.when(
      (items) => emit(
        MedicationOccurrencesState(
          status: MedicationOccurrencesStatus.ready,
          occurrences: items,
        ),
      ),
      (failure) => emit(
        MedicationOccurrencesState(
          status: MedicationOccurrencesStatus.failure,
          messageKey: failure.messageKey,
        ),
      ),
    );
  }

  Future<void> reload() async {
    if (_circleId == null || _from == null || _to == null) return;
    await load(_circleId!, _from!, _to!, planId: _planId);
  }

  bool canLoadEarlier(DateTime earliest) =>
      _from != null && earliest.isBefore(_from!);

  Future<void> loadEarlier(DateTime earliest) async {
    final circleId = _circleId;
    final currentFrom = _from;
    if (circleId == null ||
        currentFrom == null ||
        !earliest.isBefore(currentFrom)) {
      return;
    }
    final to = currentFrom.subtract(const Duration(days: 1));
    final candidate = currentFrom.subtract(const Duration(days: 32));
    final from = candidate.isBefore(earliest) ? earliest : candidate;
    emit(
      MedicationOccurrencesState(
        status: MedicationOccurrencesStatus.loadingMore,
        occurrences: state.occurrences,
      ),
    );
    final result = await _medications.getOccurrences(
      circleId,
      from,
      to,
      planId: _planId,
    );
    if (isClosed) return;
    result.when(
      (items) {
        _from = from;
        emit(
          MedicationOccurrencesState(
            status: MedicationOccurrencesStatus.ready,
            occurrences: [...items, ...state.occurrences],
          ),
        );
      },
      (failure) => emit(
        MedicationOccurrencesState(
          status: MedicationOccurrencesStatus.ready,
          occurrences: state.occurrences,
          messageKey: failure.messageKey,
        ),
      ),
    );
  }

  Future<bool> record(DoseOccurrence occurrence, DoseRecordDraft record) async {
    final circleId = _circleId;
    if (circleId == null ||
        state.status == MedicationOccurrencesStatus.recording) {
      return false;
    }
    emit(
      MedicationOccurrencesState(
        status: MedicationOccurrencesStatus.recording,
        occurrences: state.occurrences,
      ),
    );
    final result = await _medications.recordDose(circleId, occurrence, record);
    if (isClosed) return false;
    return result.when(
      (saved) async {
        final occurrences = [
          for (final item in state.occurrences)
            if (item.scheduleId == occurrence.scheduleId &&
                item.scheduledOn == occurrence.scheduledOn)
              item.withRecord(saved)
            else
              item,
        ];
        emit(
          MedicationOccurrencesState(
            status: MedicationOccurrencesStatus.ready,
            occurrences: occurrences,
          ),
        );
        return true;
      },
      (failure) async {
        emit(
          MedicationOccurrencesState(
            status: MedicationOccurrencesStatus.ready,
            occurrences: state.occurrences,
            messageKey: failure.messageKey,
          ),
        );
        return false;
      },
    );
  }
}
