# ----------------------------------------------------------------------------
# \file dllord.py
# \note (c) 2025 by Jens Kallup - paule32
#
# \desc Erzeugt aus den Exporten (Ordinal + Funktionsname) einer Windows-DLL
#       eine msgfmt-kompatible .po-Datei und baut daraus eine .mo-Datei.
#
# Beispiel:
# python make_po_from_dll.py --dll user32.dll --dll-dir "C:\Windows\System32" \
#      --out-po exports_user32.po --hex
#
# Voraussetzungen:
#  pip install pefile
#  msgfmt.exe (GNU gettext) im PATH oder via --msgfmt angeben
# ----------------------------------------------------------------------------
import argparse
import datetime as dt
import os
import subprocess
import sys
from pathlib import Path

try:
    import pefile
except ImportError:
    print("Fehler: Das Modul 'pefile' ist nicht installiert.")
    print("Bitte mit 'pip install pefile' nachinstallieren.", file=sys.stderr)
    sys.exit(2)

# ----------------------------------------------------------------------------
# PO-String escapen (Doppelpunkte, Quotes, Backslashes, Zeilenumbrüche).
# ----------------------------------------------------------------------------
def escape_po(s: str) -> str:
    return (
        s.replace('\\', '\\\\')
         .replace('"', '\\"')
         .replace('\r', '\\r')
         .replace('\n', '\\n')
    )

def enumerate_exports(dll_path: Path):
    """Liest Ordinal + Name der Exporte aus dll_path."""
    pe = pefile.PE(str(dll_path))
    exports = []
    if not hasattr(pe, "DIRECTORY_ENTRY_EXPORT"):
        return exports
    for sym in pe.DIRECTORY_ENTRY_EXPORT.symbols:
        ordinal = sym.ordinal
        name = None
        if sym.name:
            try:
                name = sym.name.decode("ascii")
            except Exception:
                name = sym.name.decode("utf-8", errors="replace")
        exports.append((ordinal, name))
    exports.sort(key=lambda t: t[0])
    return exports

def format_ordinal(n: int, use_hex: bool) -> str:
    return f"0x{n:X}" if use_hex else str(n)

# ----------------------------------------------------------------------------
# Schreibt eine .po mit Header + Einträgen msgid=<ordinal>, msgstr=<name>.
# ----------------------------------------------------------------------------
def write_po(exports, out_po: Path, use_hex: bool, project="dll-exports", lang=""):
    now = dt.datetime.now().strftime("%Y-%m-%d %H:%M%z")
    
    # ------------------------------------------------------------------------
    # Sicherstellen, dass Ordinale als Strings kommen – Darstellung ent-
    # scheidet Aufrufer (dezimal/hex)
    # ------------------------------------------------------------------------
    with out_po.open("w", encoding="utf-8", newline="\n") as f:
        # Minimaler, msgfmt-tauglicher Header
        f.write('# Generated from DLL exports\n')
        f.write('msgid ""\n')
        f.write('msgstr ""\n')
        f.write(f'"Project-Id-Version: {escape_po(project)}\\n"\n')
        f.write('"Report-Msgid-Bugs-To: \\n"\n')
        f.write(f'"POT-Creation-Date: {now}\\n"\n')
        f.write(f'"PO-Revision-Date: {now}\\n"\n')
        f.write('"Last-Translator: \\n"\n')
        f.write('"Language-Team: \\n"\n')
        f.write(f'"Language: {escape_po(lang)}\\n"\n')
        f.write('"MIME-Version: 1.0\\n"\n')
        f.write('"Content-Type: text/plain; charset=UTF-8\\n"\n')
        f.write('"Content-Transfer-Encoding: 8bit\\n"\n\n')
        
        # ------------------------------------------------------------------------
        # 1) Ordinal -> Name
        # ------------------------------------------------------------------------
        f.write('# --- Forward mapping: ordinal -> name ---\n')
        for ordinal, name in exports:
            ord_str = format_ordinal(ordinal, use_hex)
            f.write(f'msgid "{escape_po(ord_str)}"\n')
            f.write(f'msgstr "{escape_po(name or "")}"\n\n')
        
        # ------------------------------------------------------------------------
        # 2) Name -> Ordinal (namenlose Exporte überspringen, Deduplizierung nach
        # Name)
        # ------------------------------------------------------------------------
        f.write('# --- Reverse mapping: name -> ordinal ---\n')
        seen_names = set()
        for ordinal, name in exports:
            if not name:
                continue
            if name in seen_names:
                continue
            seen_names.add(name)
            ord_str = format_ordinal(ordinal, use_hex)
            f.write(f'msgid "{escape_po(name)}"\n')
            f.write(f'msgstr "{escape_po(ord_str)}"\n\n')

