import 'package:app/core/constants/app_colors.dart';
import 'package:flutter/painting.dart';

/// The colors of the app's character, a small Saturn whose ring goes around
/// the people and things it cares for. Warm honey like the brand, with a
/// light from the top start, darker bands, a night side, and a cream ring.
/// Values with an alpha are shades laid over the body.
abstract class AppMascot {
  AppMascot._();

  // The ball, from the lit spot to the night edge.
  static const Color highlight = Color(0xFFFFF3CF);
  static const Color body = Color(0xFFF2C766);
  static const Color mid = Color(0xFFE9B24E);
  static const Color shade = Color(0xFFB7802A);

  /// The darker and lighter bands across the ball.
  static const Color band = Color(0x52C48028);
  static const Color bandLight = Color(0x73FFF0C8);

  /// The night side, laid over the lower end.
  static const Color night = Color(0x59784610);
  static const Color nightClear = Color(0x00784610);

  /// The glossy spot and the rim light on the lit side.
  static const Color gloss = Color(0xA6FFFFFF);
  static const Color glossClear = Color(0x00FFFFFF);
  static const Color rim = Color(0x8CFFFFFF);

  // The ring, light in the middle and darker at the ends.
  static const Color ringLight = Color(0xFFFFF4DA);
  static const Color ringMid = Color(0xFFF1D49A);
  static const Color ringDark = Color(0xFFD9AE62);
  static const Color ringGroove = Color(0x59B7802A);
  static const Color ringLip = Color(0xB3FFFFFF);

  /// The back half of the ring is on the night side.
  static const Color ringBackShade = Color(0x1F785014);

  /// The ring's shadow on the ball.
  static const Color ringShadow = Color(0x476E3C00);

  // The face.
  static const Color ink = AppColors.ink;
  static const Color eyeLight = Color(0xFFFFFFFF);
  static const Color cheek = Color(0x73F08070);
  static const Color tongue = Color(0xFFF08A7E);

  /// The shine on the shoes and the shadow on the ground.
  static const Color sole = Color(0x40FFFFFF);
  static const Color ground = Color(0x1A202734);
}
