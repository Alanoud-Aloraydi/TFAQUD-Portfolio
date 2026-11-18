import 'package:app/features/home/domain/entities/home_entity.dart';

/// The circle with [selectedId], or the first one when none matches.
CareCircleSummary selectedCircleOf(
  List<CareCircleSummary> circles,
  String? selectedId,
) {
  CareCircleSummary selected = circles.first;
  for (final CareCircleSummary circle in circles) {
    if (circle.id == selectedId) selected = circle;
  }
  return selected;
}
