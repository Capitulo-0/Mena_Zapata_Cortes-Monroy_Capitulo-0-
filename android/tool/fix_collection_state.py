from pathlib import Path
p=Path('lib/features/gutendex/presentation/screens/free_library_screen.dart');s=p.read_text(encoding='utf-8').replace("  String _query = '';", "  final _searchController = TextEditingController();\n  @override\n  void dispose() {\n    _searchController.dispose();\n    super.dispose();\n  }\n  String _query = '';")
s=s.replace("key: const ValueKey('free-library-search'),", "key: const ValueKey('free-library-search'),\n          controller: _searchController,")
p.write_text(s,encoding='utf-8')
p=Path('test/gutendex/free_collection_test.dart');s=p.read_text(encoding='utf-8').replace('await File(key).readAsBytes()', 'File(key).readAsBytesSync()');s=s.replace('await tester.ensureVisible(search);',"await tester.scrollUntilVisible(search, -200, scrollable: find.byType(Scrollable).first);");s=s.replace("tester.widget<TextField>(search).controller?.text ?? work.title", "tester.widget<TextField>(search).controller!.text")
s=s.replace("        expect(\n          tester.widget<TextField>(search).controller!.text,", "        await tester.scrollUntilVisible(search, -200, scrollable: find.byType(Scrollable).first);\n        expect(\n          tester.widget<TextField>(search).controller!.text,")
p.write_text(s,encoding='utf-8')
