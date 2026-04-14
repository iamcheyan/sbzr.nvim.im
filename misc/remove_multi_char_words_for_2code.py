#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path


def is_single_char(word: str) -> bool:
    return len(word) == 1


def process_line(line: str) -> tuple[str, list[str]]:
    line = line.rstrip("\n")
    if not line:
        return line, []

    parts = line.split(" ")
    code = parts[0]
    base_code = code.rstrip("'")
    if len(base_code) != 2 or code != base_code + ("'" if code.endswith("'") else ""):
        return line, []

    kept = [code]
    removed: list[str] = []
    for item in parts[1:]:
        if not item:
            continue
        if ":" not in item:
            kept.append(item)
            continue
        word, freq = item.split(":", 1)
        if is_single_char(word):
            kept.append(item)
        else:
            removed.append(word)

    return " ".join(kept), removed


def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    dict_path = repo_root / "dict" / "sbzr.yaml"

    removed_total = 0
    removed_samples: dict[str, list[str]] = {}

    new_lines: list[str] = []
    with dict_path.open("r", encoding="utf-8") as f:
        for line in f:
            new_line, removed = process_line(line)
            new_lines.append(new_line + "\n")
            if removed:
                removed_total += len(removed)
                # Keep a small sample per code for reporting.
                code = new_line.split(" ", 1)[0]
                bucket = removed_samples.setdefault(code, [])
                for w in removed:
                    if len(bucket) >= 10:
                        break
                    if w not in bucket:
                        bucket.append(w)

    dict_path.write_text("".join(new_lines), encoding="utf-8")

    print(f"Removed {removed_total} multi-char words under 2-letter codes.")
    for code in sorted(removed_samples.keys()):
        sample = " ".join(removed_samples[code])
        print(f"{code}: {sample}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
