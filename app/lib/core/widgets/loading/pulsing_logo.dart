import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/widgets/loading/tfaqud_loader.dart';
import 'package:flutter/material.dart';

/// The logo breathing, for the launch: a little smaller and softer, then
/// full, again and again ([AppMotion.logoPulse] each way). It does not turn;
/// the turning logo is for a page that reads ([TfaqudLoader]). With motion
/// reduced it stays still and full. It says nothing to a screen reader.
class PulsingLogo extends StatefulWidget {
  const PulsingLogo({super.key, required this.size});

  final double size;

  @override
  State<PulsingLogo> createState() => _PulsingLogoState();
}

class _PulsingLogoState extends State<PulsingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: AppMotion.logoPulse,
    value: 1,
  );
  late final Animation<double> _eased = CurvedAnimation(
    parent: _breath,
    curve: AppMotion.easeOut,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 0.9,
    end: 1,
  ).animate(_eased);
  late final Animation<double> _opacity = Tween<double>(
    begin: 0.7,
    end: 1,
  ).animate(_eased);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _breath
        ..stop()
        ..value = 1;
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ScaleTransition(
      scale: _scale,
      child: FadeTransition(
        opacity: _opacity,
        child: Image.asset(
          TfaqudLoader.logo,
          width: widget.size,
          height: widget.size,
          filterQuality: FilterQuality.medium,
        ),
      ),
    ),
  );
}
