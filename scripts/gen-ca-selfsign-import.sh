#!/usr/bin/env bash
#
# This script generates a CA cert/key and selfsigned cert/key for a Hostname
# Execute this command locally
#
# ./gen-ca-selfsign-import.sh
#
# Example:
# HOSTNAME=127.0.0.1 STORE_PASSWORD=password ./scripts/gen-ca-selfsign-import.sh
#
# Define the following env vars:
# - HOSTNAME: Host name or IP address of the HTTPS server (E.G. 127.0.0.1, ...)
# - STORE_PASSWORD: password to be used for the keys store. (E.g: password)
#

HOSTNAME=${HOSTNAME:=127.0.0.1}
FQ_HOSTNAME=${HOSTNAME}.nip.io
STORE_PASSWORD=${STORE_PASSWORD:=password}
TEMP_DIR="_temp"

# Defining some colors for output
RED='\033[0;31m'
NC='\033[0m' # No Color
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

repeat_char(){
  COLOR=${1}
	for i in {1..50}; do echo -ne "${!COLOR}$2${NC}"; done
}

log_msg() {
    COLOR=${1}
    MSG="${@:2}"
    echo -e "\n${!COLOR}## ${MSG}${NC}"
}

log_line() {
    COLOR=${1}
    MSG="${@:2}"
    echo -e "${!COLOR}## ${MSG}${NC}"
}

log() {
  MSG="${@:2}"
  echo; repeat_char ${1} '#'; log_msg ${1} ${MSG}; repeat_char ${1} '#'; echo
}

log_line "CYAN" "The fully qualified name of the server is: ${FQ_HOSTNAME}"

rm -rf ${TEMP_DIR} && mkdir -p ${TEMP_DIR}/{root,server,java}

log_line "CYAN" "Generate the CA certificate (ca.pem) and its private key file (ca.key)"
openssl genrsa -out ${TEMP_DIR}/root/ca.key 2048
openssl req -x509 -new \
    -nodes \
    -sha256 \
    -days 3650 \
    -subj '/CN=CA Authory/O=Red Hat/L=Florennes/C=BE' \
    -key ${TEMP_DIR}/root/ca.key \
    -out ${TEMP_DIR}/root/ca.pem

log_line "CYAN" "Generate the server or tls key (tls.key) & certificate signing request (tls.csr)"

#Create OpenSSL config
cat <<EOF > ${TEMP_DIR}/root/ca.cnf
[req]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn

[dn]
C  = BE
ST = Namur
L  = Florennes
O  = Red Hat
OU = Snowdrop
CN = "$FQ_HOSTNAME"
EOF

cat <<EOF > ${TEMP_DIR}/root/v3.ext
basicConstraints        = CA:FALSE
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid,issuer
keyUsage                = critical, cRLSign, digitalSignature, keyCertSign
subjectAltName          = @alt_names
[alt_names]
DNS.1 = "$FQ_HOSTNAME"

[alt_names]
DNS.1 = ${FQ_HOSTNAME}
EOF

openssl req -new -sha256 -nodes \
    -out ${TEMP_DIR}/server/tls.csr \
    -newkey rsa:4096 \
    -keyout ${TEMP_DIR}/server/tls.key -config <( cat ${TEMP_DIR}/root/ca.cnf )

log_line "CYAN" "Sign the Server or TLS CSR with CA and generates the certificate file (tls.crt)"
openssl x509 -req \
    -in ${TEMP_DIR}/server/tls.csr \
    -CA ${TEMP_DIR}/root/ca.pem \
    -CAkey ${TEMP_DIR}/root/ca.key -CAcreateserial \
    -out ${TEMP_DIR}/server/tls.crt -days 3650 -sha256 \
    -extfile ${TEMP_DIR}/root/v3.ext

log_line "CYAN" "Combine the server or TLS key and certificate in a PKCS#12 (P12) bundle"
openssl pkcs12 -inkey ${TEMP_DIR}/server/tls.key -in ${TEMP_DIR}/server/tls.crt -CAfile ${TEMP_DIR}/root/ca.pem -chain -passin pass:${STORE_PASSWORD} -passout pass:${STORE_PASSWORD} -export -out ${TEMP_DIR}/server/tls.p12

log_line "CYAN" "Generate the jks file from the p12 file"
keytool -importkeystore -srckeystore ${TEMP_DIR}/server/tls.p12 -srcstoretype pkcs12 -srcstorepass ${STORE_PASSWORD} -deststorepass ${STORE_PASSWORD} -destkeystore ${TEMP_DIR}/java/tls.jks

log_line "CYAN" "Check the content of the jks store"
keytool -list -keystore ${TEMP_DIR}/java/tls.jks -storepass ${STORE_PASSWORD}

log_line "CYAN" "Exporting the public key"
openssl x509 -pubkey -in ${TEMP_DIR}/server/tls.crt -noout > ${TEMP_DIR}/server/tls_pub.key

log_line "CYAN" "Show p12 content"
openssl pkcs12 -info -in _temp/server/tls.p12 -passin pass:${STORE_PASSWORD} -passout pass:${STORE_PASSWORD}

# TODO: To be checked if we need them
#openssl x509 -outform der -in cert/tls.pem -out cert/tls.cer
#openssl x509 -outform der -in ca/ca.pem -out ca/ca.cer

#keytool -noprompt -import -alias tls -storetype PKCS12 -file cert/tls.cer -keystore cert/cacerts -trustcacerts -storepass changeit
#keytool -noprompt -import -alias ca -storetype PKCS12 -file ca/ca.cer -keystore cert/cacerts -trustcacerts -storepass changeit



