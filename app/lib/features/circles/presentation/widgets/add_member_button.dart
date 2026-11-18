import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/widgets/invite_member_sheet.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
