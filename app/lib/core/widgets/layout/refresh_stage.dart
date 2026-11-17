/// Where a pull-down refresh stands, as the header over the page says it:
/// pulled a little («اسحب للتحديث»), far enough to let go («أفلت للتحديث»),
/// reading («جارٍ التحديث…»), then done for a moment («تم التحديث»).
enum RefreshStage {
  idle(null),
  pulling('refresh.pull'),
  armed('refresh.release'),
  loading('refresh.loading'),
  done('refresh.done');

  const RefreshStage(this.wordsKey);

  /// The words under the loader; null while nothing shows.
  final String? wordsKey;

  /// Whether the page is held open over the header, reading or just read.
  bool get isHeld => this == loading || this == done;
}
