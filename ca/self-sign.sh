#!/usr/bin/env bash

##########################################################################################
# Author: Amin Abbaspour
# Date: 2022-06-12
# License: MIT (https://github.com/abbaspour/auth0-bash/blob/master/LICENSE)
##########################################################################################

set -eo pipefail

command -v openssl >/dev/null || { echo >&2 "error: openssl not found";  exit 3; }
command -v awk >/dev/null || { echo >&2 "error: awk not found";  exit 3; }

function usage() {
    cat <<END >&2
USAGE: $0 [-n domain]
        -n name     # name of key pair (default is localhost)
        -h|?        # usage
        -v          # verbose

eg,
     $0 -n backend-api
END
    exit $1
}

declare pair_name='localhost'

while getopts "n:hv?" opt; do
    case ${opt} in
    n) pair_name=${OPTARG} ;;
    v) set -x;;
    h | ?) usage 0 ;;
    *) usage 1 ;;
    esac
done

[[ -z "${pair_name}" ]] && { echo >&2 "ERROR: pair_name undefined.";  usage 1; }


declare -r private_pem="${pair_name}-private.pem"
declare -r private_x5c="${pair_name}-private.x5c"
declare -r cert_pem="${pair_name}-cert.pem"
declare -r cert_x5c="${pair_name}-cert.x5c"
declare -r public_pem="${pair_name}-public.pem"
declare -r public_x5c="${pair_name}-public.x5c"

cat >openssl.cnf <<-EOF
  [req]
  distinguished_name = req_distinguished_name
  x509_extensions = v3_req
  prompt = no
  default_bits            = 2048
  [req_distinguished_name]
  CN = ${pair_name}
  [v3_req]
  keyUsage = keyEncipherment, dataEncipherment
  extendedKeyUsage = serverAuth
EOF

openssl req -nodes -new -x509 -config openssl.cnf -days 365 -keyout "${private_pem}" -out "${cert_pem}"
openssl x509 -inform PEM -in "${cert_pem}" -pubkey -noout >"${public_pem}"

awk 'NR>1 && !/^-----END/ {printf "%s", $0}' "${private_pem}" > "${private_x5c}"
awk 'NR>1 && !/^-----END/ {printf "%s", $0}' "${cert_pem}" > "${cert_x5c}"
awk 'NR>1 && !/^-----END/ {printf "%s", $0}' "${public_pem}" > "${public_x5c}"

rm openssl.cnf

