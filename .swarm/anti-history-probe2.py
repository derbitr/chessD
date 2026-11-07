import sqlite3

BASE = r'C:\Users\Breno\.gemini\antigravity'
SUM = BASE + r'\conversation_summaries.db'

conn = sqlite3.connect(SUM)
cur = conn.cursor()

print('=== FTS MATCH: chess ===')
try:
    rows = cur.execute(
        "SELECT conversation_id, title, workspace, last_modified_time, step_count "
        "FROM conversations_fts WHERE conversations_fts MATCH 'chess' "
        "ORDER BY rank LIMIT 20").fetchall()
    for r in rows:
        print(r)
except Exception as e:
    firing = repr(e)
    print('ERR MATCH chess:', firing)
    try:
        rows = cur.execute(
            "SELECT conversation_id, title, workspace, last_modified_time, step_count "
            "FROM conversations_fts WHERE conversations_fts MATCH 'xadrez' "
            "ORDER BY rank LIMIT 20").fetchall()
        print('xlrz rows:')
        for r in rows:
            print(r)
    except Exception as e2:
        print('ERR MATCH xadrez:', repr(e2))

print()
print('=== titles with chess/xadrez (data table LIKE) ===')
try:
    like_rows = cur.execute(
        "SELECT conversation_id, title, workspace, last_modified_time, step_count "
        "FROM conversations_fts WHERE title LIKE '%chess%' OR title LIKE '%xadrez%' "
        "LIMIT 20").fetchall()
    for r in like_rows:
        print(r)
except Exception as e:
    print('ERR LIKE:', repr(e))

print()
print('=== latest 15 summaries ===')
rows = cur.execute(
    "SELECT conversation_id, title, workspace_uris, last_modified_time, step_count, source "
    "FROM conversation_summaries ORDER BY last_modified_time DESC LIMIT 15").fetchall()
for r in rows:
    print(r)

conn.close()
