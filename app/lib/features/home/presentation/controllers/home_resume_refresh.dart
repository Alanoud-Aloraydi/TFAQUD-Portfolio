import 'package:app/features/home/presentation/controllers/home_shell_lifecycle.dart';
import 'package:app/features/home/presentation/controllers/home_state_reactor.dart';
import 'package:flutter/widgets.dart';

/// Reads the home again when the app comes back to the front. It listens
/// from [initState] to [dispose].
mixin HomeResumeRefresh<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  HomeStateReactor get reactor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    refreshOnResume(context, reactor);
  }
}
