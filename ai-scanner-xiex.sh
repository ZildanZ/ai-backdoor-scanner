

#!/bin/bash

clear

# Tampilkan ASCII art
banner=$(cat << "EOF"
███████╗██╗██╗░░░░░██████╗░░█████╗░███╗░░██╗░██████╗███████╗░█████╗░
╚════██║██║██║░░░░░██╔══██╗██╔══██╗████╗░██║██╔════╝██╔════╝██╔══██╗
░░███╔═╝██║██║░░░░░██║░░██║███████║██╔██╗██║╚█████╗░█████╗░░██║░░╚═╝
██╔══╝░░██║██║░░░░░██║░░██║██╔══██║██║╚████║░╚═══██╗██╔══╝░░██║░░██╗
███████╗██║███████╗██████╔╝██║░░██║██║░╚███║██████╔╝███████╗╚█████╔╝
╚══════╝╚═╝╚══════╝╚═════╝░╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░╚══════╝░╚════╝░
EOF
)
echo "$banner"
echo ""
echo "Selamat datang di AI Backdoor Scanner"
echo "---------------------------------------"
echo "Tool ini akan memeriksa file PHP apakah mengandung backdoor atau tidak."
echo "Silakan masukkan folder yang ingin diperiksa."
echo ""

# Minta input folder dari user
read -rp "Masukkan path folder: " TARGET_DIR

# Cek apakah folder ada
if [[ ! -d "$TARGET_DIR" ]]; then
    echo "[!] Folder '$TARGET_DIR' tidak ditemukan!"
    exit 1
fi

# Variabel API
API_URL="https://xiex.my.id/api/ai/chat/completions"
API_KEY="ApiKey"
MODEL="brainxiex"
DEBUG_FILE="debug.txt"

FILES=($(find "$TARGET_DIR" -type f -name "*.php"))
TOTAL=${#FILES[@]}

echo "[*] Memulai analisis AI untuk file PHP..."
echo "=== DEBUG LOG ===" > "$DEBUG_FILE"

i=1
for FILE in "${FILES[@]}"; do
    echo ""
    echo "[#] ($i/$TOTAL) Memeriksa: $FILE"

    CONTENT=$(head -n 100 "$FILE")

    if [[ -z "$CONTENT" ]]; then
        echo "[?] $FILE -> kosong / tidak bisa dianalisis"
        echo -e "\n[$FILE] Kosong / tidak bisa dianalisis" >> "$DEBUG_FILE"
        ((i++))
        continue
    fi

    PROMPT=$(printf "Apakah kode PHP berikut berisi backdoor? Berikan jawaban singkat dan to the point:\n\n%s" "$CONTENT")

    JSON=$(jq -n \
        --arg model "$MODEL" \
        --arg apikey "$API_KEY" \
        --arg content "$PROMPT" \
        '{
            model: $model,
            apikey: $apikey,
            messages: [{role: "user", content: $content}]
        }') || {
        echo "[!] $FILE -> gagal membuat JSON (kemungkinan prompt terlalu panjang)"
        echo -e "\n[$FILE] ERROR saat membuat JSON" >> "$DEBUG_FILE"
        ((i++))
        continue
    }

    echo -e "\n=== [$FILE] ===" >> "$DEBUG_FILE"
    echo -e ">> JSON:\n$JSON" >> "$DEBUG_FILE"

    RESPONSE=$(curl -s -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -d "$JSON")

    echo -e ">> RESPONSE:\n$RESPONSE" >> "$DEBUG_FILE"

    RESULT=$(echo "$RESPONSE" | jq -r '.answer // .message.content // .choices[0].message.content // "Tidak ada respon dari AI"')

    if [[ "$RESULT" == *"apikey salah"* ]]; then
        echo "[+] $FILE -> hasil: apikey salah"
    elif [[ "$RESULT" == "null" || -z "$RESULT" ]]; then
        echo "[!] $FILE -> respons error dari server"
        echo "    ↳ Pesan server: $(echo "$RESPONSE" | jq -r '.message // .error // empty')"
    else
        echo "[+] $FILE -> hasil: $RESULT"
    fi

    sleep 5
    ((i++))
done





