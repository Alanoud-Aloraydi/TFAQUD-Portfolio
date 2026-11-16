import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/medical_gap.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The words of the missing answers, joined: «فصيلة الدم، الأمراض المزمنة».
String medicalGapsText(BuildContext context, List<MedicalGap> gaps) => gaps
    .map((MedicalGap gap) => context.tr('medical_alert.gap.${gap.name}'))
    .join(context.tr('medical_alert.separator'));
