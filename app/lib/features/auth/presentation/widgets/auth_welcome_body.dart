import 'package:app/features/auth/presentation/widgets/auth_app_name.dart';
import 'package:app/features/auth/presentation/widgets/auth_bottom_bar.dart';
import 'package:app/features/auth/presentation/widgets/auth_intro_page.dart';
import 'package:app/features/auth/presentation/widgets/auth_intros.dart';
import 'package:app/features/auth/presentation/widgets/auth_moving_glows.dart';
import 'package:flutter/material.dart';

/// The welcome over its glows: the app's name, the pages, and the bottom
/// controls.
class AuthWelcomeBody extends StatelessWidget {
  const AuthWelcomeBody({
    super.key,
    required this.controller,
    required this.page,
    required this.onPageChanged,
    required this.onStart,
    required this.onNext,
  });

  final PageController controller;
  final int page;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onStart;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: AuthMovingGlows(controller: controller, page: page),
        ),
        SafeArea(
          child: Column(
            children: <Widget>[
              const AuthAppName(),
              Expanded(
                child: PageView.builder(
                  controller: controller,
                  // The cards' soft shadows show past the pages' edge.
                  clipBehavior: Clip.none,
                  itemCount: authIntros.length,
                  onPageChanged: onPageChanged,
                  itemBuilder: (BuildContext context, int index) =>
                      AuthIntroPage(
                        intro: authIntros[index],
                        step: index + 1,
                        active: index == page,
                      ),
                ),
              ),
              AuthBottomBar(
                count: authIntros.length,
                current: page,
                onStart: onStart,
                onNext: onNext,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
