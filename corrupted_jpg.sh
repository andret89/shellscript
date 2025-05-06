#!/bin/bash

# Controlla che sia stato passato un percorso
if [ -z "$1" ]; then
    echo "❌ Uso: $0 /percorso/alla/cartella"
    exit 1
fi

DIR="$1"
OUTPUT_FILE="corrupted_jpg.csv"

# Controlla se il percorso esiste
if [ ! -d "$DIR" ]; then
    echo "❌ Directory non trovata: $DIR"
    exit 1
fi

# Intestazione CSV
# echo '"filepath","md5"' > "$OUTPUT_FILE"
# Disabilita la separazione delle parole (importante per gestire file con spazi nel nome)
IFS=
find "$DIR" -type f -iname "*.jpg" -exec jpeginfo -s -c {} \; \
| grep -v 'OK' \
| cut -d',' -f1 \
| xargs -P 8 -I {} md5sum "{}" \
| awk '{ 
    hash = $1; 
    $1 = ""; 
    sub(/^ +/, ""); 
    print "\"" $0 "\"," hash 
}'\
| tee -a $OUTPUT_FILE


echo "✅ File salvato: $OUTPUT_FILE"