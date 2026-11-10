import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/picker_field.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/core/widgets/pickers/city_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The person's own birth date and city, each a row that opens its sheet.
/// Used by onboarding and by the circle pages of the person's own care when
/// the account has not saved them.
class BirthDateCityFields extends StatelessWidget {
  const BirthDateCityFields({
    super.key,
    required this.birthDate,
    required this.city,
    required this.onBirthDate,
    required this.onCity,
    this.showErrors = false,
  });

  final DateTime? birthDate;
  final String? city;
  final ValueChanged<DateTime> onBirthDate;
  final ValueChanged<String> onCity;

  /// After a tap on the main button with a field still empty.
  final bool showErrors;

  Future<void> _pickBirthDate(BuildContext context) async {
    final DateTime? picked = await showBirthDateSheet(
      context,
      selected: birthDate,
    );
    if (picked != null) onBirthDate(picked);
  }

  Future<void> _pickCity(BuildContext context) async {
    final String? picked = await showCitySheet(context, selected: city);
    if (picked != null) onCity(picked);
  }

  @override
  Widget build(BuildContext context) {
    final String requiredText = context.tr('common.field_required');
    final DateTime? date = birthDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PickerField(
          label: context.tr('circles.birth_date'),
          hint: context.tr('circles.birth_date_hint'),
          icon: AppIcons.calendar,
          value: date == null ? null : formatBirthDate(context, date),
          onTap: () => _pickBirthDate(context),
          errorText: showErrors && date == null ? requiredText : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        PickerField(
          label: context.tr('circles.city'),
          hint: context.tr('circles.city_hint'),
          icon: AppIcons.mapPin,
          value: city,
          onTap: () => _pickCity(context),
          errorText: showErrors && city == null ? requiredText : null,
        ),
      ],
    );
  }
}
