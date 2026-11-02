import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/materials/mascot_style.dart';
import 'package:flutter/material.dart';

/// How the character looks.
enum MascotMood {
  /// Eyes open and a wide smile: hello.
  happy,

  /// Eyes closed and a soft smile: calm, all is shared.
  calm,

  /// Eyes open under firm brows: sure, nothing is missed.
  sure,
}

/// The app's character: a small Saturn on two legs whose ring goes around
/// the people and things it cares for, the way a circle of family goes
/// around the person they care for. The [orbiters] (small round badges)
/// ride the ring, slowly; the ones behind the ball pass behind it.
///
/// [radius] is the ball's radius; the widget is 4.2 radii wide and 2.5
/// radii tall. When it appears, the ring makes one slow turn and comes to
/// rest (an endless loop would distract, and keep the phone busy). With
/// Reduce Motion it holds still.
class SaturnMascot extends StatefulWidget {
  const SaturnMascot({
    super.key,
    required this.radius,
    this.mood = MascotMood.happy,
    this.orbiters = const <Widget>[],
  });

  final double radius;
  final MascotMood mood;

  /// Badges on the ring, spread evenly, each about half a radius wide.
  final List<Widget> orbiters;

  @override
  State<SaturnMascot> createState() => _SaturnMascotState();
}

class _SaturnMascotState extends State<SaturnMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: AppMotion.mascotOrbit,
  );

  /// The turn slows down as it ends.
  late final Animation<double> _turn = CurvedAnimation(
    parent: _orbit,
    curve: AppMotion.easeOut,
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _orbit.stop();
    } else if (!_started) {
      _started = true;
      _orbit.forward();
    }
  }

  @override
  void dispose() {
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double r = widget.radius;
    final Size size = Size(4.2 * r, 2.5 * r);
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _turn,
        builder: (BuildContext context, Widget? child) {
          final double t = _turn.value;
          // A slow turn of the ring, and a gentle float twice per turn.
          final double phase = 0.9 + t * 2 * math.pi;
          final double float = math.sin(t * 4 * math.pi) * r * 0.03;
          final _Geometry geometry = _Geometry(r, size);
          final List<_Placed> placed = <_Placed>[
            for (int i = 0; i < widget.orbiters.length; i++)
              geometry.place(
                widget.orbiters[i],
                phase + i / widget.orbiters.length * 2 * math.pi,
              ),
          ];
          Widget badge(_Placed p) => Positioned(
            left: p.offset.dx - _Geometry.badge * r,
            top: p.offset.dy - _Geometry.badge * r + float,
            width: 2 * _Geometry.badge * r,
            height: 2 * _Geometry.badge * r,
            child: p.child,
          );
          return SizedBox.fromSize(
            size: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BackPainter(geometry: geometry, float: float),
                  ),
                ),
                for (final _Placed p in placed)
                  if (!p.front) badge(p),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _FrontPainter(
                      geometry: geometry,
                      float: float,
                      mood: widget.mood,
                    ),
                  ),
                ),
                for (final _Placed p in placed)
                  if (p.front) badge(p),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A small white round badge for the ring: an icon or one letter (a
/// person's initial), with a soft shadow.
class MascotBadge extends StatelessWidget {
  const MascotBadge({
    super.key,
    this.icon,
    this.letter,
    this.color = AppSemanticColors.surfaceContent,
    this.iconColor = AppSemanticColors.textPrimary,
  });

  final IconData? icon;
  final String? letter;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final IconData? glyph = icon;
    final String? initial = letter;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double side = box.maxWidth;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppSemanticColors.textPrimary.withValues(alpha: 0.18),
                blurRadius: side * 0.25,
                offset: Offset(0, side * 0.06),
              ),
            ],
          ),
          child: Center(
            child: glyph != null
                ? Icon(glyph, size: side * 0.55, color: iconColor)
                : Text(
                    initial ?? '',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: side * 0.45,
                      height: 1,
                      color: iconColor,
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _Placed {
  const _Placed(this.child, this.offset, {required this.front});

  final Widget child;
  final Offset offset;

  /// On the near half of the ring, in front of the ball.
  final bool front;
}

/// Where things are, in pixels of the widget's box. The ball's center is
/// [center]; the ring is tilted by [tilt] and sits a little below it.
class _Geometry {
  _Geometry(this.r, Size size) : center = Offset(size.width / 2, 1.05 * r);

  final double r;
  final Offset center;

  static const double tilt = -0.2;

  /// The ring's middle line, where the badges ride (in radii).
  static const double rideX = 1.57;
  static const double rideY = 0.38;

  /// The ring sits this far below the ball's center (in radii).
  static const double ringDrop = 0.06;

  /// Half the width of a badge (in radii).
  static const double badge = 0.27;

  Offset get ringCenter => center + Offset(0, ringDrop * r);

  _Placed place(Widget child, double angle) {
    final double lx = math.cos(angle) * rideX * r;
    final double ly = math.sin(angle) * rideY * r;
    final double x = lx * math.cos(tilt) - ly * math.sin(tilt);
    final double y = lx * math.sin(tilt) + ly * math.cos(tilt);
    return _Placed(
      child,
      ringCenter + Offset(x, y - 0.14 * r),
      front: math.sin(angle) > 0,
    );
  }
}

/// What is behind the ball: its ground shadow, the legs and the far half of
/// the ring.
class _BackPainter extends CustomPainter {
  _BackPainter({required this.geometry, required this.float});

  final _Geometry geometry;
  final double float;

  @override
  void paint(Canvas canvas, Size size) {
    final double r = geometry.r;
    final Offset c = geometry.center;
    // The shadow stays on the ground while the body floats.
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(0, 1.34 * r),
        width: 1.5 * r,
        height: 0.16 * r,
      ),
      Paint()..color = AppMascot.ground,
    );
    canvas.save();
    canvas.translate(c.dx, c.dy + float);
    _legs(canvas, r);
    canvas.restore();
    canvas.save();
    canvas.translate(geometry.ringCenter.dx, geometry.ringCenter.dy + float);
    canvas.rotate(_Geometry.tilt);
    _ring(canvas, r, back: true);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BackPainter old) =>
      old.float != float || old.geometry.r != geometry.r;
}

