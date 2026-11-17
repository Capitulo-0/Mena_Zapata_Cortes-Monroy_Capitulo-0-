from pathlib import Path
p=Path('tool/prepare_collection.py'); s=p.read_text(encoding='utf-8'); pos=s.index('def inspect(titles):'); s=s[:pos]+'''def extract(parsed, mode='scan'):
 parser=LiteraryText()
 html=parsed['text']['*']
 if mode=='page': html=html.replace('mw-content-ltr mw-parser-output','mw-content-ltr mw-parser-output prp-pages-output',1)
 parser.feed(html)
 return parser, re.sub(r'^(?:i: i\\n\\n)+','',parser.text())

'''+s[pos:]
s=s.replace("parser=LiteraryText(); parser.feed(p['text']['*']); text=parser.text()", "parser,text=extract(p,section.get('extraction','scan'))") if False else s
s=s.replace("   parser=LiteraryText(); parser.feed(p['text']['*']); text=parser.text()", "   parser,text=extract(p,section.get('extraction','scan'))")
s=s.replace("assert parser.pages and len(text)>500, 'No scan-backed literary body'", "assert (parser.pages or section.get('extraction')=='page') and len(text)>500, 'No literary body'")
s=s.replace("section=section['label'],page=section['page']", "extraction=section.get('extraction','scan'),section=section['label'],page=section['page']")
s=s.replace("section['permanent_url']", "section['permanent_url']")
p.write_text(s,encoding='utf-8')
p=Path('tool/verify_collection.py');s=p.read_text(encoding='utf-8').replace('CACHE,key,LiteraryText','CACHE,key,LiteraryText,extract');s=s.replace("parser=LiteraryText(); parser.feed(p['text']['*']); assert parser.text()==part", "parser,extracted=extract(p,s.get('extraction','scan')); assert extracted==part")
p.write_text(s,encoding='utf-8')
