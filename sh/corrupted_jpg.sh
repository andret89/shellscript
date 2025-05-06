#!/bin/bash

# Verifica argomento
if [ -z "$1" ]; then
    echo "❌ Uso: $0 /percorso/alla/cartella"
    exit 1
fi

# Verifica directory
if [ ! -d "$1" ]; then
    echo "❌ Directory non trovata: $DIR"
    exit 1
fi

DIR="$1"
OUTPUT_FILE="corrupted_jpg.csv"
TEMP_FILE="tmp.txt"

# Ottieni info su partizione e disco
read -r DEVICE_PARTITION PARTITION_SIZE <<< $(df -H "$DIR" | awk 'NR==2 {print $1, $2}')
read -r  PARTITION_NAME PARTITION_LABEL <<< $(lsblk -no NAME,LABEL "$DEVICE_PARTITION")
DISK=$(lsblk -no PKNAME "$DEVICE_PARTITION")
DEVICE_MODEL=$(udevadm info --query=all --name="/dev/$DISK" | grep "ID_MODEL=" | cut -d= -f2)
DEVICE_MODEL=${DEVICE_MODEL:-UNKNOWN}
# Ottieni la dimensione del disco in GB
DEVICE_SIZE=$(lsblk -dno SIZE "/dev/$DISK" | awk '{print $1}')

echo "📦 Dispositivo: $DEVICE_MODEL"
echo "💾 Dimensione: ${DEVICE_SIZE}"
echo "🧩 Partizione: ${PARTITION_NAME}-${PARTITION_LABEL}-${PARTITION_SIZE}"

# Pulisce output
> "$TEMP_FILE"

# Trova JPG corrotti e salva i nomi in formato sicuro (null-separated)
find "$DIR" -type f -iname "*.jpg" -print0 \
| while IFS= read -r -d '' file; do
    if ! jpeginfo -c -s "$file" | grep -q 'OK'; then
        printf '%s\0' "$file" >> "$TEMP_FILE"
    fi
done

# Aggiungi header CSV solo se il file è vuoto o non esiste
if [ ! -s "$OUTPUT_FILE" ]; then
    echo '"md5","filepath","device_model","device_size","partition_label","partition_size"'> "$OUTPUT_FILE"
fi

# Calcola MD5 per ciascun file nel file temporaneo
while IFS= read -r -d '' filename; do
    if [ ! -f "$filename" ]; then
        echo "$DEVICE_MODEL,ERROR,File not found,\"$filename\""
        continue
    fi
    MD5=$(md5sum "$filename" | awk '{print $1}')
    echo "$MD5,\"$filename\",$DEVICE_MODEL,$DEVICE_SIZE,$PARTITION_LABEL,$PARTITION_SIZE" >> "$OUTPUT_FILE"
done < "$TEMP_FILE"

# Rimuovi file temporaneo
rm -f "$TEMP_FILE"



echo "✅ File salvato: $OUTPUT_FILE"
