<div align="center">

# WebBridge Desktop

**Client desktop non ufficiale per WhatsApp Web su Linux**  
**Unofficial WhatsApp Web desktop client for Linux**

![WebBridge Desktop icon](icon.png)

[🇮🇹 Italiano](#italiano) · [🇬🇧 English](#english) · [Download v1.0.3](https://github.com/FOcculto/webbridge-desktop/releases/tag/v1.0.3) · [APT repository](https://focculto.github.io/webbridge-desktop-apt/)

</div>

> **Disclaimer / Avvertenza** — WebBridge Desktop è un progetto indipendente e non ufficiale. Non è affiliato, sponsorizzato né approvato da WhatsApp o Meta. WhatsApp è un marchio del rispettivo titolare.

---

<a id="italiano"></a>
## 🇮🇹 Italiano

### Cos'è WebBridge Desktop?

WebBridge Desktop è un'applicazione Electron per utilizzare **WhatsApp Web** in una finestra desktop su Linux. Il progetto nasce da una versione modificata del [client open source di Himel Rana](https://github.com/Swe-HimelRana/whatsapp), con particolare attenzione all'integrazione con Ubuntu, alla gestione dei collegamenti e alla separazione del profilo utente.

Non implementa un protocollo WhatsApp indipendente: utilizza il servizio web di WhatsApp, la cui disponibilità e il cui funzionamento dipendono dal fornitore del servizio.

### Funzionalità — v1.0.3

- Applicazione desktop per Linux basata su Electron.
- Profilo separato in `~/.config/webbridge-desktop`.
- Apertura diretta delle conversazioni tramite URL supportati (ad esempio `https://wa.me/<numero>`).
- Condivisione di testo e collegamenti, con scelta del destinatario in WhatsApp Web.
- Integrazione con il protocollo `whatsapp://` e con il desktop Linux.
- Gestore separato e **opzionale** per i collegamenti HTTPS: non è necessario cambiare il browser predefinito per utilizzare l'app.
- Renderer Electron con sandbox attiva, verificata su Ubuntu durante i test della versione 1.0.3.
- Distribuzione DEB per architettura **amd64**, anche tramite repository APT firmato.

### Installazione

#### Opzione A — Scaricare il DEB

1. Apri la pagina [GitHub Releases](https://github.com/FOcculto/webbridge-desktop/releases/tag/v1.0.3).
2. Scarica `webbridge-desktop_1.0.3_amd64.deb`.
3. Nella cartella del download esegui:

```bash
sudo apt install ./webbridge-desktop_1.0.3_amd64.deb
```

#### Opzione B — Repository APT firmato (consigliato per gli aggiornamenti)

La chiave pubblica del repository deve corrispondere a questa impronta, pubblicata qui come riferimento indipendente:

```text
839E 76D2 1EA7 DB10 A25E F112 EE6E 5C3C D04D 64D5
```

Scarica e controlla la chiave, quindi configura APT:

```bash
curl -fsSLo /tmp/webbridge-desktop.gpg \
  https://focculto.github.io/webbridge-desktop-apt/whatsapp-custom.gpg

gpg --show-keys --fingerprint /tmp/webbridge-desktop.gpg
```

**Confronta l'impronta mostrata con quella riportata sopra prima di proseguire.**

```bash
sudo install -d -m 755 /etc/apt/keyrings
sudo install -m 644 /tmp/webbridge-desktop.gpg \
  /etc/apt/keyrings/webbridge-desktop.gpg

sudo tee /etc/apt/sources.list.d/webbridge-desktop.sources >/dev/null <<'SOURCES'
Types: deb
URIs: https://focculto.github.io/webbridge-desktop-apt/
Suites: ./
Signed-By: /etc/apt/keyrings/webbridge-desktop.gpg
SOURCES

sudo apt update
sudo apt install webbridge-desktop
```

La configurazione `Signed-By` limita l'uso della chiave a questo repository. I pacchetti verranno aggiornati tramite i normali comandi APT.

### Esempi d'uso

```bash
# Apri una conversazione (sostituisci il segnaposto)
webbridge-desktop 'https://wa.me/393XXXXXXXXX'

# Condividi un testo e scegli il destinatario
webbridge-desktop 'whatsapp://send?text=Ciao%20da%20WebBridge'
```

Per l'uso del gestore HTTPS facoltativo consulta [INSTALLATION.md](INSTALLATION.md), quando disponibile nella versione pubblicata. L'associazione globale degli URL `http` e `https` non viene richiesta dall'installazione standard.

### Sicurezza e privacy

WebBridge Desktop carica WhatsApp Web in Electron. Nei test della versione 1.0.3, i processi renderer hanno mostrato `NoNewPrivs: 1`, `Seccomp: 2` e un filtro Seccomp attivo. Questo indica l'applicazione di protezioni a livello di processo, **non** una garanzia assoluta di sicurezza.

Il profilo applicativo è memorizzato localmente in `~/.config/webbridge-desktop`: può contenere dati di sessione, quindi **non va condiviso** né pubblicato su GitHub. Il progetto non richiede agli utenti di comunicare password o codici di autenticazione al manutentore.

### Aggiornamento e rimozione

```bash
sudo apt update && sudo apt upgrade
```

Per disinstallare l'applicazione:

```bash
sudo apt remove webbridge-desktop
```

Per eliminare anche il repository APT, rimuovi manualmente `/etc/apt/sources.list.d/webbridge-desktop.sources` e `/etc/apt/keyrings/webbridge-desktop.gpg`, poi esegui `sudo apt update`. La rimozione del pacchetto non implica la cancellazione del profilo personale.

### Sviluppo

Per compilare dai sorgenti è necessario un ambiente Node.js/npm compatibile con le versioni dichiarate dal progetto.

```bash
git clone https://github.com/FOcculto/webbridge-desktop.git
cd webbridge-desktop
npm ci
npx electron-builder --linux deb --x64 --config build-deb.json
```

L'output è prodotto nella directory `dist-custom/`. Prima di pubblicare modifiche, verifica la licenza e controlla che non siano inclusi file sensibili.

### Schermate

Le schermate dell'applicazione saranno aggiunte dopo una revisione per evitare di mostrare contatti, messaggi o altre informazioni personali.

---

<a id="english"></a>
## 🇬🇧 English

### About

WebBridge Desktop is an independent Electron application providing **WhatsApp Web** in a Linux desktop window. It is based on a modified version of [Himel Rana's open-source client](https://github.com/Swe-HimelRana/whatsapp), with improvements to Linux desktop integration, URL handling, sharing, and profile isolation.

It is **not** a separate WhatsApp protocol implementation. Service availability and behavior depend on WhatsApp Web.

### Features — v1.0.3

- Electron-based desktop application for Linux.
- Independent user profile at `~/.config/webbridge-desktop`.
- Direct chat opening using supported URLs such as `https://wa.me/<number>`.
- Text and link sharing with recipient selection in WhatsApp Web.
- `whatsapp://` URL protocol support and desktop integration.
- Optional HTTPS link handler; installing the app does not require replacing your default browser.
- Electron renderer sandbox enabled and checked during Ubuntu testing.
- Signed APT repository and amd64 Debian package.

### Installation

**Direct download:** get `webbridge-desktop_1.0.3_amd64.deb` from [GitHub Releases](https://github.com/FOcculto/webbridge-desktop/releases/tag/v1.0.3), then run:

```bash
sudo apt install ./webbridge-desktop_1.0.3_amd64.deb
```

**APT repository:** follow the commands in the [Italian APT installation section](#installazione). The signing key fingerprint is:

```text
839E 76D2 1EA7 DB10 A25E F112 EE6E 5C3C D04D 64D5
```

Verify the fingerprint before trusting the key. `Signed-By` scopes it to this repository.

### Usage

```bash
webbridge-desktop 'https://wa.me/393XXXXXXXXX'
webbridge-desktop 'whatsapp://send?text=Hello%20from%20WebBridge'
```

### Security and privacy

The Electron renderer processes showed active process-level sandbox protections in testing (`NoNewPrivs: 1`, `Seccomp: 2`). This is not a guarantee against every vulnerability. Authentication and session data live in the user's local profile, which should never be shared. No credentials should be sent to the maintainer.

### Updates and removal

```bash
sudo apt update && sudo apt upgrade
sudo apt remove webbridge-desktop
```

Removing the application does not automatically erase the local user profile. If you installed the APT source, its `.sources` and keyring files can be removed separately.

### Build from source

```bash
git clone https://github.com/FOcculto/webbridge-desktop.git
cd webbridge-desktop
npm ci
npx electron-builder --linux deb --x64 --config build-deb.json
```

### Screenshots

Screenshots will be published after checking that they do not reveal personal chats, contacts, or other private data.

---

## Credits, license & trademark notice / Riconoscimenti, licenza e marchi

- **Original project / Progetto originale:** [Himel Rana — WhatsApp Linux client](https://github.com/Swe-HimelRana/whatsapp).
- **Modified project maintainer / Manutentore versione modificata:** [FOcculto](https://github.com/FOcculto).
- **License / Licenza:** MIT — see [LICENSE](LICENSE) for the applicable copyright notices and license terms.
- **Trademark notice / Nota sui marchi:** WhatsApp and Meta are trademarks of their respective owners. WebBridge Desktop is independent and **not affiliated with, endorsed by, or sponsored by Meta or WhatsApp**.

## Links

- [Source code / Sorgenti](https://github.com/FOcculto/webbridge-desktop)
- [GitHub Releases](https://github.com/FOcculto/webbridge-desktop/releases)
- [Signed APT repository / Repository APT firmato](https://focculto.github.io/webbridge-desktop-apt/)
- [Report a problem / Segnala un problema](https://github.com/FOcculto/webbridge-desktop/issues)


---

## Cronologia delle versioni / Version history

### Versione 1.0.3 — 18 ottobre 2026

Prima release pubblica di WebBridge Desktop.

Funzionalità principali:
- Client desktop Linux per WhatsApp Web.
- Sandbox Electron attiva.
- Profilo utente indipendente.
- Apertura diretta delle conversazioni.
- Condivisione di testi e collegamenti.
- Integrazione con `xdg-open`.
- Distribuzione tramite repository APT firmato.

**Cronologia completa:** [CHANGELOG.md](CHANGELOG.md)

### Version 1.0.3 — October 18, 2026

First public release of WebBridge Desktop.

Main features:
- Linux desktop client for WhatsApp Web.
- Electron sandbox enabled.
- Independent user profile.
- Direct conversation opening.
- Text and link sharing.
- `xdg-open` integration.
- Distribution through a signed APT repository.

**Full version history:** [CHANGELOG.md](CHANGELOG.md)
