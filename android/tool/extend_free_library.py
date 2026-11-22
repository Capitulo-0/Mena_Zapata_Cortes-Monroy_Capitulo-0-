from pathlib import Path
p=Path('lib/features/gutendex/models/free_work.dart'); s=p.read_text(encoding='utf-8'); s="part 'prepared_free_works.dart';\n\n"+s
s=s.replace('    this.assetPath,','    this.assetPath,\n    this.genre,\n    this.isComplete = false,')
s=s.replace('  final String? assetPath;\n  bool get available => assetPath != null;','  final String? assetPath;\n  final String? genre;\n  final bool isComplete;\n  bool get available => isComplete && assetPath != null;')
s=s.replace("    assetPath: 'assets/free_works/lazarillo_1921.txt',","    assetPath: 'assets/free_works/lazarillo_1921.txt',\n    isComplete: true,")
s=s.replace("    assetPath: 'assets/free_works/vida_sueno.txt',","    assetPath: 'assets/free_works/vida_sueno.txt',\n    isComplete: true,")
s=s.replace('\n];','\n  ...preparedFreeWorks,\n];'); p.write_text(s,encoding='utf-8')
Path('lib/features/gutendex/models/prepared_free_works.dart').write_text("part of 'free_work.dart';\n\nconst preparedFreeWorks = <FreeWork>[];\n",encoding='utf-8')
p=Path('lib/features/gutendex/data/asset_reader_source.dart'); s=p.read_text(encoding='utf-8').replace('    if (path == null ||','    if (!work.available ||\n        path == null ||'); p.write_text(s,encoding='utf-8')
p=Path('lib/features/gutendex/presentation/screens/free_library_screen.dart'); s=p.read_text(encoding='utf-8'); s=s.replace('class FreeLibraryScreen extends StatelessWidget {','class FreeLibraryScreen extends StatefulWidget {')
start=s.index('  @override\n  Widget build(BuildContext context) => Scaffold(')
s=s[:start]+'''  @override
  State<FreeLibraryScreen> createState() => _FreeLibraryScreenState();
}

class _FreeLibraryScreenState extends State<FreeLibraryScreen> {
  String _query = '';
  String? _genre;
  String _searchKey(String value) {
    var result = value.toLowerCase().trim();
    const accents = 'áéíóúüñ';
    const plain = 'aeiouun';
    for (var i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], plain[i]);
    }
    return result;
  }
  List<FreeWork> get _filtered => widget.works.where((work) =>
    (_genre == null || work.genre == _genre) &&
    _searchKey('${work.title} ${work.author}').contains(_searchKey(_query))).toList();
  @override
  Widget build(BuildContext context) => Scaffold('''+s[start+len('  @override\n  Widget build(BuildContext context) => Scaffold('):]
s=s.replace('        for (final work in [\n          ...works.where((w) => w.available),\n          ...works.where((w) => !w.available),\n        ])', '''        TextField(
          key: const ValueKey('free-library-search'),
          decoration: const InputDecoration(
            labelText: 'Buscar por título o autor',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        if (widget.works.any((w) => w.genre != null)) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const ValueKey('free-library-genre'),
            isExpanded: true,
            initialValue: _genre ?? '',
            decoration: const InputDecoration(labelText: 'Género'),
            items: [
              const DropdownMenuItem(value: '', child: Text('Todos los géneros')),
              for (final genre in (widget.works.map((w) => w.genre).whereType<String>().toSet().toList()..sort()))
                DropdownMenuItem(value: genre, child: Text(genre)),
            ],
            onChanged: (value) => setState(() => _genre = value == '' ? null : value),
          ),
        ],
        const SizedBox(height: 12),
        Text('${_filtered.length} obras · ${widget.works.where((w) => w.available).length} con lectura disponible'),
        if (_filtered.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('No hay obras que coincidan.')),
        const SizedBox(height: 12),
        for (final work in _filtered)''')
s=s.replace('FreeWorkDetailScreen(work: work, source: source)','FreeWorkDetailScreen(work: work, source: widget.source)').replace('MaterialPageRoute(builder: onlineBuilder)','MaterialPageRoute(builder: widget.onlineBuilder)')
p.write_text(s,encoding='utf-8')
