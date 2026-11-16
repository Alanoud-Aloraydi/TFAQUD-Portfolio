import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A plain sentence in place of the form: a failure, or nothing to record.
Widget simplifiedMeasureMessage(BuildContext context, String key) => Text(
  context.tr(key),
  style: SimplifiedStyle.text(SimplifiedStyle.body, color: SimplifiedStyle.ink),
);
