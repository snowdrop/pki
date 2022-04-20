#!/usr/bin/env bash

echo "Ca certificate"
cat ./cert-manager-secret.json | jq -r '.data."ca.crt"' | base64 -d -

echo "TLS certificate"
cat ./cert-manager-secret.json | jq -r '.data."tls.crt"' | base64 -d -
