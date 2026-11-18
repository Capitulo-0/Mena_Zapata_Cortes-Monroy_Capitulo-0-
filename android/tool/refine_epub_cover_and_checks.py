from pathlib import Path
p=Path('tool/epub_chrome.mjs');s=p.read_text(encoding='utf-8').replace('async pickFile(file){','async pickFile(file,label=\'Importar libro EPUB\'){').replace("await this.click('Importar libro EPUB');",'await this.click(label);');p.write_text(s,encoding='utf-8')
p=Path('lib/features/epub/presentation/imported_epub_section.dart');s=p.read_text(encoding='utf-8');old='''child: const Icon(
                          Icons.menu_book,
                          color: AppColors.gold,
                        ),''';new='''child: Padding(padding: const EdgeInsets.all(4), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.menu_book, color: AppColors.gold, size: 16),
                          const SizedBox(height: 4),
                          Text(book.title, maxLines: 3, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'serif', fontSize: 7, color: AppColors.background)),
                        ])),''';assert old in s;s=s.replace(old,new);p.write_text(s,encoding='utf-8')
p=Path('test/gutendex/free_collection_test.dart');s=p.read_text(encoding='utf-8').replace("expect(freeWorks, hasLength(50));","expect(freeWorks, hasLength(50));\n    expect(freeWorks.map((w) => w.title.trim().toLowerCase()).toSet(), hasLength(50));");p.write_text(s,encoding='utf-8')
