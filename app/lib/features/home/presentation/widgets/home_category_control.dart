import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The three kinds of care that «الخطة» and «السجل» split their pages by.
/// The order is the order of the segments and of the pages.
enum HomeCategory { medications, measurements, appointments }

/// Remembers which [HomeCategory] a tab page shows, for the page's
/// [HomeCategoryControl] and its pages (`category.index` is the page).
mixin HomeCategorySelection<T extends StatefulWidget> on State<T> {
  HomeCategory category = HomeCategory.medications;

  /// Shows [value]; the same one again does nothing.
  void selectCategory(HomeCategory value) {
    if (value != category) setState(() => category = value);
  }
}

/// Shared category selector for home composition tabs. The counts are shown
/// beside the labels unless [showCounts] is false.
class HomeCategoryControl extends StatelessWidget {
  const HomeCategoryControl({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.counts,
    this.showCounts = true,
  });

  final HomeCategory selected;
  final ValueChanged<HomeCategory> onChanged;

  /// How many of each kind there are.
  final Map<HomeCategory, int> counts;
  final bool showCounts;

  @override
  Widget build(BuildContext context) => GlassSegmentedControl<HomeCategory>(
    segments: <HomeCategory, String>{
      for (final HomeCategory value in HomeCategory.values)
        value: context.tr('home_category.${value.name}'),
    },
    selected: selected,
    onChanged: onChanged,
    counts: showCounts ? counts : null,
  );
}
