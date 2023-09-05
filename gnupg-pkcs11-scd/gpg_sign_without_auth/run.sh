#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

log() {
  echo "$(date --iso-8601=s) run.sh: $@" 1>&2
}

SMARTCARD_READER_USB_ID="046a:00a1"
DOCKER_IMAGE_TAG="gpg_sign_without_auth:latest"

cd "$(dirname "$0")"

log "git revision: $(git rev-parse HEAD)$(git diff --quiet && echo "" || echo "-dirty")"

SMARTCARD_READER_DEVICE_FILE="$(
  lsusb | gawk '
    $1 == "Bus" && $3 == "Device" && $5 == "ID" && $6 == "'"$SMARTCARD_READER_USB_ID"'" {
      print("/dev/bus/usb/" $2 "/" gensub(":$", "", 1, $4))
    }
  '
)"

log "smartcard reader device file: $SMARTCARD_READER_DEVICE_FILE"

sudo chgrp "${GROUPS[0]}" "$SMARTCARD_READER_DEVICE_FILE"

ls -l "$SMARTCARD_READER_DEVICE_FILE"


docker build \
  --quiet \
  --tag "$DOCKER_IMAGE_TAG" \
  .

docker run \
  --device "$SMARTCARD_READER_DEVICE_FILE" \
  "$DOCKER_IMAGE_TAG"
