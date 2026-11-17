from pathlib import Path
p=Path('lib/features/epub/presentation/epub_reader_screen.dart');s=p.read_text(encoding='utf-8');old='''                                        setState(() => _showIndex = false);
                                        _controller.display(cfi: chapter.href);'''
if old not in s:
 start=s.index('setState(() => _showIndex = false);');print(repr(s[start-80:start+180]));raise SystemExit('Inspect navigation block')
s=s.replace(old,'''                                        setState(() => _showIndex = false);
                                        // Let epub.js finish its resize/CFI restoration before changing chapter.
                                        Future<void>.delayed(const Duration(milliseconds: 350), () {
                                          if (_active && _ready) _controller.display(cfi: chapter.href);
                                        });''')
s=s.replace("'line-height': '1.6',", "'line-height': '1.6',\n                                'background-color': '#F6EFDF',\n                                'color': '#3B2A20',")
p.write_text(s,encoding='utf-8')
