#!/usr/bin/env python3
'''
Estrai dati foto corrotte da shotwell database
'''

import sqlite3
import os
import argparse
from datetime import datetime, timezone

# === Argomenti da CLI ===
parser = argparse.ArgumentParser(description="Importa foto corrotte da un DB Shotwell a un altro.")
parser.add_argument('--origin', required=True, help="Valore da inserire nella colonna 'origin'")
args = parser.parse_args()
ORIGIN_TEXT = args.origin

# === Percorsi ai database ===
home = os.environ['HOME']
SRC_DB = os.path.join(home, '.local/share/shotwell/data/photo.db')
DST_DB = os.path.join(home, '.local/share/shotwell/data/photo_corrupted.db')

# === Connessione ai DB ===
src_conn = sqlite3.connect(SRC_DB)
dst_conn = sqlite3.connect(DST_DB)
src_cursor = src_conn.cursor()
dst_cursor = dst_conn.cursor()

# === Crea tabella nel DB di destinazione (se non esiste) ===
dst_cursor.execute("""
CREATE TABLE IF NOT EXISTS PhotoTable (
    id INTEGER PRIMARY KEY,
    filename TEXT UNIQUE NOT NULL,
    md5 TEXT UNIQUE NOT NULL,
    timestamp TEXT,
    time_imported TEXT,
    comment TEXT,
    origin TEXT,
    fixed TEXT,
    status TEXT
)
""")

# === Funzione per convertire timestamp UNIX in datetime UTC con oggetto timezone-aware ===
def convert_timestamp(timestamp):
    if timestamp:
        return datetime.fromtimestamp(timestamp, tz=timezone.utc).strftime('%Y-%m-%d %H:%M:%S')
    return None

# === Estrai solo le foto corrotte ===
src_cursor.execute("""
SELECT filename, md5, timestamp, time_created, time_reimported, comment
FROM PhotoTable
WHERE flags != 0 OR comment IS NOT NULL OR md5 IS NULL
""")
rows = src_cursor.fetchall()

# === Inserisci i dati con il campo origin personalizzato ===
for row in rows:
    filename, md5, timestamp, time_created, time_reimported, comment = row
    
    # Converti i timestamp in datetime UTC
    timestamp = convert_timestamp(timestamp)
    time_created = convert_timestamp(time_created)
    
    try:
        dst_cursor.execute("""
        INSERT OR IGNORE INTO PhotoTable
        (filename, md5, timestamp, time_imported, comment, origin)
        VALUES (?, ?, ?, ?, ?, ?)
        """, (filename, md5, timestamp, time_created, comment, ORIGIN_TEXT))
    except sqlite3.IntegrityError as e:
        print(f"⚠️ Errore inserimento: {e} su {filename}")

dst_conn.commit()
src_conn.close()
dst_conn.close()

print(f"✅ Importazione completata con origin = '{ORIGIN_TEXT}'.")
