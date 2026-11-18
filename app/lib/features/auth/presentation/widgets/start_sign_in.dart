import 'dart:async';

import 'package:app/core/navigation/routers.dart';
import 'package:app/features/auth/domain/repositories/welcome_memory.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// «ابدأ» and «تخطي»: the welcome is done for this install
/// ([WelcomeMemory]), and the phone number page opens.
void startSignIn(BuildContext context) {
  unawaited(GetIt.I<WelcomeMemory>().markSeen());
  context.push(Routes.authPhone);
}
