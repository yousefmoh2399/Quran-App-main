import sqlite3
import json
import glob
import os
import sys

def main():
    db_path = 'assets/db/app_data.db'
    if not os.path.exists(db_path):
        print(f"Error: {db_path} not found")
        sys.exit(1)

    con = sqlite3.connect(db_path)
    cur = con.cursor()

    # Check if glyph_code_v1 column exists in mushaf_words
    cur.execute("PRAGMA table_info(mushaf_words);")
    columns = [row[1] for row in cur.fetchall()]
    if 'glyph_code_v1' not in columns:
        print("Adding column glyph_code_v1 to mushaf_words...")
        cur.execute("ALTER TABLE mushaf_words ADD COLUMN glyph_code_v1 TEXT;")
    else:
        print("Column glyph_code_v1 already exists in mushaf_words.")

    # Check if qpc_v1 column exists in mushaf_lines
    cur.execute("PRAGMA table_info(mushaf_lines);")
    line_columns = [row[1] for row in cur.fetchall()]
    if 'qpc_v1' not in line_columns:
        print("Adding column qpc_v1 to mushaf_lines...")
        cur.execute("ALTER TABLE mushaf_lines ADD COLUMN qpc_v1 TEXT;")
    else:
        print("Column qpc_v1 already exists in mushaf_lines.")

    # Load layout files and update words and lines
    total_words_updated = 0
    total_lines_updated = 0

    print("Updating mushaf_words and mushaf_lines from tools/source/mushaf_layout...")
    for p in range(1, 605):
        pad = f"{p:03d}"
        fpath = f"tools/source/mushaf_layout/page-{pad}.json"
        if not os.path.exists(fpath):
            print(f"Warning: {fpath} not found!")
            continue

        with open(fpath, 'r', encoding='utf-8') as f:
            data = json.load(f)

        lines = data.get('lines', [])
        for line in lines:
            line_num = line.get('line')
            line_type = line.get('type')
            words = line.get('words', [])

            line_qpc_v1 = line.get('qpcV1')
            if not line_qpc_v1 and words:
                line_qpc_v1 = ' '.join(w.get('qpcV1', '') for w in words if w.get('qpcV1'))

            if line_qpc_v1:
                cur.execute(
                    "UPDATE mushaf_lines SET qpc_v1 = ? WHERE page_number = ? AND line_number = ?",
                    (line_qpc_v1, p, line_num)
                )
                total_lines_updated += 1

            for w in words:
                location = w.get('location')
                qpc_v1 = w.get('qpcV1')
                if location and qpc_v1:
                    cur.execute(
                        "UPDATE mushaf_words SET glyph_code_v1 = ? WHERE page_number = ? AND line_number = ? AND location = ?",
                        (qpc_v1, p, line_num, location)
                    )
                    total_words_updated += 1

    con.commit()

    # Verification
    cur.execute("SELECT count(*) FROM mushaf_words WHERE glyph_code_v1 IS NULL OR glyph_code_v1 = ''")
    null_words = cur.fetchone()[0]
    cur.execute("SELECT count(*) FROM mushaf_words")
    total_db_words = cur.fetchone()[0]

    cur.execute("SELECT count(*) FROM mushaf_lines WHERE qpc_v1 IS NOT NULL AND qpc_v1 != ''")
    lines_with_v1 = cur.fetchone()[0]
    cur.execute("SELECT count(*) FROM mushaf_lines")
    total_lines = cur.fetchone()[0]

    con.close()

    print("========================================")
    print(f"Total DB words: {total_db_words}")
    print(f"Words with empty/null glyph_code_v1: {null_words}")
    print(f"Total lines: {total_lines}, Lines with qpc_v1: {lines_with_v1}")
    print("Migration finished successfully.")
    print("========================================")

if __name__ == '__main__':
    main()
