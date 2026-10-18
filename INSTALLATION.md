# WebBridge Desktop — installazione su Ubuntu / Debian

WebBridge Desktop è un client Linux **non ufficiale** per WhatsApp Web, non affiliato a Meta o WhatsApp.

Repository dei sorgenti: https://github.com/FOcculto/webbridge-desktop
Repository APT: https://github.com/FOcculto/webbridge-desktop-apt

## Requisiti

- Ubuntu/Debian o derivata compatibile; attualmente solo **amd64**.
- `curl`, `gnupg`, `sudo` e `apt` installati.
- Connessione HTTPS e accesso a GitHub Pages.

## Installazione consigliata

Scarica e **leggi** `install.sh` dal repository dei sorgenti, poi eseguilo come utente normale:

```bash
chmod +x install.sh
./install.sh
```

Lo script scarica la chiave GPG via HTTPS, ne verifica l'impronta primaria
`839E76D21EA7DB10A25EF112EE6E5C3CD04D64D5`, la registra esclusivamente
per il repository WebBridge attraverso `Signed-By`, aggiorna APT e installa
`webbridge-desktop`. Non modifica il browser predefinito né il gestore HTTPS.

## Installazione manuale

```bash
sudo install -d -m 755 /etc/apt/keyrings
curl -fsSL https://focculto.github.io/webbridge-desktop-apt/whatsapp-custom.gpg -o /tmp/webbridge-desktop.gpg
gpg --show-keys --fingerprint /tmp/webbridge-desktop.gpg
# Confronta l'impronta visualizzata con quella indicata sopra.
sudo install -m 644 /tmp/webbridge-desktop.gpg /etc/apt/keyrings/webbridge-desktop.gpg
printf '%s\n' \
  'Types: deb' \
  'URIs: https://focculto.github.io/webbridge-desktop-apt/' \
  'Suites: ./' \
  'Architectures: amd64' \
  'Signed-By: /etc/apt/keyrings/webbridge-desktop.gpg' \
  | sudo tee /etc/apt/sources.list.d/webbridge-desktop.sources >/dev/null
sudo apt update
sudo apt install webbridge-desktop
```

## Aggiornamenti

```bash
sudo apt update && sudo apt upgrade
```

## Rimozione

```bash
sudo apt remove webbridge-desktop
sudo rm /etc/apt/sources.list.d/webbridge-desktop.sources
sudo rm /etc/apt/keyrings/webbridge-desktop.gpg
sudo apt update
```

Il profilo `~/.config/webbridge-desktop` rimane per evitare perdite involontarie di dati.

## Privacy e sicurezza

L'applicazione carica WhatsApp Web in Electron. L'uso del servizio dipende dalle condizioni di WhatsApp. La firma APT protegge l'autenticità degli indici ma non costituisce un audit di sicurezza dell'app.
