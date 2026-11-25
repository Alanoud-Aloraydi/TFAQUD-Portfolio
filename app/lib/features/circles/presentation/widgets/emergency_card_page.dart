import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/features/circles/presentation/cubit/emergency_card_cubit.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_content.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_export.dart';
import 'package:app/features/circles/presentation/widgets/page_frame_padding.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The emergency card page under its safe area: the top row, the title, and
/// the card or what stands in for it. Loading, error and content fade into
/// each other.
class EmergencyCardPage extends StatelessWidget {
  const EmergencyCardPage({
    super.key,
    required this.state,
    required this.closeTo,
    required this.cardKey,
    required this.english,
    required this.onLanguage,
    required this.onExport,
  });

  final EmergencyCardState state;
  final String closeTo;
  final GlobalKey cardKey;
  final bool english;
  final ValueChanged<bool> onLanguage;

  /// Null while a PDF is being made.
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: pageFramePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          EmergencyCardTopRow(
            closeTo: closeTo,
            canExport: state.status == EmergencyCardStatus.ready,
            onExport: onExport,
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            header: true,
            child: Text(
              context.tr('circles.card_title'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: ContentSwitcher(
              stateKey: state.status,
              child: EmergencyCardContent(
                state: state,
                cardKey: cardKey,
                english: english,
                onLanguage: onLanguage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
