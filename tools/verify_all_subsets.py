import os
import sys
import sqlite3
from fontTools.ttLib import TTFont

sys.stdout.reconfigure(encoding='utf-8')

DB_PATH = 'assets/db/app_data.db'
FONTS_DIR = 'assets/fonts/qpc_v2'

def main():
    con = sqlite3.connect(DB_PATH)
    cur = con.cursor()
    
    total_glyphs_checked = 0
    pages_checked = 0
    missing_records = []
    
    print("Verifying 604 fonts against all database glyph codes...")
    for p in range(1, 605):
        font_path = os.path.join(FONTS_DIR, f'p{p}.ttf')
        if not os.path.exists(font_path):
            missing_records.append((p, "FILE_NOT_FOUND", None))
            continue
            
        font = TTFont(font_path)
        cmap = font.getBestCmap()
        
        cur.execute('SELECT glyph_code FROM mushaf_words WHERE page_number = ?', (p,))
        words = [r[0] for r in cur.fetchall()]
        
        for w in words:
            for c in w:
                cp = ord(c)
                total_glyphs_checked += 1
                if cp not in cmap and cp not in (0x0020, 0x00A0):
                    missing_records.append((p, f"U+{cp:04X}", c))
                    
        pages_checked += 1
        if p % 100 == 0 or p == 604:
            print(f"Verified {p}/604 pages... ({total_glyphs_checked:,} glyph instances checked)")
            
    con.close()
    
    print("\n--- Verification Summary ---")
    print(f"Total Pages Checked: {pages_checked}/604")
    print(f"Total Glyphs Checked: {total_glyphs_checked:,}")
    if missing_records:
        print(f"FAILED: Found {len(missing_records)} missing glyph instances!")
        for rec in missing_records[:10]:
            print(f"  Page {rec[0]}: {rec[1]}")
        sys.exit(1)
    else:
        print("SUCCESS: 100% of glyph codes present in all 604 page fonts!")

if __name__ == '__main__':
    main()