/// The ball, the ring's shadow on it, the face and the near half of the
/// ring.
class _FrontPainter extends CustomPainter {
  _FrontPainter({
    required this.geometry,
    required this.float,
    required this.mood,
  });

  final _Geometry geometry;
  final double float;
  final MascotMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final double r = geometry.r;
    final Offset c = geometry.center;
    canvas.save();
    canvas.translate(c.dx, c.dy + float);
    _body(canvas, r);
    canvas.save();
    canvas.translate(0, _Geometry.ringDrop * r);
    _ringShadow(canvas, r);
    canvas.restore();
    _face(canvas, r, mood);
    canvas.translate(0, _Geometry.ringDrop * r);
    canvas.rotate(_Geometry.tilt);
    _ring(canvas, r, back: false);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FrontPainter old) =>
      old.float != float || old.mood != mood || old.geometry.r != geometry.r;
}

// ---- drawing, centered on the ball, in pixels of radius r ----------------

Rect _oval(double x, double y, double rx, double ry) =>
    Rect.fromCenter(center: Offset(x, y), width: 2 * rx, height: 2 * ry);

void _legs(Canvas canvas, double r) {
  final Paint leg = Paint()
    ..color = AppMascot.ink
    ..strokeWidth = 0.08 * r
    ..strokeCap = StrokeCap.round;
  for (final double side in <double>[-1, 1]) {
    canvas.drawLine(
      Offset(side * 0.30 * r, 0.86 * r),
      Offset(side * 0.34 * r, 1.20 * r),
      leg,
    );
    canvas.drawOval(
      _oval(side * 0.42 * r, 1.24 * r, 0.15 * r, 0.08 * r),
      Paint()..color = AppMascot.ink,
    );
    canvas.drawOval(
      _oval(side * 0.46 * r, 1.21 * r, 0.06 * r, 0.025 * r),
      Paint()..color = AppMascot.sole,
    );
  }
}

