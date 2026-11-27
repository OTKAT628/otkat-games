#!/usr/bin/env python3
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
ROOT=Path(__file__).resolve().parents[1]
WEB=ROOT/"web"
OUT=WEB/"downloads"/"packages"
OUT.mkdir(parents=True,exist_ok=True)
for old in OUT.glob("*.zip"): old.unlink()
THREE_D=["hide-and-seek","survival","arena","forgotten","skyrun","racing","space","magic","prehistoric"]
CANVAS=["depths","swarm","kingdoms","orbital","cozy"]
def add(z, rel):
    p=ROOT/rel
    if p.exists(): z.write(p,rel)
def launcher(target,title):
    return f'''<!doctype html><html lang="ru"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{title} — OTKAT</title><body style="background:#090b14;color:#f4f3f8;font:16px system-ui;padding:3rem"><h1>{title}</h1><p>Пакет браузерного прототипа OTKAT.</p><p><a style="color:#f6e34b" href="{target}">Запустить игру →</a></p><p>Для запуска из ZIP распакуй архив и открой локальный сервер из этой папки. Инструкция — в README.txt.</p></body></html>'''
def make(slug,title,kind):
    out=OUT/f"{slug}-browser-source.zip"
    with ZipFile(out,"w",ZIP_DEFLATED) as z:
        if kind=="canvas":
            add(z,f"web/{slug}/index.html"); add(z,"web/new-games.js"); add(z,"web/styles.css")
            target=f"web/{slug}/index.html"
        elif kind=="driftline":
            add(z,"web/driftline/index.html"); add(z,"web/driftline/garage-3d.js"); add(z,"web/styles.css")
            target="web/driftline/index.html"
        else:
            add(z,"web/prototype-3d/index.html"); add(z,"web/styles.css")
            target=f"web/prototype-3d/index.html?game={slug}"
        z.writestr("index.html",launcher(target,title))
        z.writestr("README.txt",f"""{title} — OTKAT browser prototype source package

This archive contains source files for the browser prototype, not a native installer.
It does NOT contain an EXE, APK, DMG, AppImage or console build.

How to run:
1. Extract the ZIP.
2. Open a terminal in the extracted folder.
3. Run: python -m http.server 8000
4. Open http://127.0.0.1:8000/ in your browser.

The 3D prototype and Driftline 3D garage load Three.js from a CDN and require an internet connection.
The game UI is currently Russian. An English game translation is not included yet.
Progress is stored locally in your browser where supported.
""")
for slug in THREE_D: make(slug,slug.replace("-"," ").title(),"3d")
for slug in CANVAS: make(slug,slug.replace("-"," ").title(),"canvas")
make("driftline","Driftline: Apex Circuit","driftline")
# Native Godot source for Hide & Seek is a separate editable project, not an installer.
godot=OUT/"hide-and-seek-godot-source.zip"
with ZipFile(godot,"w",ZIP_DEFLATED) as z:
    base=ROOT/"games"/"hide-and-seek"
    if base.exists():
        for p in base.rglob("*"):
            if p.is_file(): z.write(p,p.relative_to(ROOT))
    z.writestr("README-IMPORT.txt","Godot 4.7.2 source project. Open Godot Project Manager > Import and select games/hide-and-seek/project.godot. This is source code, not an APK or EXE.")
print(f"Created {len(list(OUT.glob('*.zip')))} game source ZIP packages in {OUT}")
