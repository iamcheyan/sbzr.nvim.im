#!/usr/bin/env python3
import os
import sys
from pathlib import Path


def escape_vim_regex_very_magic(text: str) -> str:
    # Escape characters that are special in Vim's very-magic regex.
    specials = r"\/.^$~[]*+?{}()|"
    out = []
    for ch in text:
        if ch in specials:
            out.append("\\" + ch)
        else:
            out.append(ch)
    return "".join(out)


def escape_vim_double_quoted(text: str) -> str:
    return text.replace("\\", "\\\\").replace('"', '\\"')


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: search_dict.py <pattern>")
        return 1

    pattern = sys.argv[1]
    if "\n" in pattern or "\r" in pattern:
        print("Error: pattern must be a single line")
        return 1

    repo_root = Path(__file__).resolve().parents[1]
    dict_path = repo_root / "dict" / "sbzr.yaml"

    escaped = escape_vim_regex_very_magic(pattern)
    # Exact token match: line start or space before, and space/colon/end after.
    vim_pattern = rf"\v(^| ){escaped}($| |:)"
    vim_pattern = escape_vim_double_quoted(vim_pattern)

    feedkeys_cmd = f'call feedkeys("/{vim_pattern}")'

    os.execvp(
        "nvim",
        [
            "nvim",
            str(dict_path),
            "-c",
            "set hlsearch",
            "-c",
            "set incsearch",
            "-c",
            feedkeys_cmd,
        ],
    )


if __name__ == "__main__":
    raise SystemExit(main())
