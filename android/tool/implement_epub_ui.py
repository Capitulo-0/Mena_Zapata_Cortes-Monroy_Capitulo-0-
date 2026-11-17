from pathlib import Path
files={
'lib/features/epub/presentation/epub_reader_screen.dart':r'''import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import '../../../core/session/local_account_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../data/epub_repository.dart';
import '../models/imported_epub.dart';

class EpubReaderScreen extends StatefulWidget {
  const EpubReaderScreen({super.key,required this.source,required this.repository,required this.account});
  final ValidatedEpub source;
  final EpubRepository repository;
  final String account;
  @override
  State<EpubReaderScreen> createState()=>_EpubReaderScreenState();
}
class _EpubReaderScreenState extends State<EpubReaderScreen> {
  final _controller=EpubController();
  late ImportedEpub _book;
  late EpubSource _source;
  late bool _restoring;
  bool _ready=false,_showIndex=false,_locationsReady=false,_closing=false,_allowPop=false;
  String? _error,_saveError;
  Future<void> _saves=Future.value();
  bool get _active=>mounted && (LocalAccountScope.read(context) ?? 'guest')==widget.account;
  @override
  void initState() {
    super.initState();_book=widget.source.book;_source=EpubSource.fromData(widget.source.bytes);_restoring=_book.cfi.isNotEmpty;
  }
  void _save() {
    final book=_book;
    _saves=_saves.then((_) async {
      if(!_active) return;
      try { await widget.repository.progress(book); if(_active) setState(()=>_saveError=null); }
      catch (_) { if(_active) setState(()=>_saveError='No se guardó el avance. Revisa espacio y permisos antes de salir.'); }
    });
  }
  void _position(EpubLocation value) {
    if(!_active || _restoring || value.startCfi.isEmpty) return;
    setState(()=>_book=_book.position(cfi:value.startCfi,progress:_locationsReady && value.progress.isFinite ? value.progress.clamp(0,1) : _book.progress));
    _save();
  }
  Future<void> _font(int delta) async {
    if(!_ready || !_active) return;
    final size=(_book.fontSize+delta).clamp(12,32);
    try {
      await _controller.setFontSize(fontSize:size.toDouble());
      if(!_active)return;setState(()=>_book=_book.position(fontSize:size));_save();
    } catch (_) { if(_active)setState(()=>_error='No se pudo ajustar la letra. Vuelve a abrir el EPUB.'); }
  }
  Future<void> _leave({bool discard=false}) async {
    if(_closing)return;_closing=true;
    if(_active && !discard) {
      await _saves;
      if(!_active) { _pop();return; }
      try { await widget.repository.progress(_book); }
      catch (_) { if(mounted)setState(()=>_saveError='No se guardó el avance. Puedes reintentar o salir sin guardar.'); _closing=false;return; }
    }
    _pop();
  }
  void _pop() {
    if(!mounted)return;setState(()=>_allowPop=true);
    WidgetsBinding.instance.addPostFrameCallback((_) { if(mounted)Navigator.of(context).pop(); });
  }
  @override
  Widget build(BuildContext context) {
    final account=context.dependOnInheritedWidgetOfExactType<LocalAccountScope>()?.uid ?? 'guest';
    if(account!=widget.account) return Scaffold(appBar:AppBar(title:const Text('Lectura cerrada')),body:const Center(child:Text('La cuenta cambió. Vuelve a Mi Biblioteca.')));
    return PopScope(canPop:_allowPop,onPopInvokedWithResult:(didPop,result) {if(!didPop)unawaited(_leave());},child:Scaffold(
      backgroundColor:AppColors.backgroundOf(context),
      appBar:AppBar(backgroundColor:AppColors.deep,foregroundColor:AppColors.background,
        leading:IconButton(tooltip:'Volver a Mi Biblioteca',icon:const Icon(Icons.arrow_back),onPressed:()=>_leave()),
        title:Text(_book.title,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:16))),
      body:SafeArea(child:Column(children:[
        Padding(padding:const EdgeInsets.symmetric(horizontal:12,vertical:6),child:Row(children:[
          Expanded(child:Text(_book.author,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12))),
          Text('${(_book.progress*100).round()} %',key:const ValueKey('epub-progress')),
        ])),
        Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly,children:[
          IconButton(key:const ValueKey('epub-index'),tooltip:'Índice de capítulos',onPressed:()=>setState(()=>_showIndex=!_showIndex),icon:const Icon(Icons.list)),
          IconButton(tooltip:'Página anterior',onPressed:_ready?()=>_controller.prev():null,icon:const Icon(Icons.chevron_left)),
          IconButton(tooltip:'Reducir letra EPUB',onPressed:_ready && _book.fontSize>12?()=>_font(-2):null,icon:const Icon(Icons.text_decrease)),
          Text('${_book.fontSize}',key:const ValueKey('epub-font-size')),
          IconButton(tooltip:'Aumentar letra EPUB',onPressed:_ready && _book.fontSize<32?()=>_font(2):null,icon:const Icon(Icons.text_increase)),
          IconButton(tooltip:'Página siguiente',onPressed:_ready?()=>_controller.next():null,icon:const Icon(Icons.chevron_right)),
        ]),
        if(_saveError!=null) Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:Column(children:[Text(_saveError!,style:const TextStyle(color:Colors.red)),TextButton(onPressed:()=>_leave(discard:true),child:const Text('Salir sin guardar'))])),
        if(_error!=null) Padding(padding:const EdgeInsets.all(12),child:Text(_error!)),
        if(!_ready && _error==null) const LinearProgressIndicator(),
        if(_showIndex) SizedBox(height:150,child:ListView(children:[
          for(final chapter in _book.chapters) ListTile(dense:true,title:Text(chapter.title),onTap:_ready?() {setState(()=>_showIndex=false);_controller.display(cfi:chapter.href);}:null),
        ])),
        Expanded(child:_error!=null?const Center(child:Text('No se pudo abrir el EPUB. Regresa y reimpórtalo si es necesario.')):EpubViewer(
          key:ValueKey(_book.id),epubSource:_source,epubController:_controller,
          initialCfi:_book.cfi.isEmpty?null:widget.source.book.cfi,
          useLocalServer:false,
          displaySettings:EpubDisplaySettings(fontSize:_book.fontSize,spread:EpubSpread.none,flow:EpubFlow.paginated,
            allowScriptedContent:false,useSnapAnimationAndroid:false,
            theme:EpubTheme.custom(backgroundDecoration:const BoxDecoration(color:Color(0xFFF6EFDF)),foregroundColor:const Color(0xFF3B2A20),customCss:{'body':{'font-family':'Georgia, serif','line-height':'1.6'}})),
          onEpubLoaded:(){if(_active)setState(()=>_ready=true);},
          onLoadError:(_){if(_active)setState(()=>_error='Este EPUB no se pudo mostrar. No se ha modificado el archivo original.');},
          onInitialPositionLoading:(){_restoring=true;},
          onInitialPositionLoaded:(){_restoring=false;},
          onLocationLoaded:()async { _locationsReady=true;try{final position=await _controller.getCurrentLocation();if(_active)_position(position);}catch(_){} },
          onRelocated:_position,
        )),
      ])),
    ));
  }
}
''',
'lib/features/epub/presentation/imported_epub_section.dart':r'''import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/session/local_account_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../data/epub_file_access.dart';
import '../data/epub_repository.dart';
import '../data/epub_store.dart';
import '../models/imported_epub.dart';
import 'epub_reader_screen.dart';

class ImportedEpubSection extends StatefulWidget {
  const ImportedEpubSection({super.key,this.store,this.files=const SystemEpubFileAccess(),this.readerBuilder});
  final EpubStore? store;
  final EpubFileAccess files;
  final Widget Function(ValidatedEpub,EpubRepository,String)? readerBuilder;
  @override
  State<ImportedEpubSection> createState()=>_ImportedEpubSectionState();
}
class _ImportedEpubSectionState extends State<ImportedEpubSection> {
  late final EpubStore _store=widget.store??createEpubStore();
  EpubRepository? _repository;
  String? _account,_error;
  List<ImportedEpub> _books=[];
  bool _busy=false,_expanded=false;
  int _generation=0;
  bool _current(int g)=>mounted && g==_generation && (LocalAccountScope.read(context)??'guest')==_account;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final account=context.dependOnInheritedWidgetOfExactType<LocalAccountScope>()?.uid??'guest';
    if(account==_account)return;
    _generation++;_account=account;_books=[];_error=null;_busy=false;_expanded=false;
    _repository=EpubRepository(account:account,store:_store);unawaited(_refresh(_generation));
  }
  Future<void> _refresh(int g) async {
    try {final books=await _repository!.list();if(_current(g))setState(()=>_books=books);}
    catch(e){if(_current(g))setState(()=>_error=e is EpubFailure?e.message:'No se pudo abrir el almacenamiento EPUB.');}
  }
  Future<void> _run(Future<void> Function(int,EpubRepository) task) async {
    if(_busy)return;final g=_generation;final repository=_repository!;
    setState((){_busy=true;_error=null;});
    try{await task(g,repository);}catch(e){if(_current(g))setState(()=>_error=e is EpubFailure?e.message:'No pudimos completar la acción EPUB.');}
    finally {if(_current(g)){await _refresh(g);if(_current(g))setState(()=>_busy=false);}}
  }
  Future<void> _open(ImportedEpub book,int g,EpubRepository repository) async {
    final source=await repository.open(book);if(!_current(g))return;
    final account=_account!;
    await Navigator.of(context).push<void>(MaterialPageRoute(builder:(_)=>widget.readerBuilder?.call(source,repository,account)??EpubReaderScreen(source:source,repository:repository,account:account)));
  }
  Future<void> _import({ImportedEpub? replace}) => _run((g,repository)async {
    // Picker is invoked before the first await that could lose the user gesture.
    final source=await widget.files.pick();if(source==null || !_current(g))return;
    if(replace!=null && replace.id!=source.book.id)throw const EpubFailure('Selecciona el mismo EPUB original para recuperar esta lectura.');
    final confirm=await showDialog<bool>(context:context,builder:(dialog)=>AlertDialog(
      title:const Text('Incorporar EPUB'),scrollable:true,
      content:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(source.book.title),Text(source.book.author),const SizedBox(height:12),Text('${source.book.chapters.length} entradas en el índice · EPUB'),const SizedBox(height:12),const Text('Se guardará solo en este navegador o dispositivo para esta cuenta. No se sincroniza con otros equipos.')]),
      actions:[TextButton(onPressed:()=>Navigator.pop(dialog,false),child:const Text('Cancelar')),FilledButton(key:const ValueKey('epub-confirm-import'),onPressed:()=>Navigator.pop(dialog,true),child:const Text('Guardar y leer'))]));
    if(confirm!=true || !_current(g))return;
    final book=await repository.import(source);if(!_current(g))return;
    setState(()=>_expanded=true);await _refresh(g);if(_current(g))await _open(book,g,repository);
  });
  Future<void> _export(ImportedEpub book)=>_run((g,repository)async {
    final bytes=await repository.bytes(book);if(!_current(g))return;
    final saved=await widget.files.export(book,bytes);if(_current(g) && saved)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Copia EPUB exportada sin modificar el archivo original.')));
  });
  Future<void> _remove(ImportedEpub book)=>_run((g,repository)async {
    final confirm=await showDialog<bool>(context:context,builder:(dialog)=>AlertDialog(title:const Text('Eliminar EPUB de Mi Biblioteca'),content:Text('Se eliminarán la copia local y el avance de «${book.title}» de esta cuenta. Exporta antes si quieres conservar una copia.'),actions:[TextButton(onPressed:()=>Navigator.pop(dialog,false),child:const Text('Cancelar')),FilledButton(key:const ValueKey('epub-confirm-delete'),onPressed:()=>Navigator.pop(dialog,true),child:const Text('Eliminar'))]));
    if(confirm==true && _current(g))await repository.remove(book);
  });
  @override
  Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Wrap(spacing:8,runSpacing:4,children:[
      OutlinedButton.icon(key:const ValueKey('epub-import'),onPressed:_busy?null:()=>_import(),icon:const Icon(Icons.file_open_outlined),label:const Text('Importar libro EPUB')),
      TextButton(key:const ValueKey('epub-imported-toggle'),onPressed:()=>setState(()=>_expanded=!_expanded),child:Text('Mis libros importados (${_books.length})')),
    ]),
    if(_busy)const LinearProgressIndicator(),
    if(_error!=null)Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Text(_error!,key:const ValueKey('epub-error'),style:const TextStyle(color:Colors.red))),
    if(_expanded)...[
      const Padding(padding:EdgeInsets.symmetric(vertical:8),child:Text('EPUB guardados solo en este navegador/dispositivo. No se sincronizan. Las cuentas mantienen colecciones locales separadas.',style:TextStyle(fontSize:12))),
      if(_books.isEmpty)const Text('Aún no has importado un EPUB.'),
      for(final book in _books)Card(key:ValueKey('imported-epub-${book.id}'),color:AppColors.surfaceOf(context),child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(width:52,height:76,decoration:BoxDecoration(color:AppColors.deep,borderRadius:BorderRadius.circular(5)),alignment:Alignment.center,child:const Icon(Icons.menu_book,color:AppColors.gold)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(book.title,style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:4),Text(book.author),const SizedBox(height:4),Text('EPUB · ${book.status} · ${(book.progress*100).round()} %',style:const TextStyle(fontSize:12))]))]),
        const SizedBox(height:8),
        if(!book.fileAvailable)const Text('El archivo local no está disponible. Reimporta el EPUB original para recuperar esta lectura.'),
        Wrap(spacing:8,runSpacing:4,children:[
          FilledButton(key:ValueKey('epub-read-${book.id}'),onPressed:_busy?null:book.fileAvailable?()=>_run((g,r)=>_open(book,g,r)):()=>_import(replace:book),child:Text(!book.fileAvailable?'Reimportar EPUB':book.cfi.isEmpty?'Leer EPUB':'Continuar leyendo')),
          TextButton(key:ValueKey('epub-export-${book.id}'),onPressed:_busy || !book.fileAvailable?null:()=>_export(book),child:const Text('Exportar copia EPUB')),
          TextButton(key:ValueKey('epub-delete-${book.id}'),onPressed:_busy?null:()=>_remove(book),child:const Text('Eliminar de mi Biblioteca')),
        ]),
      ]))),
    ],
  ]);
}
'''
}
for name,text in files.items():
 p=Path(name);p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text,encoding='utf-8')
p=Path('lib/features/library/presentation/screens/library_screen.dart');s=p.read_text(encoding='utf-8');s=s.replace("import 'dart:async';","import 'dart:async';\nimport '../../../epub/presentation/imported_epub_section.dart';")
s=s.replace('            _buildHeader(),\n            const SizedBox(height: 12),','            _buildHeader(),\n            const SizedBox(height: 8),\n            const ImportedEpubSection(),\n            const SizedBox(height: 12),',1);p.write_text(s,encoding='utf-8')
