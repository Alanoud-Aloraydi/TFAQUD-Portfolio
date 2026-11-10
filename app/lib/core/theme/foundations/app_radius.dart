import 'package:flutter/material.dart';

/// Concentric radius scale of the design system: an inner corner equals its
/// container's radius minus the padding between them (Apple).
/// A radius-l card with 16 padding holds radius-s shapes (28 − 16 = 12);
/// with 8 padding it holds a radius-m panel (28 − 8 = 20).
abstract class AppRadius {
  AppRadius._();

  /// Alerts: a 48 capsule button 12 inside the panel (24 + 12).
  static const double xl = 36;
  static const double l = 28; // standalone cards and grouped lists
  static const double m = 20; // nested in an l card with 8 padding
  static const double s = 12; // fields and tiles in an l card with 16 padding
  static const double xs = 4; // marks in an s shape with 8 padding

  /// Capsules: the radius is half the height (design system radius-capsule).
  static const double capsule = 999;

  /// Older names, kept so existing screens follow the new scale.
  static const double card = l;
  static const double field = s;
  static const double sheet = l;

  /// Rounded superellipse: the iOS corner shape (60% smoothing in Figma).
  static RoundedSuperellipseBorder shape(
    double radius, {
    BorderSide side = BorderSide.none,
  }) {
    return RoundedSuperellipseBorder(
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      side: side,
    );
  }
}
