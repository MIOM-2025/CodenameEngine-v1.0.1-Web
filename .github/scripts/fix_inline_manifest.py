#!/usr/bin/env python3
"""Clear the per-entry preload flag in the manifest lime inlines into the web
build.

manifest/default.json is generated but never read; the browser parses the
serialized copy embedded in CodenameEngine.js. Leaving preload=true there means
the whole library (963 entries / 183 MB of audio and images) is downloaded and
decoded before the title screen, which is where the multi-gigabyte memory use
comes from.
"""
import sys

from fix_web_manifest import clear_preload

PREFIX = '{\\"name\\":null,\\"assets\\":\\"'


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
        cursor_after = end
        if body and body[0] == 'a' and body[-1] == 'h':
            fixed, seen, changed = clear_preload(body)
            seen_total += seen
            changed_total += changed
            count += 1
            out.append(src[cursor:start])
            out.append(fixed)
            cursor = cursor_after
        else:
            out.append(src[cursor:cursor_after])
            cursor = cursor_after

    out.append(src[cursor:])
    result = ''.join(out)
    if result != src:
        open(path, 'w', encoding='utf-8').write(result)
    if verbose:
        print('%s: %d inline manifests, %d preload flags, %d switched to false'
              % (path, count, seen_total, changed_total))
    return seen_total, changed_total


if __name__ == '__main__':
    for p in sys.argv[1:]:
        patch_js(p)

