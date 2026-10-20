import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/widgets/pill_button.dart';
import 'package:app/features/auth/presentation/widgets/orbit_painter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Welcome page: the brand picture on top, the start button below.
class AuthFeatureScreen extends StatelessWidget {
  const AuthFeatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      body: Column(
        children: <Widget>[
          const Expanded(flex: 13, child: _WelcomePanel()),
          Expanded(
            flex: 7,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    PillButton(
                      label: context.tr('auth.start'),
                      onPressed: () => context.push(Routes.authPhone),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('auth.terms_note'),
                      textAlign: TextAlign.center,
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      child: ColoredBox(
        color: AppColors.brand,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            // The brand mark sits a little above the middle of the panel.
            final double centerY = constraints.maxHeight * 0.48;
            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: CustomPaint(painter: OrbitPainter(centerY: centerY)),
                ),
                Positioned(
                  top: centerY + 86,
                  left: 24,
                  right: 24,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        context.tr('auth.app_name'),
                        style: text.headlineLarge?.copyWith(
                          color: AppColors.onBrand,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('auth.tagline'),
                        textAlign: TextAlign.center,
                        style: text.bodyLarge?.copyWith(
                          color: AppColors.onBrand,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
