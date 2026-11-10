/// The simplified mode's text size, chosen in «حسابي»: «عادي», «كبير»,
/// «أكبر». Its [factor] scales every text of the mode, on top of the
/// phone's own text size.
enum SimplifiedTextSize {
  normal(1),
  large(1.15),
  larger(1.3);

  const SimplifiedTextSize(this.factor);

  final double factor;
}
