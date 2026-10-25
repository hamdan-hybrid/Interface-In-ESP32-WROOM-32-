# Interface Palang Parkir Pintu Masuk (ESP32)

Firmware siap upload untuk **ESP32 DevKit (ESP32-WROOM-32)** sebagai interface palang parkir
pintu masuk. Membaca loop detector (VLD) mobil/motor, tombol tiket, tombol bantuan, kartu member
(reader Wiegand), dan status palang, lalu mengirim data ke server lewat WiFi. Server membuka
palang dengan memanggil `http://IP-ESP32/open-gate?sn=SN` (relay aktif 1 detik). Suara lewat
modul Serial MP3 Player v1.1 (YX5300) + speaker. Setting dan log lewat Bluetooth (BLE).

Versi firmware: lihat [`firmware/VERSI.txt`](firmware/VERSI.txt). Versi yang terpasang tampil
sebagai `FIRMWARE:` di log saat boot dan di perintah `status`.

## Isi folder

| Folder / file | Isi |
|---------------|-----|
| `upload.sh` | Upload firmware (Linux) |
| `firmware/` | File firmware (`*.bin`) dan `VERSI.txt` |
| `sdcard/01/` | File suara `001.mp3` ... `009.mp3` untuk kartu SD modul MP3 |
| `tools/` | esptool (dipakai otomatis oleh `upload.sh`) |

## Upload firmware

Upload dari komputer **Linux 64-bit** (Ubuntu, Debian, Mint, dll). Tidak perlu Arduino IDE
dan tidak perlu memasang apa pun. Yang dibutuhkan hanya kabel USB **data** (kabel yang hanya
untuk charge tidak bisa dipakai).

Colokkan ESP32, buka terminal di folder ini, lalu jalankan:

```
bash upload.sh
```

Tunggu sampai muncul `SELESAI`, ESP32 restart sendiri.
Jika muncul `Tidak punya izin ke /dev/ttyUSB0`, jalankan sekali
`sudo usermod -aG dialout $USER`, lalu logout dan login lagi.

### Pilihan upload

| Perintah | Kegunaan |
|----------|----------|
| `bash upload.sh` | Update firmware. Setting WiFi, server, dan PIN Bluetooth **tetap**. |
| `bash upload.sh --erase` | ESP32 **baru** / reset total. Semua setting terhapus, PIN kembali `123456`. |
| `bash upload.sh /dev/ttyUSB1` | Pilih port jika ada lebih dari satu. |
| `BAUD=115200 bash upload.sh` | Langsung upload pelan. Biasanya tidak perlu: jika gagal, `upload.sh` otomatis mengulang di 115200. |

### Jika gagal

| Pesan | Solusi |
|-------|--------|
| `ESP32 tidak terdeteksi` | Ganti kabel USB (harus kabel data), coba port USB lain. |
| `Failed to connect` / `No serial data received` | Tahan tombol **BOOT** di ESP32 saat upload, lepas setelah muncul `Writing`. |
| `This chip is ESP32-S3, not ESP32` (atau chip lain) | Board salah, firmware ini hanya untuk ESP32-WROOM-32. |
| `upload.sh hanya untuk Linux 64-bit` | Pakai laptop / PC Linux 64-bit. |
| `UPLOAD GAGAL` (setelah diulang otomatis di 115200) | Ganti kabel USB yang lebih pendek / bagus, colok langsung ke laptop (tanpa hub USB). |
| Karakter aneh `����` di Serial Monitor sesaat setelah restart | Normal, abaikan. |

## Setting pertama (Bluetooth)

Bluetooth (BLE) selalu aktif dan dilindungi PIN pairing 6 angka (awal `123456`).

1. Di HP buka aplikasi **Serial Bluetooth Terminal** (mode BLE), sambungkan ke
   `HYBRID-INTERFACE`, lalu masukkan PIN.
