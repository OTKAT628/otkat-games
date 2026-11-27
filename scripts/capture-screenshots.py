#!/usr/bin/env python3
from pathlib import Path
from playwright.sync_api import sync_playwright
BASE="http://127.0.0.1:4173"
OUT=Path("web/screenshots")
OUT.mkdir(parents=True,exist_ok=True)
three_d=["hide-and-seek","survival","arena","forgotten","skyrun","racing","space","magic","prehistoric"]
canvas=["depths","swarm","kingdoms","orbital","cozy"]
targets=[(s,f"/prototype-3d/index.html?game={s}","3d") for s in three_d]
targets += [(s,f"/{s}/index.html","canvas") for s in canvas]
targets += [("driftline","/driftline/index.html","driftline")]
with sync_playwright() as p:
    browser=p.chromium.launch()
    for slug,path,kind in targets:
        page=browser.new_page(viewport={"width":1280,"height":900},device_scale_factor=1)
        try:
            page.goto(BASE+path,wait_until="domcontentloaded",timeout=60000)
            page.wait_for_timeout(1800)
            if kind=="3d":
                start=page.locator("#start")
                if start.count() and start.is_visible():
                    start.click(timeout=8000)
                    page.wait_for_timeout(2600)
                target=page.locator(".stage")
            elif kind=="canvas":
                target=page.locator(".game-panel")
                page.wait_for_timeout(1200)
            else:
                target=page.locator(".layout")
                page.wait_for_timeout(1800)
            if target.count():
                target.first.screenshot(path=str(OUT/f"{slug}.png"),timeout=30000)
            else:
                page.screenshot(path=str(OUT/f"{slug}.png"),full_page=True,timeout=30000)
            print("Captured",slug)
        except Exception as exc:
            print("Screenshot capture failed for",slug,":",exc)
            try: page.screenshot(path=str(OUT/f"{slug}.png"),full_page=True,timeout=30000)
            except Exception: pass
        finally:
            page.close()
    browser.close()
