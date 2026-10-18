#!/usr/bin/env bash
# WebBridge Desktop — prepare a signed APT release (does not push to GitHub)
set -Eeuo pipefail

usage() {
  cat <<'HELP'
Usage: ./release.sh VERSION
Example: ./release.sh 1.0.4

Run from the WebBridge Desktop source repository. The APT repository is
expected in ../whatsapp-custom-apt (override with APT_REPO_DIR).
This script updates the source version, builds a DEB, checks metadata,
refreshes signed APT indexes and stages (but does not commit/push) changes.

Before running: commit outstanding source and APT changes, and ensure your
GPG signing key exists. No private keys are copied into the repository.
HELP
}

if [[ $# -ne 1 || "${1:-}" == --help || "${1:-}" == -h ]]; then usage; [[ "${1:-}" == --help || "${1:-}" == -h ]] && exit 0 || exit 2; fi
VERSION=$1
if [[ ! $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "ERROR: VERSION must look like 1.0.4" >&2; exit 2
fi

SOURCE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
APT_REPO_DIR=${APT_REPO_DIR:-"$(dirname "$SOURCE_DIR")/whatsapp-custom-apt"}
APT_REPO_DIR=$(cd -- "$APT_REPO_DIR" && pwd -P)
DOCS_DIR="$APT_REPO_DIR/docs"
KEY_FINGERPRINT=${WEBBRIDGE_GPG_KEY:-839E76D21EA7DB10A25EF112EE6E5C3CD04D64D5}

for tool in git npm npx node python3 dpkg-deb apt-ftparchive gzip gpg sha256sum; do
  command -v "$tool" >/dev/null || { echo "ERROR: missing $tool" >&2; exit 1; }
done
[[ -f "$SOURCE_DIR/build-deb.json" && -f "$SOURCE_DIR/package.json" && -f "$SOURCE_DIR/LICENSE" ]] || {
  echo 'ERROR: source project/config/license missing' >&2; exit 1;
}
[[ -d "$DOCS_DIR/pool/main" && -f "$DOCS_DIR/.nojekyll" ]] || {
  echo "ERROR: APT directory is not ready: $DOCS_DIR" >&2; exit 1;
}
for repo in "$SOURCE_DIR" "$APT_REPO_DIR"; do
  git -C "$repo" rev-parse --is-inside-work-tree >/dev/null || { echo "ERROR: $repo is not a Git checkout" >&2; exit 1; }
  if [[ -n $(git -C "$repo" status --porcelain) ]]; then
    echo "ERROR: uncommitted changes in $repo. Commit/stash before running." >&2; exit 1
  fi
done

if ! gpg --list-secret-keys --with-colons "$KEY_FINGERPRINT" 2>/dev/null | grep -q '^sec:'; then
  echo "ERROR: signing key not found: $KEY_FINGERPRINT" >&2; exit 1
fi

cd "$SOURCE_DIR"
CURRENT=$(node -p 'require("./package.json").version')
if [[ $CURRENT == "$VERSION" ]]; then
  echo "ERROR: requested version equals current version ($CURRENT)" >&2; exit 1
fi
printf 'Source version: %s -> %s\nAPT repo: %s\n' "$CURRENT" "$VERSION" "$APT_REPO_DIR"

# Bump package.json and package-lock.json together; refuse scripts/network installs.
npm version "$VERSION" --no-git-tag-version --ignore-scripts
npm ci --ignore-scripts
node --check main.js
python3 -m py_compile resources/whatsapp-link-handler.py
npx electron-builder --linux deb --x64 --config build-deb.json
DEB="$SOURCE_DIR/dist-custom/webbridge-desktop_${VERSION}_amd64.deb"
[[ -s "$DEB" ]] || { echo "ERROR: DEB missing: $DEB" >&2; exit 1; }

metadata=$(dpkg-deb -f "$DEB" Package Version Architecture)
expected=$(printf 'webbridge-desktop\n%s\namd64' "$VERSION")
[[ "$metadata" == "$expected" ]] || {
  echo "ERROR: unexpected DEB metadata:" >&2; printf '%s\n' "$metadata" >&2; exit 1
}

# Ensure runtime files exist and license is included inside app.asar.
if ! dpkg-deb -c "$DEB" | grep -F 'whatsapp-link-handler.py' >/dev/null; then
  echo 'ERROR: link handler missing in DEB' >&2; exit 1
fi
if [[ ! -f "$SOURCE_DIR/dist-custom/linux-unpacked/resources/app.asar" ]]; then
  echo 'ERROR: app.asar not found' >&2; exit 1
fi
# The archive listing is saved first to avoid pipe/SIGPIPE surprises.
ASAR_LIST=$(mktemp)
trap 'rm -f "$ASAR_LIST"' EXIT
npx --yes --package=@electron/asar asar list "$SOURCE_DIR/dist-custom/linux-unpacked/resources/app.asar" > "$ASAR_LIST"
if ! grep -qx '/LICENSE' "$ASAR_LIST"; then
  echo 'ERROR: LICENSE missing from app.asar' >&2; exit 1
fi

# Check the repository contains just this one DEB and never publish stale indexes.
mapfile -t existing_debs < <(find "$DOCS_DIR/pool/main" -maxdepth 1 -type f -name '*.deb' -print)
for old in "${existing_debs[@]}"; do rm -f -- "$old"; done
cp -- "$DEB" "$DOCS_DIR/pool/main/"
cd "$DOCS_DIR"
apt-ftparchive packages pool/ > Packages.new
mv -- Packages.new Packages
gzip -n -9 -c Packages > Packages.gz.new
mv -- Packages.gz.new Packages.gz
apt-ftparchive \
  -o APT::FTPArchive::Release::Origin='WebBridge Desktop' \
  -o APT::FTPArchive::Release::Label='WebBridge Desktop APT' \
  -o APT::FTPArchive::Release::Suite=stable \
  -o APT::FTPArchive::Release::Codename=stable \
  -o APT::FTPArchive::Release::Architectures=amd64 \
  release . > Release.new
mv -- Release.new Release

gpg --local-user "$KEY_FINGERPRINT" --yes --output InRelease --clearsign Release
gpg --local-user "$KEY_FINGERPRINT" --yes --armor --output Release.gpg --detach-sign Release

# Verify signatures and the package hash stored in Packages.
gpgv --keyring "$DOCS_DIR/whatsapp-custom.gpg" "$DOCS_DIR/InRelease"
gpgv --keyring "$DOCS_DIR/whatsapp-custom.gpg" "$DOCS_DIR/Release.gpg" "$DOCS_DIR/Release"
actual_sha=$(sha256sum "$DOCS_DIR/pool/main/$(basename "$DEB")" | awk '{print $1}')
indexed_sha=$(awk '$1=="SHA256:" {print $2; exit}' Packages)
[[ "$actual_sha" == "$indexed_sha" ]] || { echo 'ERROR: SHA256 mismatch' >&2; exit 1; }

printf '\nPrepared release %s — NOT published.\n' "$VERSION"
printf '\nSource changes:\n'
git -C "$SOURCE_DIR" status --short
printf '\nAPT changes:\n'
git -C "$APT_REPO_DIR" status --short
cat <<'NEXT'

NEXT — only after manual verification of the generated DEB:
  cd SOURCE_DIR
  git add package.json package-lock.json
  git commit -m "Release VERSION"
  git push origin main

  cd APT_REPO_DIR
  git add docs/
  git commit -m "Publish WebBridge VERSION"
  git push origin main

Review the Git diffs before committing. GitHub Pages will update after the
APT push. Do not publish if the DEB fails functional testing.
NEXT
