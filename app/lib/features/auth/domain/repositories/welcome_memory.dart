/// Whether this install already showed the welcome pages.
///
/// The welcome shows once: after «ابدأ» or «تخطي», a signed-out phone opens
/// on the phone number page instead. Where that is kept is the data layer's
/// business; nothing about it goes to the server.
abstract class WelcomeMemory {
  /// True once [markSeen] ran on this install.
  Future<bool> seen();

  /// The person finished or skipped the welcome.
  Future<void> markSeen();
}
