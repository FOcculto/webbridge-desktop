#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL='https://focculto.github.io/webbridge-desktop-apt'
KEY_URL="${REPO_URL}/whatsapp-custom.gpg"
EXPECTED_FINGERPRINT='839E76D21EA7DB10A25EF112EE6E5C3CD04D64D5'
KEYRING='/etc/apt/keyrings/webbridge-desktop.gpg'
SOURCES='/etc/apt/sources.list.d/webbridge-desktop.sources'

if [[ "$(id -u)" -eq 0 ]]; then
  echo 'Esegui questo script come utente normale, non con sudo.' >&2
  exit 1
fi
for cmd in curl gpg dpkg sudo apt-get install mktemp; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Comando necessario mancante: $cmd" >&2; exit 1; }
done

if [[ "$(dpkg --print-architecture)" != 'amd64' ]]; then
  echo 'Il repository pubblica attualmente solo pacchetti amd64.' >&2
  exit 1
fi

if [[ ! -f /etc/os-release ]]; then
  echo 'Impossibile identificare la distribuzione Linux.' >&2
  exit 1
fi
. /etc/os-release
if [[ "${ID:-}" != debian && "${ID:-}" != ubuntu && " ${ID_LIKE:-} " != *' debian '* && " ${ID_LIKE:-} " != *' ubuntu '* ]]; then
  echo 'Questo installer e destinato a distribuzioni basate su Debian/Ubuntu.' >&2
  exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

printf 'Scaricamento della chiave pubblica...\n'
curl --proto '=https' --tlsv1.2 --fail --location --silent --show-error \
  "$KEY_URL" --output "$tmpdir/repository.gpg"

# Validate the full fingerprint independently of the downloaded key's claims.
mapfile -t fingerprints < <(gpg --batch --quiet --show-keys --with-colons "$tmpdir/repository.gpg" \
  | awk -F: '$1 == "fpr" { print toupper($10) }')
if [[ "${#fingerprints[@]}" -ne 2 || "${fingerprints[0]}" != "$EXPECTED_FINGERPRINT" ]]; then
  # Primary key and its encryption subkey normally yield two fpr records.
  # We also accept a public export without the subkey.
  if [[ "${#fingerprints[@]}" -ne 1 || "${fingerprints[0]}" != "$EXPECTED_FINGERPRINT" ]]; then
    echo 'Impronta della chiave GPG diversa da quella attesa. Installazione interrotta.' >&2
    exit 1
  fi
fi
printf 'Chiave verificata: %s\n' "$EXPECTED_FINGERPRINT"

printf 'Configurazione del repository APT...\n'
sudo install -d -m 0755 /etc/apt/keyrings
sudo install -m 0644 "$tmpdir/repository.gpg" "$KEYRING"
cat > "$tmpdir/webbridge-desktop.sources" <<SOURCES_EOF
Types: deb
URIs: ${REPO_URL}/
Suites: ./
Architectures: amd64
Signed-By: ${KEYRING}
SOURCES_EOF
sudo install -m 0644 "$tmpdir/webbridge-desktop.sources" "$SOURCES"

printf 'Aggiornamento degli indici APT...\n'
sudo apt-get update
printf 'Installazione di WebBridge Desktop...\n'
sudo apt-get install webbridge-desktop
printf 'Installazione completata. Cerca "WebBridge Desktop" nel menu applicazioni.\n'
printf 'Le associazioni HTTPS e il browser predefinito non sono stati modificati.\n'
