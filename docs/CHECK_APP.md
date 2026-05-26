# CHECK APP (Flutter/Android)

Guida rapida per verificare configurazione e collegamenti dell'app.

## 1) Posizionati nella root del repo app

```bash
cd Banking_App
```

## 2) Verifica script check presente

```bash
ls check_test.py
```

## 3) Verifica base (struttura + env + wiring + manifest)

```bash
python check_test.py
```

## 4) Check con reachability backend (facoltativo)

Se hai già `.env` con `API_BASE_URL` valido, lo script proverà anche `/api/health` automaticamente.

Esempio `.env`:

```dotenv
API_BASE_URL=[https://abc12345.ngrok-free.app]
```

Poi rilancia:

```bash
python check_test.py
```

## 5) Interpretazione risultato

- `PASS` = controllo superato
- `WARN` = non bloccante ma da verificare
- `FAIL` = errore bloccante, da correggere prima del test app

## 6) Errori comuni

- `.env` mancante o `API_BASE_URL` placeholder
- `main.dart` non carica `.env`
- Manifest senza permessi rete/camera/NFC
- endpoint mancanti in `api_service.dart`