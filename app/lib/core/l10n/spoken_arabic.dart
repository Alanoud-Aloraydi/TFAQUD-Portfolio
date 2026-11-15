/// Arabic written for a screen reader to say, not for the screen to show.
///
/// Arabic on screen carries no vowels, so the reader guesses them, and it
/// guesses some of our words wrong: «سكر» comes out «سَكَر» (drunkenness)
/// instead of «سُكَّر», and «ملغ» is spelled out letter by letter. The words
/// it says wrong carry their vowels in [_spokenWords], and the short forms
/// are said in full. None of this reaches the screen: it is only for a
/// `semanticsLabel` or a `Semantics(label:)`.
library;

/// The words the reader says wrong, with the vowels it needs, and the short
/// forms said in full. A word that is written with its vowels already does
/// not match here, so a translation can always overrule a line below.
const Map<String, String> _spokenWords = <String, String>{
  // The app's own name, spelled as the app spells it everywhere else.
  'تفقد': 'تفقُد',
  // The two measurements. «سكر» without its vowels is another word.
  'سكر': 'سُكَّر',
  'السكر': 'السُّكَّر',
  'ضغط': 'ضَغْط',
  'الضغط': 'الضَّغْط',
  'دم': 'دَم',
  'الدم': 'الدَّم',
  'فصيلة': 'فَصِيلة',
  'قياس': 'قِياس',
  'القياس': 'القِياس',
  'قياسات': 'قِياسات',
  'القياسات': 'القِياسات',
  // Medicines and doses.
  'دواء': 'دَواء',
  'الدواء': 'الدَّواء',
  'أدوية': 'أدوِية',
  'الأدوية': 'الأدوِية',
  'جرعة': 'جُرعة',
  'الجرعة': 'الجُرعة',
  'جرعات': 'جُرعات',
  'الجرعات': 'الجُرعات',
  'حبة': 'حَبّة',
  'حبات': 'حَبّات',
  'حبتين': 'حَبّتين',
  'مرة': 'مَرّة',
  'مرتين': 'مَرّتين',
  'مرات': 'مَرّات',
  'وحدة': 'وَحدة',
  'حساسية': 'حَساسِيّة',
  'الحساسية': 'الحَساسِيّة',
  // Units, said in full instead of spelled out letter by letter.
  'ملغ': 'مِلّيغرام',
  'مج': 'مِلّيغرام',
  'مل': 'مِلّيلتر',
  // The plan, the appointments, and how a task stands.
  'خطة': 'خُطّة',
  'الخطة': 'الخُطّة',
  'موعد': 'مَوعِد',
  'موعده': 'مَوعِده',
  'الموعد': 'المَوعِد',
  'مواعيد': 'مَواعِيد',
  'المواعيد': 'المَواعِيد',
  'متأخر': 'مُتأخِّر',
  'متأخرة': 'مُتأخِّرة',
  'فائتة': 'فائِتة',
  'الفائتة': 'الفائِتة',
  'قادمة': 'قادِمة',
  'تم': 'تَمّ',
};

/// A clock time and the one letter after it. On screen a time is «4:30 م»
/// (`common.am` and `common.pm`), and read out that letter is said by its
/// own name — «ميم» — so it is said in full instead.
final RegExp _beforeNoon = RegExp(r'(\d{1,2}:\d{2}) ص(?![\u0621-\u064A])');
final RegExp _afterNoon = RegExp(r'(\d{1,2}:\d{2}) م(?![\u0621-\u064A])');

/// A run of Arabic letters with no vowel mark touching either end: one bare
/// word. A word the translation already vowelled fails the two guards and
/// is left exactly as it was written, marks and all.
final RegExp _bareWord = RegExp(
  r'(?<![\u064B-\u0652\u0670])[\u0621-\u064A]+(?![\u064B-\u0652\u0670])',
);

/// [text] the way the reader should say it: « · » becomes a pause, and each
/// word of [_spokenWords] gets its vowels. Null in, null out, so a label
/// that was never given stays unsaid. For a label, never for a [Text].
String? spoken(String? text) => text
    ?.replaceAll(' · ', '، ')
    .replaceAllMapped(_beforeNoon, (Match m) => '${m[1]} صباحًا')
    .replaceAllMapped(_afterNoon, (Match m) => '${m[1]} مساءً')
    .replaceAllMapped(_bareWord, (Match m) => _spokenWords[m[0]] ?? m[0]!);
