import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The room a glass sheet leaves above itself, under the status bar: the
/// height of the page's top bar, so a tall sheet starts below it.
const double glassSheetTopGap = 64;

/// The tallest a glass sheet grows on a screen of [media]: from the bottom
/// up to [glassSheetTopGap] under the status bar.
double glassSheetMaxHeight(MediaQueryData media) =>
    media.size.height - media.viewPadding.top - glassSheetTopGap;

/// How far the glass sheet floats above the screen's bottom edge, before its
/// own gap: over the keyboard while it is open, otherwise over the iPhone's
/// home indicator or Android's navigation bar. `useSafeArea` keeps a sheet
/// clear of the top and the sides only, and from Android 15 the app draws
/// under the navigation bar, whose buttons would cover the last row.
double glassSheetBottomInset(MediaQueryData media) =>
    math.max(media.viewInsets.bottom, media.viewPadding.bottom);
