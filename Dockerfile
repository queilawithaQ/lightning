FROM alpine:3.7 as builder

RUN apk add --no-cache \
     ca-certificates \
     autoconf \
     automake \
     build-base \
     libressl \
     libtool \
     gmp-dev \
     python \
     python-dev \
     python3 \
     sqlite-dev \
     wget \
     git \
     file \
     gnupg \
     swig

ENV LIGHTNINGD_VERSION=master

WORKDIR /opt/lightningd
COPY . .

ARG DEVELOPER=0
RUN make -j3 DEVELOPER=${DEVELOPER} && cp lightningd/lightning* cli/lightning-cli /usr/bin/

ENV BITCOIN_VERSION 0.16.0
ENV BITCOIN_URL https://bitcoincore.org/bin/bitcoin-core-$BITCOIN_VERSION/bitcoin-$BITCOIN_VERSION-x86_64-linux-gnu.tar.gz
ENV BITCOIN_SHA256 e6322c69bcc974a29e6a715e0ecb8799d2d21691d683eeb8fef65fc5f6a66477
ENV BITCOIN_ASC_URL https://bitcoincore.org/bin/bitcoin-core-$BITCOIN_VERSION/SHA256SUMS.asc
ENV BITCOIN_PGP_KEY 01EA5486DE18A882D4C2684590C8019E36C2E964

RUN mkdir /opt/bitcoin && cd /opt/bitcoin \
    && wget -qO bitcoin.tar.gz "$BITCOIN_URL" \
    && echo "$BITCOIN_SHA256  bitcoin.tar.gz" | sha256sum -c - \
    && gpg --keyserver keyserver.ubuntu.com --recv-keys "$BITCOIN_PGP_KEY" \
    && wget -qO bitcoin.asc "$BITCOIN_ASC_URL" \
    && gpg --verify bitcoin.asc \
    && BD=bitcoin-$BITCOIN_VERSION/bin \
    && tar -xzvf bitcoin.tar.gz $BD/bitcoin-cli --strip-components=1 \
    && rm bitcoin.tar.gz

ENV LITECOIN_VERSION 0.14.2
ENV LITECOIN_URL https://download.litecoin.org/litecoin-0.14.2/linux/litecoin-0.14.2-x86_64-linux-gnu.tar.gz
ENV LITECOIN_SHA256 05f409ee57ce83124f2463a3277dc8d46fca18637052d1021130e4deaca07b3c
ENV LITECOIN_ASC_URL https://download.litecoin.org/litecoin-0.14.2/linux/litecoin-0.14.2-linux-signatures.asc
ENV LITECOIN_PGP_KEY FE3348877809386C

# install litecoin binaries
RUN mkdir /opt/litecoin && cd /opt/litecoin \
    && wget -qO litecoin.tar.gz "$LITECOIN_URL" \
    && echo "$LITECOIN_SHA256  litecoin.tar.gz" | sha256sum -c - \
    && gpg --keyserver keyserver.ubuntu.com --recv-keys "$LITECOIN_PGP_KEY" \
    && wget -qO litecoin.asc "$LITECOIN_ASC_URL" \
    && gpg --verify litecoin.asc \
    && BD=litecoin-$LITECOIN_VERSION/bin \
    && tar -xzvf litecoin.tar.gz $BD/litecoin-cli --strip-components=1 --exclude=*-qt \
    && rm litecoin.tar.gz

FROM alpine:3.7

RUN apk add --no-cache \
     gmp-dev \
     sqlite-dev \
     inotify-tools \
     socat

ENV LIGHTNINGD_DATA=/root/.lightning
ENV LIGHTNINGD_PORT=9835

RUN mkdir $LIGHTNINGD_DATA && \
    touch $LIGHTNINGD_DATA/config
VOLUME [ "/root/.lightning" ]

COPY --from=builder /opt/lightningd/cli/lightning-cli /usr/bin
COPY --from=builder /opt/lightningd/lightningd/lightning* /usr/bin/
COPY --from=builder /opt/bitcoin/bin /usr/bin
COPY --from=builder /opt/litecoin/bin /usr/bin
COPY tools/docker-entrypoint.sh entrypoint.sh

EXPOSE 9735 9835
ENTRYPOINT  [ "./entrypoint.sh" ]
