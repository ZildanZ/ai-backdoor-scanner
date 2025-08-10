#!/bin/bash

# Tampilkan ASCII art
clear
banner=$(cat << "EOF"
███████╗██╗██╗░░░░░██████╗░░█████╗░███╗░░██╗░██████╗███████╗░█████╗░
╚════██║██║██║░░░░░██╔══██╗██╔══██╗████╗░██║██╔════╝██╔════╝██╔══██╗
░░███╔═╝██║██║░░░░░██║░░██║███████║██╔██╗██║╚█████╗░█████╗░░██║░░╚═╝
██╔══╝░░██║██║░░░░░██║░░██║██╔══██║██║╚████║░╚═══██╗██╔══╝░░██║░░██╗
███████╗██║███████╗██████╔╝██║░░██║██║░╚███║██████╔╝███████╗╚█████╔╝
╚══════╝╚═╝╚══════╝╚═════╝░╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░╚══════╝░╚════╝░
EOF
)
echo -e "\033[38;2;0;191;255m$banner\033[0m"
echo
echo "[*] AI PHP Backdoor Scanner"
echo "[*] Masukkan path file .txt berisi daftar file PHP yang ingin dianalisis:"
read -rp ">> " FILE_LIST

# Cek keberadaan file list
if [[ ! -f "$FILE_LIST" ]]; then
    echo "[-] File $FILE_LIST tidak ditemukan. Keluar."
    exit 1
fi

API_KEY="APIKEY"
MODEL="cecep"

echo
echo "[*] Memulai analisis AI untuk file PHP..."

while read -r filepath; do
    if [[ ! -f "$filepath" ]]; then
        echo "[-] $filepath -> file tidak ditemukan"
        continue
    fi

    snippet=$(head -n 40 "$filepath" | jq -Rs .)

    response=$(curl -s https://xiex.my.id/api/ai/chat/completions \
      -H "Authorization: Bearer $API_KEY" \
      -H "Content-Type: application/json" \
      -H "User-Agent: ZildanZ-AI-PHP-Backdoor-Scanner/1.0" \
      -d '{
        "model": "'$MODEL'",
        "messages": [
          {
            "role": "system",
            "content": "Kamu adalah analis keamanan siber. Tugasmu adalah mendeteksi apakah potongan kode PHP ini merupakan backdoor. File dianggap backdoor jika mengandung: password tersembunyi, fungsi rekursif untuk scan direktori, sistem command seperti system(), exec(), shell_exec(), file_get_contents dari input, fungsi encode/decode base64, gzip, eval(), atau manipulasi file tidak biasa. Jawab hanya dengan 'backdoor' atau 'aman'."
          },
          {
            "role": "user",
            "content": '"$snippet"'
          }
        ],
        "temperature": 0
      }')

    result=$(echo "$response" | jq -r '.choices[0].message.content // empty')

    if [[ "$result" == "backdoor" ]]; then
        echo "[!] $filepath -> teridentifikasi backdoor"
    elif [[ "$result" == "aman" ]]; then
        echo "[+] $filepath -> aman"
    else
        echo "[?] $filepath -> tidak dapat dianalisis (respons: $result)"
    fi

    sleep 1
done < "$FILE_LIST"
