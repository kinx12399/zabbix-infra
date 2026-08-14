#!/bin/bash

STREAM_URL="$1"
TEMP_FILE="/tmp/rtmp_check_$RANDOM.flv"

# 1차 시도
/usr/bin/rtmpdump \
    -v \
    -r "$STREAM_URL" \
    -B 1 \
    -o "$TEMP_FILE" \
    >/dev/null 2>&1

# 실패 시 2초 후 한 번 재시도
if [ ! -s "$TEMP_FILE" ]; then
    sleep 2

    rm -f "$TEMP_FILE"

    /usr/bin/rtmpdump \
        -v \
        -r "$STREAM_URL" \
        -B 1 \
        -o "$TEMP_FILE" \
        >/dev/null 2>&1
fi

if [ -s "$TEMP_FILE" ]; then
    echo 1
else
    echo 0
fi

rm -f "$TEMP_FILE"

exit 0