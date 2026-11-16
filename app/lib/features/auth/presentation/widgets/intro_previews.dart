import 'package:app/features/auth/presentation/widgets/intro_follow_preview.dart';
import 'package:app/features/auth/presentation/widgets/intro_organize_preview.dart';
import 'package:app/features/auth/presentation/widgets/intro_share_preview.dart';
import 'package:flutter/material.dart';

/// The picture of a welcome page: real parts of the app drawn with example
/// data, so the person knows the app before they open it.
///
/// 1. The next dose, a reading and a visit, as on «اليوم».
/// 2. The circle's members, and a note that Khalid recorded a dose.
/// 3. The person switcher of the top bar, with two people and «إضافة شخص».
///
/// It is a picture: VoiceOver skips it (the title and the line under it say
/// the same), it is drawn at one size and scaled down to the room there is,
/// and the text size setting does not change it. The cards rise into place
/// one after another as [enter] goes from 0 to 1.
class IntroPreview extends StatelessWidget {
  const IntroPreview({super.key, required this.step, required this.enter});

  /// 1, 2 or 3.
  final int step;
  final Animation<double> enter;

  /// The size the pictures are drawn at: an iPhone's width less the margins.
  static const Size canvas = Size(350, 400);

  @override
  Widget build(BuildContext context) {
    final Widget picture = switch (step) {
      1 => IntroOrganizePreview(enter: enter),
      2 => IntroSharePreview(enter: enter),
      _ => IntroFollowPreview(enter: enter),
    };
    return ExcludeSemantics(
      child: MediaQuery.withNoTextScaling(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox.fromSize(size: canvas, child: picture),
        ),
      ),
    );
  }
}
