import 'package:app/core/widgets/overlays/glass_menu_route.dart';
import 'package:app/features/appointments/domain/entities/visit_paper.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:app/features/appointments/presentation/widgets/visit_edit_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Opens «تعديل ورقة الزيارة» over the visit page, on the page's
/// [VisitCubit], filled with [paper] as it is so far.
Future<void> showVisitEditSheet(BuildContext context, VisitPaper? paper) =>
    showGlassSheet<void>(
      context,
      title: context.tr('appointments.edit_visit'),
      builder: (_) => BlocProvider.value(
        value: context.read<VisitCubit>(),
        child: VisitEditSheet(paper: paper),
      ),
    );
