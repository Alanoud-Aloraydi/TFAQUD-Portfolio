import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/circles/presentation/widgets/time_zone_names.dart';
import 'package:flutter/material.dart';

/// The zones that match the search, a fixed part of the screen high. The
/// chosen one is bold with a check; a tap only marks a zone.
class TimeZoneList extends StatelessWidget {
  const TimeZoneList({
    super.key,
    required this.zones,
    required this.selected,
    required this.onSelected,
  });

  final List<String> zones;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.4,
      child: ListView.builder(
        itemCount: zones.length,
        itemBuilder: (BuildContext context, int index) {
          final String zone = zones[index];
          final bool chosen = zone == selected;
          return ListTile(
            title: Text(
              timeZoneName(zone),
              textDirection: TextDirection.ltr,
              style: text.bodyLarge?.copyWith(
                fontWeight: chosen ? AppTextTheme.bold : AppTextTheme.regular,
              ),
            ),
            trailing: chosen
                ? const Icon(
                    ActionIcons.check,
                    color: AppSemanticColors.textPrimary,
                  )
                : null,
            onTap: () => onSelected(zone),
          );
        },
      ),
    );
  }
}
