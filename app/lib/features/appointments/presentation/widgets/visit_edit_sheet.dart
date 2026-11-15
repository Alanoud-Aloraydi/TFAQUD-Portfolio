import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/appointments/domain/visit_paper.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/visit_state.dart';
import 'package:app/features/appointments/presentation/visit_paper_texts.dart';
import 'package:app/features/appointments/presentation/widgets/visit_paper_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the «تعديل ورقة الزيارة» sheet holds: the three texts and «حفظ».
/// The glass sheet draws the title, scrolls, and stays above the keyboard.
class VisitEditSheet extends StatefulWidget {
  const VisitEditSheet({super.key, required this.paper});

  final VisitPaper? paper;

  @override
  State<VisitEditSheet> createState() => _VisitEditSheetState();
}

class _VisitEditSheetState extends State<VisitEditSheet> {
  late final VisitPaperTexts _texts = VisitPaperTexts(widget.paper);

  @override
  void dispose() {
    _texts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VisitState state = context.watch<VisitCubit>().state;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (String key, int limit, TextEditingController text)
            in _texts.fields) ...[
          VisitPaperField(titleKey: key, controller: text, limit: limit),
          const SizedBox(height: AppSpacing.md),
        ],
        if (state.errorKey case final String error)
          Text(
            context.tr(error),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        FilledButton(
          onPressed: state.saving ? null : _save,
          child: Text(context.tr('appointments.save')),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final bool saved = await context.read<VisitCubit>().save(_texts.draft);
    if (!saved || !mounted) return;
    AppToast.show(context, 'toast.visit_saved');
    Navigator.of(context).pop();
  }
}
