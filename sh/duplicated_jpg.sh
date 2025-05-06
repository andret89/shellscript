#!/bin/bash

# Controlla che sia stato passato un percorso
if [ -z "$1" ]; then
    echo "❌ Uso: $0 /percorso/al/file"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="duplicated_jpg.csv"

# Controlla se il percorso esiste
if [ ! -d "$INPUT_FILE" ]; then
    echo "❌ File non trovato: $INPUT_FILE"
    exit 1
fi

# Disabilita la separazione delle parole (importante per gestire file con spazi nel nome)
IFS=
find "$INPUT_FILE" -type f -iname "*.jpg" -exec md5sum {} + | sort | awk '
{
  count[$1]++;
  files[$1] = (files[$1] ? files[$1] RS : "") $0;
}
END {
  for (hash in count) {
    if (count[hash] > 1) {
      split(files[hash], lines, RS);
      for (i in lines) {
        split(lines[i], parts, "  ");
        if (parts[2] != "") {
          print "\"" parts[2] "\",\"" parts[1] "\""
        }
      }
    }
  }
}' > $OUTPUT_FILE
echo "✅ File salvato: $OUTPUT_FILE"