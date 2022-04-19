# Instructions

https://www.baeldung.com/spring-boot-https-self-signed-certificate
https://www.misterpki.com/pkcs12/
https://janikvonrotz.ch/2019/01/22/create-pkcs12-key-and-truststore-with-keytool-and-openssl/

## Requirements

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.yaml
```

## Commands

Generate a private key and selfsigned certificate
```bash
# We can use the following command to generate our PKCS12 keystore format:
keytool -genkeypair \
  -alias snowdrop \
  -keyalg RSA \
  -keysize 2048 \
  -dname "CN=snowdrop.dev,OU=Middleware,O=Red Hat,L=Florennes,S=Namur,C=BE" \
  -storetype PKCS12 \
  -keystore cert/snowdrop.p12 \
  -storepass password \
  -validity 3650
Generating 2,048 bit RSA key pair and self-signed certificate (SHA256withRSA) with a validity of 3,650 days
        for: CN=snowdrop.dev, OU=Middleware, O=Red Hat, L=Florennes, ST=Namur, C=BE
```

## To check the content of the store
```bash
keytool -list -storetype PKCS12 -keystore cert/snowdrop.p12 -storepass password 
OR 
openssl pkcs12 -info -in cert/snowdrop.p12 -passin pass:password -passout pass:password
```

## To output the private key
```bash
openssl pkcs12 -info -in cert/snowdrop.p12 -passin pass:password -passout pass:password -nodes -nocerts > cert/sowdrop.crt
```

## To output the certificates
```bash
openssl pkcs12 -info -in cert/snowdrop.p12 -passin pass:password -passout pass:password -nokeys -out cert/snowdrop.crt
```
## To get the public key

```bash
openssl pkcs12 -in cert/snowdrop.p12 -passin pass:password -passout pass:password -clcerts -nokeys -out cert/snowdrop.pem
openssl x509 -pubkey -in cert/snowdrop.pem -noout > cert/snowdrop_pub.pem
```

## Create now a pkcs12 using cert manager

```bash
kubectl delete ClusterIssuer/selfsigned-issuer
kubectl delete Certificate/snowdrop-dev -n cert-manager
kubectl delete secret/snowdrop-p12 -n cert-manager
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
  namespace: cert-manager
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

Read the secret content
```bash
kubectl get secret/snowdrop-p12 -n cert-manager -o yaml
```

## Additional information

For generating our keystore in a JKS format, we can use the following command:
`keytool -genkeypair -alias snowdrop -keyalg RSA -keysize 2048 -keystore snowdrop.jks -storepass password -validity 3650`

**Note**: We recommend using the PKCS12 format, which is an industry standard format !

So in case we already have a JKS keystore, we can convert it to PKCS12 format using the following command:
`keytool -importkeystore -srckeystore baeldung.jks -destkeystore baeldung.p12 -deststoretype pkcs12`

**Note**: We'll have to provide the source keystore password and also set a new keystore password. The alias and keystore password will be needed later.