import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

/// A sub-screen's big title, a heading for VoiceOver and TalkBack, with an
/// optional widget beside it.
class SimplifiedPageTitle extends StatelessWidget {
  const SimplifiedPageTitle({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SimplifiedStyle.page,
        12,
        SimplifiedStyle.page,
        0,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 12,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                title,
                style: SimplifiedStyle.head(SimplifiedStyle.display),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
