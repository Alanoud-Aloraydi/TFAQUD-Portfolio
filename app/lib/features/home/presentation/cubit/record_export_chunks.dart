import 'package:app/features/home/domain/export_period.dart';
import 'package:app/features/home/presentation/cubit/record_export_scope.dart';
import 'package:app/features/home/presentation/cubit/record_export_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The server answers at most a month at a time, so a long period is read
/// in pieces.
mixin RecordExportChunks on Cubit<RecordExportState>, RecordExportScope {
  static const int _chunkDays = 31;

  Future<List<T>> chunked<T>(
    ExportPeriod period,
    Future<List<T>> Function(String circleId, DateTime from, DateTime to) read,
  ) async {
    final items = <T>[];
    var start = period.start;
    while (!start.isAfter(period.end)) {
      final candidate = DateTime(
        start.year,
        start.month,
        start.day + _chunkDays,
      );
      final end = candidate.isAfter(period.end) ? period.end : candidate;
      items.addAll(await read(circleId, start, end));
      start = DateTime(end.year, end.month, end.day + 1);
    }
    return items;
  }
}
