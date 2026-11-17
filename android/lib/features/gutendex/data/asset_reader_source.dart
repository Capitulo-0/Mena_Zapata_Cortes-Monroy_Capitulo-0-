import 'package:flutter/services.dart';

import '../../reader/models/reader_document.dart';
import '../models/free_work.dart';

/// Only bundled, explicitly approved work assets; no URL fetch or persistence.
class AssetReaderSource {
  const AssetReaderSource({this.bundle});
  final AssetBundle? bundle;
  Future<ReaderSource> load(
    FreeWork work, {
    bool Function()? isCancelled,
  }) async {
    final path = work.assetPath;
    if (!work.available ||
        path == null ||
        !path.startsWith('assets/free_works/') ||
        path.contains('..') ||
        !path.endsWith('.txt')) {
      throw const ReaderFailure('Esta obra no tiene texto local disponible.');
    }
    if (isCancelled?.call() == true) throw const ReaderCancelled();
    final data = await (bundle ?? rootBundle).load(path);
    if (isCancelled?.call() == true) throw const ReaderCancelled();
    if (data.lengthInBytes > ReaderSource.maxBytes) {
      throw const ReaderFailure('El archivo supera el límite de 8 MiB.');
    }
    return ReaderSource.utf8(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      title: work.title,
      author: work.author,
    ).validated(isCancelled: isCancelled);
  }
}
