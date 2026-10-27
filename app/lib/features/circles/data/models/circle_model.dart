import 'package:app/features/home/domain/entities/home_entity.dart';

/// Reads the answer of a circle call: `{"circle": {...}}`. Only the id and the
/// name are kept; the other pages read the rest when they need it.
class CircleModel {
  const CircleModel(this._entity);

  final CareCircleSummary _entity;

  factory CircleModel.fromJson(Map<String, dynamic> json) {
    final circle = json['circle'] as Map<String, dynamic>;
    return CircleModel(
      CareCircleSummary(
        id: circle['id'] as String,
        name: circle['name'] as String,
      ),
    );
  }

  CareCircleSummary toEntity() => _entity;
}
