'use strict';

const {
  app,
  BrowserWindow,
  Menu,
  dialog,
  shell,
  session
} = require('electron');

const { URL } = require('node:url');

const HOME_URL = 'https://web.whatsapp.com/';
const USER_AGENT =
  'Mozilla/5.0 (X11; Linux x86_64) ' +
  'AppleWebKit/537.36 (KHTML, like Gecko) ' +
  'Chrome/124.0.0.0 Safari/537.36';

let mainWindow = null;
let pendingURL = null;


// --------------------------------------------------
// 1. VALIDAZIONE DEI COLLEGAMENTI WHATSAPP
// --------------------------------------------------


function whatsappURL(value) {
  if (typeof value !== 'string') return null;

  if (!/^(https:\/\/|whatsapp:\/\/)/i.test(value)) {
    return null;
  }

  try {
    const url = new URL(value);

    let phone = null;
    let recognized = false;

    if (url.protocol === 'https:') {

      if (['wa.me', 'www.wa.me'].includes(url.hostname)) {
        if (url.username || url.password || url.port) return null;

        const parts = url.pathname.split('/').filter(Boolean);
        if (parts.length > 1) return null;

        phone = parts[0] || null;
        recognized = true;

      } else if (
        ['api.whatsapp.com',
         'www.whatsapp.com',
         'web.whatsapp.com'].includes(url.hostname) &&
        url.pathname === '/send'
      ) {
        if (url.username || url.password || url.port) return null;

        phone = url.searchParams.get('phone');
        recognized = true;
      }

    } else if (
      url.protocol === 'whatsapp:' &&
      url.hostname === 'send' &&
      (url.pathname === '' || url.pathname === '/')
    ) {
      phone = url.searchParams.get('phone');
      recognized = true;
    }

    if (!recognized) return null;

    const message = url.searchParams.get('text');

    if (phone) {
      phone = phone.replace(/^\+/, '');

      if (!/^[0-9]{5,15}$/.test(phone)) {
        return null;
      }
    }

    // Limita la dimensione dei contenuti ricevuti.
    if (message !== null && message.length > 16000) {
      return null;
    }

    // Deve esistere almeno un numero o un messaggio.
    if (!phone && !message) {
      return null;
    }

    const target = new URL('https://web.whatsapp.com/send');

    if (phone) {
      target.searchParams.set('phone', phone);
    }

    if (message) {
      target.searchParams.set('text', message);
    }

    return target.href;

  } catch {
    return null;
  }
}

function findWhatsAppURL(args) {
  for (const arg of args) {
    const result = whatsappURL(arg);
    if (result) return result;
  }

  return null;
}


// --------------------------------------------------
// 3. CONTROLLO DELLA NAVIGAZIONE
// --------------------------------------------------

function isWhatsAppWeb(value) {
  try {
    const url = new URL(value);

    return (
      url.protocol === 'https:' &&
      url.hostname === 'web.whatsapp.com'
    );

  } catch {
    return false;
  }
}


function openExternalSafely(value) {
  try {
    const url = new URL(value);

    if (
      url.protocol === 'https:' ||
      url.protocol === 'http:'
    ) {
      shell.openExternal(url.href).catch(console.error);
    }

  } catch {
    // URL non valido: non aprire nulla.
  }
}


// --------------------------------------------------
// 4. MENU CONTESTUALE
// --------------------------------------------------

function setupContextMenu(win) {

  win.webContents.on('context-menu', (event, params) => {

    const menu = Menu.buildFromTemplate([
      { role: 'copy' },
      { role: 'cut' },
      { role: 'paste' },
      { role: 'selectAll' },
      { type: 'separator' },
      { role: 'reload' }
    ]);

    menu.popup({ window: win });
  });
}


// --------------------------------------------------
// 5. CREAZIONE FINESTRA PRINCIPALE
// --------------------------------------------------

