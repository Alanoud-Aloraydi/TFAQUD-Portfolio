import 'dart:async';

/// Runs one job at a time. Calls made while the job runs do not start a
/// second one: they fold into one more run right after it, so the last
/// change is always read, however many calls came in.
class CoalescingRunner {
  CoalescingRunner(this._job);

  final Future<void> Function() _job;
  Future<void>? _running;

  /// The run that follows the running one, shared by every call that came
  /// in meanwhile.
  Future<void>? _queued;
  bool _dropped = false;

  /// Runs the job, or joins the one run that follows the running one. The
  /// future ends when a run that started after this call is done, so a
  /// caller that changed the job's input knows the change is applied.
  Future<void> run() {
    final Future<void>? running = _running;
    if (running == null) {
      final Future<void> started = _job().whenComplete(() => _running = null);
      _running = started;
      return started;
    }
    // A call after dropPending asks for the run again. The running job's
    // failure is its own callers'; the next run starts either way.
    _dropped = false;
    return _queued ??= running.then<void>((_) {}, onError: (Object _) {}).then((
      _,
    ) {
      _queued = null;
      if (!_dropped) return run();
      _dropped = false;
    });
  }

  /// Forgets the run asked for during the current one (sign-out: there is
  /// nothing left to read); its callers' futures end with the current run.
  void dropPending() {
    if (_queued != null) _dropped = true;
  }
}
