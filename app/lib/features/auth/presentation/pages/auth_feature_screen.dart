import 'dart:async';

import 'package:app/app/router/routers.dart';
import 'package:app/app/services/signed_out.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/legal/legal_links_note.dart';
import 'package:app/features/auth/domain/repositories/welcome_memory.dart';
import 'package:app/features/auth/presentation/widgets/intro_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// The welcome: the app's name, its three pages ([introPages]) and one bar.
class AuthFeatureScreen extends StatefulWidget {
  const AuthFeatureScreen({super.key});

  @override
  State<AuthFeatureScreen> createState() => _AuthFeatureScreenState();
}

class _AuthFeatureScreenState extends State<AuthFeatureScreen> {
  final PageController _pages = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    unawaited(forgetSignedOutPerson());
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// «تخطي» and «ابدأ»: the welcome is done on this phone.
  void _start() {
    unawaited(GetIt.I<WelcomeMemory>().markSeen());
    context.push(Routes.authPhone);
  }

  void _next() {
    final int next = _page + 1;
    if (next == introPages.length) return _start();
    if (MediaQuery.disableAnimationsOf(context)) return _pages.jumpToPage(next);
    const Duration time = AppMotion.contentEnter;
    unawaited(_pages.nextPage(duration: time, curve: AppMotion.easeOutCubic));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('auth.app_name')), centerTitle: true),
    body: PageView(
      controller: _pages,
      onPageChanged: (int page) => setState(() => _page = page),
      children: introPages,
    ),
    bottomNavigationBar: IntroBar(
      page: _page + 1,
      total: introPages.length,
      onSkip: _start,
      onNext: _next,
    ),
  );
}

/// The bar under every page ([introControls]), and on the last page the
/// note on the terms under «ابدأ».
class IntroBar extends StatelessWidget {
  const IntroBar({
    super.key,
    required this.page,
    required this.total,
    required this.onSkip,
    required this.onNext,
  });

  /// From 1 to [total].
  final int page;
  final int total;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : AppMotion.contentEnter,
          child: introControls(
            context,
            page: page,
            total: total,
            onSkip: onSkip,
            onNext: onNext,
          ),
        ),
        // Hidden, not gone, so the bar keeps its size on every page.
        Visibility.maintain(
          visible: page == total,
          child: const LegalLinksNote(),
        ),
      ],
    ),
  );
}

/// The welcome's buttons: «تخطي», the dots and «التالي»; on the last page
/// one wide «ابدأ» in their place, as the welcome before it had.
Widget introControls(
  BuildContext context, {
  required int page,
  required int total,
  required VoidCallback onSkip,
  required VoidCallback onNext,
}) {
  final ButtonStyle dark = FilledButton.styleFrom(
    backgroundColor: AppSemanticColors.textPrimary,
    foregroundColor: AppSemanticColors.surfaceContent,
    shape: const StadiumBorder(),
    // At least as wide as «التالي», as tall as every main button.
    minimumSize: const Size(120, AppSizes.button),
  );
  if (page == total) {
    return SizedBox(
      key: const ValueKey<String>('start'),
      width: double.infinity,
      child: FilledButton(
        onPressed: onNext,
        style: dark,
        child: Text(context.tr('auth.start')),
      ),
    );
  }
  return Row(
    key: const ValueKey<String>('next'),
    children: <Widget>[
      TextButton(onPressed: onSkip, child: Text(context.tr('intro.skip'))),
      Expanded(
        child: Center(
          child: IntroDots(page: page, total: total),
        ),
      ),
      FilledButton(
        onPressed: onNext,
        style: dark,
        child: Text(context.tr('intro.next')),
      ),
    ],
  );
}

/// The welcome's pages as dots: the page on show is a longer dark bar, the
/// others short and light, so only one stands out. VoiceOver reads
/// «الخطوة 1 من 3».
class IntroDots extends StatelessWidget {
  const IntroDots({super.key, required this.page, required this.total});

  /// From 1 to [total].
  final int page;
  final int total;

  static const double _dot = 7;
  static const double _on = 24;

  @override
  Widget build(BuildContext context) {
    final Duration duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.contentEnter;
    final List<String> args = <String>['$page', '$total'];
    return Semantics(
      label: spoken(context.tr('common.step_of', args: args)),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.tight,
          children: <Widget>[
            for (int i = 1; i <= total; i++)
              AnimatedContainer(
                duration: duration,
                curve: AppMotion.easeOutCubic,
                width: i == page ? _on : _dot,
                height: _dot,
                decoration: ShapeDecoration(
                  color: i == page
                      ? AppSemanticColors.textPrimary
                      : AppSemanticColors.borderSubtle,
                  shape: const StadiumBorder(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
