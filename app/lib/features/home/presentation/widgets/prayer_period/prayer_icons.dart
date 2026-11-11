import 'package:app/core/icons/tafaqod_phosphor_icons.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:flutter/widgets.dart';

IconData prayerIcon(Prayer prayer) => switch (prayer) {
  Prayer.fajr => TafaqodPhosphorIcons.sunHorizon,
  Prayer.dhuhr => TafaqodPhosphorIcons.sun,
  Prayer.asr => TafaqodPhosphorIcons.sunDim,
  // Phosphor's sun-horizon glyph is left-right symmetric, so mirroring it
  // for Maghrib looked identical to Fajr. Maghrib is still about the sun
  // (not the moon, which is Isha), so a fading/clouded sun shape instead.
  Prayer.maghrib => TafaqodPhosphorIcons.cloudSun,
  Prayer.isha => TafaqodPhosphorIcons.moonStars,
};
