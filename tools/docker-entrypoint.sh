#!/bin/bash

cat <<-EOF > "$LIGHTNINGD_DATA/config"
${LIGHTNINGD_OPT}
EOF

: ${EXPOSE_TCP:=false}

export NETWORK=`cat $LIGHTNINGD_DATA/config | sed -n 's/^network=\(.*\)$/\1/p'`
export CHAIN=`cat $LIGHTNINGD_DATA/config | sed -n 's/^chain=\(.*\)$/\1/p'`

sed -i '/^chain=/d' $LIGHTNINGD_DATA/config

export REPLACEDNETWORK="";
if [ "$CHAIN" == "btc" ]; then
    if [ "$NETWORK" == "mainnet" ]; then
        REPLACEDNETWORK="bitcoin"
    fi
fi

if [ "$CHAIN" == "ltc" ]; then
    if [ "$NETWORK" == "mainnet" ]; then
        REPLACEDNETWORK="litecoin"
    fi
    if [ "$NETWORK" == "testnet" ]; then
        REPLACEDNETWORK="litecoin-testnet"
    fi
    if [ "$NETWORK" == "regtest" ]; then
        echo "REGTEST NOT AVAILABLE FOR LTC"
        exit
    fi
fi

if [[ $REPLACEDNETWORK ]]; then
    sed -i '/^network=/d' $LIGHTNINGD_DATA/config
    echo "network=$REPLACEDNETWORK" >> $LIGHTNINGD_DATA/config
    echo "Replaced network $NETWORK by $REPLACEDNETWORK in $LIGHTNINGD_DATA/config"
fi

if [ "$EXPOSE_TCP" == "true" ]; then

    lightningd &

    echo "C-Lightning starting"
    while read i; do if [ "$i" = "lightning-rpc" ]; then break; fi; done \
    < <(inotifywait  -e create,open --format '%f' --quiet $LIGHTNINGD_DATA --monitor)
    echo "C-Lightning started"


    socat -d -d TCP4-listen:$LIGHTNINGD_PORT,fork,reuseaddr UNIX-CONNECT:$LIGHTNINGD_DATA/lightning-rpc
else
    lightningd
fi