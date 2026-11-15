import 'package:equatable/equatable.dart';

/// One normal band a month chart shades, and the legend's name for it.
/// [inner] lies inside another band (fasting inside after a meal) and is
/// shaded darker so both show.
class ChartBand extends Equatable {
  const ChartBand(this.low, this.high, this.labelKey, {this.inner = false});

  final int low;
  final int high;
  final String labelKey;
  final bool inner;

  @override
  List<Object?> get props => [low, high, labelKey, inner];
}
