import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/utils/text_limits.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The longest city name the server keeps (`City` in circles/inputs.py).
const int cityMaxLength = 60;

/// The search field at the top of the city sheet.
class CitySearchField extends StatelessWidget {
  const CitySearchField({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      // The longest city the server keeps.
      inputFormatters: const <TextInputFormatter>[
        CodePointLengthFormatter(cityMaxLength),
      ],
      decoration: InputDecoration(
        hintText: context.tr('circles.city_search'),
        prefixIcon: const Icon(ActionIcons.search),
      ),
    );
  }
}