2. Kirim satu baris, akhiri dengan Enter:

   ```
   ssid;password;domain;apikey;pin
   ```

   Contoh: `ParkirWiFi;rahasia123;192.168.1.10:3000;APIKEY_DARI_SERVER;482913`

   - `domain` = alamat server, boleh tanpa `http://`.
   - `pin` = PIN Bluetooth baru (6 angka). Kosong (`...;apikey;`) atau tidak ditulis = PIN tidak diubah.
   - SSID dan password tidak boleh mengandung tanda `;`.
3. ESP32 menyimpan setting lalu restart. Jika PIN diganti, hapus `HYBRID-INTERFACE` dari
   daftar Bluetooth HP, lalu pairing ulang dengan PIN baru.
4. Ketik `status`. Baris `WIFI:` harus menampilkan IP, dan `SERVER:` harus `OK`.

**Wajib ganti PIN dari `123456`.** Siapa pun yang tahu PIN bisa mengubah setting dan membuka
palang lewat Bluetooth. Jika lupa PIN, sambungkan USB, lalu di Serial Monitor (115200)
ketik `pin 654321`.

## Daftar barang (1 unit)

Loop detector (VLD) dan barrier gate sudah ada di lokasi, tidak termasuk daftar ini.

**Modul utama**

| Barang | Spesifikasi | Jumlah | Dipakai untuk |
|--------|-------------|:------:|---------------|
| ESP32 DevKit | chip **ESP32-WROOM-32**, USB CP2102 | 1 | otak sistem, WiFi, Bluetooth |
| Modul step down | LM2596 DC-DC, 12V → **5,0V** (atur trimpot sebelum dipasang) | 2 | A: ESP32 + relay. B: modul MP3 |
| Modul MP3 | Serial MP3 Player v1.1 (YX5300) + kartu microSD ≤ 32 GB (FAT32) | 1 | suara pengumuman |
| Speaker | colokan jack 3,5 mm, ke output modul MP3 | 1 | suara pengumuman |
| Modul relay | 1 channel 5V, ada jumper H/L | 1 | buka palang (jumper di **H**) |
| Modul optocoupler | 4 channel, input 12V | 1 | status palang, VLD mobil, VLD motor |
| Reader kartu | RFID 12V, output Wiegand 26/34 | 1 | kartu member (set ke Wiegand 34) |
| Tombol | push button NO (tekan = nyambung) | 2 | tombol tiket, tombol bantuan |
| Adaptor | 12V 3A | 1 | catu daya semua |
| Socket DC | jack female sesuai colokan adaptor (umumnya 5,5 × 2,1 mm), dipasang di box | 1 | colokan adaptor ke box |
| Kipas | 12V DC, ukuran sesuai box | 1 | pendingin di dalam box |
| Box project | plastik / ABS, ukuran secukupnya (semua modul, terminal, dan kabel muat) | 1 | wadah |

**Pengaman reader (wajib)**

Reader yang kami pakai mengeluarkan **5 V** di D0/D1, sedangkan pin ESP32 maksimal 3,3 V.

| Barang | Nilai | Jumlah | Dipakai untuk |
|--------|-------|:------:|---------------|
| Dioda Schottky | BAT85 (boleh 1N5819 / BAT43 / SS14) | 2 | D0 dan D1 |
| Resistor | 4k7, ¼ W | 2 | pull-up D0 dan D1 ke 3V3 |

**Kabel dan lain-lain (secukupnya)**

| Barang | Dipakai untuk |
|--------|---------------|
| Kabel jumper female-female | ESP32 ke modul-modul di dalam box |
| Kabel daya 2 core (±18 AWG) | socket DC → terminal → step down dan kipas |
| UTP / FTP Cat5e (±3 m, sesuai jarak) | ke barrier: status palang dan relay buka |
| Kabel twisted / shielded | ke reader kartu |
| Kabel 2 core | ke tombol dan VLD |
| Terminal blok sekrup | +12V, GND bersama, kabel keluar box |

