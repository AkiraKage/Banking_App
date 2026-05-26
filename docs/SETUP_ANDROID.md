# Setup Android App (Flutter)

## 1) Prerequisiti

- Flutter SDK installato
- Android Studio configurato
- Emulator Android o device reale

## 2) Configura `.env` app (unico file)

Nella root `Banking_App/`:

```
cp .env.example .env
```

Apri `.env` e imposta:

```
dotenv API_BASE_URL=https://<TUO_DOMINIO_NGROK>
``` 

Esempio:

```
dotenv API_BASE_URL=https://abc12345.ngrok-free.app
```

> Se il dominio ngrok cambia, aggiorni solo questo campo.

## 3) Dipendenze

```
flutter clean flutter pub get
``` 

## 4) Avvio app

```
flutter run
```

## 5) Test rapido

- Login con utente seed (`mario.rossi` / `password123`)
- Home mostra saldo backend
- Bonifico / QR / NFC aggiornano Home automaticamente (refresh cross-tab)
