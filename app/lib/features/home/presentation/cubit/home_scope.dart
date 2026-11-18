import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:app/features/home/presentation/cubit/home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the home shell is read with, shared by everything it does.
mixin HomeScope on Cubit<HomeState> {
  HomeUseCase get home;

  /// Counts the reads of the home data; only the newest one is shown.
  int revision = 0;
}
