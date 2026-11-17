from pathlib import Path
p=Path('lib/features/epub/data/epub_store_web.dart');s=p.read_text(encoding='utf-8').replace("'$owner/\\\\uffff'", "'$owner/~'").replace("'$owner/\\uffff'", "'$owner/~'");p.write_text(s,encoding='utf-8')
p=Path('lib/features/epub/data/epub_validator.dart');s=p.read_text(encoding='utf-8');pos=s.index('  void _safeMarkup(');s=s[:pos]+'''  String _bookHref(String opf, String target) {
    final base = opf.split('/')..removeLast();
    final parts = target.split('/');
    var shared = 0;
    while (shared < base.length && shared < parts.length && base[shared] == parts[shared]) { shared++; }
    return Uri(path: [...List.filled(base.length-shared, '..'), ...parts.skip(shared)].join('/')).toString();
  }
'''+s[pos:]
s=s.replace("resolved +", "_bookHref(opfPath, resolved) +")
s=s.replace("'Capítulo ${chapters.length + 1}', path", "'Capítulo ${chapters.length + 1}', _bookHref(opfPath, path)")
p.write_text(s,encoding='utf-8')
p=Path('lib/features/epub/models/imported_epub.dart');s=p.read_text(encoding='utf-8').replace('    bool? fileAvailable,','    bool? fileAvailable,\n    List<EpubTocItem>? chapters,').replace('    chapters: chapters,','    chapters: chapters ?? this.chapters,');p.write_text(s,encoding='utf-8')
p=Path('lib/features/epub/data/epub_repository.dart');s=p.read_text(encoding='utf-8').replace("    const EpubValidator().validate(data, book.fileName);\n    return ValidatedEpub(book, data);", "    final validated = const EpubValidator().validate(data, book.fileName);\n    return ValidatedEpub(book.position(chapters: validated.book.chapters), data);")
p.write_text(s,encoding='utf-8')
p=Path('lib/features/epub/presentation/epub_reader_screen.dart');s=p.read_text(encoding='utf-8').replace("initialCfi: _book.cfi.isEmpty ? null : widget.source.book.cfi", "initialCfi: widget.source.book.cfi.isEmpty ? null : widget.source.book.cfi")
s=s.replace('if (_active) setState(() => _ready = true);', '''if (!_active) return;
                          setState(() => _ready = true);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_active) _controller.display(cfi: widget.source.book.cfi.isNotEmpty ? widget.source.book.cfi : _book.chapters.first.href);
                          });''')
p.write_text(s,encoding='utf-8')
