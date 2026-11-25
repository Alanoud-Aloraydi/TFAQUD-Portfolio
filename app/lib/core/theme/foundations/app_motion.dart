import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Existing interface timing and curves, independent of business deadlines.
abstract class AppMotion {
  AppMotion._();

  static const Duration fieldFeedback = Duration(milliseconds: 120);
  static const Duration formScroll = Duration(milliseconds: 200);

  static const Duration segmentSlide = Duration(milliseconds: 260);
  static const Duration contentEnter = Duration(milliseconds: 280);
  static const Duration contentExit = Duration(milliseconds: 160);
  static const Duration alert = Duration(milliseconds: 320);
  static const Duration menuEnter = Duration(milliseconds: 420);
  static const Duration menuExit = Duration(milliseconds: 260);
  static const Duration shimmer = Duration(milliseconds: 1400);

  /// One round of the loader's logo, as Claude Design turns it.
  static const Duration loaderTurn = Duration(milliseconds: 1600);

  /// The launch logo: one breath in (or out), how long it stays over the
  /// starting app at least, and its fade as the app shows under it.
  static const Duration logoPulse = Duration(milliseconds: 1100);
  static const Duration launchHold = Duration(milliseconds: 2500);
  static const Duration launchFade = Duration(milliseconds: 450);

  /// How long a pulled page says «تم التحديث» before it closes.
  static const Duration refreshDone = Duration(milliseconds: 600);

  /// How long a refused permission's switch shows where it is going, once
  /// the word is on screen, before the app leaves for the phone's Settings.
  static const Duration settingsLead = Duration(seconds: 2);

  /// The card a tapped notification opens, as Telegram marks the message a
  /// link opens: tinted for this long once in view, then fading out over
  /// [tapHighlightFade].
  static const Duration tapHighlight = Duration(milliseconds: 1000);
  static const Duration tapHighlightFade = Duration(milliseconds: 600);

  static const int branchEnterMilliseconds = 260;
  static const int branchExitMilliseconds = 140;
  static const Duration branchEnterDuration = Duration(
    milliseconds: branchEnterMilliseconds,
  );
  static const Duration branchExitDuration = Duration(
    milliseconds: branchExitMilliseconds,
  );
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve easeInCubic = Curves.easeInCubic;
  static const double alertClosingScale = 0.96;
  static const double alertOpeningScale = 1.08;
  static const Curve alertSpring = Cubic(0.2, 0.9, 0.3, 1.04);
  static const Curve menuSpring = _GlassSpring();
  static const Curve branchEnter = Interval(0.3, 1, curve: Curves.easeOut);
}

/// Existing spring response shared by the custom glass menu.
class _GlassSpring extends Curve {
  const _GlassSpring();

  static final SpringSimulation _spring = SpringSimulation(
    SpringDescription.withDampingRatio(mass: 1, stiffness: 300, ratio: 0.72),
    0,
    1,
    0,
  );

  static const double _seconds = 0.42;

  @override
  double transformInternal(double t) => _spring.x(t * _seconds);
}

/// Shared depth definitions for opaque content.
abstract class AppEffects {
  AppEffects._();

  static const Color interactionOverlay = Color(0x14202734);
  static const Color subtleEdge = Color(0x1F202734);
  static const Color shimmerClear = Color(0x00FFFFFF);
  static const Color shimmerHighlight = Color(0xB3FFFFFF);
  static const List<BoxShadow> alertPanelShadow = <BoxShadow>[
    BoxShadow(color: subtleEdge, blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> segmentShadow = <BoxShadow>[
    BoxShadow(color: interactionOverlay, blurRadius: 4, offset: Offset(0, 1)),
  ];
}
