#!/usr/bin/env bash
#
# This scrHOSTNAMEt generates a CA cert/key and selfsigned cert/key for a Hostname
# Execute this command locally
#
# ./gen-ca-selfsign-import.sh
#
# Example:
# HOSTNAME=127.0.0.1 ./scripts/gen-ca-selfsign-import.sh
#
# Define the following env vars:
# - HOSTNAME: Host name or IP address of the HTTPS server
#

HOSTNAME=${HOSTNAME:=127.0.0.1}
FQ_HOSTNAME=${HOSTNAME}.nip.io
TEMP_DIR="_temp"

create_openssl_cfg() {
CFG=$(cat <<EOF
[req]
distinguished_name = subject
x509_extensions    = x509_ext
prompt             = no
[subject]
C  = BE
ST = Namur
L  = Florennes
O  = Red Hat
OU = Snowdrop
CN = "$FQ_HOSTNAME"
[x509_ext]
basicConstraints        = critical, CA:TRUE
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always, issuer:always
keyUsage                = critical, cRLSign, digitalSignature, keyCertSign
nsComment               = "OpenSSL Generated Certificate"
subjectAltName          = @alt_names
[alt_names]
DNS.1 = "$FQ_HOSTNAME"
EOF
)
echo "$CFG"
}


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

rm -rf ${TEMP_DIR} && mkdir -p ${TEMP_DIR}

log_line "CYAN" "Generate the CA certificate (ca.pem) and its private key file (ca.key)"
openssl genrsa -out ${TEMP_DIR}/ca.key 2048
openssl req -x509 -new \
    -nodes \
    -sha256 \
    -days 3650 \
    -subj '/CN=CA Authory/O=Red Hat/L=Florennes/C=BE' \
    -key ${TEMP_DIR}/ca.key \
    -out ${TEMP_DIR}/ca.pem

log_line "CYAN" "Generate the server or tls key (tls.pem) & certificate signing request (tls.csr)"

#Create OpenSSL config
cat <<EOF > ${TEMP_DIR}/ca.cnf
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

cat <<EOF > ${TEMP_DIR}/v3.ext
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
    -out ${TEMP_DIR}/tls.csr \
    -newkey rsa:4096 \
    -keyout ${TEMP_DIR}/tls.key -config <( cat ${TEMP_DIR}/ca.cnf )

log_line "CYAN" "Sign the Server or TLS CSR with CA and generates the certificate file (tls.pem)"
openssl x509 -req \
    -in ${TEMP_DIR}/tls.csr \
    -CA ${TEMP_DIR}/ca.pem \
    -CAkey ${TEMP_DIR}/ca.key -CAcreateserial \
    -out ${TEMP_DIR}/tls.pem -days 3650 -sha256 \
    -extfile ${TEMP_DIR}/v3.ext