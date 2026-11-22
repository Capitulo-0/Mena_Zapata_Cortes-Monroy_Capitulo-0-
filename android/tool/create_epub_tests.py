from pathlib import Path
files={
 'test/epub/epub_core_test.dart':r'''import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android/features/epub/data/epub_validator.dart';
import 'package:android/features/epub/data/epub_repository.dart';
import 'package:android/features/epub/data/epub_store_native.dart';
import 'package:android/features/epub/models/imported_epub.dart';
import '../fixtures/epub/fixture_bytes.dart';

Uint8List fixture()=>base64Decode(fixtureEpubBase64);
Uint8List changed(String path,String text) {
 final archive=ZipDecoder().decodeBytes(fixture());
 final output=Archive();
 for(final file in archive.files) {
   final bytes=file.name==path?utf8.encode(text):file.readBytes()!;
   final entry=ArchiveFile(file.name,bytes.length,bytes)..compression=file.name=='mimetype'?CompressionType.none:CompressionType.deflate;
   output.add(entry);
 }
 if(!archive.files.any((f)=>f.name==path)){final bytes=utf8.encode(text);output.add(ArchiveFile(path,bytes.length,bytes));}
 return Uint8List.fromList(ZipEncoder().encode(output));
}
void main() {
 const validator=EpubValidator();
 test('original real EPUB has its title author and three ordered chapters',(){
   final source=validator.validate(fixture(),'fixture.epub');
   expect(source.book.title,'La llave de papel — prueba EPUB');expect(source.book.author,contains('texto original'));
   expect(source.book.chapters,hasLength(3));
   expect(source.book.chapters[1].title,contains('El puente de las voces'));
   expect(source.bytes,orderedEquals(File('test/fixtures/epub/capitulo0_prueba_3_capitulos.epub').readAsBytesSync()));
 });
 test('extension empty corrupt truncated excessive and altered CRC are rejected',(){
   for(final pair in [(fixture(),'false.txt'),(Uint8List(0),'empty.epub'),(Uint8List.fromList([1,2,3]),'bad.epub'),(fixture().sublist(0,400),'cut.epub'),(Uint8List(EpubValidator.maxBytes+1),'large.epub')]) {
     expect(()=>validator.validate(pair.$1,pair.$2),throwsA(isA<EpubFailure>()));
   }
   final damaged=fixture();damaged[45]^=255;
   expect(()=>validator.validate(damaged,'bad.epub'),throwsA(isA<EpubFailure>()));
 });
 test('DRM scripts active handlers remote CSS and traversal are rejected',(){
   for(final data in [changed('META-INF/encryption.xml','<encryption/>'),changed('OEBPS/capitulo1.xhtml','<html><script>alert(1)</script></html>'),changed('OEBPS/capitulo1.xhtml','<html><body onload="alert(1)">x</body></html>'),changed('OEBPS/capitulo1.xhtml','<html><img src="https://example.test/pixel"/></html>'),changed('OEBPS/remote.css','@import "https://example.test/font";'),changed('../outside.txt','not allowed')]) {
     expect(()=>validator.validate(data,'unsafe.epub'),throwsA(isA<EpubFailure>()));
   }
 });
 test('declared decompression bomb is rejected before decoding',(){
   final data=fixture();final view=ByteData.sublistView(data);
   for(var p=0;p<data.length-46;p++){if(view.getUint32(p,Endian.little)==0x02014b50){view.setUint32(p+24,EpubValidator.maxExpanded+1,Endian.little);break;}}
   expect(()=>validator.validate(data,'bomb.epub'),throwsA(isA<EpubFailure>().having((e)=>e.message,'message',contains('descomprimido'))));
 });
 test('real private files survive recreation, preserve CFI, isolate accounts, export and reimport',()async {
   final dir=Directory.systemTemp.createTempSync('capitulo0_epub_test_');addTearDown(()=>dir.deleteSync(recursive:true));
   final repo=EpubRepository(account:'account-A',store:NativeEpubStore(baseDirectory:dir));
   final source=validator.validate(fixture(),'fixture.epub');
   final book=await repo.import(source);expect(await repo.list(),hasLength(1));
   await repo.import(source);expect(await repo.list(),hasLength(1));
   await repo.progress(book.position(cfi:'epubcfi(/6/4!/4/2/1:0)',progress:.4,fontSize:22));
   final restarted=EpubRepository(account:'account-A',store:NativeEpubStore(baseDirectory:dir));
   final restored=(await restarted.list()).single;
   expect(restored.cfi,'epubcfi(/6/4!/4/2/1:0)');expect(restored.fontSize,22);expect(restored.progress,.4);
   final other=EpubRepository(account:'account-B',store:NativeEpubStore(baseDirectory:dir));
   expect(await other.list(),isEmpty);await expectLater(other.bytes(book),throwsA(isA<EpubFailure>()));
   final exported=await restarted.bytes(restored);expect(exported,orderedEquals(fixture()));
   await restarted.remove(restored);expect(await restarted.list(),isEmpty);
   final reimport=await restarted.import(validator.validate(exported,'exported.epub'));
   expect((await restarted.open(reimport)).book.chapters,hasLength(3));
   expect(reimport.cfi,isEmpty);
 });
 test('a missing original is marked unavailable and can be recovered without losing progress',()async{
   final dir=Directory.systemTemp.createTempSync('capitulo0_epub_missing_');addTearDown(()=>dir.deleteSync(recursive:true));
   final store=NativeEpubStore(baseDirectory:dir);final repo=EpubRepository(account:'A',store:store);
   final source=validator.validate(fixture(),'fixture.epub');final book=await repo.import(source);
   await repo.progress(book.position(cfi:'epubcfi(/6/4!/4/2/1:0)',progress:.4));
   File('${dir.path}/imported_epubs_v1/${repo.owner}/${book.id}.epub').deleteSync();
   expect((await repo.list()).single.fileAvailable,isFalse);
   await expectLater(repo.open(book),throwsA(isA<EpubFailure>()));
   final restored=await repo.import(source);expect(restored.cfi,isNotEmpty);expect(await repo.bytes(restored),orderedEquals(fixture()));
 });
}
''',
}
for name,text in files.items():
 p=Path(name);p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text,encoding='utf-8')
