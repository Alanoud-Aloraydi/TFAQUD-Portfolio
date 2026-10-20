import 'package:app/core/navigation/routers.dart';
import 'package:app/core/widgets/loading_widget.dart';
import 'package:app/features/auth/presentation/cubit/splash_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The first page. It shows the loading animation while the app finds out
/// whether this phone is signed in, then moves on. It needs a [SplashCubit]
/// above it in the widget tree.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, StartDestination>(
      listener: (context, destination) {
        switch (destination) {
          case StartDestination.home:
            context.go(Routes.today);
          case StartDestination.signIn:
            context.go(Routes.auth);
          case StartDestination.checking:
            break;
        }
      },
      child: const Scaffold(body: LoadingWidget()),
    );
  }
}