/// The ring as a band between two ellipses, in its own frame. [back] keeps
/// the far half (above the middle line), otherwise the near half.
void _ring(Canvas canvas, double r, {required bool back}) {
  final Rect outer = _oval(0, 0, 1.78 * r, 0.46 * r);
  final Rect inner = _oval(0, 0, 1.36 * r, 0.31 * r);
  canvas.save();
  canvas.clipRect(
    back
        ? Rect.fromLTRB(-3 * r, -3 * r, 3 * r, 0)
        : Rect.fromLTRB(-3 * r, 0, 3 * r, 3 * r),
  );
  final Path band = Path()
    ..fillType = PathFillType.evenOdd
    ..addOval(outer)
    ..addOval(inner);
  canvas.drawPath(
    band,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(-1.78 * r, 0),
        Offset(1.78 * r, 0),
        const <Color>[
          AppMascot.ringDark,
          AppMascot.ringMid,
          AppMascot.ringLight,
          AppMascot.ringMid,
          AppMascot.ringDark,
        ],
        const <double>[0, 0.2, 0.5, 0.8, 1],
      ),
  );
  // A thin groove, as Saturn's rings have.
  canvas.drawOval(
    _oval(0, 0, 1.58 * r, 0.385 * r),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.025 * r
      ..color = AppMascot.ringGroove,
  );
  // A bright lip on the near edge.
  canvas.drawArc(
    _oval(0, 0, 1.76 * r, 0.45 * r),
    0.15 * math.pi,
    0.7 * math.pi,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.03 * r
      ..strokeCap = StrokeCap.round
      ..color = AppMascot.ringLip,
  );
  if (back) canvas.drawPath(band, Paint()..color = AppMascot.ringBackShade);
  canvas.restore();
}

void _body(Canvas canvas, double r) {
  final Rect ball = _oval(0, 0, r, r);
  canvas.drawOval(
    ball,
    Paint()
      ..shader = ui.Gradient.radial(
        Offset(-0.1 * r, -0.1 * r),
        1.25 * r,
        const <Color>[
          AppMascot.highlight,
          AppMascot.body,
          AppMascot.mid,
          AppMascot.shade,
        ],
        const <double>[0, 0.32, 0.75, 1],
        TileMode.clamp,
        null,
        Offset(-0.38 * r, -0.42 * r),
        0.05 * r,
      ),
  );
  canvas.save();
  canvas.clipPath(Path()..addOval(ball));
  // Bands, curved like the surface of a ball seen a little from above.
  const List<(double, double, Color)> bands = <(double, double, Color)>[
    (-0.62, 0.11, AppMascot.band),
    (-0.36, 0.06, AppMascot.bandLight),
    (-0.12, 0.14, AppMascot.band),
    (0.38, 0.10, AppMascot.band),
    (0.62, 0.06, AppMascot.bandLight),
  ];
  for (final (double y, double h, Color color) in bands) {
    final double top = (y - h / 2) * r;
    final double bottom = (y + h / 2) * r;
    final Path path = Path()
      ..moveTo(-1.2 * r, top)
      ..quadraticBezierTo(0, top + 0.16 * r, 1.2 * r, top)
      ..lineTo(1.2 * r, bottom)
      ..quadraticBezierTo(0, bottom + 0.16 * r, -1.2 * r, bottom)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }
  // The night side, soft on the lower end.
  canvas.drawRect(
    ball,
    Paint()
      ..shader = ui.Gradient.radial(
        Offset(-0.2 * r, -0.25 * r),
        1.55 * r,
        const <Color>[AppMascot.nightClear, AppMascot.night],
        const <double>[0.39, 1],
        TileMode.clamp,
        null,
        Offset(-0.45 * r, -0.5 * r),
        0,
      ),
  );
  canvas.restore();
  // A glossy spot and a rim light on the lit side.
  canvas.drawOval(
    _oval(-0.42 * r, -0.5 * r, 0.32 * r, 0.26 * r),
    Paint()
      ..shader = ui.Gradient.radial(
        Offset(-0.42 * r, -0.5 * r),
        0.32 * r,
        const <Color>[AppMascot.gloss, AppMascot.glossClear],
      ),
  );
  canvas.drawArc(
    _oval(0, 0, 0.94 * r, 0.94 * r),
    1.08 * math.pi,
    0.34 * math.pi,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.05 * r
      ..strokeCap = StrokeCap.round
      ..color = AppMascot.rim,
  );
}

