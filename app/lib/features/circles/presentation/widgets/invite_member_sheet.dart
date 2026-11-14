import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/forms/phone_field.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The sheet of «إضافة عضو»: the number and «إرسال الدعوة».
class InviteMemberSheet extends StatefulWidget {
  const InviteMemberSheet({super.key, required this.cubit});

  final CircleOverviewCubit cubit;

  @override
  State<InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends State<InviteMemberSheet> {
  final TextEditingController _phone = TextEditingController();
  String? _errorKey;
  bool _saving = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_saving) return;
    setState(() => _saving = true);
    final String? error = await widget.cubit.invite(
      ArabicDigits.digitsOnly(_phone.text),
    );
    if (!mounted) return;
    if (error == null) {
      AppToast.show(context, 'toast.invite_sent');
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _errorKey = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PhoneField(
          controller: _phone,
          autofocus: false,
          onChanged: (_) => setState(() => _errorKey = null),
          showError: _errorKey == 'circle_overview.phone_invalid',
        ),
        if (_errorKey != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              context.tr(_errorKey!),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppSemanticColors.statusError),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: _saving ? null : _send,
          style: FilledButton.styleFrom(
            backgroundColor: AppSemanticColors.textPrimary,
            foregroundColor: AppSemanticColors.surfaceContent,
            iconColor: AppSemanticColors.accentLeaf,
          ),
          icon: const Icon(AppIcons.paperPlane, size: AppSizes.iconSmall),
          label: Text(context.tr('circle_overview.send_invite')),
        ),
      ],
    );
  }
}
