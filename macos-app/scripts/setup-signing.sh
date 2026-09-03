#!/bin/sh
# One-time setup: creates a local, self-signed code-signing identity named
# "Overwatch Node Dev" so package_app.sh can sign the built .app with a
# stable identity instead of ad-hoc (`-`). A stable identity is what makes
# TCC permissions (Accessibility, Bluetooth, Automation) survive rebuilds —
# see package_app.sh's comments for the full reasoning.
#
# This is a *local* identity: it never leaves this machine, isn't checked
# into the repo, and grants no trust to anyone but you. Free, no Apple
# Developer Program needed.
#
# If this script fails or macOS still won't trust the result on your OS
# version, create the identity manually instead — see README.md's
# "Code-signing setup" section for the Keychain Access GUI steps.
set -e

IDENTITY_NAME="${SIGNING_IDENTITY:-Overwatch Node Dev}"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

# On some Macs the login keychain isn't actually in the user's keychain
# *search list* (distinct from it being the *default* keychain) — when
# that's the case, `security find-identity`/`codesign` silently never look
# inside it at all, even for a correctly created and trusted identity.
# `codesign` has no flag to point at a specific keychain file, so this has
# to be fixed at the search-list level, not worked around per-command.
# Confirmed happening on a real machine while building this script — fixing
# it unconditionally here (idempotent, standard practice for codesigning
# setup scripts) so nobody else has to rediscover it by hand.
CURRENT_SEARCH_LIST="$(security list-keychains -d user | sed 's/^[[:space:]]*"//;s/"$//')"
if ! printf '%s\n' "$CURRENT_SEARCH_LIST" | grep -qxF "$KEYCHAIN"; then
    echo "Your login keychain isn't in the keychain search list — adding it..."
    # shellcheck disable=SC2086
    security list-keychains -d user -s "$KEYCHAIN" $CURRENT_SEARCH_LIST
fi

if security find-identity -v -p codesigning 2>/dev/null | grep -q "$IDENTITY_NAME"; then
    echo "\"$IDENTITY_NAME\" already exists in your keychain — nothing to do."
    exit 0
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

echo "Generating a self-signed code-signing certificate..."
# Both extensions below are required — macOS's codesigning policy checks
# X509v3 Key Usage specifically (not just Extended Key Usage), and a cert
# missing it imports and trusts fine but still shows up as "Invalid Key
# Usage for policy" in `security find-identity -v`, unusable by codesign.
# Confirmed by diffing against a known-working manually-created identity.
openssl req -x509 -newkey rsa:2048 \
    -keyout "$WORKDIR/key.pem" -out "$WORKDIR/cert.pem" \
    -days 3650 -nodes -subj "/CN=$IDENTITY_NAME" \
    -addext "keyUsage=critical,digitalSignature" \
    -addext "extendedKeyUsage=critical,codeSigning" 2>/dev/null

# Two things here are required for macOS's Keychain to accept this .p12,
# both confirmed by testing against a throwaway keychain — either one
# alone still fails with "MAC verification failed during PKCS12 import":
#   1. Legacy PBE algorithms (SHA1+3DES / SHA1 MAC) via the "legacy"
#      OpenSSL provider — OpenSSL 3.x defaults to AES-256/SHA-256, which
#      macOS's (much older) PKCS12 parser can't read at all.
#   2. A non-empty passphrase — macOS's parser also fails MAC
#      verification on a *correctly* empty-password PKCS12, even with
#      legacy algorithms. The passphrase below is random, used only to
#      get the file from openssl to `security import`, and is discarded
#      with the rest of $WORKDIR when this script exits.
P12_PASS="$(openssl rand -base64 24)"
openssl pkcs12 -export -provider legacy -provider default \
    -inkey "$WORKDIR/key.pem" -in "$WORKDIR/cert.pem" \
    -out "$WORKDIR/cert.p12" -passout "pass:$P12_PASS" \
    -certpbe PBE-SHA1-3DES -keypbe PBE-SHA1-3DES -macalg SHA1

echo "Importing into your login keychain..."
security import "$WORKDIR/cert.p12" -k "$KEYCHAIN" -T /usr/bin/codesign -P "$P12_PASS"

echo "Trusting it for code signing (you may see a macOS confirmation prompt)..."
# trustRoot, not trustAsRoot — this cert genuinely is self-signed/a root
# (subject == issuer), and trustAsRoot is for the opposite case (trusting
# a non-root cert as if it were one). Using trustAsRoot here fails with
# "SecTrustSettingsSetTrustSettings: ...parameters...not valid" — confirmed
# by reproducing it against a throwaway cert before landing this fix.
security add-trusted-cert -r trustRoot -p codeSign -k "$KEYCHAIN" "$WORKDIR/cert.pem"

echo
echo "Done. \"$IDENTITY_NAME\" is ready."
echo "Verify with: security find-identity -v -p codesigning | grep \"$IDENTITY_NAME\""
echo "Then build with: ./run.sh"
