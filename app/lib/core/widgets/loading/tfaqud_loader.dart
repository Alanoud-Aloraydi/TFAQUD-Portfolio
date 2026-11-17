import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:flutter/material.dart';

/// The app's loader, as Claude Design draws it («Loading»): the logo's four
/// people turning one full round every 1.6 seconds. While it is not
/// [animating] it rests at [turn] (a pulled page turns it with the pull);
/// with motion reduced it stays still. It says nothing to a screen reader;
/// the words beside it do.
class TfaqudLoader extends StatefulWidget {
  const TfaqudLoader({
    super.key,
    required this.size,
    this.animating = true,
    this.turn = 0,
  });

  final double size;
  final bool animating;

  /// Where it rests while not [animating], in rounds.
  final double turn;

  /// The logo the loader turns.
  static const String logo = 'assets/images/logo.png';

  @override
  State<TfaqudLoader> createState() => _TfaqudLoaderState();
}

class _TfaqudLoaderState extends State<TfaqudLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: AppMotion.loaderTurn,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _follow();
  }

  @override
  void didUpdateWidget(TfaqudLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _follow();
  }

  void _follow() {
    final bool turning =
        widget.animating && !MediaQuery.disableAnimationsOf(context);
    if (turning && !_turn.isAnimating) {
      _turn.repeat();
    } else if (!turning) {
      _turn
        ..stop()
        ..value = widget.animating ? 0 : widget.turn % 1;
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RotationTransition(
      turns: _turn,
      child: Image.asset(
        TfaqudLoader.logo,
        width: widget.size,
        height: widget.size,
        filterQuality: FilterQuality.medium,
      ),
    ),
  );
}
