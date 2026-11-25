import 'dart:async';

import 'package:app/app/router/routers.dart';
import 'package:app/app/services/signed_out.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/features/auth/domain/repositories/welcome_memory.dart';
import 'package:app/features/auth/presentation/widgets/intro_bar.dart';
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