Selain pengaman reader, resistor / kapasitor / elco lain **tidak wajib**: firmware memakai
pull-up internal ESP32 dan memfilter noise sendiri. Lihat
[Tambahan opsional](#tambahan-opsional) jika di lokasi ada gangguan.

## Pin ESP32

Semua input aktif LOW (0 V saat aktif). Semua sambungan langsung (kabel jumper), kecuali
Wiegand D0/D1 yang lewat pengaman reader.

| GPIO | Fungsi | Sambungan |
|------|--------|-----------|
| 2   | Relay palang | IN modul relay 5V (jumper **H**). HIGH = buka (pulsa 1 detik) |
| 4   | VLD mobil | OUT2 modul opto 4 channel 12V |
| 5   | VLD motor | OUT3 modul opto |
| 15  | Status palang | OUT1 modul opto. LOW = palang tertutup |
| 25  | Tombol tiket | satu kaki tombol ke GPIO25, kaki lain ke GND |
| 26  | Tombol bantuan | satu kaki tombol ke GPIO26, kaki lain ke GND |
| 21  | Wiegand D0 | kabel D0 reader → **katoda** dioda (sisi bergaris) → **anoda** ke GPIO21. Resistor 4k7 dari GPIO21 ke 3V3 |
| 22  | Wiegand D1 | sama dengan D0: kabel D1 → katoda dioda → anoda ke GPIO22. Resistor 4k7 dari GPIO22 ke 3V3 |
| 17  | Audio TX → RX modul MP3 | langsung |
| 18  | Audio RX ← TX modul MP3 | langsung |
| 3V3 | VCC sisi output modul opto | **bukan** 5V |
| GND | GND semua modul | ESP32, step down, modul MP3, relay, opto, reader, kipas: GND jadi satu |

Jangan dipakai: GPIO 1/3 (USB serial), 6–11 (flash), 0/12 (strapping boot), 34–39 (input
saja, tanpa pull-up).

**Reader kartu:**
- Set ke **Wiegand 34** (kabel abu-abu ke GND) agar nomor kartu utuh dan sama dengan
  reader USB. Wiegand 26 tetap terbaca, tapi byte teratas nomor kartu hilang.
- Dioda menahan 5 V dari reader agar tidak masuk ke ESP32. Saat reader mengirim data
  (kabel ditarik ke 0 V), dioda menghantar dan GPIO terbaca LOW. Tanpa dioda, pin ESP32
  menerima 5 V terus-menerus dan bisa rusak pelan-pelan walaupun kartu tetap terbaca.
- Cek setelah dipasang: tegangan GPIO21 dan GPIO22 ke GND saat diam harus ±3,3 V (bukan
  5 V), dan tap kartu harus muncul `KARTU: ...` di log dengan nomor yang sama seperti sebelumnya.
- Reader merek lain: ukur dulu kabel D0/D1 ke GND (reader diberi 12V, D0/D1 belum ke
  ESP32). 5 V / 12 V → pakai pengaman ini. 0 V (open-collector) → boleh langsung, tanpa dioda.

### Daya

- Adaptor 12V 3A → socket DC di box → terminal +12V.
- Step down A (LM2596) diset 5,0 V → pin 5V ESP32 + DC+ modul relay.
- Step down B (LM2596) diset 5,0 V → modul MP3.
- +12V langsung → reader, sisi input modul opto, COM kontak barrier, relay VLD, dan kipas.
- Semua GND ke satu terminal GND.

Atur tegangan step down dengan multimeter **sebelum** disambung ke ESP32 / modul. Lebih dari
5,5 V bisa merusak ESP32 dan modul MP3.

### Modul opto dan kabel barrier

- Modul opto: +12V → COM kontak → NO/NC kontak → IN1/IN2/IN3; G/- sisi input → GND.
  Kontak tersambung → OUT = LOW.
- Kabel ke barrier (UTP/FTP Cat5e, ±3 m): pasangan 1 = status palang (+12V dan IN1),
  pasangan 2 = relay COM/NO ke input OPEN barrier. Shield ke GND di sisi kotak saja.

### Anti-noise

- Firmware sudah memfilter noise: pulsa Wiegand < 15 µs / > 500 µs dibuang, VLD harus stabil
  200 ms (datang) / 500 ms (pergi), tombol 50 ms, status palang 100 ms, balasan modul MP3
  dicek formatnya.
- GND semua modul wajib jadi satu. Kabel reader twisted / shielded.
- Kabel speaker jauhkan dari kabel relay / loop.
- Jika karakter rusak `����` muncul di Serial Monitor saat alat sedang jalan, cek ground
  antara USB laptop dan adaptor 12V. Di lapangan pantau log lewat Bluetooth.

### Tambahan opsional

Tidak wajib. Pasang hanya jika ada masalah di lokasi, atau untuk unit yang ingin lebih awet.

| Masalah / tujuan | Tambahan |
|------------------|----------|
| Pengaman kebakaran / korsleting | Sekring 3A + holder setelah socket adaptor 12V (sangat disarankan, murah) |
| Kartu kadang terbaca salah / `WIEGAND: ... NOISE` sering muncul | Kapasitor 1 nF dari GPIO21 dan GPIO22 ke GND |
| Tombol kadang tertekan sendiri (kabel tombol panjang) | Per tombol: resistor 4k7 dari GPIO ke 3V3, resistor 330 Ω seri, kapasitor 100 nF ke GND |
| Palang sempat bergerak sendiri saat ESP32 dinyalakan | Resistor 10k dari GPIO2 ke GND |
| Suara berdengung / berdesis | Resistor 1k seri di GPIO17 → RX modul MP3. Filter LC di jalur 5V modul MP3: induktor 100 µH (≥ 1A) + elco 1000 µF 16V + kapasitor 100 nF |
| Lonjakan tegangan di jalur 12V (lokasi banyak petir / motor besar) | Dioda TVS SMBJ15A + elco 470 µF 25V dari +12V ke GND |

## Kartu SD (modul MP3)

Format kartu SD **FAT32**, lalu salin folder `sdcard/01` ke root kartu, sehingga isinya
`01/001.mp3` ... `01/009.mp3`. Nama folder harus persis `01`.

| Kode | Suara | Kapan diputar |
|------|-------|---------------|
| 0001 | Sistem siap | WiFi dan server tersambung (boot / pulih) |
| 0002 | Bantuan | tombol bantuan ditekan |
| 0003 | Selamat datang | kendaraan datang dan palang tertutup; diulang (jeda 2 detik) sampai tombol tiket ditekan / kartu di-tap |
| 0004 | Antrian | kendaraan datang saat palang belum tertutup |
| 0005 | Kartu tidak terdaftar | jawaban server |
| 0006 | Member masih di area | jawaban server |
| 0007 | Langganan habis | jawaban server |
| 0008 | Silakan masuk | palang dibuka; diulang (jeda 2 detik) sampai kendaraan lewat |
| 0009 | Koneksi terputus | WiFi / server putus, atau server tidak menjawab |

## Perintah Serial / Bluetooth

Perintah yang sama berlaku di Serial Monitor (USB, 115200 baud, akhiran newline) dan di
aplikasi Bluetooth. Selama HP terhubung, semua log tampil di aplikasi.

| Perintah | Fungsi |
|----------|--------|
| `status` | versi firmware, status input, palang, WiFi, server |
| `cek audio` | status modul MP3 dan jumlah file di kartu SD (harus 9) |
| `tes uart` | uji UART audio (jumper GPIO17-GPIO18, modul MP3 dilepas) |
| `play 0001` ... `play 0009` | putar suara |
| `open gate` | buka palang (tes relay) |
| `pin 123456` | ganti PIN Bluetooth (HP harus pairing ulang) |
