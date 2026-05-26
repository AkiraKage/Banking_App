# Setup Android App (Flutter + FVM)

## 1) Prerequisiti OS e FVM

- Android Studio installato (con Android SDK)
- Emulator Android configurato **oppure** device reale con USB debug attivo

A seconda del tuo sistema operativo, installa FVM (Flutter Version Management) tramite il gestore di
pacchetti per avere l'eseguibile pronto all'uso senza dover configurare manualmente il `PATH`.

### Arch Linux

```bash
paru -S fvm
```

### macOS

```bash
brew tap leoafarias/fvm
brew install fvm
```

Verifica l'installazione (valido per entrambi):

```bash
fvm --version
```

---

## 2) Installa Flutter con FVM

In questo progetto la versione è definita all'interno del file `.fvmrc` (es. `stable`). Spostati
nella cartella del progetto per permettere a FVM di leggere il file e scaricare l'SDK corretto.

```bash
cd Banking_App/
fvm install
```

> **Nota:** Non serve installare Flutter globalmente fuori da FVM. FVM gestirà la versione in modo
> isolato per questa directory.

Verifica che l'SDK sia stato scaricato correttamente:

```bash
fvm flutter --version
fvm doctor
```

## 3) Configura `.env` app (unico file)

Assicurati di essere nella root `Banking_App/` ed esegui:

```bash
cp .env.example .env
```

Apri `.env` e imposta:

```dotenv
API_BASE_URL=https://<TUO_DOMINIO_NGROK>
```

Esempio:

```dotenv
API_BASE_URL=</TUO_DOMINIO_NGROK>
```

> Se il dominio ngrok cambia (es. riavvio della versione free), aggiorni solo questo campo e riavvii
> l'app.

## 4) Dipendenze

```bash
fvm flutter clean 
fvm flutter pub get
```

## 5) Avvio app

Con l'emulatore Android aperto o il dispositivo fisico collegato:

```bash
fvm flutter run
```

## 6) Test rapido

- Login con utente seed (`mario.rossi` / `password123`)
- Home mostra saldo backend
- Bonifico / QR / NFC aggiornano Home automaticamente (refresh cross-tab)

