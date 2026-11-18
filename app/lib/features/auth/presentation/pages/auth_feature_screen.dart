import 'dart:async';

import 'package:app/core/services/signed_out.dart';
import 'package:app/core/theme/components/navigation_themes.dart';
import 'package:app/features/auth/presentation/widgets/auth_welcome_body.dart';
import 'package:app/features/auth/presentation/widgets/show_next_intro.dart';
import 'package:app/features/auth/presentation/widgets/start_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/core/theme/app_intro_colors.dart';

/// The welcome: three pages that show the app itself. Each has a picture
/// of real parts of the app with example data (the next dose, the circle,
/// the person switcher) over soft glows, then the step, a title and one
/// line. At the bottom, in reach of the thumb: «تخطي», the dots of the
/// pages, and «التالي». The last page has «ابدأ», which opens the phone
/// number; «تخطي» goes there at once.
class AuthFeatureScreen extends StatefulWidget {
  const AuthFeatureScreen({super.key});

  @override
  State<AuthFeatureScreen> createState() => _AuthFeatureScreenState();
}

class _AuthFeatureScreenState extends State<AuthFeatureScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    // Nobody is signed in on the welcome (after a sign-out, an ended sign-in
    // or a deleted account): what was the last person's goes.
    unawaited(forgetSignedOutPerson());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Every page is light, so the status bar icons are dark.
      value: AppNavigationThemes.systemBars,
      child: Scaffold(
        backgroundColor: AppIntroColors.canvas,
        body: AuthWelcomeBody(
          controller: _controller,
          page: _page,
          onPageChanged: (int page) => setState(() => _page = page),
          onStart: () => startSignIn(context),
          onNext: () => showNextIntro(context, _controller, _page),
        ),
      ),
    );
  }
}
