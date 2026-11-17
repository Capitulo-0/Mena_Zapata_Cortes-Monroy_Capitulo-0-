from pathlib import Path
p=Path('tool/epub_chrome.mjs');s=p.read_text(encoding='utf-8');s=s.replace("document.querySelector('flt-semantics-placeholder')?.click()", "(()=>{function visit(n){if(n.nodeType===1){if(n.tagName==='FLT-SEMANTICS-PLACEHOLDER')n.click();if(n.shadowRoot)visit(n.shadowRoot)}for(const child of n.childNodes??[])visit(child)}visit(document)})()")
p.write_text(s,encoding='utf-8')
p=Path('lib/features/library/presentation/screens/library_screen.dart');s=p.read_text(encoding='utf-8');old='child: Padding(padding: const EdgeInsets.all(16), child: _buildHeader()),';new='''child: ListView(
        padding: const EdgeInsets.all(16),
        children: [_buildHeader(), const SizedBox(height: 8), const ImportedEpubSection()],
      ),''';assert old in s;s=s.replace(old,new);p.write_text(s,encoding='utf-8')
p=Path('lib/features/epub/data/epub_validator.dart');s=p.read_text(encoding='utf-8').replace("if (RegExp(r'<!\\s*(DOCTYPE|ENTITY)', caseSensitive: false).hasMatch(text))", "if (RegExp(r'<!\\s*(DOCTYPE|ENTITY)|<\\?(?!xml\\s)', caseSensitive: false).hasMatch(text))");p.write_text(s,encoding='utf-8')
