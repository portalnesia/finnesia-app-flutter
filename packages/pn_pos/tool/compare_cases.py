#!/usr/bin/env python3
"""Differential byte comparison: Dart port vs the TypeScript source.

Not a test — a one-off verification harness, run by hand when the port is re-checked
against `finnesia-monorepo`:

    cd packages/pn_pos && dart run tool/escpos_format_cases.dart > /tmp/dart.json
    cd finnesia-monorepo/apps/web && bun run src/lib/__probe-escpos-diff.ts > /tmp/ts.json
    python packages/pn_pos/tool/compare_cases.py /tmp/dart.json /tmp/ts.json

Exits 0 only when every case is present on both sides and byte-identical.
"""
import json
import sys


def main() -> int:
    dart = json.load(open(sys.argv[1], encoding="utf-8"))
    ts = json.load(open(sys.argv[2], encoding="utf-8"))

    only_dart = sorted(set(dart) - set(ts))
    only_ts = sorted(set(ts) - set(dart))
    if only_dart:
        print(f"CASES MISSING FROM TYPESCRIPT ({len(only_dart)}): {only_dart}")
    if only_ts:
        print(f"CASES MISSING FROM DART ({len(only_ts)}): {only_ts}")

    shared = sorted(set(dart) & set(ts))
    mismatches = []
    for name in shared:
        if dart[name] != ts[name]:
            mismatches.append(name)

    print(f"compared {len(shared)} cases")
    for name in mismatches:
        d, t = dart[name], ts[name]
        first = next((i for i, (a, b) in enumerate(zip(d, t)) if a != b), min(len(d), len(t)))
        print(f"\nMISMATCH {name}")
        print(f"  dart {len(d)} bytes, ts {len(t)} bytes, first difference at {first}")
        print(f"  dart: {d[max(0, first - 8):first + 24]}")
        print(f"  ts  : {t[max(0, first - 8):first + 24]}")

    if mismatches or only_dart or only_ts:
        print(f"\nFAILED: {len(mismatches)} mismatched, "
              f"{len(only_dart) + len(only_ts)} case-name differences")
        return 1

    print("OK — every case byte-identical")
    return 0


if __name__ == "__main__":
    sys.exit(main())