/// The ring's shadow on the ball: a soft crescent just above its near half.
void _ringShadow(Canvas canvas, double r) {
  canvas.save();
  canvas.clipPath(
    Path()..addOval(_oval(0, -_Geometry.ringDrop * r, r, r)),
  );
  canvas.rotate(_Geometry.tilt);
  final Path crescent = Path()
    ..arcTo(_oval(0, 0.10 * r, 1.5 * r, 0.40 * r), 0, math.pi, true)
    ..arcTo(_oval(0, 0.02 * r, 1.5 * r, 0.30 * r), math.pi, -math.pi, false)
    ..close();
  canvas.drawPath(
    crescent,
    Paint()
      ..color = AppMascot.ringShadow
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.05 * r),
  );
  canvas.restore();
}

void _face(Canvas canvas, double r, MascotMood mood) {
  canvas.save();
  canvas.translate(0, -0.18 * r);
  final Paint ink = Paint()..color = AppMascot.ink;
  final Paint line = Paint()
    ..color = AppMascot.ink
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final double ex = 0.30 * r;
  final double ey = -0.04 * r;
  if (mood == MascotMood.calm) {
    line.strokeWidth = 0.055 * r;
    for (final double side in <double>[-1, 1]) {
      canvas.drawArc(
        _oval(side * ex, ey + 0.02 * r, 0.1 * r, 0.1 * r),
        1.1 * math.pi,
        0.8 * math.pi,
        false,
        line,
      );
    }
  } else {
    final Paint light = Paint()..color = AppMascot.eyeLight;
    for (final double side in <double>[-1, 1]) {
      canvas.drawOval(_oval(side * ex, ey, 0.1 * r, 0.135 * r), ink);
      canvas.drawOval(
        _oval(side * ex + 0.035 * r, ey - 0.05 * r, 0.04 * r, 0.04 * r),
        light,
      );
      canvas.drawOval(
        _oval(side * ex - 0.025 * r, ey + 0.04 * r, 0.014 * r, 0.014 * r),
        light,
      );
    }
    if (mood == MascotMood.sure) {
      line.strokeWidth = 0.045 * r;
      for (final double side in <double>[-1, 1]) {
        canvas.drawLine(
          Offset(side * (ex + 0.1 * r), ey - 0.2 * r),
          Offset(side * (ex - 0.07 * r), ey - 0.15 * r),
          line,
        );
      }
    }
  }
  final Paint cheek = Paint()..color = AppMascot.cheek;
  for (final double side in <double>[-1, 1]) {
    canvas.drawOval(_oval(side * 0.5 * r, 0.13 * r, 0.11 * r, 0.065 * r), cheek);
  }
  if (mood == MascotMood.happy) {
    final Path mouth = Path()
      ..moveTo(-0.15 * r, 0.12 * r)
      ..quadraticBezierTo(0, 0.14 * r, 0.15 * r, 0.12 * r)
      ..quadraticBezierTo(0.13 * r, 0.33 * r, 0, 0.33 * r)
      ..quadraticBezierTo(-0.13 * r, 0.33 * r, -0.15 * r, 0.12 * r)
      ..close();
    canvas.drawPath(mouth, ink);
    canvas.drawArc(
      _oval(0, 0.28 * r, 0.07 * r, 0.04 * r),
      math.pi,
      math.pi,
      true,
      Paint()..color = AppMascot.tongue,
    );
  } else {
    line.strokeWidth = 0.05 * r;
    final double dip = mood == MascotMood.sure ? 0.24 : 0.27;
    canvas.drawPath(
      Path()
        ..moveTo(-0.11 * r, 0.16 * r)
        ..quadraticBezierTo(0, dip * r, 0.11 * r, 0.16 * r),
      line,
    );
  }
  canvas.restore();
}
