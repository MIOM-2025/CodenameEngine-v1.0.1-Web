#!/usr/bin/env python3
"""Add the on-screen pad and a cache-busting stamp to the built index.html."""
import os
import re

PAD = '.github/scripts/touch-controls.html'
TARGET = os.environ.get('CNE_INDEX', 'export/release/html5/bin/index.html')
NEWLINE = chr(10)

pad = open(PAD, encoding='utf-8').read()
html = open(TARGET, encoding='utf-8').read()

if 'cne-pad' in html:
    start = html.index('<div id="cne-pad">')
    end = html.index('</script>', start) + len('</script>')
    html = html[:start] + pad + html[end:]
elif '</body>' in html:
    html = html.replace('</body>', pad + NEWLINE + '</body>', 1)
else:
    html = html + NEWLINE + pad

rev = os.environ.get('GITHUB_SHA', '')[:7]
if rev:
    html = re.sub(r'(src="[^"]*\.js)(\?[^"]*)?(")',
                  lambda m: m.group(1) + '?v=' + rev + m.group(3), html)

open(TARGET, 'w', encoding='utf-8').write(html)
print('index.html patched, rev=%s, pad=%s' % (rev, 'cne-pad' in html))
