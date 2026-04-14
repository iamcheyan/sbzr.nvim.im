#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从 SQLite 数据库导出为当前 Rime 词库格式。
"""

import os
import sqlite3
import sys
from collections import defaultdict


def build_header(dict_name):
    name = dict_name
    if name.endswith(".dict"):
        name = name[:-5]
    return [
        "# Rime dictionary",
        "# encoding: utf-8",
        "---",
        f"name: {name}",
        'version: "0.1"',
        "sort: by_weight",
        "use_preset_vocabulary: false",
        "columns:",
        "  - text",
        "  - code",
        "  - weight",
        "...",
        "",
    ]


def export_db_to_txt(db_file, txt_file):
    if not os.path.exists(db_file):
        print(f"错误: 数据库文件不存在: {db_file}")
        return False

    conn = sqlite3.connect(db_file)
    cursor = conn.cursor()
    cursor.execute("SELECT key, word, frequency FROM words ORDER BY key, frequency DESC, word")
    rows = cursor.fetchall()
    conn.close()

    key_words_map = defaultdict(list)
    for key, word, frequency in rows:
        key_words_map[key].append((word, 0 if frequency is None else frequency))

    dict_name = os.path.basename(txt_file)
    if dict_name.endswith(".yaml"):
        dict_name = dict_name[:-5]

    output = build_header(dict_name)
    for key in sorted(key_words_map.keys()):
        for word, frequency in key_words_map[key]:
            output.append(f"{word}\t{key}\t{frequency}")

    with open(txt_file, "w", encoding="utf-8") as f:
        f.write("\n".join(output) + "\n")

    print(f"导出成功: {txt_file}")
    print(f"统计: {len(key_words_map)} 个编码, {len(rows)} 条记录")
    return True


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    db_file = sys.argv[1]
    if len(sys.argv) >= 3:
        txt_file = sys.argv[2]
    elif db_file.endswith(".db"):
        txt_file = db_file[:-3] + ".yaml"
    else:
        txt_file = db_file + ".yaml"

    sys.exit(0 if export_db_to_txt(db_file, txt_file) else 1)


if __name__ == "__main__":
    main()
