import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android/features/reader/data/local_txt_picker.dart';
import 'package:android/features/reader/models/reader_document.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('miguelruivo.flutter.plugins.filepicker');
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null);
  });

  test('native adapter requests one TXT stream without eagerly loading bytes', () async {
    var cleared = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'clear') { cleared++; return true; }
        expect(call.method, 'custom');
        final args = call.arguments as Map;
        expect(args['allowedExtensions'], ['txt']);
        expect(args['allowMultipleSelection'], isFalse);
        expect(args['withData'], isFalse);
        return null;
      });
    expect(await const SystemLocalTxtPicker().pick(), isNull);
    expect(cleared, 1);
  });

  test('native adapter guards concurrent picks and releases its temporary cache once', () async {
    var picked = 0;
    var cleared = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'clear') { cleared++; return true; }
        picked++;
        return [{
          'name': 'solo.txt', 'path': 'unused_test_path',
          'size': 5, 'bytes': null,
        }];
      });
    final first = (await const SystemLocalTxtPicker().pick())!;
    expect(first.name, 'solo.txt');
    expect(first.size, 5);
    await expectLater(const SystemLocalTxtPicker().pick(), throwsA(isA<ReaderFailure>()));
    expect(picked, 1);
    // Do not subscribe: this adapter test neither opens nor writes any file.
    await first.release();
    await first.release();
    expect(cleared, 1);
  });

  test('failed native cleanup is reported and unlocks the selector', () async {
    var cleared = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'clear') return ++cleared > 1;
        return null;
      });
    await expectLater(const SystemLocalTxtPicker().pick(), throwsA(isA<ReaderFailure>()));
    expect(await const SystemLocalTxtPicker().pick(), isNull);
    expect(cleared, 2);
  });
}
