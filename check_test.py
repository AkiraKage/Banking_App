#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Check di integrità per l'app Banking_App (Flutter).

Cosa verifica:
  - Struttura del progetto Flutter (file fondamentali presenti)
  - File `.env` / `.env.example` con `API_BASE_URL` valido (senza placeholder)
  - Dipendenze in `pubspec.yaml` (flutter_dotenv, http, provider,
    mobile_scanner, local_auth, flutter_secure_storage, permission_handler)
  - main.dart che carica il `.env`
  - api_service.dart con endpoint completi (incluso `/api/me`)
    e header `ngrok-skip-browser-warning`
  - MeData definita in api_service per profilo + IBAN
  - actions_tab.dart usa IBAN dinamico (no hardcoded)
  - bank_card.dart parametrizzata con cardholderName/lastFour/iban
    + bottone copia IBAN
  - home_tab.dart fa polling silenzioso ogni 30s + ascolta AppEvents
    + passa IBAN alla BankCard
  - transfer/qr emettono `AppEvents.emitAccountDataChanged`
  - AndroidManifest con permessi INTERNET, NETWORK_STATE, CAMERA
  - Reachability del backend su `/api/health` se `API_BASE_URL` valido
"""

import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple
from urllib import error, request

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
        print("\n=== CHECK PROGETTO BANKING APP ===\n")
        for status, title, detail in self.items:
            icon = {"PASS": "✅", "WARN": "⚠️", "FAIL": "❌"}.get(status, "•")
            print(f"{icon} [{status}] {title}")
            if detail:
                print(f"   {detail}")
        print("\n==================================\n")
        passed = sum(1 for i in self.items if i[0] == PASS)
        warns = sum(1 for i in self.items if i[0] == WARN)
        fails = sum(1 for i in self.items if i[0] == FAIL)
        print(f"Riepilogo: {passed} PASS · {warns} WARN · {fails} FAIL")
        if self.failed:
            print("Esito finale: FAIL ❌")
        else:
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
    markers = ("<", ">", "TUO_DOMINIO", "INSERISCI", "PLACEHOLDER")
    return any(m in upper for m in markers if isinstance(m, str)) or any(m in v for m in ("<", ">"))


def is_url(v: str) -> bool:
    return bool(re.match(r"^https?://[A-Za-z0-9._:-]+(?:/.*)?$", v))


def http_get(url: str, timeout: int = 6) -> Tuple[int, str]:
    req = request.Request(
        url=url,
        method="GET",
        headers={"ngrok-skip-browser-warning": "true", "Accept": "application/json"},
    )
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

    # ----------------------------------------------------------
    # 1) Struttura progetto Flutter
    # ----------------------------------------------------------
    files_required = [
        root / "pubspec.yaml",
        root / "lib" / "main.dart",
        root / "lib" / "services" / "api_service.dart",
        root / "lib" / "screens" / "home_tab.dart",
        root / "lib" / "screens" / "actions_tab.dart",
        root / "lib" / "screens" / "transfer_screen.dart",
        root / "lib" / "screens" / "qr_deposit_screen.dart",
        root / "lib" / "widgets" / "bank_card.dart",
        root / "android" / "app" / "src" / "main" / "AndroidManifest.xml",
        root / "android" / "app" / "src" / "debug" / "AndroidManifest.xml",
    ]
    missing = [str(p.relative_to(root)) for p in files_required if not p.exists()]
    if missing:
        r.add(FAIL, "File fondamentali mancanti", ", ".join(missing))
        r.print()
        return 1
    r.add(PASS, "Struttura progetto Flutter", "OK")

    # ----------------------------------------------------------
    # 2) .env / .env.example
    # ----------------------------------------------------------
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
            r.add(FAIL, "API_BASE_URL contiene placeholder", api_base)
        elif not is_url(api_base):
            r.add(FAIL, "API_BASE_URL non valida", api_base)
        elif api_base.endswith("/"):
            r.add(WARN, "API_BASE_URL termina con slash", "Meglio rimuoverlo per coerenza")
        else:
            r.add(PASS, "API_BASE_URL valida", api_base)

    # ----------------------------------------------------------
    # 3) pubspec.yaml dipendenze
    # ----------------------------------------------------------
    pubspec = read(root / "pubspec.yaml")
    required_deps = [
        "flutter_dotenv",
        "http",
        "provider",
        "flutter_secure_storage",
        "permission_handler",
        "mobile_scanner",
        "local_auth",
    ]
    missing_deps = [d for d in required_deps if d not in pubspec]
    if missing_deps:
        r.add(FAIL, "Dipendenze mancanti in pubspec.yaml", ", ".join(missing_deps))
    else:
        r.add(PASS, "Dipendenze Flutter", "Tutte presenti")

    if "assets:" in pubspec and ".env" in pubspec:
        r.add(PASS, "pubspec.yaml include .env negli asset", "OK")
    else:
        r.add(WARN, ".env non dichiarato negli asset di pubspec.yaml", "Aggiungi - .env sotto assets:")

    # ----------------------------------------------------------
    # 4) main.dart carica .env
    # ----------------------------------------------------------
    main_dart = read(root / "lib" / "main.dart")
    if "flutter_dotenv" in main_dart and "dotenv.load" in main_dart:
        r.add(PASS, "main.dart carica .env", "OK")
    else:
        r.add(FAIL, "main.dart non carica .env", "Aggiungi import flutter_dotenv + await dotenv.load()")

    # ----------------------------------------------------------
    # 5) api_service.dart - wiring completo
    # ----------------------------------------------------------
    api_service = read(root / "lib" / "services" / "api_service.dart")

    endpoints = [
        "/api/login",
        "/api/refresh",
        "/api/logout",
        "/api/me",
        "/api/balance",
        "/api/transactions",
        "/api/transfer",
        "/api/qr/",
    ]
    missing_ep = [e for e in endpoints if e not in api_service]
    if missing_ep:
        r.add(FAIL, "Endpoint mancanti in api_service", ", ".join(missing_ep))
    else:
        r.add(PASS, "Endpoint API completi (incluso /api/me)", "OK")

    if "dotenv.env['API_BASE_URL']" in api_service or 'dotenv.env["API_BASE_URL"]' in api_service:
        r.add(PASS, "api_service usa API_BASE_URL da dotenv", "OK")
    else:
        r.add(WARN, "api_service non usa dotenv", "Controlla baseUrl")

    if "ngrok-skip-browser-warning" in api_service:
        r.add(PASS, "Header ngrok-skip-browser-warning presente", "Evita interstitial HTML di ngrok")
    else:
        r.add(FAIL, "Header ngrok-skip-browser-warning mancante", "Aggiungere in _baseHeaders")

    if "class MeData" in api_service and "getMe()" in api_service:
        r.add(PASS, "MeData + getMe() definiti", "OK")
    else:
        r.add(FAIL, "Classe MeData o metodo getMe() mancante", "Necessari per profilo + IBAN")

    # ----------------------------------------------------------
    # 6) ActionsTab usa IBAN dinamico
    # ----------------------------------------------------------
    actions_tab = read(root / "lib" / "screens" / "actions_tab.dart")
    if "authProvider.userIban" in actions_tab or "ApiService.getMe()" in actions_tab:
        r.add(PASS, "ActionsTab usa IBAN dinamico", "OK")
    else:
        r.add(FAIL, "ActionsTab non usa IBAN dinamico", "Usa authProvider.userIban o getMe()")

    if "IT60 X054 2811 1010 0000 0123 456" in actions_tab:
        r.add(FAIL, "IBAN hardcoded ancora presente in ActionsTab", "Rimuovi il valore demo")
    else:
        r.add(PASS, "Nessun IBAN hardcoded in ActionsTab", "OK")

    # ----------------------------------------------------------
    # 7) BankCard parametrizzata + copia IBAN
    # ----------------------------------------------------------
    bank_card = read(root / "lib" / "widgets" / "bank_card.dart")

    required_card_tokens = ["cardholderName", "lastFour", "iban"]
    missing_card_tokens = [t for t in required_card_tokens if t not in bank_card]
    if missing_card_tokens:
        r.add(FAIL, "BankCard non completa", f"Mancano: {', '.join(missing_card_tokens)}")
    else:
        r.add(PASS, "BankCard parametrizzata (cardholderName/lastFour/iban)", "OK")

    if "Clipboard.setData" in bank_card and ("Copia" in bank_card or "copy_rounded" in bank_card):
        r.add(PASS, "BankCard ha copia IBAN", "OK")
    else:
        r.add(FAIL, "BankCard senza bottone copia IBAN", "Aggiungi Clipboard.setData + pulsante")

    if "'ALOK'" in bank_card or "ALOK" in bank_card.replace("CONTACTLESS", ""):
        r.add(FAIL, "Nome hardcoded ancora presente in BankCard", "Sostituisci con cardholderName dinamico")
    else:
        r.add(PASS, "Nessun nome hardcoded in BankCard", "OK")

    # ----------------------------------------------------------
    # 8) HomeTab - polling + wiring BankCard
    # ----------------------------------------------------------
    home_tab = read(root / "lib" / "screens" / "home_tab.dart")
    if "AppEvents.stream.listen" in home_tab and "AppEvent.accountDataChanged" in home_tab:
        r.add(PASS, "HomeTab ascolta eventi refresh", "OK")
    else:
        r.add(WARN, "HomeTab non ascolta eventi refresh", "Cross-tab potrebbe non aggiornarsi")

    if "Timer.periodic" in home_tab and "_silentRefresh" in home_tab:
        r.add(PASS, "HomeTab fa polling silenzioso", "OK")
    else:
        r.add(WARN, "HomeTab senza polling automatico", "Aggiungi Timer.periodic")

    if "WidgetsBindingObserver" in home_tab and "didChangeAppLifecycleState" in home_tab:
        r.add(PASS, "HomeTab gestisce lifecycle (resume/pause)", "OK")
    else:
        r.add(WARN, "HomeTab non gestisce lifecycle", "Consigliato per pausare polling in background")

    if "iban:" in home_tab and "BankCard(" in home_tab:
        r.add(PASS, "HomeTab passa IBAN alla BankCard", "OK")
    else:
        r.add(FAIL, "HomeTab non passa IBAN alla BankCard", "Aggiungi parametro iban: ...")

    # ----------------------------------------------------------
    # 9) Cross-tab refresh (Transfer/QR)
    # ----------------------------------------------------------
    transfer = read(root / "lib" / "screens" / "transfer_screen.dart")
    qr = read(root / "lib" / "screens" / "qr_deposit_screen.dart")
    if all("AppEvents.emitAccountDataChanged()" in src for src in (transfer, qr)):
        r.add(PASS, "Transfer/QR emettono refresh", "OK")
    else:
        r.add(WARN, "Emit refresh mancante in Transfer o QR", "Controlla le schermate")

    # ----------------------------------------------------------
    # 10) AndroidManifest - permessi
    # ----------------------------------------------------------
    manifest_main = read(root / "android" / "app" / "src" / "main" / "AndroidManifest.xml")
    manifest_debug = read(root / "android" / "app" / "src" / "debug" / "AndroidManifest.xml")

    for perm, friendly in [
        ("android.permission.INTERNET", "INTERNET"),
        ("android.permission.ACCESS_NETWORK_STATE", "ACCESS_NETWORK_STATE"),
        ("android.permission.CAMERA", "CAMERA (QR scanner)"),
    ]:
        if perm in manifest_main:
            r.add(PASS, f"Manifest main: {friendly}", "OK")
        else:
            r.add(WARN, f"Manifest main: {friendly} mancante", "Verifica necessità nel tuo caso")

    if "usesCleartextTraffic" in manifest_main or "usesCleartextTraffic" in manifest_debug:
        r.add(PASS, "Manifest cleartextTraffic attivo (debug http locale)", "OK")
    else:
        r.add(WARN, "cleartextTraffic non dichiarato", "Serve se usi backend http locale")

    # ----------------------------------------------------------
    # 11) Reachability backend
    # ----------------------------------------------------------
    if env_real.exists() and app_env.get("API_BASE_URL"):
        api_base = app_env["API_BASE_URL"].rstrip("/")
        if is_url(api_base) and not is_placeholder(api_base):
            code, body = http_get(f"{api_base}/api/health")
            if code == 200:
                r.add(PASS, "Reachability backend /api/health", "OK")
            elif code == 0:
                r.add(WARN, "Backend non raggiungibile ora", f"Errore di rete: {body[:120]}")
            else:
                r.add(WARN, f"Backend risponde con HTTP {code}", body[:160])

    r.print()
    return 1 if r.failed else 0


if __name__ == "__main__":
    sys.exit(main())