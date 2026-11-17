from pathlib import Path
files={
 'test/epub/epub_import_widgets_test.dart':r'''import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android/core/session/local_account_scope.dart';
import 'package:android/core/theme/app_theme.dart';
import 'package:android/features/epub/data/epub_file_access.dart';
import 'package:android/features/epub/data/epub_store.dart';
import 'package:android/features/epub/data/epub_validator.dart';
import 'package:android/features/epub/models/imported_epub.dart';
import 'package:android/features/epub/presentation/imported_epub_section.dart';
import '../fixtures/epub/fixture_bytes.dart';
import '../library_regression_test.dart' show installLocalTestAssets;

class MemoryStore implements EpubStore {
 final records=<String,ImportedEpub>{};final files=<String,Uint8List>{};bool full=false;
 @override Future<List<ImportedEpub>> list(String owner)async=>records.entries.where((e)=>e.key.startsWith('$owner/')).map((e)=>e.value).toList();
 @override Future<bool> contains(String owner,String id)async=>files.containsKey('$owner/$id');
 @override Future<Uint8List?> read(String owner,String id)async=>files['$owner/$id'];
 @override Future<void> insert(String owner,ImportedEpub book,Uint8List bytes)async{if(full)throw StateError('quota');records['$owner/${book.id}']=book;files['$owner/${book.id}']=Uint8List.fromList(bytes);}
 @override Future<void> update(String owner,ImportedEpub book)async{if(full)throw StateError('quota');records['$owner/${book.id}']=book;}
 @override Future<void> remove(String owner,String id)async{records.remove('$owner/$id');files.remove('$owner/$id');}
}
class Files implements EpubFileAccess {
 ValidatedEpub? result;Uint8List? exported;EpubFailure? failure;
 @override Future<ValidatedEpub?> pick()async{if(failure!=null)throw failure!;return result;}
 @override Future<bool> export(ImportedEpub book,Uint8List bytes)async{exported=Uint8List.fromList(bytes);return true;}
}
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();setUpAll(installLocalTestAssets);
 late MemoryStore store;late Files files;
 setUp((){store=MemoryStore();files=Files()..result=const EpubValidator().validate(base64Decode(fixtureEpubBase64),'fixture.epub');});
 Widget app(String account)=>MaterialApp(theme:AppTheme.light,builder:(c,child)=>LocalAccountScope(uid:account,child:child!),home:Scaffold(body:ListView(children:[ImportedEpubSection(store:store,files:files,readerBuilder:(source,repo,account)=>Scaffold(appBar:AppBar(title:Text(source.book.title)),body:Column(children:[Text('${source.book.chapters.length} capítulos reales'),FilledButton(onPressed:()async{await repo.progress(source.book.position(cfi:'epubcfi(/6/4!/4/2/1:0)',progress:.5,fontSize:22));if(cNavigator.currentContext case final BuildContext context) { if(context.mounted)Navigator.of(context).pop(); }},child:const Text('Guardar posición de prueba'))])))])),navigatorKey:cNavigator);
 Future<void> select(WidgetTester tester)async{await tester.tap(find.byKey(const ValueKey('epub-import')));await tester.pumpAndSettle();}
 for(final size in [const Size(320,568),const Size(360,640),const Size(390,844)]){
 testWidgets('import confirm read restore export delete and account isolation $size',(tester)async{
  tester.view.physicalSize=size;tester.view.devicePixelRatio=1;addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(app('A'));await tester.pumpAndSettle();await select(tester);
  await tester.tap(find.byKey(const ValueKey('epub-confirm-import')));await tester.pumpAndSettle();expect(find.text('3 capítulos reales'),findsOneWidget);
  await tester.tap(find.text('Guardar posición de prueba'));await tester.pumpAndSettle();
  expect(find.text('Continuar leyendo'),findsOneWidget);expect(store.records,hasLength(1));
  final book=store.records.values.single;expect(book.cfi,isNotEmpty);expect(book.fontSize,22);
  final export=find.byKey(ValueKey('epub-export-${book.id}'));await tester.ensureVisible(export);await tester.tap(export);await tester.pumpAndSettle();expect(files.exported,orderedEquals(base64Decode(fixtureEpubBase64)));
  await tester.pumpWidget(const SizedBox());await tester.pumpAndSettle();await tester.pumpWidget(app('A'));await tester.pumpAndSettle();await tester.tap(find.byKey(const ValueKey('epub-imported-toggle')));await tester.pumpAndSettle();expect(find.text('Continuar leyendo'),findsOneWidget);
  await tester.pumpWidget(app('B'));await tester.pumpAndSettle();expect(find.text('Mis libros importados (0)'),findsOneWidget);expect(find.text('Continuar leyendo'),findsNothing);
  await tester.pumpWidget(app('A'));await tester.pumpAndSettle();await tester.tap(find.byKey(const ValueKey('epub-imported-toggle')));await tester.pumpAndSettle();
  final delete=find.byKey(ValueKey('epub-delete-${book.id}'));await tester.ensureVisible(delete);await tester.tap(delete);await tester.pumpAndSettle();await tester.tap(find.text('Cancelar'));await tester.pumpAndSettle();expect(store.records,hasLength(1));
  await tester.tap(delete);await tester.pumpAndSettle();await tester.tap(find.byKey(const ValueKey('epub-confirm-delete')));await tester.pumpAndSettle();expect(store.records,isEmpty);expect(store.files,isEmpty);expect(tester.takeException(),isNull);
 });}
 testWidgets('picker and confirmation cancellation do not create entries',(tester)async{
  files.result=null;await tester.pumpWidget(app('A'));await tester.pumpAndSettle();await select(tester);expect(store.records,isEmpty);
  files.result=const EpubValidator().validate(base64Decode(fixtureEpubBase64),'fixture.epub');await select(tester);await tester.tap(find.text('Cancelar'));await tester.pumpAndSettle();expect(store.records,isEmpty);
 });
 testWidgets('quota failure and corrupt file have clear errors and no empty cards',(tester)async{
  store.full=true;await tester.pumpWidget(app('A'));await tester.pumpAndSettle();await select(tester);await tester.tap(find.byKey(const ValueKey('epub-confirm-import')));await tester.pumpAndSettle();expect(find.textContaining('no quedó almacenado'),findsOneWidget);expect(store.records,isEmpty);
  files.failure=const EpubFailure('El EPUB está corrupto.');await select(tester);expect(find.text('El EPUB está corrupto.'),findsOneWidget);expect(store.records,isEmpty);
 });
}
final cNavigator=GlobalKey<NavigatorState>();
'''
}
for name,text in files.items():
 p=Path(name);p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text,encoding='utf-8')
