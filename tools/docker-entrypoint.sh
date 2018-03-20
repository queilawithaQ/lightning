#!/bin/bash

cat <<-EOF > "$LIGHTNINGD_DATA/config"
${LIGHTNINGD_OPT}
EOF

: ${EXPOSE_TCP:=false}

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