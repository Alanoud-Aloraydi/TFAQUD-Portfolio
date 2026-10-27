import 'package:app/core/widgets/inline_error.dart';
import 'package:app/core/widgets/labeled_text_field.dart';
import 'package:app/core/widgets/pill_button.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Which names a sheet changes. The other names are sent as they are, because
/// the server takes the three together.
enum ProfileField { displayName, fullName }

/// Opens the sheet that changes the display name or the full name. The sheet
/// is above the page, so it receives [cubit] and does not look for it.
Future<void> showProfileEditSheet(
  BuildContext context, {
  required AccountCubit cubit,
  required ProfileField field,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext sheetContext) =>
        _ProfileEditSheet(cubit: cubit, field: field),
  );
}

class _ProfileEditSheet extends StatefulWidget {
  const _ProfileEditSheet({required this.cubit, required this.field});

  final AccountCubit cubit;
  final ProfileField field;

  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  late final TextEditingController _first;
  late final TextEditingController _last;
  late final TextEditingController _display;
  bool _saving = false;
  bool _showErrors = false;
  String? _errorKey;

  @override
  void initState() {
    super.initState();
    final AccountSummary? account = widget.cubit.state.account;
    _first = TextEditingController(text: account?.firstName ?? '');
    _last = TextEditingController(text: account?.lastName ?? '');
    _display = TextEditingController(text: account?.displayName ?? '');
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _display.dispose();
    super.dispose();
  }

  bool get _complete => widget.field == ProfileField.displayName
      ? _display.text.trim().isNotEmpty
      : _first.text.trim().isNotEmpty && _last.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (_saving) return;
    if (!_complete) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() {
      _saving = true;
      _errorKey = null;
    });
    final String? failure = await widget.cubit.saveProfile(
      firstName: _first.text,
      lastName: _last.text,
      displayName: _display.text,
    );
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _errorKey = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String requiredText = context.tr('circles.field_required');
    final bool displayOnly = widget.field == ProfileField.displayName;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  context.tr(
                    displayOnly
                        ? 'account.edit_display_title'
                        : 'account.edit_full_title',
                  ),
                  style: text.titleLarge,
                ),
              ),
              const SizedBox(height: 16),
              if (displayOnly)
                LabeledTextField(
                  label: context.tr('account.display_name'),
                  controller: _display,
                  maxLength: AccountCubit.maxDisplayNameLength,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  helperText: context.tr('onboarding.display_name_hint'),
                  onChanged: (String _) => setState(() => _errorKey = null),
                  errorText: _showErrors && _display.text.trim().isEmpty
                      ? requiredText
                      : null,
                )
              else ...<Widget>[
                LabeledTextField(
                  label: context.tr('onboarding.first_name'),
                  controller: _first,
                  maxLength: AccountCubit.maxNameLength,
                  autofocus: true,
                  onChanged: (String _) => setState(() => _errorKey = null),
                  errorText: _showErrors && _first.text.trim().isEmpty
                      ? requiredText
                      : null,
                ),
                const SizedBox(height: 16),
                LabeledTextField(
                  label: context.tr('onboarding.last_name'),
                  controller: _last,
                  maxLength: AccountCubit.maxNameLength,
                  textInputAction: TextInputAction.done,
                  onChanged: (String _) => setState(() => _errorKey = null),
                  errorText: _showErrors && _last.text.trim().isEmpty
                      ? requiredText
                      : null,
                ),
              ],
              if (_errorKey != null) ...<Widget>[
                const SizedBox(height: 16),
                InlineError(messageKey: _errorKey!),
              ],
              const SizedBox(height: 24),
              PillButton(
                label: context.tr('account.save'),
                isLoading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
