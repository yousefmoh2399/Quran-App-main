import os
import sys
import time
import sqlite3
import zipfile
import io
from concurrent.futures import ProcessPoolExecutor
from fontTools import subset
from fontTools.ttLib import TTFont

sys.stdout.reconfigure(encoding='utf-8')

DB_PATH = 'assets/db/app_data.db'
FONTS_DIR = 'assets/fonts/qpc_v2'
BACKUP_DIR = 'assets/fonts/qpc_v2_backup'
TEMP_DIR = 'tools/subset_temp'

def get_page_codepoints(db_path, page_num, font_cmap):
    con = sqlite3.connect(db_path)
    cur = con.cursor()
    cur.execute('SELECT glyph_code FROM mushaf_words WHERE page_number = ?', (page_num,))
    words = [r[0] for r in cur.fetchall()]
    
    cur.execute('SELECT qpc_v2 FROM mushaf_lines WHERE page_number = ?', (page_num,))
    lines = [r[0] for r in cur.fetchall() if r[0]]
    con.close()
    
    codepoints = set()
    for text in words + lines:
        for char in text:
            cp = ord(char)
            if cp in font_cmap:
                codepoints.add(cp)
                
    for cp in [0x0020, 0x00A0, 0x200C, 0x200D, 0x200E, 0x200F, 0x25CC]:
        if cp in font_cmap:
            codepoints.add(cp)
            
    return codepoints

def process_page(page_num):
    orig_path = os.path.join(FONTS_DIR, f'p{page_num}.ttf')
    if not os.path.exists(orig_path):
        return page_num, 0, 0, False, "File not found"
        
    orig_size = os.path.getsize(orig_path)
    
    try:
        font = TTFont(orig_path)
        orig_cmap = font.getBestCmap()
        codepoints = get_page_codepoints(DB_PATH, page_num, orig_cmap)
        
        options = subset.Options()
        options.hinting = False
        options.layout_features = ['*']
        options.drop_tables += ['LTSH', 'VDMX', 'hdmx', 'DSIG', 'FFTM', 'gasp', 'kern']
        options.notdef_outline = False
        options.glyph_names = False
        options.ignore_missing_glyphs = True
        
        subsetter = subset.Subsetter(options=options)
        subsetter.populate(unicodes=codepoints)
        subsetter.subset(font)
        
        out_path = os.path.join(TEMP_DIR, f'p{page_num}.ttf')
        font.save(out_path)
        new_size = os.path.getsize(out_path)
        
        # Verify
        sub_font = TTFont(out_path)
        sub_cmap = sub_font.getBestCmap()
        missing = [cp for cp in codepoints if cp not in sub_cmap]
        if missing:
            return page_num, orig_size, new_size, False, f"Missing {len(missing)} codepoints"
            
        return page_num, orig_size, new_size, True, "OK"
    except Exception as e:
        return page_num, orig_size, 0, False, str(e)

def main():
    os.makedirs(TEMP_DIR, exist_ok=True)
    start_time = time.time()
    
    total_orig = 0
    total_new = 0
    errors = []
    
    print("Starting subsetting for pages 1 to 604...")
    for p in range(1, 605):
        p_num, orig_sz, new_sz, success, msg = process_page(p)
        total_orig += orig_sz
        total_new += new_sz
        if not success:
            errors.append((p_num, msg))
            print(f"ERROR on page {p_num}: {msg}")
        elif p % 100 == 0 or p == 604:
            print(f"Processed {p}/604 pages... (Current: {total_orig/(1024*1024):.2f}MB -> {total_new/(1024*1024):.2f}MB)")
            
    elapsed = time.time() - start_time
    print(f"\nDone in {elapsed:.1f}s.")
    print(f"Total original: {total_orig/(1024*1024):.2f} MB")
    print(f"Total subsetted: {total_new/(1024*1024):.2f} MB")
    print(f"Savings: {(total_orig - total_new)/(1024*1024):.2f} MB ({(1 - total_new/total_orig)*100:.1f}%)")
    print(f"Errors: {len(errors)}")

if __name__ == '__main__':
    main()
