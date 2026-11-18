import 'package:app/features/simplified_mode/domain/prayer_period.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// آ«ط¨ط¹ط¯ ط§ظ„ظ…ط؛ط±ط¨آ».
String simplifiedPeriod(BuildContext context, PrayerPeriod period) =>
    context.tr('simplified_mode.period.${period.name}');

/// The plain part of the day beside a period: آ«ط§ظ„ظ…ط³ط§ط،آ».
String simplifiedPeriodHint(BuildContext context, PrayerPeriod period) =>
    context.tr('simplified_mode.period_hint.${period.name}');
