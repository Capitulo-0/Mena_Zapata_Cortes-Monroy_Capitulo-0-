from pathlib import Path
p=Path('tool/epub_chrome.mjs');s=p.read_text(encoding='utf-8').replace('async click(label,contains=false){','async click(label,contains=false,attempt=0){');s=s.replace("if(!point)throw new Error('No clickable semantics: '+label+'; '+await this.text());", "if(!point){if(attempt<15){await pause(300);return this.click(label,contains,attempt+1)}throw new Error('No clickable semantics: '+label+'; '+await this.text())}")
p.write_text(s,encoding='utf-8')
p=Path('tool/epub_chrome_edge_cases.mjs');s=p.read_text(encoding='utf-8');old=" await c.click('Volver a Mi Biblioteca');await c.waitText('Continuar leyendo');\n await c.click('Eliminar de mi Biblioteca');await c.click('Eliminar');await c.waitText('Mis libros importados (0)');";new=""" const initial=await c.text();
 if(initial.includes('Incorporar EPUB'))await c.click('Cancelar');
 else if(initial.includes('Volver a Mi Biblioteca'))await c.click('Volver a Mi Biblioteca');
 if((await records()).length){if(!(await c.text()).includes('Eliminar de mi Biblioteca'))await c.click('Mis libros importados (1)');await c.click('Eliminar de mi Biblioteca');await c.click('Eliminar');}
 await c.waitText('Mis libros importados (0)');""";assert old in s;s=s.replace(old,new);p.write_text(s,encoding='utf-8')
p=Path('test_web/epub_persistence_test.dart');p.parent.mkdir(exist_ok=True);p.write_text('''import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:android/features/epub/data/epub_store.dart';
import 'package:android/features/epub/data/epub_repository.dart';
import 'package:android/features/epub/data/epub_validator.dart';
import 'package:android/features/epub/models/imported_epub.dart';
import '../test/fixtures/epub/fixture_bytes.dart';

void main() {
  test('real IndexedDB preserves bytes/CFI across store recreation and isolates accounts', () async {
    final suffix=DateTime.now().microsecondsSinceEpoch.toString();
    final source=const EpubValidator().validate(base64Decode(fixtureEpubBase64),'fixture.epub');
    final first=EpubRepository(account:'browser-A-$suffix',store:createEpubStore());
    final other=EpubRepository(account:'browser-B-$suffix',store:createEpubStore());
    final book=await first.import(source);
    addTearDown(() async {await first.remove(book);await other.remove(book);});
    await first.progress(book.position(cfi:'epubcfi(/6/4!/4/2/1:0)',progress:.5,fontSize:22));
    final restarted=EpubRepository(account:'browser-A-$suffix',store:createEpubStore());
    final restored=(await restarted.list()).single;
    expect(restored.cfi,'epubcfi(/6/4!/4/2/1:0)');expect(restored.fontSize,22);expect(restored.fileAvailable,isTrue);
    expect(await restarted.bytes(restored),orderedEquals(source.bytes));
    expect(await other.list(),isEmpty);await expectLater(other.bytes(book),throwsA(isA<EpubFailure>()));
    await restarted.import(source);expect(await restarted.list(),hasLength(1));
    final copy=await restarted.bytes(restored);await restarted.remove(restored);expect(await restarted.list(),isEmpty);
    final again=await restarted.import(const EpubValidator().validate(copy,'copy.epub'));
    expect((await restarted.open(again)).book.chapters,hasLength(3));expect(again.cfi,isEmpty);
  });
}
''',encoding='utf-8')
