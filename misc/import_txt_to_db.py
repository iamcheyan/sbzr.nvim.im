#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从当前 Rime 词库格式导入到 SQLite 数据库。

支持的词库格式:
  词\t编码\t权重

会自动忽略 YAML 头部、注释、空行和非词条行。
"""

import os
import sqlite3
import sys
from collections import defaultdict


def parse_rime_dict(dict_file):
    entries = defaultdict(dict)

    with open(dict_file, "r", encoding="utf-8") as f:
        for raw_line in f:
            line = raw_line.rstrip("\n")
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            if stripped in ("---", "..."):
                continue
            if "\t" not in line:
                continue

            parts = [part.strip() for part in line.split("\t")]
            if len(parts) < 2:
                continue

            word = parts[0]
            key = parts[1]
            if not word or not key or not key.isalpha() or not key.islower():
                continue

            try:
                weight = int(parts[2]) if len(parts) >= 3 and parts[2] else 0
            except ValueError:
                weight = 0

            existing = entries[key].get(word)
            if existing is None or weight > existing:
                entries[key][word] = weight

    return entries


def init_database(db_file):
    conn = sqlite3.connect(db_file)
    cursor = conn.cursor()
    cursor.execute(
        """
        CREATE TABLE IF NOT EXISTS words (
            key TEXT NOT NULL,
            word TEXT NOT NULL,
            frequency INTEGER DEFAULT 0,
            PRIMARY KEY (key, word)
        )
        """
    )
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_key ON words(key)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_word ON words(word)")
    conn.commit()
    conn.close()


def import_rime_dict_to_db(dict_file, db_file):
    if not os.path.exists(dict_file):
        print(f"错误: 词库文件不存在: {dict_file}")
        return False

    entries = parse_rime_dict(dict_file)
    if not entries:
        print(f"错误: 未从词库中解析出有效条目: {dict_file}")
        return False

    init_database(db_file)

    conn = sqlite3.connect(db_file)
    cursor = conn.cursor()
    cursor.execute("DELETE FROM words")

    batch = []
    total = 0
    for key in sorted(entries.keys()):
        words = sorted(entries[key].items(), key=lambda item: (-item[1], item[0]))
        for word, weight in words:
            batch.append((key, word, weight))
            total += 1

    cursor.executemany(
        "INSERT OR REPLACE INTO words(key, word, frequency) VALUES (?, ?, ?)", batch
    )
    conn.commit()
    conn.close()

    print(f"导入成功: {dict_file}")
    print(f"统计: {len(entries)} 个编码, {total} 条记录")
    return True


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    dict_file = sys.argv[1]
    if len(sys.argv) >= 3:
        db_file = sys.argv[2]
    elif dict_file.endswith(".yaml"):
        db_file = dict_file[:-5] + ".db"
    else:
        db_file = dict_file + ".db"

    sys.exit(0 if import_rime_dict_to_db(dict_file, db_file) else 1)


if __name__ == "__main__":
    main()
