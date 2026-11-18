import 'package:app/core/widgets/pickers/city_tile.dart';
import 'package:flutter/material.dart';

/// The scrolling list of cities in the city sheet, [height] tall.
class CityList extends StatelessWidget {
  const CityList({
    super.key,
    required this.cities,
    required this.selected,
    required this.height,
    required this.onSelected,
  });

  final List<String> cities;
  final String? selected;
  final double height;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      // Never empty: a name that matches nothing is offered as
      // typed.
      child: ListView.separated(
        itemCount: cities.length,
        separatorBuilder: (BuildContext context, int index) => const Divider(),
        itemBuilder: (BuildContext context, int index) {
          final String city = cities[index];
          return CityTile(
            city: city,
            chosen: city == selected,
            onTap: () => onSelected(city),
          );
        },
      ),
    );
  }
}
