import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/features/auth/presentation/widgets/auth_intros.dart';
import 'package:app/features/auth/presentation/widgets/start_sign_in.dart';
import 'package:flutter/widgets.dart';

/// «التالي» on page [page]: the next page, or the phone number after the
/// last.
void showNextIntro(BuildContext context, PageController controller, int page) {
  if (page == authIntros.length - 1) {
    startSignIn(context);
    return;
  }
  // Reduce Motion: the next page shows at once.
  if (MediaQuery.disableAnimationsOf(context)) {
    controller.jumpToPage(page + 1);
  } else {
    controller.nextPage(
      duration: AppMotion.contentEnter,
      curve: AppMotion.easeOutCubic,
    );
  }
}
