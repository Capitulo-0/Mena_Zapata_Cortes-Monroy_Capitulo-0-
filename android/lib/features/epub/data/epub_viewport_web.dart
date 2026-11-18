import 'package:web/web.dart' as web;

/// Narrow compatibility adapter for the viewer's example-page 800px minimum.
/// Touches only its same-origin host document, never book scripts or app styles.
void fitEpubViewport() {
  final frames = web.document.querySelectorAll('iframe');
  for (var i = 0; i < frames.length; i++) {
    final frame = frames.item(i) as web.HTMLIFrameElement;
    if (!frame.src.endsWith(
      '/flutter_epub_viewer/lib/assets/webpage/html/swipe.html',
    )) {
      continue;
    }
    final document = frame.contentDocument;
    final body = document?.body;
    if (body == null) {
      continue;
    }
    body.style.minHeight = '0';
    body.style.margin = '0';
    body.style.overflow = 'hidden';
    (document!.documentElement as web.HTMLElement).style.overflow = 'hidden';
    final viewer = document.getElementById('viewer') as web.HTMLElement?;
    if (viewer != null) {
      viewer.style.margin = '0';
    }
  }
}
