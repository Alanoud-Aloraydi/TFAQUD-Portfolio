import 'package:app/features/home/domain/entities/home_entity.dart';

/// Maps the home API payload without retaining clinical or session data.
class HomeModel {
  const HomeModel(this._entity);

  final HomeEntity _entity;

  factory HomeModel.fromJson(Map<String, dynamic> json) {
    final account = json['account'] as Map<String, dynamic>;
    final circles = json['care_circles'] as List<dynamic>;
    return HomeModel(
      HomeEntity(
        accountId: account['id'] as String,
        displayName: account['display_name'] as String?,
        profileComplete: account['profile_complete'] as bool,
        circles: circles.map((item) {
          final circle = item as Map<String, dynamic>;
          return CareCircleSummary(
            id: circle['id'] as String,
            name: circle['name'] as String,
            canManageMedications:
                circle['can_manage_medications'] as bool? ?? false,
          );
        }).toList(),
      ),
    );
  }

  HomeEntity toEntity() => _entity;
}
