import 'package:app/core/services/dose_retention_memory.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Through which day the warning before doses are deleted was answered:
/// `read` is false until it is known, so nothing shows meanwhile.
typedef DoseRetentionRead = ({bool read, DateTime? settled});

/// [DoseRetentionRead] of [circleId] on this phone.
class DoseRetentionCubit extends Cubit<DoseRetentionRead> {
  DoseRetentionCubit(this._memory, this.circleId)
    : super((read: false, settled: null));

  final DoseRetentionMemory _memory;
  final String circleId;

  Future<void> load() async {
    final DateTime? settled = await _memory.settled(circleId);
    if (!isClosed) emit((read: true, settled: settled));
  }

  /// Exported, or set aside: the warning comes back with the next days.
  Future<void> settle(DateTime through) async {
    emit((read: true, settled: through));
    await _memory.settle(circleId, through);
  }
}
