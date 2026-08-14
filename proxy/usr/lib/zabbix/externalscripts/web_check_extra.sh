#!/bin/bash

SCHEME="$1"
TARGET="$2"
DOMAIN="$3"
PATH_URL="$4"
TIMEOUT_RAW="$5"
TIMEOUT="${TIMEOUT_RAW%s}"

if ! [[ "$TIMEOUT" =~ ^[0-9]+$ ]]; then
    TIMEOUT=30
fi

# 2회 검사 + 2초 재시도를 고려하여
# 각 curl이 사용할 시간을 계산.
# 전체 TIMEOUT보다 약 2초 여유를 남긴다.
ATTEMPT_TIMEOUT=$(( (TIMEOUT - 4) / 2 ))

if [ "$ATTEMPT_TIMEOUT" -lt 1 ]; then
    ATTEMPT_TIMEOUT=1
fi

if [[ "$TARGET" == *:* ]]; then
    TARGET_HOST="${TARGET%:*}"
    TARGET_PORT="${TARGET##*:}"
else
    TARGET_HOST="$TARGET"

    if [ "$SCHEME" = "https" ]; then
        TARGET_PORT=443
    else
        TARGET_PORT=80
    fi
fi

check() {
    if [ "$SCHEME" = "https" ]; then
        curl -k -sS -o /dev/null \
            --connect-timeout "$ATTEMPT_TIMEOUT" \
            --max-time "$ATTEMPT_TIMEOUT" \
            --connect-to "${DOMAIN}:${TARGET_PORT}:${TARGET_HOST}:${TARGET_PORT}" \
            -w '%{http_code} %{time_total}' \
            "https://${DOMAIN}:${TARGET_PORT}${PATH_URL}" 2>/dev/null
    else
        curl -sS -o /dev/null \
            --connect-timeout "$ATTEMPT_TIMEOUT" \
            --max-time "$ATTEMPT_TIMEOUT" \
            -H "Host: ${DOMAIN}" \
            -w '%{http_code} %{time_total}' \
            "http://${TARGET_HOST}:${TARGET_PORT}${PATH_URL}" 2>/dev/null
    fi
}
# 1차 검사
RESULT=$(check)
RC=$?

STATUS=$(echo "$RESULT" | awk '{print $1}')
RT=$(echo "$RESULT" | awk '{print $2}')

[ -z "$STATUS" ] && STATUS=0
[ -z "$RT" ] && RT=0

# 200~399면 바로 정상 반환
if [ "$RC" -eq 0 ] \
    && [ "$STATUS" -ge 200 ] 2>/dev/null \
    && [ "$STATUS" -lt 400 ]; then

    printf '{"status":%s,"time":%s}\n' "$STATUS" "$RT"
    exit 0
fi

# 실패 또는 비정상 응답이면 2초 후 1회 재검사
sleep 2

RESULT=$(check)
RC=$?

STATUS=$(echo "$RESULT" | awk '{print $1}')
RT=$(echo "$RESULT" | awk '{print $2}')

[ -z "$STATUS" ] && STATUS=0
[ -z "$RT" ] && RT=0

# curl 자체 실패/timeout
if [ "$RC" -ne 0 ]; then
    STATUS=0
    RT=0
fi

printf '{"status":%s,"time":%s}\n' "$STATUS" "$RT"
exit 0