# ----------------------------------------------------------------------------
# Führt msgfmt aus, um aus .po -> .mo zu bauen.
# ----------------------------------------------------------------------------
def run_msgfmt(msgfmt_exe: str, po_path: Path, mo_path: Path):
    cmd = [msgfmt_exe, "-o", str(mo_path), str(po_path)]
    try:
        cp = subprocess.run(cmd, check=False, capture_output=True, text=True)
    except FileNotFoundError:
        # Fallback: unter Unix heißt es oft "msgfmt" ohne .exe
        if msgfmt_exe.lower().endswith(".exe"):
            alt = msgfmt_exe[:-4]
        else:
            alt = msgfmt_exe + ".exe"
        try:
            cp = subprocess.run([alt, "-o", str(mo_path), str(po_path)], check=False, capture_output=True, text=True)
        except FileNotFoundError:
            print(f"Fehler: '{msgfmt_exe}' nicht gefunden. Bitte --msgfmt angeben oder in PATH bereitstellen.", file=sys.stderr)
            sys.exit(3)

    if cp.returncode != 0:
        print("msgfmt meldete einen Fehler:", file=sys.stderr)
        if cp.stdout:
            print(cp.stdout, file=sys.stderr)
        if cp.stderr:
            print(cp.stderr, file=sys.stderr)
        sys.exit(cp.returncode)

def main():
    ap = argparse.ArgumentParser(
        description="Extrahiert Ordinale + Funktionsnamen aus einer DLL und erzeugt .po/.mo (msgfmt-kompatibel)."
    )
    ap.add_argument("--dll"     , required = True,          help="Name der DLL (z.B. user32.dll) oder vollständiger Pfad")
    ap.add_argument("--dll-dir" , default  = None,          help="Verzeichnis der DLL (z.B. C:\\Windows\\System32). Optional, wird mit --dll kombiniert.")
    ap.add_argument("--out-po"  , required = True,          help="Ausgabedatei .po")
    ap.add_argument("--out-mo"  , default  = None,          help="Ausgabedatei .mo (optional; Standard: gleicher Name wie .po mit Endung .mo)")
    ap.add_argument("--msgfmt"  , default  = "msgfmt.exe",  help="Pfad zu msgfmt.exe (Default: msgfmt.exe aus PATH)")
    ap.add_argument("--hex"     , action   = "store_true",  help="Ordinale als Hex (z.B. 0x1A3) statt dezimal in msgid schreiben")
    ap.add_argument("--project" , default  = "dll-exports", help="Project-Id-Version im PO-Header")
    ap.add_argument("--language", default  = "",            help="Language im PO-Header (z.B. de)")
    
    args = ap.parse_args()

    dll_path = Path(args.dll)
    if args.dll_dir and not dll_path.is_absolute():
        dll_path = Path(args.dll_dir) / dll_path

    if not dll_path.exists():
        print(f"Fehler: DLL nicht gefunden: {dll_path}", file=sys.stderr)
        sys.exit(1)

    out_po = Path(args.out_po)
    out_po.parent.mkdir(parents=True, exist_ok=True)

    exports = enumerate_exports(dll_path)

    # Darstellung der Ordinale vorbereiten
    if args.hex:
        display = [(f"0x{ord_:X}", name) for (ord_, name) in exports]
    else:
        display = [(str(ord_), name) for (ord_, name) in exports]
    write_po(display, out_po, use_hex=args.hex, project=args.project, lang=args.language)

    # .mo-Pfad bestimmen
    out_mo = Path(args.out_mo) if args.out_mo else out_po.with_suffix(".mo")
    run_msgfmt(args.msgfmt, out_po, out_mo)

    print(f"Fertig.\nPO: {out_po}\nMO: {out_mo}")

if __name__ == "__main__":
    main()
