import 'package:flutter/widgets.dart';

/// The Phosphor regular glyphs of the visit kinds that have none in AppIcons
/// (phosphor_flutter 2.1.0 code points), not mirrored, as AppIcons declares
/// its own. Read through appointmentKindIcon.
abstract final class AppointmentIcons {
  static const String _family = 'PhosphorRegular';
  static const String _package = 'phosphor_flutter';

  static const IconData stethoscope = IconData(
    0xe7ea, // مراجعة
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData clipboardText = IconData(
    0xe198, // كشف جديد
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData videoCamera = IconData(
    0xe4da, // استشارة عن بُعد
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData ambulance = IconData(
    0xe572, // طوارئ
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData testTube = IconData(
    0xe7a0, // تحليل
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData scan = IconData(
    0xebb6, // أشعة
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData eye = IconData(
    0xe220, // فحص نظر
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData ear = IconData(
    0xe70c, // فحص سمع
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData hospital = IconData(
    0xe844, // عملية
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData personSimpleWalk = IconData(
    0xe73a, // علاج طبيعي
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData handHeart = IconData(
    0xe810, // جلسة علاج
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData bandaids = IconData(
    0xe0b2, // تغيير ضماد أو إبرة
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData syringe = IconData(
    0xe968, // تطعيم
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData tooth = IconData(
    0xe9cc, // أسنان
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData brain = IconData(
    0xe74e, // جلسة نفسية
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData userSound = IconData(
    0xeca8, // جلسة نطق وتخاطب
    fontFamily: _family,
    fontPackage: _package,
  );
}
