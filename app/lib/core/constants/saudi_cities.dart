/// The cities the city sheet offers. The first seven are the cities of the
/// design (CREAT-01B), in its order. Add a city by adding its name here. The
/// name is saved as written, so it is also what the circle shows later.
abstract class SaudiCities {
  SaudiCities._();

  static const List<String> all = <String>[
    'الرياض',
    'جدة',
    'مكة المكرمة',
    'المدينة المنورة',
    'الدمام',
    'بريدة',
    'أبها',
    'الطائف',
    'تبوك',
    'الخبر',
    'الظهران',
    'الهفوف',
    'الجبيل',
    'حائل',
    'نجران',
    'جازان',
    'ينبع',
    'القطيف',
    'خميس مشيط',
    'الباحة',
    'عرعر',
    'سكاكا',
    'الخرج',
  ];

  /// The cities whose name contains [query]. Letters that people write in more
  /// than one way (the forms of alef, the teh marbuta, the alef maqsura) count
  /// as the same letter, so "ابها" finds "أبها". An empty query gives all.
  static List<String> search(String query) {
    final String wanted = _normalize(query);
    if (wanted.isEmpty) return all;
    return <String>[
      for (final String city in all)
        if (_normalize(city).contains(wanted)) city,
    ];
  }

  static String _normalize(String text) {
    return text
        .trim()
        .replaceAll(RegExp('[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp('\\s+'), ' ');
  }
}
