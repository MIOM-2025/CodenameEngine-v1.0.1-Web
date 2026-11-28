#!/usr/bin/env python3
"""Trim the preload flag in the manifest lime inlines into the web build.

manifest/default.json is written but never read; the browser parses the copy
embedded in CodenameEngine.js. Preloading all 963 entries means downloading and
decoding ~183 MB before the title screen, which costs gigabytes of memory, so
large entries are flipped to lazy loading. Small ones stay preloaded, because
the engine expects fonts, UI pieces and its own sound effects to be present the
moment a library is loaded.
"""
import sys

from fix_web_manifest import Reader

PREFIX = '{\\"name\\":null,\\"assets\\":\\"'
SIZE_LIMIT = 200000


def read_int(s, i):
    j = i + 1
    if s[j] == '-':
        j += 1
    k = j
    while k < len(s) and s[k].isdigit():
        k += 1
    return int(s[j:k]), k


def trim(serialized, limit=SIZE_LIMIT):
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
        size = 0
        preload_pos = -1
        while j < len(s) and s[j] != 'g':
            key, vstart = r.key_at(j)
            vend = r.parse(vstart)
            if key == 'size' and s[vstart] == 'i':
                size, _ = read_int(s, vstart)
            elif key == 'preload':
                preload_pos = vstart
            j = vend
        if preload_pos >= 0:
            seen += 1
            if s[preload_pos] == 't' and size > limit:
                edits.append(preload_pos)
                changed += 1
        i = j + 1
    chars = list(s)
    for p in edits:
        chars[p] = 'f'
    return ''.join(chars), seen, changed


def patch_js(path, limit=SIZE_LIMIT, verbose=True):
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
            fixed, seen, changed = trim(body, limit)
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
        print('%s: %d manifests, %d flags, %d lazy (>%d bytes)'
              % (path, count, seen_total, changed_total, limit))
    return seen_total, changed_total


if __name__ == '__main__':
    for p in sys.argv[1:]:
        patch_js(p)

