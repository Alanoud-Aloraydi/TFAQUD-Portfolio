import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_state.dart';
import 'package:app/features/circles/presentation/widgets/edit_patient_photo.dart';
import 'package:app/features/circles/presentation/widgets/patient_card_photo.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The patient's picture at the top of «تعديل الدائرة», with «تغيير
/// الصورة» under it; a new one shows here and on the card at once.
class CircleEditPhoto extends StatelessWidget {
  const CircleEditPhoto({
    super.key,
    required this.circleId,
    required this.overview,
  });

  final String circleId;

  /// The circle as the sheet opened; the picture follows its reads.
  final CircleOverview overview;

  @override
  Widget build(BuildContext context) {
    final CircleOverviewCubit cubit = context.read<CircleOverviewCubit>();
    return BlocBuilder<CircleOverviewCubit, CircleOverviewState>(
      builder: (context, state) {
        final CircleOverview shown = state.overview ?? overview;
        return Column(
          children: <Widget>[
            PatientCardPhoto(circleId: circleId, overview: shown),
            TextButton.icon(
              onPressed: () => editPatientPhoto(
                context,
                circleId: circleId,
                overview: shown,
                onSaved: cubit.load,
              ),
              icon: const Icon(CupertinoIcons.camera),
              label: Text(context.tr('circle_edit.change_photo')),
            ),
          ],
        );
      },
    );
  }
}
