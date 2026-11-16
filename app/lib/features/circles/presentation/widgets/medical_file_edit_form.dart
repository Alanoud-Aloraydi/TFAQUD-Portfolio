import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:app/features/circles/presentation/widgets/medical_file_edit_body.dart';
import 'package:app/features/circles/presentation/widgets/medical_form_fields.dart';
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
