import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/network/circle_endpoints.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/core/widgets/navigation/white_filter_menu.dart';
import 'package:app/features/appointments/presentation/cubit/appointment_companions_cubit.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_lead_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «المرافقون»: a chip for each member who can go, checked when [chosen];
/// a tap toggles one ([onToggle]), and going is optional.
class AppointmentCompanionChips extends StatelessWidget {
  const AppointmentCompanionChips({
    super.key,
    required this.circleId,
    required this.state,
    required this.chosen,
    required this.onToggle,
  });

  final String circleId;
  final AppointmentCompanionsState state;
  final Set<String> chosen;
  final void Function(String id, bool selected) onToggle;

  @override
  Widget build(BuildContext context) => InsetBlock(
    child: state.loading
        ? const LoadingNote()
        : state.errorKey != null
        ? TextButton(
            onPressed: () =>
                context.read<AppointmentCompanionsCubit>().load(circleId),
            child: Text(context.tr(state.errorKey!)),
          )
        : state.companions.isEmpty
        ? Text(context.tr('appointments.no_companions'))
        : Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final item in state.companions)
                FilterChip(
                  avatar: PersonPhoto(
                    name: item.name,
                    photoPath: CircleEndpoints.memberPhoto(circleId, item.id),
                    avatarCode: item.avatarCode,
                    size: 20,
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(item.name),
                      if (chosen.contains(item.id)) ...<Widget>[
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(ActionIcons.check, size: 16),
                      ],
                    ],
                  ),
                  showCheckmark: false,
                  selected: chosen.contains(item.id),
                  onSelected: (bool selected) => onToggle(item.id, selected),
                ),
            ],
          ),
  );
}

/// The menu that narrows «السجل» to one kind of its visits.
class AppointmentRecordFilterMenu extends StatelessWidget {
  const AppointmentRecordFilterMenu({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final AppointmentRecordFilter selected;
  final ValueChanged<AppointmentRecordFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return WhiteFilterMenu<AppointmentRecordFilter>(
      options: <AppointmentRecordFilter, String>{
        for (final AppointmentRecordFilter value
            in AppointmentRecordFilter.values)
          value: context.tr(value.labelKey),
      },
      selected: selected,
      onChanged: onChanged,
    );
  }
}
