import 'package:app/core/constants/app_images.dart';
import 'package:flutter/widgets.dart';

/// The poses of the guide owl, one for each thing the app does.
enum OwlPose {
  /// Holds a care checklist: everything in one place.
  organize(AppImages.owlOrganize),

  /// Wings open inside a circle of people: care is shared.
  share(AppImages.owlShare),

  /// Points at the cards of two people: more than one person followed.
  follow(AppImages.owlFollow);

  const OwlPose(this.asset);

  final String asset;
}

/// The app's guide: a wise owl that explains the app on the welcome pages.
///
/// It is a drawing (navy feathers, a honey face, amber eyes and a small leaf
/// by one ear), so screen readers skip it; the words beside it say what it
/// shows. It keeps its shape and fits the space it is given.
class GuideOwl extends StatelessWidget {
  const GuideOwl({super.key, required this.pose});

  final OwlPose pose;

  /// The drawing's width over its height (all poses are the same size, so
  /// the owl stands in the same place on every page).
  static const double aspectRatio = 600 / 640;

  /// Loads the three poses ahead, so a page never shows an empty space
  /// while its picture is read.
  static void precache(BuildContext context) {
    for (final OwlPose pose in OwlPose.values) {
      precacheImage(AssetImage(pose.asset), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Image.asset(
          pose.asset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
