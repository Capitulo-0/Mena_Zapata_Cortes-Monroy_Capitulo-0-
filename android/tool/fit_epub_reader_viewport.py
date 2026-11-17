from pathlib import Path
p=Path('lib/features/epub/presentation/epub_reader_screen.dart');s=p.read_text(encoding='utf-8').replace("import '../data/epub_repository.dart';", "import '../data/epub_repository.dart';\nimport '../data/epub_viewport.dart';")
s=s.replace('setState(() => _showIndex = false);\n                                  _controller.display(cfi: chapter.href);', '''setState(() => _showIndex = false);
                                  // epub.js restores its old CFI while resizing: navigate after that restoration.
                                  Future<void>.delayed(const Duration(milliseconds: 350), () {
                                    if (_active && _ready) { _controller.display(cfi: chapter.href); }
                                  });''')
s=s.replace('setState(() => _ready = true);\n                          WidgetsBinding', 'setState(() => _ready = true);\n                          fitEpubViewport();\n                          WidgetsBinding')
s=s.replace("'line-height': '1.6',", "'line-height': '1.6',\n                                'background-color': '#F6EFDF',\n                                'color': '#3B2A20',")
p.write_text(s,encoding='utf-8')
files={
'lib/features/epub/data/epub_viewport.dart':"export 'epub_viewport_stub.dart' if (dart.library.js_interop) 'epub_viewport_web.dart';\n",
'lib/features/epub/data/epub_viewport_stub.dart':'void fitEpubViewport() {}\n',
'lib/features/epub/data/epub_viewport_web.dart':'''import 'package:web/web.dart' as web;

/// Narrow compatibility adapter for the viewer's example-page 800px minimum.
/// Touches only its same-origin host document, never book scripts or app styles.
void fitEpubViewport() {
  final frames=web.document.querySelectorAll('iframe');
  for(var i=0;i<frames.length;i++) {
    final frame=frames.item(i) as web.HTMLIFrameElement;
    if(!frame.src.endsWith('/flutter_epub_viewer/lib/assets/webpage/html/swipe.html')) { continue; }
    final document=frame.contentDocument;
    final body=document?.body;
    if(body==null) { continue; }
    body.style.minHeight='0';body.style.margin='0';body.style.overflow='hidden';
    (document!.documentElement as web.HTMLElement).style.overflow='hidden';
    final viewer=document.getElementById('viewer') as web.HTMLElement?;
    if(viewer!=null) { viewer.style.margin='0'; }
  }
}
'''}
for name,text in files.items():Path(name).write_text(text,encoding='utf-8')
