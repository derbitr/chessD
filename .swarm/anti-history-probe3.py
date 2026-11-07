import sqlite3
import json

BASE = r'C:\Users\Breno\.gemini\antigravity'
SUM = BASE + r'\conversation_summaries.db'
CID = '0c012fc0-740a-4389-bd11-c56f89f0e271'

conn = sqlite3.connect(SUM)
cur = conn.cursor()

rows = cur.execute(
    "SELECT conversation_id, chunk_index, chunk_first_step, chunk_last_step, "
    "user_step_byte_offsets, agent_step_byte_offsets, title, user_body, agent_body "
    "FROM conversations_fts WHERE conversation_id = ? ORDER BY chunk_index", (CID,)).fetchall()

print('chunks found:', len(rows))
out_path = BASE + r'\scratch\chess-app\.swarm\chess-history-raw.txt'
parts = []
for r in rows:
    conv_id, chunk_idx, first, last, uoff, aoff, title, ubody, abody = r
    parts.append(f"--- CHUNK {chunk_idx} steps {first}-{last} ---")
    parts.append("USER BODY:")
    parts.append(ubody if isinstance(ubody, str) else str(ubody))

with open(out_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(parts))
print('written:', out_path)

# also check summary row for this conversation
row = cur.execute(
    "SELECT title, preview, raw_summary FROM conversation_summaries WHERE conversation_id=?",
    (CID,)).fetchone()
if row:
    print('SUMMARY title:', row[0])
    print('SUMMARY preview:', (row[1] or '')[:200])

conn.close()
