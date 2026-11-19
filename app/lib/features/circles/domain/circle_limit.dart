/// How many circles one person can be in at once; the server refuses one
/// more with `too_many_circles`.
abstract final class CircleLimit {
  /// The circles they are in, plus the requests they sent that still wait.
  static const int perPerson = 6;

  /// Whether a person with [circles] circles and [waitingRequests] sent
  /// requests still waiting has reached the limit.
  static bool reached(int circles, int waitingRequests) =>
      circles + waitingRequests >= perPerson;
}
