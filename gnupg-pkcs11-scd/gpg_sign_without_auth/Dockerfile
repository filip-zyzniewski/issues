FROM debian:unstable-20230814-slim AS build

RUN \
  apt-get update && \
  apt-get install --yes --no-install-recommends \
    autoconf \
    automake \
    build-essential \
    ca-certificates \
    curl \
    flex \
    libassuan-dev \
    libassuan0 \
    libgcrypt20 \
    libgcrypt20-dev \
    libgpg-error-dev \
    libgpg-error0 \
    libksba-dev \
    libksba8 \
    libnpth0 \
    libnpth0-dev \
    libssl-dev \
    libssl3 \
    libtool \
    libusb-1.0-0 \
    libusb-1.0-0-dev \
    pkg-config


RUN \
  mkdir source && \
  cd source && \
  curl https://gnupg.org/ftp/gcrypt/gnupg/gnupg-2.4.3.tar.bz2 | tar -jx && \
  cd gnupg-2.4.3 && \
  ./configure && \
  make && \
  make install && \
  cd .. && \
  rm -rf gnupg-2.4.3

RUN \
  cd source && \
  curl -L https://github.com/OpenSC/pkcs11-helper/releases/download/pkcs11-helper-1.29.0/pkcs11-helper-1.29.0.tar.bz2 | \
  tar -jx && \
  cd pkcs11-helper-1.29.0 && \
  ./configure && \
  make && \
  make install && \
  cd .. && \
  rm -rf kcs11-helper-1.29.0

RUN \
  ln -s gpgrt-config /usr/bin/gpg-error-config && \
  cd source && \
  curl -L https://github.com/alonbl/gnupg-pkcs11-scd/releases/download/gnupg-pkcs11-scd-0.10.0/gnupg-pkcs11-scd-0.10.0.tar.bz2 | \
  tar -jx && \
  cd gnupg-pkcs11-scd-0.10.0 && \
  ./configure && \
  make && \
  make install && \
  cd .. && \
  rm -rf nupg-pkcs11-scd-0.10.0
  
RUN \
  cd source && \
  curl https://pcsclite.apdu.fr/files/pcsc-lite-1.9.9.tar.bz2 | \
  tar -jx && \
  cd pcsc-lite-1.9.9 && \
  ./configure --disable-libsystemd --disable-libudev && \
  make && \
  make install && \
  cd .. && \
  rm -rf pcsc-lite-1.9.9

RUN \
  cd source && \
  curl -L https://github.com/OpenSC/OpenSC/releases/download/0.23.0/opensc-0.23.0.tar.gz | \
  tar -zx && \
  cd opensc-0.23.0 && \
  ./bootstrap && \
  ./configure && \
  make && \
  make install && \
  cd .. && \
  rm -rf opensc-0.23.0

RUN \
  cd source && \
  curl https://ccid.apdu.fr/files/ccid-1.5.1.tar.bz2 | \
  tar -jx && \
  cd ccid-1.5.1 && \
  ./configure && \
  make && \
  make install && \
  cd .. && \
  rm -rf ccid-1.5.1

RUN \
  cd source && \
  curl -L https://github.com/OpenSC/libp11/releases/download/libp11-0.4.12/libp11-0.4.12.tar.gz | \
  tar -zx && \
  cd libp11-0.4.12 && \
  ./configure && \
  make && \
  make install && \
  cd .. && \
  rm -rf libp11-0.4.12

RUN \
  cd source && \
  curl -L https://pcsc-perl.apdu.fr/pcsc-perl-1.4.14.tar.bz2 | \
  tar -jx && \
  cd pcsc-perl-1.4.14 && \
  perl Makefile.PL && \
  make && \
  make install && \
  cd .. && \
  rm -r pcsc-perl-1.4.14

RUN \
  cd source && \
  curl -L https://github.com/LudovicRousseau/pcsc-tools/archive/refs/tags/1.6.2.tar.gz | \
  tar -zx && \
  cd pcsc-tools-1.6.2 && \
  ./bootstrap && \
  ./configure && \
  make && \
  make install && \
  cd .. && \
  rm -rf pcsc-tools-1.6.2

RUN \
 mkdir /run/pcscd && \
 useradd --uid 1000 --create-home gpg && \
 chown gpg:gpg /run/pcscd

COPY --chown=gpg:gpg dot-gnupg /home/gpg/.gnupg
RUN chmod 0700 /home/gpg/.gnupg
COPY --chown=gpg:gpg gpg_setup_sign.sh openssl-engine.conf gpg-generate-key.batch /home/gpg/

RUN ldconfig

USER gpg

CMD /home/gpg/gpg_setup_sign.sh
