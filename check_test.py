#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from urllib import request, error

PASS = "PASS"
WARN = "WARN"
FAIL = "FAIL"


class Reporter:
    def __init__(self) -> None:
        self.items: List[Tuple[str, str, str]] = []
        self.failed = False

    def add(self, status: str, title: str, detail: str = "") -> None:
        if status == FAIL:
            self.failed = True
        self.items.append((status, title, detail))

    def print(self) -> None:
        print("\n=== CHECK APP ANDROID/FLUTTER ===\n")
        for status, title, detail in self.items:
            icon = {"PASS": "✅", "WARN": "⚠️", "FAIL": "❌"}.get(status, "•")
            print(f"{icon} [{status}] {title}")
            if detail:
                print(f"   {detail}")
        print("\n===============================\n")
        if self.failed:
            print("Esito finale: FAIL ❌")
        else:
            warns = sum(1 for i in self.items if i[0] == WARN)
            print("Esito finale: OK ✅" if warns == 0 else "Esito finale: OK con warning ⚠️")


def parse_env(path: Path) -> Dict[str, str]:
    out: Dict[str, str] = {}
    if not path.exists():
        return out
    for raw in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        out[k.strip()] = v.strip().strip('"').strip("'")
    return out


def read(path: Path) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8", errors="ignore")


def is_placeholder(v: str) -> bool:
    upper = v.upper()
    return "<" in v or ">" in v or "TUO_DOMINIO" in upper or "INSERISCI" in upper


def is_url(v: str) -> bool:
    return bool(re.match(r"^https?://[A-Za-z0-9._:-]+(?:/.*)?$", v))


def http_get(url: str, timeout: int = 6) -> Tuple[int, str]:
    req = request.Request(url=url, method="GET")
    try:
        with request.urlopen(req, timeout=timeout) as resp:
            return resp.status, resp.read().decode("utf-8", errors="ignore")
    except error.HTTPError as e:
        return e.code, e.read().decode("utf-8", errors="ignore")
    except Exception as e:
        return 0, str(e)


def main() -> int:
    root = Path.cwd()
    r = Reporter()

    # file chiave
    files_required = [
        root / "pubspec.yaml",
        root / "lib" / "main.dart",
        root / "lib" / "services" / "api_service.dart",
        root / "android" / "app" / "src" / "main" / "AndroidManifest.xml",
        root / "android" / "app" / "src" / "debug" / "AndroidManifest.xml",
    ]
    missing = [str(p) for p in files_required if not p.exists()]
    if missing:
        r.add(FAIL, "File fondamentali mancanti", ", ".join(missing))
        r.print()
        return 1
    r.add(PASS, "Struttura progetto app", "OK")

    env_example = root / ".env.example"
    env_real = root / ".env"

    if env_example.exists():
        r.add(PASS, ".env.example presente")
    else:
        r.add(WARN, ".env.example mancante", "Consigliato per onboarding")

    app_env = parse_env(env_real)
    if not env_real.exists():
        r.add(WARN, ".env mancante", "Crea .env copiando .env.example")
    else:
        api_base = app_env.get("API_BASE_URL", "")
        if not api_base:
            r.add(FAIL, "API_BASE_URL mancante in .env")
        elif is_placeholder(api_base):
            r.add(FAIL, "API_BASE_URL placeholder", api_base)
        elif not is_url(api_base):
            r.add(FAIL, "API_BASE_URL non valida", api_base)
        else:
            if api_base.endswith("/"):
                r.add(WARN, "API_BASE_URL termina con slash", "Meglio senza slash finale")
            else:
                r.add(PASS, "API_BASE_URL valida", api_base)

    # pubspec checks
    pubspec = read(root / "pubspec.yaml")
    if "flutter_dotenv" in pubspec:
        r.add(PASS, "Dipendenza flutter_dotenv", "OK")
    else:
        r.add(FAIL, "flutter_dotenv mancante in pubspec.yaml")

    # main.dart checks
    main_dart = read(root / "lib" / "main.dart")
    if "flutter_dotenv" in main_dart and "dotenv.load" in main_dart:
        r.add(PASS, "main.dart carica .env", "OK")
    else:
        r.add(FAIL, "main.dart non carica .env", "Aggiungi import flutter_dotenv + dotenv.load")

    # api_service wiring
    api_service = read(root / "lib" / "services" / "api_service.dart")
    endpoints = ["/api/login", "/api/refresh", "/api/logout", "/api/balance", "/api/transactions", "/api/transfer", "/api/qr/"]
    missing_ep = [e for e in endpoints if e not in api_service]
    if missing_ep:
        r.add(WARN, "Endpoint mancanti in api_service", ", ".join(missing_ep))
    else:
        r.add(PASS, "Endpoint principali in api_service", "OK")

    if "dotenv.env['API_BASE_URL']" in api_service or 'dotenv.env["API_BASE_URL"]' in api_service:
        r.add(PASS, "api_service usa API_BASE_URL da .env", "OK")
    else:
        r.add(WARN, "api_service non usa dotenv", "Controlla baseUrl")

    # manifest checks
    manifest_main = read(root / "android" / "app" / "src" / "main" / "AndroidManifest.xml")
    manifest_debug = read(root / "android" / "app" / "src" / "debug" / "AndroidManifest.xml")

    for perm in [
        "android.permission.INTERNET",
        "android.permission.ACCESS_NETWORK_STATE",
        "android.permission.CAMERA",
        "android.permission.NFC",
    ]:
        if perm in manifest_main:
            r.add(PASS, f"Manifest main: {perm}", "OK")
        else:
            r.add(WARN, f"Manifest main: {perm} mancante", "Verifica necessità nel tuo caso")

    if "usesCleartextTraffic" in manifest_debug:
        r.add(PASS, "Manifest debug cleartext", "OK (utile per http locale)")
    else:
        r.add(WARN, "Manifest debug cleartext assente", "Consigliato se usi backend http locale")

    # cross-tab refresh checks
    home_tab = read(root / "lib" / "screens" / "home_tab.dart")
    transfer = read(root / "lib" / "screens" / "transfer_screen.dart")
    qr = read(root / "lib" / "screens" / "qr_deposit_screen.dart")
    nfc = read(root / "lib" / "screens" / "card_nfc_screen.dart")

    if "AppEvents.stream.listen" in home_tab and "AppEvent.accountDataChanged" in home_tab:
        r.add(PASS, "Home ascolta eventi refresh", "OK")
    else:
        r.add(WARN, "Home non ascolta eventi refresh", "Cross-tab potrebbe non aggiornarsi")

    if "AppEvents.emitAccountDataChanged()" in transfer and "AppEvents.emitAccountDataChanged()" in qr and "AppEvents.emitAccountDataChanged()" in nfc:
        r.add(PASS, "Transfer/QR/NFC emettono refresh", "OK")
    else:
        r.add(WARN, "Emit refresh mancante", "Controlla Transfer/QR/NFC")

    # test reachability opzionale
    if env_real.exists() and app_env.get("API_BASE_URL"):
        api_base = app_env["API_BASE_URL"].rstrip("/")
        code, body = http_get(f"{api_base}/api/health")
        if code == 200:
            r.add(PASS, "Reachability backend /api/health", "OK")
        else:
            r.add(WARN, "Backend non raggiungibile ora", f"HTTP={code} dettaglio={body[:160]}")

    r.print()
    return 1 if r.failed else 0


if __name__ == "__main__":
    sys.exit(main())