/// The font of the app's icons: Phosphor regular, and its fill for the
/// selected tabs. The icon classes, such as `ActionIcons`, declare the
/// Phosphor code points with these names.
///
/// App icons use Phosphor regular except the shared iOS edit pencil.
/// Phosphor icons follow the handoff
/// (package `phosphor_flutter`, which brings the font).
///
/// The handoff draws them as they are, not mirrored, on its Arabic pages.
/// `PhosphorIconsRegular` mirrors every icon in Arabic, so the icons are
/// declared in those classes with the same font and code points and no
/// mirroring.
/// Only the arrows that mean a direction (`ArrowIcons.back` and
/// `ArrowIcons.forward`) follow the
/// reading direction. Code points come from phosphor_flutter 2.1.0, whose
/// code points are stable.
const String phosphorFamily = 'PhosphorRegular';
const String phosphorFillFamily = 'PhosphorFill';
const String phosphorPackage = 'phosphor_flutter';
