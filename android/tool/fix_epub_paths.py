from pathlib import Path
p=Path('tool/epub_chrome.mjs');s=p.read_text(encoding='utf-8-sig');s=s.replace("if(process.argv[1]===new URL(import.meta.url).pathname.replace(/^\\/([A-Z]:)/,'$1')){", "if(process.argv[1]?.endsWith('epub_chrome.mjs')){");p.write_text(s,encoding='utf-8')
p=Path('lib/features/epub/data/epub_validator.dart');s=p.read_text(encoding='utf-8');s=s.replace("contains('"+chr(92)*4+"')","contains('"+chr(92)*2+"')");p.write_text(s,encoding='utf-8')
