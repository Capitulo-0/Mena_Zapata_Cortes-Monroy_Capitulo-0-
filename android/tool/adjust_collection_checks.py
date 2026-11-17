from pathlib import Path
p=Path('test/home_gutendex_navigation_test.dart'); s=p.read_text(encoding='utf-8').replace('await tester.ensureVisible(online);',"await tester.scrollUntilVisible(online, 300, scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first);") ;p.write_text(s,encoding='utf-8')
p=Path('test/gutendex/free_library_test.dart');s=p.read_text(encoding='utf-8').replace("      await tester.tap(find.text('Consultar catálogo en línea'));","      await tester.scrollUntilVisible(find.text('Consultar catálogo en línea'), 300, scrollable: find.byType(Scrollable).first);\n      await tester.tap(find.text('Consultar catálogo en línea'));")
s=s.replace("      expect(find.text('Lectura disponible'), findsNWidgets(2));","      await tester.scrollUntilVisible(find.byKey(const ValueKey('free-library-search')), -300, scrollable: find.byType(Scrollable).first);\n      expect(find.text('${freeWorks.length} obras · ${freeWorks.length} con lectura disponible'), findsOneWidget);")
s=s.replace('        await tester.tap(card);',"        await tester.scrollUntilVisible(card, 200, scrollable: find.byType(Scrollable).first);\n        await tester.tap(card);")
p.write_text(s,encoding='utf-8')
import json
p=Path('tool/free_work_exports.json'); specs=json.loads(p.read_text(encoding='utf-8')); specs=[{**specs[1], 'key':'scan:rimas1885:141-218', 'last':218}]; p.write_text(json.dumps(specs,ensure_ascii=False,indent=2),encoding='utf-8')
