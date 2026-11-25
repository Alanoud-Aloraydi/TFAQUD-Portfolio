import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/widgets/layout/refresh_scope.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/widgets/circle_content.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_state_reactor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// The "الدائرة" tab (CIRCLE-01): who the circle cares for and who shares
/// it. From the top: the patient card, the two tiles that open the medical
/// file and the emergency card, the members with the pending invitations,
/// «إضافة عضو» and «مغادرة الدائرة». Needs the [HomeCubit] of the home
/// screen above it.
class CircleTabScreen extends StatelessWidget {
  const CircleTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (BuildContext context, HomeState state) {
        final String? selectedId = state.selectedCircleId;
        CareCircleSummary? circle;
        for (final CareCircleSummary candidate
            in state.data?.circles ?? const <CareCircleSummary>[]) {
          if (candidate.id == selectedId) circle = candidate;
        }
        if (circle == null) return const SizedBox.shrink();
        return BlocProvider(
          key: ValueKey(selectedId),
          // A saved photo anywhere, or the tab pulled down, reads the
          // circle again quietly, in place.
          create: (_) => CircleOverviewCubit(
            GetIt.I<CirclesUseCase>(),
            selectedId!,
            RefreshScope.withPulls(
              context,
              GetIt.I<PrivatePhotoRepository>().changes,
            ),
          )..load(),
          child: CircleContent(circle: circle),
        );
      },
    );
  }
}
