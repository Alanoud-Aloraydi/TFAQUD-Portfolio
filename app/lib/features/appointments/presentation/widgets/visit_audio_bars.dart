import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:flutter/material.dart';

/// The still waveform beside the play button: 28 bars of fixed heights,
/// a picture of a recording rather than a reading of one.
Widget visitAudioBars() => Expanded(
  child: Row(
    children: [
      for (var index = 0; index < 28; index++)
        Expanded(
          child: Container(
            height: 6.0 + (index * 7 % 13),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: AppSemanticColors.borderControlBase,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
    ],
  ),
);
