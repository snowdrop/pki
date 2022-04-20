#!/usr/bin/env bash

echo "Ca certificate"
kubectl get secret/snowdrop-p12 -n demo -o json | jq -r '.data."ca.crt"' | base64 -d -

echo "TLS certificate"
kubectl get secret/snowdrop-p12 -n demo -o json | jq -r '.data."tls.crt"' | base64 -d -
