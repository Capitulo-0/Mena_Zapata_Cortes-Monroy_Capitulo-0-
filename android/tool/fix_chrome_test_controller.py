from pathlib import Path
p=Path('tool/epub_chrome.mjs');s=p.read_text(encoding='utf-8').replace("const h=this.pending.get(m.id);this.pending.delete(m.id);if(m.error)","const h=this.pending.get(m.id);this.pending.delete(m.id);if(!h)return;if(m.error)")
old="(()=>{function visit(n){if(n.nodeType===1){if(n.tagName==='FLT-SEMANTICS-PLACEHOLDER')n.click();if(n.shadowRoot)visit(n.shadowRoot)}for(const child of n.childNodes??[])visit(child)}visit(document)})()"
new="(()=>{function find(n){if(n.nodeType===1){if(n.tagName==='FLT-SEMANTICS-PLACEHOLDER')return n;if(n.shadowRoot){const v=find(n.shadowRoot);if(v)return v}}for(const child of Array.from(n.childNodes??[])){const v=find(child);if(v)return v}return null}const p=find(document);if(p)p.click()})()"
assert old in s;s=s.replace(old,new);p.write_text(s,encoding='utf-8')
p=Path('tool/epub_chrome_e2e.mjs');s=p.read_text(encoding='utf-8');s=s.replace("try{\n await c.send('Page.reload'", "try{\n if(!(await c.eval('location.href')).startsWith('http://127.0.0.1:8766'))await c.navigate('http://127.0.0.1:8766');\n await c.send('Page.reload'");p.write_text(s,encoding='utf-8')
