import 'dart:async';

import 'package:android/features/reader/data/local_txt_picker.dart';

class FakeLocalTxtPicker implements LocalTxtPicker {
  int calls = 0;
  final pending = <Completer<LocalTxtFile?>>[];
  @override
  Future<LocalTxtFile?> pick() {
    calls++;
    final result = Completer<LocalTxtFile?>();
    pending.add(result);
    return result.future;
  }
}

class FakeLocalTxtFile {
  FakeLocalTxtFile(this.bytes, {this.name = 'archivo.txt', int? reportedSize,
    this.stream})
      : size = reportedSize ?? bytes.length;
  final List<int> bytes;
  final String name;
  final int size;
  final Stream<List<int>>? stream;
  int reads = 0;
  int releases = 0;
  LocalTxtFile get file => LocalTxtFile(name: name, size: size,
    openRead: () {
      reads++;
      return stream ?? Stream.value(bytes);
    },
    release: () async { releases++; });
}
