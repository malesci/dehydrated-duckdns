#!/usr/bin/env bash

CERT_DIR=/data/letsencrypt
WORK_DIR=/data/workdir
CONFIG_PATH=/data/options.json

# Let's encrypt
LE_UPDATE="0"

# DuckDNS
if [ "$(jq --raw-output '.ipv4' $CONFIG_PATH)" != null ]; then IPV4=$(jq --raw-output '.ipv4' $CONFIG_PATH); else  IPV4=""; fi
if [ "$(jq --raw-output '.ipv6' $CONFIG_PATH)" != null ]; then IPV6=$(jq --raw-output '.ipv4' $CONFIG_PATH); else  IPV6=""; fi

TOKEN=$(jq --raw-output '.token' $CONFIG_PATH)
DOMAINS=$( (jq --raw-output '.domains[]' $CONFIG_PATH) | sed -e 's/ /,/g')
WAIT_TIME=$(jq --raw-output '.seconds' $CONFIG_PATH)
ALGO=$(jq --raw-output '.lets_encrypt.algo' $CONFIG_PATH)
ACCEPT_TERMS=$(jq --raw-output '.lets_encrypt.accept_terms' $CONFIG_PATH)

# Function that performe a renew
function le_renew() {
    local domain_args=()
    local domains=''
    local aliases=''
    domains=$(jq --raw-output '.domains[]' $CONFIG_PATH)

    # Prepare domain for Let's Encrypt
    for domain in ${domains}; do
        for alias in $(jq --raw-output --exit-status "[.aliases[]|{(.alias):.domain}]|add.\"${domain}\" | select(. != null)" $CONFIG_PATH) ; do
            aliases="${aliases} ${alias}"
        done
    done

    aliases="$(echo "${aliases}" | tr ' ' '\n' | sort | uniq)"
    echo "$(date) | INFO  | Renew certificate for domains: $(echo -n "${domains}") and aliases: $(echo -n "${aliases}")"

    for domain in $(echo "${domains}" "${aliases}" | tr ' ' '\n' | sort | uniq); do
        domain_args+=("--domain" "${domain}")
    done
    
    dehydrated --cron --algo "${ALGO}" --hook ./hooks.sh --challenge dns-01 "${domain_args[@]}" --out "${CERT_DIR}" --config "${WORK_DIR}/config" || true
    LE_UPDATE="$(date +%s)"
}

# Register/generate certificate if terms accepted

if [ "$ACCEPT_TERMS" = true ] ; then
    # Init folder structs
    mkdir -p "${CERT_DIR}"
    mkdir -p "${WORK_DIR}"

    # Clean up possible stale lock file
    if [ -e "${WORK_DIR}/lock" ]; then
        rm -f "${WORK_DIR}/lock"
        echo "$(date) | WARN  | Reset dehydrated lock file"
    fi

    # Generate new certs
    if [ ! -d "${CERT_DIR}/live" ]; then
        # Create empty dehydrated config file so that this dir will be used for storage
        touch "${WORK_DIR}/config"
        dehydrated --register --accept-terms --config "${WORK_DIR}/config"
    fi
fi

# Run duckdns
while true; do

    [[ ${IPV4} != *:/* ]] && ipv4=${IPV4} || ipv4=$(curl -s -m 10 "${IPV4}")
    [[ ${IPV6} != *:/* ]] && ipv6=${IPV6} || ipv6=$(curl -s -m 10 "${IPV6}")

    if answer="$(curl -s "https://www.duckdns.org/update?domains=${DOMAINS}&token=${TOKEN}&ip=${ipv4}&ipv6=${ipv6}&verbose=true")" && [ "${answer}" != 'KO' ]; then
        echo "$(date) | INFO  | ${answer}"
    else
        echo "$(date) | WARN  | ${answer}"
    fi

    now="$(date +%s)"
    
    if [ "$ACCEPT_TERMS" = true ] && [ $((now - LE_UPDATE)) -ge 43200 ]; then
        le_renew
    fi

    sleep "${WAIT_TIME}"
done