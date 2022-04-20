#!/usr/bin/env bash

if [ -z "$1" ]
  then
    echo "No certificate file name to parsed passed ! "
    echo "Usage: $0 [Certificate file name]"
	  exit 0
fi

CERT_NAME=${1}

echo "================================================"
echo "Name of file certificate to parse: ${CERT_NAME}"
echo "================================================"
kubectl get secret/snowdrop-p12 -n demo -o json | jq -r .data.\"${CERT_NAME}\" | base64 -d - | openssl x509 -noout -text > _temp/cert-manager/${CERT_NAME}.txt
