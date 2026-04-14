#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从数据库导出为当前 Rime 词库行格式，供插件编辑缓冲区使用。

输出格式:
  词\t编码\t权重
"""

import os
import sqlite3
import sys


def export_db_for_edit(db_file):
    if not os.path.exists(db_file):
        print(f"错误: 数据库文件不存在: {db_file}", file=sys.stderr)
        return None

    conn = sqlite3.connect(db_file)
    cursor = conn.cursor()
    cursor.execute("SELECT key, word, frequency FROM words ORDER BY key, frequency DESC, word")
    rows = cursor.fetchall()
    conn.close()

    return [f"{word}\t{key}\t{0 if frequency is None else frequency}" for key, word, frequency in rows]


def main():
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        sys.exit(1)

    db_file = sys.argv[1]
    lines = export_db_for_edit(db_file)
    if lines is None:
        sys.exit(1)

    for line in lines:
        print(line)

    sys.exit(0)


if __name__ == "__main__":
    main()
