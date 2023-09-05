#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

KEY_LABEL="gpg"
SUBJECT="CN=Filip Zyzniewski"
TIMESTAMPER="date --iso-8601=ns"
LOG_PREFIXER='
  BEGIN {
    tscmd="'"$TIMESTAMPER"'"
  }
  {
    line=$0
    tscmd | getline
    close(tscmd)
    print $0 " " program ": " line
  }
'

log() {
  echo "$($TIMESTAMPER) gpg_setup_sign: $@" 1>&2
}

pcscd --foreground --debug 2>&1 |
awk -W interactive -v program=pcscd "$LOG_PREFIXER" &

log "waiting for the card to be available"

for i in $(seq 5)
do
  pkcs11-tool -L &>/dev/null && break
  sleep 1
done

log "information about the card"
pkcs11-tool -L

log "initializing the card"
sc-hsm-tool \
  --initialize \
  --label testcard \
  --so-pin 0123012301230123 \
  --pin 123456

KEY_ID="$(date +%s)"
log "generating a key pair"
pkcs11-tool \
  --login \
  --keypairgen \
  --key-type rsa:2048 \
  --label "$KEY_LABEL" \
  --id "$KEY_ID" \
  --always-auth

log "creating the certificate"

CERT_PEM="/tmp/cert-$KEY_ID.pem"
CERT_DER="/tmp/cert-$KEY_ID.der"

openssl req \
  -config /home/gpg/openssl-engine.conf \
  -engine pkcs11 \
  -new \
  -key 0:$KEY_ID \
  -keyform engine \
  -out "$CERT_PEM" \
  -text \
  -x509 \
  -days 3650 \
  -subj "/$SUBJECT/"

log "converting $CERT_PEM to $CERT_DER"

openssl x509 \
  -in "$CERT_PEM" \
  -outform der \
  -out "$CERT_DER"

log "writing the certificate to the card"

pkcs11-tool \
  --login \
  --write-object "$CERT_DER" \
  --type cert \
  --id "$KEY_ID" \
  --label "$KEY_LABEL"

mkfifo /tmp/gnupg-pkcs11-scd.log
awk -W interactive -v program= "$LOG_PREFIXER" /tmp/gnupg-pkcs11-scd.log &

mkfifo /tmp/gpg-agent.log
awk -W interactive -v program= "$LOG_PREFIXER" /tmp/gpg-agent.log &

log "looking up the key grip"
KEYGRIP="$(
  gpg-agent \
    --quiet \
    --server gpg-connect-agent \
    <<< "SCD LEARN" 2>/dev/null |
  awk '
    $1 == "S" &&
    $2 == "KEYPAIRINFO" &&
    $4 ~ "/'"$KEY_ID"'$" {
      print $3
    }'
)"

log "adding the key to GPG"
gpg --card-status
gpg \
  --verbose \
  --batch \
  --generate-key \
  <(sed "s:KEYGRIP:$KEYGRIP:" /home/gpg/gpg-generate-key.batch)

log "objects on the card"
pkcs11-tool --login --list-object

sleep 1
log "first signing of a message"
# this signing happens with a PIN prompt
gpg \
  --output /dev/null \
  --sign <($TIMESTAMPER)

sleep 1
log "second signing of a message"
# this signing happens without a PIN prompt
gpg \
  --output /dev/null \
  --sign <($TIMESTAMPER)

log "resetting the card"
scriptor <<< "reset"

sleep 1
log "third signing of a message"
# this signing happens with a PIN prompt
gpg \
  --output /dev/null \
  --sign <($TIMESTAMPER)

sleep 1
log "fourth signing of a message"
# this signing happens without a PIN prompt
gpg \
  --output /dev/null \
  --sign <($TIMESTAMPER)
