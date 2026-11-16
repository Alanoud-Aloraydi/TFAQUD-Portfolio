import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';
import 'package:app/features/measurements/presentation/widgets/chart_zoom.dart';
import 'package:flutter/widgets.dart';

/// The touches of a month chart [width] wide: a tap ([onTap], where), and a
/// pinch or a drag ([onView], the new view). What was under the fingers
/// when they went down stays under them. A drag up or down still scrolls
/// the page: it claims the touch first.
class ChartGestures extends StatefulWidget {
  const ChartGestures({
    super.key,
    required this.view,
    required this.width,
    required this.onView,
    required this.onTap,
    required this.child,
  });

  final ChartZoom view;
  final double width;
  final ValueChanged<ChartZoom> onView;
  final ValueChanged<Offset> onTap;
  final Widget child;

  @override
  State<ChartGestures> createState() => _ChartGesturesState();
}

class _ChartGesturesState extends State<ChartGestures> {
  /// The view, and the focal point left of the right edge, at the start.
  ChartZoom _start = ChartZoom.none;
  double _from = 0;

  double _fromRight(Offset at) => widget.width - ChartScale.labelWidth - at.dx;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapUp: (details) => widget.onTap(details.localPosition),
    onScaleStart: (details) {
      _start = widget.view;
      _from = _fromRight(details.localFocalPoint);
    },
    onScaleUpdate: (details) => widget.onView(
      _start.moved(
        from: _from,
        at: _fromRight(details.localFocalPoint),
        to: _start.zoom * details.scale,
        width: ChartScale.plotWidth(widget.width),
      ),
    ),
    child: widget.child,
  );
}
