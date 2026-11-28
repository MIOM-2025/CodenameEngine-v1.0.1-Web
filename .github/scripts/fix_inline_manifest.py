#!/usr/bin/env python3
"""Make audio lazy in the manifest lime inlines into the web build.

manifest/default.json is written but never read; the browser parses the copy
embedded in CodenameEngine.js. Preloading every entry means downloading and
decoding ~183 MB before the title screen, and the ogg tracks alone expand to
about a gigabyte of PCM.

Every entry is flipped, so loading the library costs almost nothing. The engine
then preloads the folders it actually needs, which is the only way to keep the
page inside a phone's memory: lime resolves images synchronously, so whatever a
state asks for has to be loaded before that state runs.
"""
import sys

from fix_web_manifest import Reader

PREFIX = '{\\"name\\":null,\\"assets\\":\\"'
LAZY_TYPES = ('MUSIC', 'SOUND')


def read_int(s, i):
    j = i + 1
    if s[j] == '-':
        j += 1
    k = j
    while k < len(s) and s[k].isdigit():
        k += 1
    return int(s[j:k]), k



# Folders whose contents stay on the server until something asks for them. They
# hold the bulk of the bytes: character and stage art, and the song tracks.
DEFERRED_PREFIXES = (
    'assets/images/characters/',
    'assets/images/stages/',
    'assets/images/game/',
    'assets/images/editors/',
    'assets/images/dialogue/',
    'assets/songs/',
    'assets/music/',
    'assets/videos/',
)


def should_defer(asset_id, asset_type):
    if not asset_id:
        return asset_type in ('MUSIC', 'SOUND')
    return asset_id.startswith(DEFERRED_PREFIXES)


def trim(serialized):
    r = Reader(serialized)
    s = serialized
    if not s or s[0] != 'a':
        raise ValueError('manifest root is not an array')
    edits = []
    seen = 0
    changed = 0
    i = 1
    while i < len(s) and s[i] != 'h':
        if s[i] != 'o':
            i = r.parse(i)
            continue
        j = i + 1
        etype = ''
        eid = ''
        preload_pos = -1
        while j < len(s) and s[j] != 'g':
            key, vstart = r.key_at(j)
            vend = r.parse(vstart)
            value = s[vstart:vend]
            if value.startswith('y'):
                k = s.index(':', vstart)
                literal = s[k + 1:vend]
            elif value.startswith('R'):
                idx = int(value[1:])
                literal = r.cache[idx] if idx < len(r.cache) else ''
            else:
                literal = ''
            if key == 'type':
                etype = literal
            elif key == 'id':
                eid = literal
            elif key == 'preload':
                preload_pos = vstart
            j = vend
        if preload_pos >= 0:
            seen += 1
            if s[preload_pos] == 't' and should_defer(eid, etype):
                edits.append(preload_pos)
                changed += 1
        i = j + 1
    chars = list(s)
    for p in edits:
        chars[p] = 'f'
    return ''.join(chars), seen, changed


def patch_js(path, verbose=True):
    src = open(path, encoding='utf-8').read()
    out = []
    cursor = 0
    seen_total = 0
    changed_total = 0
    count = 0

    while True:
        i = src.find(PREFIX, cursor)
        if i < 0:
            break
        start = i + len(PREFIX)
        end = src.find('\\"', start)
        if end < 0:
            break
        body = src[start:end]
        out.append(src[cursor:start])
        if body and body[0] == 'a' and body[-1] == 'h':
            fixed, seen, changed = trim(body)
            seen_total += seen
            changed_total += changed
            count += 1
            out.append(fixed)
        else:
            out.append(body)
        cursor = end

    out.append(src[cursor:])
    result = ''.join(out)
    if result != src:
        open(path, 'w', encoding='utf-8').write(result)
    if verbose:
        print('%s: %d manifests, %d flags, %d audio entries lazy'
              % (path, count, seen_total, changed_total))
    return seen_total, changed_total


if __name__ == '__main__':
    for p in sys.argv[1:]:
        patch_js(p)

