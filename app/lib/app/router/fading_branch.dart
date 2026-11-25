import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:flutter/material.dart';

/// One tab of the fading home tabs: shown and fading in while [active], fading
/// out and then offstage when not, at once when [still] (Reduce Motion).
class FadingBranch extends StatefulWidget {
  const FadingBranch({
    super.key,
    required this.active,
    required this.still,
    required this.child,
  });

  final bool active;
  final bool still;
  final Widget child;

  @override
  State<FadingBranch> createState() => _FadingBranchState();
}

class _FadingBranchState extends State<FadingBranch> {
  /// Whether the tab is painted: it is open, or still fading out.
  late bool _shown = widget.active;

  @override
  void didUpdateWidget(FadingBranch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active) {
      _shown = true;
    } else if (widget.still) {
      // No fade to wait for.
      _shown = false;
    }
  }

  void _faded() {
    if (!widget.active && mounted) setState(() => _shown = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool active = widget.active;
    return Offstage(
      offstage: !_shown,
      child: IgnorePointer(
        ignoring: !active,
        child: ExcludeFocus(
          excluding: !active,
          child: ExcludeSemantics(
            excluding: !active,
            child: AnimatedOpacity(
              opacity: active ? 1 : 0,
              duration: widget.still
                  ? Duration.zero
                  : Duration(
                      milliseconds: active
                          ? AppMotion.branchEnterMilliseconds
                          : AppMotion.branchExitMilliseconds,
                    ),
              curve: active ? AppMotion.branchEnter : AppMotion.easeIn,
              onEnd: widget.still ? null : _faded,
              // A hidden tab's own animations pause; the fade sits above
              // this, so it still runs.
              child: TickerMode(enabled: active, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
