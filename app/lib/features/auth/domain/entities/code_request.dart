/// A sign-in code that was sent: the request it belongs to, and the seconds
/// until the server sends one more code to the number (the wait grows with
/// each code, up to 10 minutes).
class CodeRequest {
  const CodeRequest({
    required this.verificationId,
    required this.resendAfterSeconds,
  });

  final String verificationId;
  final int resendAfterSeconds;
}
