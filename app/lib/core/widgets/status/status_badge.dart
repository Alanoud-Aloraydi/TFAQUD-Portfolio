import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/feedback/status_pill.dart';
import 'package:flutter/material.dart';

/// What a status says. The tone picks its colour, so the same meaning has
/// the same colour on every page.
enum StatusTone {
  /// A plain fact: «منتهية», «مدير», a measurement's condition.
  neutral,

  /// Ahead and on plan: «قادم», «تبدأ لاحقًا», «موعدها لاحقًا».
  info,

  /// Done or in force: «سارية», «تم», «ضمن الهدف», «قبِل».
  success,

  /// Wants a look: «حان موعدها», «بانتظار الرد», «خارج الهدف».
  attention,

  /// Lost: «فائتة».
  danger,

  /// Off: «ملغى», «موقوفة», «مشاهدة فقط».
  muted,

  /// Any status shown over a dark surface.
  onDark,
}

/// The one status label of the app: every «قادم», «فائتة», «سارية» and
/// «ملغى» is this badge, and only its [tone] differs. The words (and the
/// icon, when there is one) say the status, so colour is never the only
/// signal.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.text,
    required this.tone,
    this.icon,
  });

  final String text;
  final StatusTone tone;
  final IconData? icon;

  /// The fill of [tone].
  static Color fill(StatusTone tone) => switch (tone) {
    StatusTone.neutral => AppSemanticColors.segmentTrack,
    StatusTone.info => AppSemanticColors.borderPlan,
    StatusTone.success => AppSemanticColors.selectedSurface,
    StatusTone.attention => AppSemanticColors.surfaceAttention,
    StatusTone.danger => AppSemanticColors.surfaceDanger,
    StatusTone.muted => AppSemanticColors.surfaceContent,
    StatusTone.onDark => AppSemanticColors.surfaceContent.withValues(
      alpha: 0.14,
    ),
  };

  /// The text and icon colour of [tone], readable on its fill.
  static Color ink(BuildContext context, StatusTone tone) => switch (tone) {
    StatusTone.neutral || StatusTone.muted => context.tokens.textSecondary,
    StatusTone.info => AppSemanticColors.textPrimary,
    StatusTone.success => context.tokens.successText,
    StatusTone.attention => context.tokens.warningText,
    StatusTone.danger => context.tokens.errorText,
    StatusTone.onDark => AppSemanticColors.surfaceContent,
  };

  @override
  Widget build(BuildContext context) => StatusPill(
    text: text,
    icon: icon,
    background: fill(tone),
    foreground: ink(context, tone),
    // White on white would vanish: the muted badge is outlined.
    border: tone == StatusTone.muted ? AppSemanticColors.borderSubtle : null,
  );
}
