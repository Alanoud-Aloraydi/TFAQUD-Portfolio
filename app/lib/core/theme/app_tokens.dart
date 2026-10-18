import 'package:app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Colors that have no slot in ColorScheme. Accessed through context.tokens.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.success,
    required this.successInk,
    required this.successTint,
    required this.warningInk,
    required this.warningTint,
  });

  final Color success;
  final Color successInk;
  final Color successTint;
  final Color warningInk;
  final Color warningTint;

  static const AppTokens light = AppTokens(
    success: AppColors.success,
    successInk: AppColors.successInk,
    successTint: AppColors.successTint,
    warningInk: AppColors.warningInk,
    warningTint: AppColors.warningTint,
  );

  @override
  AppTokens copyWith({
    Color? success,
    Color? successInk,
    Color? successTint,
    Color? warningInk,
    Color? warningTint,
  }) {
    return AppTokens(
      success: success ?? this.success,
      successInk: successInk ?? this.successInk,
      successTint: successTint ?? this.successTint,
      warningInk: warningInk ?? this.warningInk,
      warningTint: warningTint ?? this.warningTint,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      success: Color.lerp(success, other.success, t)!,
      successInk: Color.lerp(successInk, other.successInk, t)!,
      successTint: Color.lerp(successTint, other.successTint, t)!,
      warningInk: Color.lerp(warningInk, other.warningInk, t)!,
      warningTint: Color.lerp(warningTint, other.warningTint, t)!,
    );
  }
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
