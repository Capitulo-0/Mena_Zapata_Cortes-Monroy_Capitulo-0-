from pathlib import Path
old=Path('test_web/epub_persistence_test.dart');new=Path('test/epub/epub_web_persistence_test.dart');root=Path.cwd().resolve();assert old.resolve().is_relative_to(root) and new.resolve().is_relative_to(root)
s=old.read_text(encoding='utf-8');s="import 'package:flutter/foundation.dart';\n"+s;s=s.replace("import '../test/fixtures/epub/fixture_bytes.dart';", "import '../fixtures/epub/fixture_bytes.dart';");assert s.endswith('  });\n}\n');s=s[:-len('  });\n}\n')]+ '  }, skip: !kIsWeb);\n}\n';old.rename(new);new.write_text(s,encoding='utf-8')
