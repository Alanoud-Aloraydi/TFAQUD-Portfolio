import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/inline_error.dart';
import 'package:app/features/medications/presentation/cubit/extra_dose_cubit.dart';
import 'package:app/features/medications/presentation/cubit/extra_dose_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «حفظ الجرعة», off while the dose is on its way, with why the last try
/// was not saved above it.
class ExtraDoseSaveButton extends StatelessWidget {
  const ExtraDoseSaveButton({
    super.key,
    required this.onPressed,
    this.missingKey,
  });

  final VoidCallback onPressed;

  /// What is missing in the sheet itself: a key in assets/translations.
  final String? missingKey;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ExtraDoseCubit, ExtraDoseState>(
        builder: (BuildContext context, ExtraDoseState state) {
          final String? errorKey = missingKey ?? state.errorKey;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (errorKey != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                InlineError(messageKey: errorKey),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: state.saving ? null : onPressed,
                child: Text(context.tr('medications.dose_now_save')),
              ),
            ],
          );
        },
      );
}
