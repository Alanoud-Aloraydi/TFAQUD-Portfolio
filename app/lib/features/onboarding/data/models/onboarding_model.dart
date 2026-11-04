import 'package:app/features/onboarding/domain/entities/onboarding_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'onboarding_model.freezed.dart';
part 'onboarding_model.g.dart';

@freezed
/// Maps onboarding data between the API and app.
abstract class OnboardingModel with _$OnboardingModel {
  const factory OnboardingModel({
    required int id,
    required String firstName,
    required String lastName,
  }) = _OnboardingModel;

  factory OnboardingModel.fromJson(Map<String, Object?> json) =>
      _$OnboardingModelFromJson(json);
}

/// Adds onboarding model mapper helpers to its target type.
extension OnboardingModelMapper on OnboardingModel {
  OnboardingEntity toEntity() {
    return OnboardingEntity(id: id, firstName: firstName, lastName: lastName);
  }
}
