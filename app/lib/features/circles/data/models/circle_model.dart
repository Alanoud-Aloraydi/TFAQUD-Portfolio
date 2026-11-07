import 'package:app/features/home/domain/entities/home_entity.dart';

/// Reads the answer of a circle call: `{"circle": {...}}`. Only the id and the
/// name are kept; the other pages read the rest when they need it.
///
/// `complete_creation`'s answer alone also carries `account_app_mode`: the
/// actor's own app mode right after it was committed, so the app can switch
/// shells immediately instead of waiting for the next sign-in.
class CircleModel {
  const CircleModel(this._entity, {this.accountAppMode});

  final CareCircleSummary _entity;
  final String? accountAppMode;

  factory CircleModel.fromJson(Map<String, dynamic> json) {
    final circle = json['circle'] as Map<String, dynamic>;
    return CircleModel(
      CareCircleSummary(
        id: circle['id'] as String,
        name: circle['name'] as String,
      ),
      accountAppMode: json['account_app_mode'] as String?,
    );
  }

  CareCircleSummary toEntity() => _entity;
}
