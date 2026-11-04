import 'package:app/features/auth/domain/entities/auth_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'auth_model.freezed.dart';
part 'auth_model.g.dart';

@freezed
/// Maps auth data between the API and app.
abstract class AuthModel with _$AuthModel {
  const factory AuthModel({
    required int id,
    required String firstName,
    required String lastName,
  }) = _AuthModel;

  factory AuthModel.fromJson(Map<String, Object?> json) =>
      _$AuthModelFromJson(json);
}

/// Adds auth model mapper helpers to its target type.
extension AuthModelMapper on AuthModel {
  AuthEntity toEntity() {
    return AuthEntity(id: id, firstName: firstName, lastName: lastName);
  }
}