function createWindow() {

  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    minWidth: 700,
    minHeight: 500,
    autoHideMenuBar: true,
    frame: true,

    webPreferences: {
      nodeIntegration: false,
      nodeIntegrationInSubFrames: false,
      contextIsolation: true,
      sandbox: true,
      webSecurity: true,
      webviewTag: false
    }
  });


  // Impedisce la creazione di finestre non autorizzate.
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {

    if (!isWhatsAppWeb(url)) {
      openExternalSafely(url);
    }

    return { action: 'deny' };
  });


  // Impedisce la navigazione verso siti esterni.
  mainWindow.webContents.on('will-navigate', (event, url) => {

    if (!isWhatsAppWeb(url)) {
      event.preventDefault();
      openExternalSafely(url);
    }
  });


  // Blocca i reindirizzamenti verso altri domini.
  mainWindow.webContents.on(
    'will-redirect',
    (event, url) => {
      if (!isWhatsAppWeb(url)) {
        event.preventDefault();
      }
    }
  );


  // Ripristina il menu contestuale.
  setupContextMenu(mainWindow);


  // Caricamento iniziale.
  const initialURL = pendingURL || HOME_URL;
  pendingURL = null;

  mainWindow.loadURL(initialURL, {
    userAgent: USER_AGENT
  }).catch(console.error);


  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}


// --------------------------------------------------
// 6. APERTURA DELLE CONVERSAZIONI
// --------------------------------------------------

function openConversation(args) {

  const url = findWhatsAppURL(args);

  if (!url) return;

  if (!mainWindow) {
    pendingURL = url;
    return;
  }

  if (mainWindow.isMinimized()) {
    mainWindow.restore();
  }

  mainWindow.show();
  mainWindow.focus();

  mainWindow.loadURL(url).catch(console.error);
}


// --------------------------------------------------
// 7. ISTANZA UNICA
// --------------------------------------------------


// Mantiene il profilo WhatsApp esistente anche nel DEB.
const profilePath = require('node:path').join(
  app.getPath('appData'),
  'webbridge-desktop'
);

app.setPath('userData', profilePath);

const gotTheLock = app.requestSingleInstanceLock();

if (!gotTheLock) {

  app.quit();

} else {

  pendingURL = findWhatsAppURL(process.argv);

  app.on('second-instance', (event, commandLine) => {
    openConversation(commandLine);
  });


  app.whenReady().then(() => {


    // Permessi validi esclusivamente durante questa esecuzione.
    let mediaAllowed = false;

    const trustedOrigin = (value) => {
      try {
        return new URL(value).origin === 'https://web.whatsapp.com';
      } catch {
        return false;
      }
    };

    const ses = session.defaultSession;

    // Controllo dei permessi.
    ses.setPermissionCheckHandler(
      (webContents, permission, requestingOrigin, details) => {

        if (!trustedOrigin(requestingOrigin)) {
          return false;
        }

        if (permission === 'notifications') {
          return true;
        }

        if (permission === 'clipboard-sanitized-write') {
          return true;
        }

        if (permission === 'media') {
          return mediaAllowed;
        }

        return false;
      }
    );

    // Richieste esplicite di autorizzazione.
    ses.setPermissionRequestHandler(
      async (webContents, permission, callback, details) => {

        const origin = details.requestingUrl ||
                       webContents.getURL();

        if (
          !trustedOrigin(origin) ||
          webContents !== mainWindow?.webContents
        ) {
          callback(false);
          return;
        }

        if (
          permission === 'notifications' ||
          permission === 'clipboard-sanitized-write'
        ) {
          callback(true);
          return;
        }

        if (permission === 'media') {

          const types = details.mediaTypes || [];

          const audio = types.includes('audio');
          const video = types.includes('video');

          // Non autorizzare dispositivi sconosciuti.
          if (!audio && !video) {
            callback(false);
            return;
          }

          let message = 'WhatsApp richiede accesso a ';

          if (audio && video) {
            message += 'microfono e webcam.';
          } else if (audio) {
            message += 'microfono.';
          } else {
            message += 'webcam.';
          }

          try {
            const result = await dialog.showMessageBox(
              mainWindow,
              {
                type: 'question',
                title: 'Permessi WhatsApp',
                message,
                detail:
                  'Vuoi autorizzare questa richiesta? ' +
                  'Il permesso non sarà salvato permanentemente.',
                buttons: ['Nega', 'Autorizza'],
                defaultId: 0,
                cancelId: 0,
                noLink: true
              }
            );

            const allowed = result.response === 1;

            if (allowed) {
              mediaAllowed = true;
            }

            callback(allowed);

          } catch (error) {
            console.error(
              '[Permissions] Errore:',
              error.message
            );
            callback(false);
          }

          return;
        }

        // Qualsiasi altro permesso viene negato.
        callback(false);
      }
    );

    createWindow();
  });


  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });


  app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
      app.quit();
    }
  });
}
