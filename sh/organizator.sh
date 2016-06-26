#!/bin/bash

mkdir -p "/$HOME/Organize"
mkdir -p "/$HOME/Organize/Pictures"
mkdir -p "/$HOME/Organize/Videos"
mkdir -p "/$HOME/Organize/Music"
mkdir -p "/$HOME/Organize/Documents"
mkdir -p "/$HOME/Organize/Shellscripts"
mkdir -p "/$HOME/Organize/Compress"
mkdir -p "/$HOME/Organize/Codici";

config[0]="image/::/$HOME/Organize/Pictures";
config[1]="video/::/$HOME/Organize/Videos";
config[2]="audio/::/$HOME/Organize/Music";
config[3]="application/pdf::/$HOME/Organize/Documents";
config[4]="text/plain:.sh:/$HOME/Organize/Shellscripts";
config[5]="text/plain:.py:/$HOME/Organize/Shellscripts";
config[6]="application/x-rar::/$HOME/Organize/Compress";
config[7]="application/zip::/$HOME/Organize/Compress";
config[8]="application/gzip::/$HOME/Organize/Compress";
config[9]="application/pdf::/$HOME/Organize/Documents";
config[10]="text/x-c::/$HOME/Organize/Codici";
config[11]="application/msword::/$HOME/Organize/Documents";

for confline in "${config[@]}"; do
    mimetype=$(echo $confline | cut -d':' -f1);
    extension=$(echo $confline | cut -d':' -f2);
    destination=$(echo $confline | cut -d':' -f3);
    file --mime-type * | grep "${mimetype}" | grep "${extension}:" | 
    while read line; do
        nomefile=$(echo $line | cut -d':' -f1);
        mv ${nomefile} ${destination}/${nomefile};
    done
done