from pathlib import Path
p=Path('lib/features/epub/presentation/epub_reader_screen.dart');s=p.read_text(encoding='utf-8').replace('onEpubLoaded: () {\n                          if (!_active) return;', 'onEpubLoaded: () {\n                          if (!_active || _ready) return;');p.write_text(s,encoding='utf-8')
p=Path('lib/features/gutendex/presentation/screens/free_library_screen.dart');s=p.read_text(encoding='utf-8').replace('        OutlinedButton.icon(\n          onPressed:', '        TextButton.icon(\n          onPressed:');p.write_text(s,encoding='utf-8')
