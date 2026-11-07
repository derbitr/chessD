import sqlite3
import os

BASE = r'C:\Users\Breno\.gemini\antigravity'
SUM = os.path.join(BASE, 'conversation_summaries.db')

conn = sqlite3.connect(SUM)
cur = conn.cursor()
try:
    tables = [r[0] for r in cur.execute(
        "SELECT name FROM sqlite_master WHERE type='table'").fetchall()]
    print('TABLES:', tables)
    for t in tables:
        try:
            cols = [(r[1], r[2]) for r in cur.execute(
                'PRAGMA table_info(' + t + ')').fetchall()]
            print('SCHEMA', t, '=>', cols)
        except Exception as e:
            print('ERR schema', t, repr(e))
    # try to find rows mentioning chess
    for t in tables:
        try:
            count = cur.execute('SELECT COUNT(*) FROM ' + t).fetchone()[0]
            print('COUNT', t, count)
        except Exception as e:
            print('ERR count', t, repr(e))
        # dump schema-stringified columns that may contain 'chess'
        cols = [c[0] for c in cur.execute('PRAGMA table_info(' + t + ')').fetchall()]
        for c in cols:
            try:
                like = cur.execute(
                    'SELECT COUNT(*) FROM ' + t + ' WHERE "' + c +
                    '" LIKE ? COLLATE NOCASE', ('%chess%',)).fetchone()[0]
                if like:
                    print('HIT table', t, 'col', c, 'matches', like)
            except Exception as e:
                pass
finally:
    conn.close()
