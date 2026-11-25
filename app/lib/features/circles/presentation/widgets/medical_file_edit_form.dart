import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/features/circles/domain/entities/medical_options.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_edit_body.dart';
import 'package:app/features/circles/presentation/widgets/medical_name_fields.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The fields and the save button. It is created once the file is loaded and
/// keeps the typed text, which starts from the saved values.
class MedicalFileEditForm extends StatefulWidget {
  const MedicalFileEditForm({
    super.key,
    required this.state,
    required this.savedTo,
    required this.fileRoute,
  });

  final MedicalFileEditState state;

  /// Where to go once the file is saved, when the page was opened on its way
  /// somewhere; `null` goes back to the page under this one.
  final String? savedTo;

  /// The medical file, for a save with no page under this one.
  final String fileRoute;

  @override
  State<MedicalFileEditForm> createState() => _EditFormState();
}

class _EditFormState extends State<MedicalFileEditForm> {
  late final MedicalFormFields _fields = MedicalFormFields(widget.state);

  @override
  void didUpdateWidget(MedicalFileEditForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The typed text of «أخرى» is cleared in the state when «أخرى» is
    // turned off or «لا توجد حساسية» is chosen; the fields follow it.
    _fields.syncWith(widget.state.form);
  }

  @override
  void dispose() {
    _fields.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MedicalFileEditBody(
    state: widget.state,
    fields: _fields,
    savedTo: widget.savedTo,
    fileRoute: widget.fileRoute,
  );
}

/// The text under a group of chips that «أخرى» asks for. [invalid] marks it
/// red once the person tried to save it empty.
class MedicalOtherField extends StatelessWidget {
  const MedicalOtherField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.invalid,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool invalid;

  @override
  Widget build(BuildContext context) => LabeledTextField(
    label: context.tr('circles.other_hint'),
    controller: controller,
    maxLength: MedicalOptions.otherMaxLength,
    textInputAction: TextInputAction.done,
    onChanged: onChanged,
    errorText: invalid ? context.tr('common.field_required') : null,
  );
}
