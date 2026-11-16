import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/utils/text_limits.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_form.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The free note «أخرى» asks for, 250 characters at most.
Widget simplifiedMeasureNote(
  BuildContext context,
  SimplifiedMeasureForm form,
) => TextField(
  controller: form.note,
  maxLength: 250,
  inputFormatters: const [CodePointLengthFormatter(250)],
  style: SimplifiedStyle.text(
    SimplifiedStyle.body,
    color: SimplifiedStyle.ink,
    weight: AppTextTheme.medium,
  ),
  decoration: InputDecoration(
    hintText: context.tr('simplified_mode.other_hint'),
    filled: true,
    fillColor: SimplifiedStyle.surface,
    contentPadding: const EdgeInsets.all(18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: SimplifiedStyle.ink, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: SimplifiedStyle.ink, width: 2),
    ),
  ),
);
