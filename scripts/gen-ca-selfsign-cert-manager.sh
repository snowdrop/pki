#!/usr/bin/env bash
#
# Example:
#  HOSTNAME=localhost \
#  NAMESPACE=demo \
#  STORE_PASSWORD=supersecret
#  ./scripts/gen-ca-selfsign-cert-manager.sh
#
# Define the following env vars:
# - HOSTNAME: Host name or IP address of the HTTPS server (E.g. 127.0.0.1, ...)
# - NAMESPACE: Kubernetes namespace where the generated TLS secret should be created
# - STORE_PASSWORD: Password of the keystore and truststore


HOSTNAME=${HOSTNAME:=localhost}
NAMESPACE=${NAMESPACE:=demo}
STORE_PASSWORD=${STORE_PASSWORD:=supersecret}

kubectl create ns ${NAMESPACE}
kubectl delete clusterissuer/selfsigned-issuer
kubectl delete certificate/${HOSTNAME}-tls -n ${NAMESPACE}
kubectl delete secret/pkcs12-pass -n ${NAMESPACE}
kubectl delete secret/${HOSTNAME}-tls -n ${NAMESPACE}

kubectl create secret generic pkcs12-pass -n ${NAMESPACE} --from-literal=password=${STORE_PASSWORD}

cat <<EOF | kubectl apply -f -
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${HOSTNAME}-tls
  namespace: ${NAMESPACE}
spec:
  isCA: false
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
  duration: 8760h
  renewBefore: 360h
  secretName: ${HOSTNAME}-tls
  usages:
  - server auth
  - client auth
EOF