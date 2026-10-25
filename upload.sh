#!/usr/bin/env bash
# Upload firmware parkir-mp3-reader ke ESP32 DevKit (ESP32-WROOM-32).
#
#   bash upload.sh                  port dicari otomatis, setting WiFi/PIN tetap
#   bash upload.sh /dev/ttyUSB1     pilih port sendiri
#   bash upload.sh --erase          hapus semua dulu (ESP32 baru / reset setting)
#   BAUD=115200 bash upload.sh      jika upload gagal di tengah jalan
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
FW="$DIR/firmware"
BAUD="${BAUD:-921600}"
PORT=""
ERASE=0

for arg in "$@"; do
    case "$arg" in
        --erase) ERASE=1 ;;
        -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
        *) PORT="$arg" ;;
    esac
done

for f in bootloader.bin partitions.bin boot_app0.bin firmware.bin; do
    if [ ! -f "$FW/$f" ]; then
        echo "File $FW/$f tidak ada. Salin ulang folder production lengkap."
        exit 1
    fi
done

# esptool: bawaan folder ini (Linux 64-bit), lalu yang terpasang di sistem.
# Izin executable hilang jika folder diunduh sebagai ZIP dari GitHub.
BUNDLED="$DIR/tools/esptool-linux-x64"
[ -f "$BUNDLED" ] && [ ! -x "$BUNDLED" ] && chmod +x "$BUNDLED" 2>/dev/null || true

if [ "$(uname -s)" = "Linux" ] && [ "$(uname -m)" = "x86_64" ] && [ -x "$BUNDLED" ]; then
    ESPTOOL=("$BUNDLED")
elif command -v esptool >/dev/null 2>&1; then
    ESPTOOL=(esptool)
elif command -v esptool.py >/dev/null 2>&1; then
    ESPTOOL=(esptool.py)
elif python3 -c "import esptool" >/dev/null 2>&1; then
    ESPTOOL=(python3 -m esptool)
else
    echo "esptool tidak ditemukan. Pasang dulu:  pip install esptool  (atau: pipx install esptool)"
    exit 1
fi

# esptool v5 memakai write-flash / default-reset, v4 memakai write_flash / default_reset.
MAJOR="$("${ESPTOOL[@]}" version 2>/dev/null | tail -n 1 | cut -d. -f1 | tr -dc '0-9')"

if [ "${MAJOR:-0}" -ge 5 ]; then
    WRITE=write-flash; ERASE_CMD=erase-flash; BEFORE=default-reset; AFTER=hard-reset
    MODE=--flash-mode; FREQ=--flash-freq; SIZE=--flash-size
else
    WRITE=write_flash; ERASE_CMD=erase_flash; BEFORE=default_reset; AFTER=hard_reset
    MODE=--flash_mode; FREQ=--flash_freq; SIZE=--flash_size
fi

if [ -z "$PORT" ]; then
    PORTS=()
    for p in /dev/ttyUSB* /dev/ttyACM* /dev/cu.usbserial* /dev/cu.SLAB_USBtoUART* /dev/cu.wchusbserial*; do
        [ -e "$p" ] && PORTS+=("$p")
    done

    if [ "${#PORTS[@]}" -eq 0 ]; then
        echo "ESP32 tidak terdeteksi. Cek kabel USB (harus kabel data, bukan kabel charge saja)."
        exit 1
    fi

    if [ "${#PORTS[@]}" -gt 1 ]; then
        echo "Ada lebih dari satu port: ${PORTS[*]}"
        echo "Pilih salah satu, contoh:  bash upload.sh ${PORTS[0]}"
        exit 1
    fi

    PORT="${PORTS[0]}"
fi

if [ ! -w "$PORT" ]; then
    echo "Tidak punya izin ke $PORT. Jalankan sekali:"
    echo "  sudo usermod -aG dialout \$USER"
    echo "lalu logout dan login lagi."
    exit 1
fi

echo "== FIRMWARE"
sed -n '1,3p' "$FW/VERSI.txt" 2>/dev/null || true
echo "== PORT: $PORT"

if [ "$ERASE" -eq 1 ]; then
    echo "== HAPUS SEMUA ISI FLASH (WiFi, server, PIN kembali awal)"
    "${ESPTOOL[@]}" --chip esp32 --port "$PORT" --baud "$BAUD" $ERASE_CMD
fi

echo "== UPLOAD"
"${ESPTOOL[@]}" --chip esp32 --port "$PORT" --baud "$BAUD" \
    --before $BEFORE --after $AFTER \
    $WRITE -z $MODE keep $FREQ keep $SIZE keep \
    0x1000  "$FW/bootloader.bin" \
    0x8000  "$FW/partitions.bin" \
    0xe000  "$FW/boot_app0.bin" \
    0x10000 "$FW/firmware.bin"

echo
echo "SELESAI. ESP32 sudah restart dengan firmware baru."
if [ "$ERASE" -eq 1 ]; then
    echo "Setting kosong: kirim ssid;password;domain;apikey;pin lewat Bluetooth (PIN awal 123456)."
fi
