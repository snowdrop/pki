#!/usr/bin/env bash

set -e

if [ -z "$1" ]
  then
    echo "No certificate file name to parsed passed ! "
    echo "Usage: $0 [Certificate file name]"
	  exit 0
fi

CERT_NAME=${1}
TEMP_DIR="_temp"
NAMESPACE=${NAMESPACE:=demo}
HOST=${HOST:=localhost}

mkdir -p ${TEMP_DIR}/cert-manager

echo "================================================"
echo "Name of file certificate to parse: ${CERT_NAME}"
echo "================================================"
kubectl get secret/${HOST}-tls -n ${NAMESPACE} -o json | jq -r --arg CERT_NAME "$CERT_NAME" '.data[$CERT_NAME] | @base64d' > ${TEMP_DIR}/cert-manager/${CERT_NAME}
kubectl get secret/${HOST}-tls -n ${NAMESPACE} -o json | jq -r --arg CERT_NAME "$CERT_NAME" '.data[$CERT_NAME] | @base64d' | openssl x509 -noout -text > ${TEMP_DIR}/cert-manager/${CERT_NAME}.txt
