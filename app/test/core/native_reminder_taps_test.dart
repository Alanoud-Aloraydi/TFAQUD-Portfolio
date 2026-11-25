import 'package:app/app/services/notifications/plugin_phone_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('test/reminder_taps');
  final TestDefaultBinaryMessenger messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  /// The app's delegate sending a tap that came after Dart listened.
  Future<void> nativeTap(Object? tap) => messenger.handlePlatformMessage(
    channel.name,
    const StandardMethodCodec().encodeMethodCall(MethodCall('tap', tap)),
    (_) {},
  );

  test('the reminder that opened the closed app comes first, then each '
      'tap as it happens', () async {
    messenger.setMockMethodCallHandler(channel, (MethodCall call) async {
      expect(call.method, 'listen');
      return <Object?>[
        <String, String>{'payload': 'dose:c-1', 'action': ''},
      ];
    });
    final List<String> taps = <String>[];

    await const NativeReminderTaps(
      channel,
    ).listen((String payload, String action) => taps.add('$payload/$action'));
    await nativeTap(<String, String>{
      'payload': 'measurement:c-1',
      'action': '',
    });
    await nativeTap(<String, String>{
      'payload': 'dose:c-1',
      'action': 'snooze',
    });

    expect(taps, <String>['dose:c-1/', 'measurement:c-1/', 'dose:c-1/snooze']);
  });

  test('a tap without its payload or action is not given', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (MethodCall call) async => <Object?>[
        <String, Object?>{'payload': 'dose:c-1'},
        'dose:c-1',
        null,
      ],
    );
    final List<String> taps = <String>[];

    await const NativeReminderTaps(channel)
        .listen((String payload, String action) => taps.add(payload));
    await nativeTap(<String, Object?>{'payload': 7, 'action': ''});

    expect(taps, isEmpty);
  });

  test('a build without the native side starts without taps', () async {
    final List<String> taps = <String>[];

    await const NativeReminderTaps(channel)
        .listen((String payload, String action) => taps.add(payload));

    expect(taps, isEmpty);
  });
}
