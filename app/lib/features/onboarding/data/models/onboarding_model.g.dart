// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OnboardingModel _$OnboardingModelFromJson(Map<String, dynamic> json) =>
    _OnboardingModel(
      id: (json['id'] as num).toInt(),
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
    );

Map<String, dynamic> _$OnboardingModelToJson(_OnboardingModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
    };
