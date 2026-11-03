import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/account/presentation/widgets/settings_card.dart';
import 'package:app/features/circles/presentation/widgets/request_sent_view.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Full-screen account name editor; the verified phone number stays read-only.
class AccountEditScreen extends StatefulWidget {
  const AccountEditScreen({super.key});

  @override
  State<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends State<AccountEditScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _display = TextEditingController();
  bool _filled = false;
  bool _saving = false;
  String? _errorKey;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _display.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _errorKey = null;
    });
    final error = await context.read<AccountCubit>().saveProfile(
      firstName: _first.text,
      lastName: _last.text,
      displayName: _display.text,
    );
    if (!mounted) return;
    if (error == null) {
      context.pop(true);
    } else {
      setState(() {
        _saving = false;
        _errorKey = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: BlocConsumer<AccountCubit, AccountState>(
          listener: (context, state) {
            if (state.sessionEnded) {
              context.go(Routes.auth);
              return;
            }
            final account = state.account;
            if (_filled || account == null) return;
            _first.text = account.firstName;
            _last.text = account.lastName;
            _display.text = account.displayName;
            _filled = true;
          },
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(context.tr('account.cancel')),
                  ),
                  Expanded(
                    child: Text(
                      context.tr('account.edit_title'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FilledButton(
                    onPressed: state.status == AccountStatus.ready && !_saving
                        ? _save
                        : null,
                    child: Text(context.tr('account.save')),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (state.status == AccountStatus.loading)
                const Center(child: CircularProgressIndicator())
              else if (state.status == AccountStatus.failure)
                TextButton(
                  onPressed: context.read<AccountCubit>().load,
                  child: Text(context.tr(state.messageKey ?? 'error.unknown')),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _NameField(
                                label: context.tr('onboarding.first_name'),
                                controller: _first,
                                onChanged: (_) =>
                                    setState(() => _errorKey = null),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _NameField(
                                label: context.tr('onboarding.last_name'),
                                controller: _last,
                                onChanged: (_) =>
                                    setState(() => _errorKey = null),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        LabeledTextField(
                          label: context.tr('account.display_name'),
                          controller: _display,
                          maxLength: AccountCubit.maxDisplayNameLength,
                          onChanged: (_) => setState(() => _errorKey = null),
                        ),
                        const SizedBox(height: AppSpacing.labelGap),
                        InsetText.note(context.tr('account.display_name_help')),
                        const SizedBox(height: AppSpacing.lg),
                        SettingsSection(
                          title: context.tr('account.phone'),
                          children: [
                            InfoRow(
                              label: context.tr('account.phone'),
                              value: RequestSentView.displayPhone(
                                state.account!.phoneNumber,
                              ),
                              ltr: true,
                            ),
                          ],
                        ),
                        if (_errorKey != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          InsetText(
                            context.tr(_errorKey!),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _NameField extends StatelessWidget {
  const _NameField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.inset),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall),
      ),
      const SizedBox(height: AppSpacing.labelGap),
      TextField(
        controller: controller,
        maxLength: AccountCubit.maxNameLength,
        textAlign: TextAlign.start,
        textDirection: TextDirection.rtl,
        onChanged: onChanged,
        decoration: InputDecoration(
          // White with a line edge, from the theme, so the field shows on
          // the page.
          counterText: '',
          constraints: const BoxConstraints(minHeight: AppSizes.touch),
        ),
      ),
    ],
  );
}
