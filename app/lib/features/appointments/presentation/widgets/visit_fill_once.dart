import 'dart:async';

import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/visit_state.dart';
import 'package:app/features/appointments/presentation/widgets/show_visit_edit_sheet.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Opens «تعديل ورقة الزيارة» by itself, once, as soon as the visit is
/// read, when the page was reached from «حضرت» (its address asks with
/// fill=1): the person lands on the form to fill in. A later reload of the
/// page does not open it again.
class VisitFillOnce extends StatefulWidget {
  const VisitFillOnce({super.key, required this.child});

  final Widget child;

  @override
  State<VisitFillOnce> createState() => _VisitFillOnceState();
}

class _VisitFillOnceState extends State<VisitFillOnce> {
  bool _opened = false;

  @override
  Widget build(BuildContext context) => BlocListener<VisitCubit, VisitState>(
    listenWhen: (VisitState before, VisitState now) =>
        before.loading && !now.loading && !now.loadFailed,
    listener: (BuildContext context, VisitState state) {
      final Uri address = GoRouterState.of(context).uri;
      if (_opened || address.queryParameters['fill'] != '1') return;
      _opened = true;
      unawaited(showVisitEditSheet(context, state.paper));
    },
    child: widget.child,
  );
}
