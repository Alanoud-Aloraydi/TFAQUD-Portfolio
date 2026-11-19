import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/medications/domain/entities/extra_dose.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The extra doses of one medicine on its page, newest first: null until
/// they are read. The server keeps three months of doses and answers at
/// most a month at a time, so they are read a month after another.
class ExtraDoseHistoryCubit extends Cubit<List<ExtraDose>?> {
  ExtraDoseHistoryCubit(this._medications) : super(null);

  final MedicationsUseCase _medications;

  static const int _months = 3;
  static const int _monthDays = 31;

  /// A month that fails ends the reading: what was read stays shown.
  Future<void> load(String circleId, String planId, DateTime today) async {
    final List<ExtraDose> doses = <ExtraDose>[];
    for (var month = 0; month < _months; month++) {
      final DateTime to = addDays(today, -month * _monthDays);
      final result = await _medications.getExtraDoses(
        circleId,
        addDays(to, -(_monthDays - 1)),
        to,
        planId: planId,
      );
      if (isClosed) return;
      final List<ExtraDose>? read = result.tryGetSuccess();
      if (read == null) break;
      doses.addAll(read);
    }
    emit(doses);
  }
}
