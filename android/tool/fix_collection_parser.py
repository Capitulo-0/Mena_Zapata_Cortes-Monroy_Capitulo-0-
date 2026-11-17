from pathlib import Path
p=Path('tool/prepare_collection.py'); s=p.read_text(encoding='utf-8'); s=s.replace('from prepare_free_works import LiteraryText','from prepare_free_works import LiteraryText as BaseLiteraryText\n\nclass LiteraryText(BaseLiteraryText):\n def handle_starttag(self,tag,attrs):\n  super().handle_starttag(tag,attrs)\n  a=dict(attrs)\n  if tag=="img" and self.stack and self.stack[-1][1] and not self.stack[-1][2]:\n   alt=a.get("alt","")\n   if len(alt)==1 and alt.isalpha(): self.parts.append(alt)\n def text(self):\n  return re.sub(r"\\u00ac\\s*\\n\\s*", "", super().text())')
s=s.replace("'pages':parser.pages", "'pages':parser.pages")
p.write_text(s,encoding='utf-8')
