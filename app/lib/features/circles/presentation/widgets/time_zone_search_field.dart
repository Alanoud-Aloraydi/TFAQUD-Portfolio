import 'package:app/core/constants/app_icons.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The search field over the zones. The zone names are Latin, so it reads
/// left to right whatever the app's language.
class TimeZoneSearchField extends StatelessWidget {
  const TimeZoneSearchField({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        hintText: context.tr('circles.time_zone_search'),
        prefixIcon: const Icon(ActionIcons.search),
      ),
    );
  }
}
