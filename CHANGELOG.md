# Changelog / Registro delle modifiche

Tutte le modifiche significative a **WebBridge Desktop** saranno documentate in questo file.  
All notable changes to **WebBridge Desktop** will be documented in this file.

Il progetto segue il formato [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) e utilizza versioni in stile [Semantic Versioning](https://semver.org/).  
This project follows the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format and uses [Semantic Versioning](https://semver.org/)-style version numbers.

> **Nota / Note:** La versione **1.0.3** è la prima release pubblica di WebBridge Desktop. Le versioni precedenti appartengono allo sviluppo locale del progetto derivato e non sono documentate qui come release pubbliche.
>
> **1.0.3** is the first public WebBridge Desktop release. Earlier versions were part of local development of the derivative project and are not listed here as public releases.

## [Unreleased] / Non ancora rilasciato

### Italiano
- Nessuna modifica annunciata per la prossima versione.

### English
- No changes announced for the next release.

## [1.0.3] — 2026-10-18

### Italiano

#### Aggiunto
- Prima distribuzione pubblica con il nome **WebBridge Desktop** e un'icona originale.
- Pacchetto **DEB per Linux amd64** e distribuzione tramite repository **APT firmato con GPG**.
- Supporto per l'apertura di conversazioni mediante link compatibili (`wa.me`, URL di invio di WhatsApp e protocollo `whatsapp://`).
- Supporto alla condivisione di testo e collegamenti **senza destinatario predefinito**, con scelta del contatto in WhatsApp Web.
- Gestore ausiliario dei collegamenti HTTPS; l'associazione ai collegamenti HTTP/HTTPS è **facoltativa**, non automatica.
- Profilo applicativo separato in `~/.config/webbridge-desktop`.
- Integrazione con il menu delle applicazioni e con il launcher di Ubuntu/GNOME.

#### Sicurezza
- Configurazione Electron con isolamento del contesto, integrazione Node disattivata nel renderer e sandbox abilitata.
- Verificata sui renderer Linux l'attivazione di `NoNewPrivs` e dei filtri Seccomp.
- Gestione restrittiva dei permessi; accesso a microfono e videocamera subordinato a conferma.

#### Documentazione e riconoscimenti
- Documentazione del progetto, istruzioni d'installazione e script di manutenzione.
- Attribuzione al progetto originale di **Himel Rana** e conservazione dell'avviso di licenza applicabile.
- Dichiarazione esplicita che WebBridge Desktop è **non ufficiale** e non affiliato a WhatsApp o Meta.

### English

#### Added
- First public distribution under the **WebBridge Desktop** name, with an original app icon.
- **Linux amd64 DEB** package and a **GPG-signed APT** distribution repository.
- Direct conversation opening through supported links (`wa.me`, WhatsApp send URLs and `whatsapp://`).
- Text and link sharing **without a predefined recipient**, allowing recipient selection in WhatsApp Web.
- Optional HTTPS link handler; HTTP/HTTPS association is **not enabled automatically**.
- Separate application profile at `~/.config/webbridge-desktop`.
- Ubuntu/GNOME application launcher integration.

#### Security
- Electron configuration with context isolation, Node integration disabled in the renderer, and sandbox enabled.
- Linux renderer checks confirmed `NoNewPrivs` and Seccomp filtering.
- Restrictive permission handling; microphone and camera requests require confirmation.

#### Documentation and credits
- Project documentation, installation instructions and maintenance scripts.
- Credit to the original project by **Himel Rana**, with retention of the applicable license notice.
- Explicit statement that WebBridge Desktop is **unofficial** and not affiliated with WhatsApp or Meta.

[1.0.3]: https://github.com/FOcculto/webbridge-desktop/releases/tag/v1.0.3
[Unreleased]: https://github.com/FOcculto/webbridge-desktop/compare/v1.0.3...main
