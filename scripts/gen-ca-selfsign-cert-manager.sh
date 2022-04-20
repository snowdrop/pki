#!/usr/bin/env bash
#
# Example:
# HOSTNAME=127.0.0.1 ./scripts/gen-ca-selfsign-cert-manager.sh
#
# Define the following env vars:
# - HOSTNAME: Host name or IP address of the HTTPS server (E.g. 127.0.0.1, ...)


kubectl create ns demo
kubectl delete clusterissuer/selfsigned-issuer
kubectl delete certificate/localhost-tls -n demo
kubectl delete secret/pkcs12-pass -n demo
kubectl delete secret/tls-secret -n demo

HOSTNAME=${HOSTNAME:=localhost}

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: Secret
metadata:
  name: pkcs12-pass
  namespace: demo
data:
  # password is 'supersecret'
  password: c3VwZXJzZWNyZXQ=
type: Opaque
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
and Certificate:
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: localhost-tls
  namespace: demo
spec:
  commonName: ${HOSTNAME}
  subject:
    organizationalUnits:
    - Snowdrop
    organizations:
    - "Red Hat"
    localities:
    - Florennes
    provinces:
    - Namur
    countries:
    - BE
  dnsNames:
  - ${HOSTNAME}
  duration: 2160h0m0s
  issuerRef:
    kind: ClusterIssuer
    name: selfsigned-issuer
  privateKey:
    algorithm: RSA
    encoding: PKCS8
    size: 2048
  keystores:
    pkcs12:
      create: true
      passwordSecretRef:
        name: pkcs12-pass
        key: password
  renewBefore: 360h0m0s
  secretName: tls-secret
  usages:
  - server auth
  - client auth
EOF