/// Keeps identity attached to the provider reference. Never borrows another cover.
class BookCoverReference {
  static String resolve(String? raw, {String? googleVolumeId}) {
    final value = raw?.trim() ?? '';
    if (value.startsWith('assets/') && !value.split('/').contains('..')) {
      return value;
    }
    var uri = Uri.tryParse(value);
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment) {
      return '';
    }
    final google =
        uri.host == 'books.google.com' ||
        uri.host == 'books.googleusercontent.com';
    if (uri.host == 'images.unsplash.com' ||
        uri.host == 'source.unsplash.com') {
      return '';
    }
    if (google && googleVolumeId != null && googleVolumeId.isNotEmpty) {
      final ids = uri.queryParametersAll['id'];
      if (uri.host == 'books.google.com' &&
          (ids == null || ids.length != 1 || ids.single != googleVolumeId)) {
        return '';
      }
      if (ids != null && (ids.length != 1 || ids.single != googleVolumeId)) {
        return '';
      }
    }
    if (uri.scheme == 'http' &&
        (google ||
            uri.host == 'www.gutenberg.org' ||
            uri.host == 'gutenberg.org')) {
      uri = uri.replace(
        scheme: 'https',
        port: uri.hasPort && uri.port != 80 ? uri.port : 443,
      );
    }
    return uri.scheme == 'https' || uri.scheme == 'http' ? uri.toString() : '';
  }
}
