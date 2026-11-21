import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «لماذا لم تأخذها؟» over the medicine's [name], read as one sentence.
Widget simplifiedSkipQuestion(BuildContext context, String name) =>
    MergeSemantics(
      child: Column(
        children: <Widget>[
          Text(
            context.tr('simplified_mode.skip_question'),
            textAlign: TextAlign.center,
            style: SimplifiedStyle.head(
              SimplifiedStyle.display,
              color: SimplifiedColors.surface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            textAlign: TextAlign.center,
            style: SimplifiedStyle.text(
              SimplifiedStyle.title,
              color: SimplifiedColors.onDarkMuted,
            ),
          ),
        ],
      ),
    );
