#!/usr/bin/env python3
"""Clear the per-entry preload flag in a lime manifest for web builds.

lime bakes preload=<bool> into every entry of manifest/default.json. On the web
target that means the browser downloads and decodes the whole library (963
entries / 183 MB) before the title screen. Neither library@preload nor
assets@preload in project.xml reaches that flag, so it is cleared here, after
the build, before the folder is published.
"""
import json
import sys


class Reader:
    def __init__(self, s):
        self.s = s
        self.cache = []

    def parse(self, i):
        s = self.s
        c = s[i]
        if c == 'n' or c in 'tf':
            return i + 1
        if c == 'i':
            j = i + 1
            if s[j] == '-':
                j += 1
            while j < len(s) and s[j].isdigit():
                j += 1
            return j
        if c == 'd':
            j = i + 1
            while j < len(s) and s[j] != 'n':
                j += 1
            return j
        if c in 'yY':
            k = s.index(':', i)
            end = k + 1 + int(s[i + 1:k])
            self.cache.append(s[k + 1:end])
            return end
        if c == 'z':
            self.cache.append('')
            return i + 1
        if c in 'Rr':
            j = i + 1
            while j < len(s) and s[j].isdigit():
                j += 1
            return j
        if c == 'a':
            j = i + 1
            while s[j] != 'h':
                j = self.parse(j)
            return j + 1
        if c == 'o':
            j = i + 1
            while s[j] != 'g':
                j = self.parse(j)
                j = self.parse(j)
            return j + 1
        if c in 'bA':
            k = s.index(':', i)
            return k + 1 + int(s[i + 1:k])
        raise ValueError('unexpected tag %r at %d' % (c, i))

    def key_at(self, i):
        s = self.s
        c = s[i]
        if c in 'yY':
            k = s.index(':', i)
            end = k + 1 + int(s[i + 1:k])
            key = s[k + 1:end]
            self.cache.append(key)
            return key, end
        if c == 'z':
            self.cache.append('')
            return '', i + 1
        if c in 'Rr':
            j = i + 1
            while s[j].isdigit():
                j += 1
            idx = int(s[i + 1:j])
            return (self.cache[idx] if idx < len(self.cache) else ''), j
        raise ValueError('unexpected key tag %r at %d' % (c, i))


def clear_preload(serialized):
    r = Reader(serialized)
    s = serialized
    if s[0] != 'a':
        raise ValueError('manifest root is not an array')
    edits = []
    seen = 0
    i = 1
    while s[i] != 'h':
        if s[i] != 'o':
            i = r.parse(i)
            continue
        j = i + 1
        while s[j] != 'g':
            key, vstart = r.key_at(j)
            vend = r.parse(vstart)
            if key == 'preload':
                seen += 1
                if s[vstart] == 't':
                    edits.append(vstart)
            j = vend
        i = j + 1
    chars = list(s)
    for p in edits:
        chars[p] = 'f'
    return ''.join(chars), seen, len(edits)


def main(path):
    doc = json.loads(open(path, encoding='utf-8').read())
    cleared, seen, changed = clear_preload(doc['assets'])
    doc['assets'] = cleared
    with open(path, 'w', encoding='utf-8') as fh:
        json.dump(doc, fh, separators=(',', ':'), ensure_ascii=False)
    print('%s: %d preload flags, %d switched to false' % (path, seen, changed))


if __name__ == '__main__':
    for p in sys.argv[1:]:
        main(p)
