import 'package:app/features/medications/presentation/widgets/ruler_look.dart';
import 'package:flutter/material.dart';

/// One mark: a long one with its words under it, or a short one between.
class RulerTick extends StatelessWidget {
  const RulerTick({
    super.key,
    required this.major,
    this.label,
    this.look = const RulerLook(),
  });

  final bool major;
  final String? label;
  final RulerLook look;

  @override
  Widget build(BuildContext context) {
    final double scale = look.scale;
    final TextStyle words =
        Theme.of(context).textTheme.labelSmall ?? const TextStyle();
    return Column(
      children: <Widget>[
        Container(
          width: (major ? 2 : 1) * scale,
          height: (major ? 26 : 14) * scale,
          color: major ? look.major : look.minor,
        ),
        const Spacer(),
        // A number is wider than its mark: it overflows to both sides.
        SizedBox(
          height: 18 * scale,
          child: label != null
              ? OverflowBox(
                  maxWidth: 40 * scale,
                  child: Text(
                    label!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: words.copyWith(
                      color: look.label,
                      fontSize: (words.fontSize ?? 11) * scale,
                    ),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
