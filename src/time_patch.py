# -----------------------------------------------------------------------------
# \file  time_stamp.py
# \note  (c) 2025 by Jens Kallup - paule32
#        all rights reserved.
#
# \desc  Create a tiny MS-Windows 11 64-bit Pro EXE.
#        modify the time stamp in PE header.
#
# "now" time
# python set_pe_time.py build\meinprog.exe -v
#
# Konkrete Zeit (ISO 8601; ohne Zeitzone wird lokale Zeit angenommen):
# python set_pe_time.py build\*.exe --iso "2025-09-12 14:23:05" --recalc-checksum -v
#
# Expliziter Unix-Timestamp:
# python set_pe_time.py meinprog.exe --timestamp 1757672585 --recalc-checksum -v
#
# -----------------------------------------------------------------------------
import argparse, glob, struct, sys, time
from datetime import datetime, timezone

PE_SIG = b'PE\0\0'
COFF_SIZE = 20

# -----------------------------------------------------------------------------
# Offset 64 (0x40) im Optional Header ist das CheckSum-Feld (PE32 & PE32+)
# -----------------------------------------------------------------------------
OPT_HDR_CHECKSUM_OFF = 0x40

def read_u32le(f, off):
    f.seek(off)
    return int.from_bytes(f.read(4), 'little')

def write_u32le(f, off, val):
    f.seek(off)
    f.write(struct.pack('<I', val & 0xFFFFFFFF))

def find_pe_structs(f):
    # e_lfanew aus DOS-Header (0x3C)
    e_lfanew = read_u32le(f, 0x3C)
    f.seek(e_lfanew)
    if f.read(4) != PE_SIG:
        raise ValueError("PE-Signatur nicht gefunden (keine PE/COFF-Datei?)")
    coff_off = e_lfanew + 4
    # -------------------------------------------------------------------------
    # TimeDateStamp liegt im COFF-Header bei Offset 4 relativ zu coff_off
    # -------------------------------------------------------------------------
    tdstamp_off = coff_off + 4
    # -------------------------------------------------------------------------
    # Größe des Optional Headers steht im COFF-Header bei Offset 16
    # -------------------------------------------------------------------------
    f.seek(coff_off + 16)
    size_opt = int.from_bytes(f.read(2), 'little')
    opt_off = coff_off + COFF_SIZE
    return e_lfanew, coff_off, tdstamp_off, opt_off, size_opt

# -----------------------------------------------------------------------------    
# Implementierung analog zu MapFileAndCheckSum:
# - CheckSum-Feld vorher auf 0 setzen
# - 16-Bit-Words summieren, am Ende Faltung + Dateilänge hinzufügen
# -----------------------------------------------------------------------------
def compute_pe_checksum(buf, checksum_offset):
    b = bytearray(buf)
    # Checksum-Feld (4 Bytes) nullen
    b[checksum_offset:checksum_offset+4] = b'\x00\x00\x00\x00'
    
    csum = 0
    n = len(b)
    i = 0
    # -------------------------------------------------------------------------
    # 16-Bit little-endian Worte addieren
    # -------------------------------------------------------------------------
    while i + 1 < n:
        csum += b[i] | (b[i+1] << 8)
        csum &= 0xFFFFFFFF
        i += 2
    if i < n:  # ungerade Länge → letztes Byte
        csum = (csum + b[i]) & 0xFFFFFFFF
    
    # -------------------------------------------------------------------------
    # Faltung auf 16 Bit
    # -------------------------------------------------------------------------
    csum = (csum & 0xFFFF) + (csum >> 16)
    csum = (csum & 0xFFFF) + (csum >> 16)
    
    # -------------------------------------------------------------------------
    # Dateilänge addieren
    # -------------------------------------------------------------------------
    csum = (csum + n) & 0xFFFFFFFF
    return csum

def set_pe_timestamp(path, ts, recalc_checksum=False, verbose=False):
    with open(path, 'rb+') as f:
        e_lfanew, coff_off, ts_off, opt_off, size_opt = find_pe_structs(f)

        # ---------------------------------------------------------------------
        # Timestamp schreiben
        # ---------------------------------------------------------------------
        write_u32le(f, ts_off, ts)
        
        # ---------------------------------------------------------------------
        # Optional: Checksumme neu berechnen & schreiben, falls Optional Header
        # groß genug
        # ---------------------------------------------------------------------
        if recalc_checksum:
            if size_opt < OPT_HDR_CHECKSUM_OFF + 4:
                raise ValueError("Optional Header zu klein, CheckSum-Feld nicht vorhanden.")
            checksum_off = opt_off + OPT_HDR_CHECKSUM_OFF

            # -----------------------------------------------------------------
            # gesamten Dateiinhalt einlesen
            # -----------------------------------------------------------------
            f.seek(0, 0)
            data = f.read()
            new_sum = compute_pe_checksum(data, checksum_off)

            # -----------------------------------------------------------------
            # neue Checksumme schreiben
            # -----------------------------------------------------------------
            write_u32le(f, checksum_off, new_sum)

        if verbose:
            print(f"[OK] {path}: TimeDateStamp={ts} (UTC {datetime.fromtimestamp(ts, tz=timezone.utc)})"
                  + (" + CheckSum aktualisiert" if recalc_checksum else ""))

def parse_args():
    p = argparse.ArgumentParser(description="PE/EXE/DLL TimeDateStamp setzen (und optional Checksumme neu berechnen).")
    p.add_argument("paths", nargs="+", help="Dateipfad(e) oder Globs (z.B. build\\*.exe)")
    g = p.add_mutually_exclusive_group()
    g.add_argument("--timestamp", type=int, help="Expliziter Unixzeitstempel (Sekunden seit 1970-01-01 UTC)")
    g.add_argument("--iso", help="Datum/Zeit als ISO-8601 (z.B. 2025-09-12T14:23:05+02:00 oder 2025-09-12 14:23:05)")
    p.add_argument("--recalc-checksum", action="store_true", help="PE-Checksumme neu berechnen")
    p.add_argument("-v", "--verbose", action="store_true")
    return p.parse_args()

def main():
    args = parse_args()
    # -------------------------------------------------------------------------
    # Zielzeit bestimmen
    # -------------------------------------------------------------------------
    if args.timestamp is not None:
        ts = int(args.timestamp)
    elif args.iso:
        s = args.iso.strip().replace(' ', 'T', 1) if ' ' in args.iso and 'T' not in args.iso else args.iso
        dt = datetime.fromisoformat(s)  # erlaubt auch +HH:MM
        if dt.tzinfo is None:
            # -----------------------------------------------------------------
            # ohne TZ: als lokale Zeit interpretieren und in UTC umrechnen
            # -----------------------------------------------------------------
            dt = dt.astimezone()  # lokale Zone anfügen
        ts = int(dt.timestamp())
    else:
        ts = int(time.time())
    
    # -------------------------------------------------------------------------
    # Globs expandieren
    # -------------------------------------------------------------------------
    files = []
    for pat in args.paths:
        m = glob.glob(pat)
        files.extend(m if m else [pat])

    ok = 0
    for path in files:
        try:
            set_pe_timestamp(path, ts, recalc_checksum=args.recalc_checksum, verbose=args.verbose)
            ok += 1
        except Exception as e:
            print(f"[FEHLER] {path}: {e}", file=sys.stderr)

    if args.verbose:
        print(f"Fertig: {ok}/{len(files)} Datei(en) bearbeitet.")

# -----------------------------------------------------------------------------
# entry point/start of execution
# -----------------------------------------------------------------------------
if __name__ == "__main__":
    main()
