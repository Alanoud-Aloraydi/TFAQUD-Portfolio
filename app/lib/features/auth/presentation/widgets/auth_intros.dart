import 'package:app/features/auth/presentation/widgets/auth_intro.dart';
import 'package:app/core/theme/app_intro_colors.dart';

/// The three pages of the welcome, in order.
const List<AuthIntro> authIntros = <AuthIntro>[
  AuthIntro(
    glowHigh: AppIntroColors.glowWarm,
    glowLow: AppIntroColors.glowLeaf,
    stepKey: 'intro.p1_step',
    titleKey: 'intro.p1_title',
    bodyKey: 'intro.p1_body',
  ),
  AuthIntro(
    glowHigh: AppIntroColors.glowLeaf,
    glowLow: AppIntroColors.glowWarm,
    stepKey: 'intro.p2_step',
    titleKey: 'intro.p2_title',
    bodyKey: 'intro.p2_body',
  ),
  AuthIntro(
    glowHigh: AppIntroColors.glowMist,
    glowLow: AppIntroColors.glowCalm,
    stepKey: 'intro.p3_step',
    titleKey: 'intro.p3_title',
    bodyKey: 'intro.p3_body',
  ),
];
