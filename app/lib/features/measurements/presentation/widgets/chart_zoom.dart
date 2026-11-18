import 'package:equatable/equatable.dart';

/// How far a month chart is spread across its days: [zoom] times as wide as
/// it fits (1 to [most]), moved [shift] pixels to the right so the later
/// days, on the left, come into view. Only the days spread: the dots and
/// the capsules keep their size, so zooming in pulls them apart.
class ChartZoom extends Equatable {
  const ChartZoom({this.zoom = 1, this.shift = 0});

  static const ChartZoom none = ChartZoom();

  /// Six times: a month of 31 days then shows about five at a time.
  static const double most = 6;

  /// One press of «+» or «−».
  static const double step = 1.5;

  final double zoom;
  final double shift;

  /// The view after a pinch, a drag or a button, from this one: [zoom]
  /// becomes [to], and the point [from] pixels left of the plot's right
  /// edge ends [at] pixels from it, so what is under the fingers stays
  /// under them. [width] is the plot's width at zoom 1; the view never
  /// scrolls past day 1 or the month's last day.
  ChartZoom moved({
    required double from,
    required double at,
    required double to,
    required double width,
  }) {
    final double next = to.clamp(1, most).toDouble();
    final double shifted = (from + shift) / zoom * next - at;
    return ChartZoom(
      zoom: next,
      shift: shifted.clamp(0, width * (next - 1)).toDouble(),
    );
  }

  /// [times] as wide, around the middle of a plot [plot] wide at zoom 1.
  ChartZoom zoomedBy(double times, double plot) =>
      moved(from: plot / 2, at: plot / 2, to: zoom * times, width: plot);

  @override
  List<Object?> get props => <Object?>[zoom, shift];
}
