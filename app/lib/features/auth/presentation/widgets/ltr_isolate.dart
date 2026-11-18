/// [text] kept left to right inside Arabic text: U+2066 and U+2069 isolate
/// a number written left to right.
String ltrIsolate(String text) => '\u2066$text\u2069';
