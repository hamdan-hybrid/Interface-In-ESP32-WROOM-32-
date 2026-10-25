#!/usr/bin/env bash
# Upload firmware parkir-mp3-reader ke ESP32 DevKit (ESP32-WROOM-32),
# dari komputer Linux 64-bit (x86_64). Tidak perlu memasang apa pun.
#
#   bash upload.sh                  port dicari otomatis, setting WiFi/PIN tetap
#   bash upload.sh /dev/ttyUSB1     pilih port sendiri
#   bash upload.sh --erase          hapus semua dulu (ESP32 baru / reset setting)
#   BAUD=115200 bash upload.sh      langsung pelan (gagal di baud tinggi diulang otomatis)
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

if [ "$(uname -s)" != "Linux" ] || [ "$(uname -m)" != "x86_64" ]; then
    echo "upload.sh hanya untuk Linux 64-bit (x86_64)."
    exit 1
fi

# esptool bawaan folder ini. Izin executable hilang jika folder diunduh
# sebagai ZIP dari GitHub.
ESPTOOL="$DIR/tools/esptool-linux-x64"

if [ ! -f "$ESPTOOL" ]; then
    echo "File $ESPTOOL tidak ada. Salin ulang folder production lengkap."
    exit 1
fi

[ -x "$ESPTOOL" ] || chmod +x "$ESPTOOL"

if [ -z "$PORT" ]; then
    PORTS=()
    for p in /dev/ttyUSB* /dev/ttyACM*; do
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
    "$ESPTOOL" --chip esp32 --port "$PORT" --baud "$BAUD" erase-flash
fi

flash()
{
    "$ESPTOOL" --chip esp32 --port "$PORT" --baud "$1" \
        --before default-reset --after hard-reset \
        write-flash -z --flash-mode keep --flash-freq keep --flash-size keep \
        0x1000  "$FW/bootloader.bin" \
        0x8000  "$FW/partitions.bin" \
        0xe000  "$FW/boot_app0.bin" \
        0x10000 "$FW/firmware.bin"
}

echo "== UPLOAD"

# Kabel panjang / murah bisa gagal di baud tinggi: ulangi sekali lebih pelan.
if ! flash "$BAUD"; then
    if [ "$BAUD" -le 115200 ]; then
        echo "UPLOAD GAGAL. Cek kabel USB, lalu coba lagi."
        exit 1
    fi

    echo
    echo "== UPLOAD GAGAL DI $BAUD, DIULANG DENGAN 115200 (LEBIH LAMBAT)"
    flash 115200 || { echo "UPLOAD GAGAL. Cek kabel USB, lalu coba lagi."; exit 1; }
fi

echo
echo "SELESAI. ESP32 sudah restart dengan firmware baru."
if [ "$ERASE" -eq 1 ]; then
    echo "Setting kosong: kirim ssid;password;domain;apikey;pin lewat Bluetooth (PIN awal 123456)."
fi
