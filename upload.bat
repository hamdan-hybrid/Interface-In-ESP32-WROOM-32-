@echo off
rem Upload firmware parkir-mp3-reader ke ESP32 DevKit (ESP32-WROOM-32).
rem
rem   upload.bat               port dicari otomatis, setting WiFi/PIN tetap
rem   upload.bat COM5          pilih port sendiri
rem   upload.bat --erase       hapus semua dulu (ESP32 baru / reset setting)
rem   upload.bat COM5 --erase
rem   set BAUD=115200 lalu upload.bat   jika upload gagal di tengah jalan
setlocal EnableDelayedExpansion
cd /d "%~dp0"

if "%BAUD%"=="" set BAUD=921600
set PORT=
set ERASE=0

:args
if "%~1"=="" goto args_done
if /i "%~1"=="--erase" (
    set ERASE=1
) else (
    set PORT=%~1
)
shift
goto args
:args_done

for %%f in (bootloader.bin partitions.bin boot_app0.bin firmware.bin) do (
    if not exist "firmware\%%f" (
        echo File firmware\%%f tidak ada. Salin ulang folder production lengkap.
        goto fail
    )
)

rem esptool: tools\esptool.exe (jika disediakan), lalu yang terpasang di sistem.
set ESPTOOL=
if exist "tools\esptool.exe" set ESPTOOL="tools\esptool.exe"
if not defined ESPTOOL where esptool >nul 2>nul && set ESPTOOL=esptool
if not defined ESPTOOL py -m esptool version >nul 2>nul && set ESPTOOL=py -m esptool
if not defined ESPTOOL python -m esptool version >nul 2>nul && set ESPTOOL=python -m esptool
if not defined ESPTOOL (
    echo esptool tidak ditemukan. Pasang Python dari python.org, lalu jalankan:
    echo   pip install esptool
    goto fail
)

rem esptool v5 memakai write-flash / default-reset, v4 memakai write_flash / default_reset.
set VER=0
for /f "delims=" %%v in ('%ESPTOOL% version 2^>nul') do set VER=%%v
set MAJOR=%VER:~0,1%
if "%MAJOR%" GEQ "5" (
    set WRITE=write-flash& set ERASE_CMD=erase-flash& set BEFORE=default-reset& set AFTER=hard-reset
    set MODE=--flash-mode& set FREQ=--flash-freq& set SIZE=--flash-size
) else (
    set WRITE=write_flash& set ERASE_CMD=erase_flash& set BEFORE=default_reset& set AFTER=hard_reset
    set MODE=--flash_mode& set FREQ=--flash_freq& set SIZE=--flash_size
)

rem Tanpa port: esptool mencoba semua port COM sendiri.
set PORT_ARG=
if defined PORT set PORT_ARG=--port %PORT%

echo == FIRMWARE
type firmware\VERSI.txt 2>nul | findstr /b "Firmware Versi Build"
if defined PORT (echo == PORT: %PORT%) else (echo == PORT: otomatis)

if "%ERASE%"=="1" (
    echo == HAPUS SEMUA ISI FLASH ^(WiFi, server, PIN kembali awal^)
    %ESPTOOL% --chip esp32 %PORT_ARG% --baud %BAUD% %ERASE_CMD%
    if errorlevel 1 goto fail
)

echo == UPLOAD
%ESPTOOL% --chip esp32 %PORT_ARG% --baud %BAUD% --before %BEFORE% --after %AFTER% %WRITE% -z %MODE% keep %FREQ% keep %SIZE% keep 0x1000 firmware\bootloader.bin 0x8000 firmware\partitions.bin 0xe000 firmware\boot_app0.bin 0x10000 firmware\firmware.bin
if errorlevel 1 goto fail

echo.
echo SELESAI. ESP32 sudah restart dengan firmware baru.
if "%ERASE%"=="1" echo Setting kosong: kirim ssid;password;domain;apikey;pin lewat Bluetooth (PIN awal 123456).
pause
exit /b 0

:fail
echo.
echo UPLOAD GAGAL. Lihat README.md bagian "Jika gagal".
pause
exit /b 1
