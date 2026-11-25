import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/forms/phone_field.dart';
import 'package:app/core/widgets/overlays/glass_menu_route.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One switch per category (doses, measurements, appointments), each this
/// circle's own setting — someone in several circles may want only one
/// circle's appointments on their phone's calendar, say.
/// «الأعضاء», and at the end how many members and pending invitations
/// there are: «3 أعضاء، دعوة معلّقة».
class CircleMembersHeader extends StatelessWidget {
  const CircleMembersHeader({super.key, required this.overview});

  final CircleOverview overview;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final int invitations = overview.pendingInvitations.length;
    final String summary = <String>[
      _count(context, 'members_count', overview.members.length),
      if (invitations > 0) _count(context, 'invitations', invitations),
    ].join('، ');
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xl,
        bottom: AppSpacing.labelGap,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              context.tr('circle_overview.members'),
              style: text.headlineMedium,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              summary,
              textAlign: TextAlign.end,
              style: text.bodySmall,
              semanticsLabel: spoken(summary),
            ),
          ),
        ],
      ),
    );
  }

  /// Arabic counting for members and invitations.
  /// The number is written 0-9.
  static String _count(BuildContext context, String noun, int count) {
    final String key = switch (count) {
      1 => 'one',
      2 => 'two',
      <= 10 => 'few',
      _ => 'many',
    };
    return context.tr('circle_overview.${noun}_$key', args: <String>['$count']);
  }
}

/// «إضافة عضو», which opens the invitation sheet. Disabled while another
/// change to the circle is on its way.
class AddMemberButton extends StatelessWidget {
  const AddMemberButton({super.key, required this.acting});

  final bool acting;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: acting ? null : () => _invite(context),
      icon: const Icon(PeopleIcons.userPlus, size: AppSizes.iconSmall),
      label: Text(context.tr('circle_overview.add_member')),
    );
  }

  void _invite(BuildContext context) {
    final CircleOverviewCubit cubit = context.read<CircleOverviewCubit>();
    showGlassSheet<void>(
      context,
      title: context.tr('circle_overview.add_member'),
      message: context.tr('circle_overview.invite_hint'),
      builder: (_) => InviteMemberSheet(cubit: cubit),
    );
  }
}

/// The sheet of «إضافة عضو»: the number and «إرسال الدعوة». A refused
/// invitation is said under the number, the sheet's one field, right above
/// the button (a toast would be hidden behind the sheet).
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
          error: _errorKey == null ? null : context.tr(_errorKey!),
        ),
        const SizedBox(height: AppSpacing.lg),
        InviteSendButton(onPressed: _saving ? null : _send),
      ],
    );
  }
}

/// «إرسال الدعوة» in ink with the paper plane in leaf. Null [onPressed]
/// while the invitation is on its way.
class InviteSendButton extends StatelessWidget {
  const InviteSendButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppSemanticColors.textPrimary,
        foregroundColor: AppSemanticColors.surfaceContent,
        iconColor: AppSemanticColors.accentLeaf,
      ),
      icon: const Icon(PeopleIcons.paperPlane, size: AppSizes.iconSmall),
      label: Text(context.tr('circle_overview.send_invite')),
    );
  }
}
