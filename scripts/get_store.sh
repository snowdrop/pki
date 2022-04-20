#!/usr/bin/env bash

TEMP_DIR="_temp"
PASSWORD="password"

mkdir -p ${TEMP_DIR}/cert-manager

echo "================================================"
echo "Got the trust and keystore p12 files from the tls-secret"
echo "================================================"
kubectl get secret/tls-secret -n demo -o json | jq -r .data."keystore.p12" | base64 -d - > ${TEMP_DIR}/cert-manager/keystore.p12
kubectl get secret/tls-secret -n demo -o json | jq -r .data."truststore.p12" | base64 -d - > ${TEMP_DIR}/cert-manager/truststore.p12

openssl pkcs12 -info -in ${TEMP_DIR}/cert-manager/keystore.p12 -passin pass:${PASSWORD} -passout pass:${PASSWORD}
openssl pkcs12 -info -in ${TEMP_DIR}/cert-manager/truststore.p12 -passin pass:${PASSWORD} -passout pass:${PASSWORD}