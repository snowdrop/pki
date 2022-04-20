Table of Contents
=================

* [Interesting references](#interesting-references)
* [Instructions](#instructions)
  * [Requirements](#requirements)
  * [Generate the CA &amp; Server certificate and their keys locally](#generate-the-ca--server-certificate-and-their-keys-locally)
  * [Create a pkcs12 using cert manager](#create-a-pkcs12-using-cert-manager)
  * [Interesting commands](#interesting-commands)
    * [To check the content of the store](#to-check-the-content-of-the-store)
    * [To export the private key](#to-export-the-private-key)
    * [To export the client and CA certificate](#to-export-the-client-and-ca-certificate)
    * [To export the public key](#to-export-the-public-key)
  * [Additional information](#additional-information)

# Interesting references

- https://www.baeldung.com/spring-boot-https-self-signed-certificate
- https://www.misterpki.com/pkcs12/
- https://stackoverflow.com/questions/9497719/extract-public-private-key-from-pkcs12-file-for-later-use-in-ssh-pk-authenticati
- https://gist.github.com/aneer-anwar/a92a9403e6ce5d0710b75e1f478a218b

# Instructions

## Requirements

To generate locally the certificate and key, the following tools are needed:
- openssl
- keytool

To generate on kubernetes the certificate and keys, install the certificat manager project

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.yaml
```

## Generate the CA & Server certificate and their keys locally

See the all-in-one instructions script: [gen-ca-selfsign-import.sh](./scripts/gen-ca-selfsign-import.sh)

Generate ca certificate and key file
```bash
openssl genrsa -out ca/ca.key 2048
openssl req -x509 -new \
    -nodes \
    -sha256 \
    -days 3650 \
    -subj '/CN=CA Authory/O=Red Hat/L=Florennes/C=BE' \
    -key ca/ca.key \
    -out ca/ca.pem
```
Generate client key & certificate signing request"
```bash
# Could be done with one command
openssl genrsa -out cert/tls.key 2048
openssl req -new -key cert/tls.key -subj '/CN=www.snowdrop.dev/O=Red Hat/L=Florennes/C=BE' -out cert/tls.csr

echo "Sign CSR with CA"
openssl x509 -req -in cert/tls.csr -CA ca/ca.pem -CAkey ca/ca.key -CAcreateserial -out cert/tls.pem -days 1024 -sha256
```

Combine your key and certificate in a PKCS#12 (P12) bundle
```bash
openssl pkcs12 -inkey cert/tls.key -in cert/tls.pem -CAfile cert/ca.pem -chain -passin pass:password -passout pass:password -export -out cert/tls.p12
```

Generate jks file from p12 file
```bash
keytool -importkeystore -srckeystore cert/tls.p12 -srcstoretype pkcs12 -srcstorepass password -deststorepass password -destkeystore cert/tls.jks 
```

## Create a pkcs12 using cert manager

```bash
kubectl create ns demo
kubectl delete clusterissuer/selfsigned-issuer
kubectl delete certificate/snowdrop-dev -n demo
kubectl delete secret/snowdrop-p12 -n demo
cat <<EOF | kubectl apply -f -
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
  name: snowdrop-dev
  namespace: demo
spec:
  commonName: snowdrop.dev
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
  - snowdrop.dev
  - www.snowdrop.dev
  duration: 2160h0m0s
  issuerRef:
    kind: ClusterIssuer
    name: selfsigned-issuer
  privateKey:  
    algorithm: RSA
    encoding: PKCS8
    size: 2048
  renewBefore: 360h0m0s
  secretName: snowdrop-p12
  usages:
  - server auth
  - client auth
EOF
```

To read the content of the generated certificates (CA and TLS), use the following commands:
```bash
./scripts/read_cert.sh ca.crt
./scripts/read_cert.sh tls.crt

cat _temp/root/ca.pem | openssl x509 -noout -text > _temp/root/ca.crt.txt
cat _temp/server/tls.crt | openssl x509 -noout -text > _temp/server/tls.crt.txt
```
and next check the content under `_temp/cert-manager/` or `_temp/root` and `_temp/server`


## Interesting commands

### To check the content of the store
```bash
keytool -list -storetype PKCS12 -keystore cert/snowdrop.p12 -storepass password 
OR 
openssl pkcs12 -info -in cert/snowdrop.p12 -passin pass:password -passout pass:password
```

### To export the private key
```bash
openssl pkcs12 -in cert/snowdrop.p12 -passin pass:password -passout pass:password -nocerts -nodes | openssl pkcs8 -nocrypt -out cert/sowdrop.key
```

### To export the client and CA certificate
```bash
openssl pkcs12 -in cert/snowdrop.p12 -passin pass:password -passout pass:password -clcerts -nokeys | openssl x509 -out cert/snowdrop.crt
openssl pkcs12 -in cert/snowdrop.p12 -passin pass:password -passout pass:password -cacerts -nokeys -chain | openssl x509 -out cert/ca.crt
```
### To export the public key

```bash
openssl x509 -pubkey -in cert/snowdrop.crt -noout > cert/snowdrop_pub.key
```

## Additional information

For generating our keystore in a JKS format, we can use the following command:
`keytool -genkeypair -alias snowdrop -keyalg RSA -keysize 2048 -keystore snowdrop.jks -storepass password -validity 3650`

**Note**: We recommend using the PKCS12 format, which is an industry standard format !

So in case we already have a JKS keystore, we can convert it to PKCS12 format using the following command:
`keytool -importkeystore -srckeystore baeldung.jks -destkeystore baeldung.p12 -deststoretype pkcs12`

**Note**: We'll have to provide the source keystore password and also set a new keystore password. The alias and keystore password will be needed later.