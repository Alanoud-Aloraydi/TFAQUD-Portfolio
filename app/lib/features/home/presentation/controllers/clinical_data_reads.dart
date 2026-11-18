import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/controllers/clinical_data_loader.dart';

/// What the loader reads, and the pull-down read again.
extension ClinicalDataReads on ClinicalDataLoader {
  /// A main page pulled down: read again quietly, done once all is back.
  Future<void> reload(CareCircleSummary circle) =>
      Future.wait(readAll(circle, quiet: true));

  List<Future<void>> readAll(CareCircleSummary circle, {required bool quiet}) {
    final String id = circle.id;
    final DateTime today = circle.clock.today();
    final window = occurrenceWindow(today);
    return <Future<void>>[
      medications.load(id, silent: quiet),
      measurementPlans.load(id, silent: quiet),
      appointments.load(id, silent: quiet),
      measurementTasks.load(id, today, silent: quiet),
      measurementReadings.load(id, today, today, silent: quiet),
      occurrences.load(id, window.from, window.to, silent: quiet),
      prayers.load(id, circle.timeZone),
    ];
  }
}
