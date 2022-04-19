# Instructions

https://www.baeldung.com/spring-boot-https-self-signed-certificate
https://www.misterpki.com/pkcs12/
https://stackoverflow.com/questions/9497719/extract-public-private-key-from-pkcs12-file-for-later-use-in-ssh-pk-authenticati
https://gist.github.com/aneer-anwar/a92a9403e6ce5d0710b75e1f478a218b

## Requirements

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.yaml
```

## Generate CA key & certificate

```bash
rm -rf {ca,cert} && mkdir -p {ca,cert}
openssl genrsa -out ca/ca.key 2048
openssl req -x509 -new -nodes -key ca/ca.key -sha256 -days 1024 -subj '/CN=CA Authory/O=Red Hat/L=Florennes/C=BE' -out ca/ca.pem

openssl genrsa -out cert/tls.key 2048
openssl req -new -key cert/tls.key -subj '/CN=www.snowdrop.dev/O=Red Hat/L=Florennes/C=BE' -out cert/tls.csr

openssl x509 -req -in cert/tls.csr -CA ca/ca.pem -CAkey ca/ca.key -CAcreateserial -out cert/tls.pem -days 1024 -sha256

openssl pkcs12 -inkey cert/tls.key -in cert/tls.pem -passin pass:password -passout pass:password -export -out cert/tls.p12

keytool -importkeystore -srckeystore cert/tls.p12 -srcstoretype pkcs12 -srcstorepass password -deststorepass password -destkeystore cert/tls.jks

openssl x509 -outform der -in cert/tls.pem -out cert/tls.cer
openssl x509 -outform der -in ca/ca.pem -out ca/ca.cer

keytool -noprompt -import -alias tls -storetype PKCS12 -file cert/tls.cer -keystore cert/cacerts -trustcacerts -storepass changeit 
keytool -noprompt -import -alias ca -storetype PKCS12 -file ca/ca.cer -keystore cert/cacerts -trustcacerts -storepass changeit 
```

## Populating a private key saved in a key store

Generate a private key
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

## To export the private key
```bash
openssl pkcs12 -in cert/snowdrop.p12 -passin pass:password -passout pass:password -nocerts -nodes | openssl pkcs8 -nocrypt -out cert/sowdrop.key
```

## To export the client and CA certificate
```bash
openssl pkcs12 -in cert/snowdrop.p12 -passin pass:password -passout pass:password -clcerts -nokeys | openssl x509 -out cert/snowdrop.crt
openssl pkcs12 -in cert/snowdrop.p12 -passin pass:password -passout pass:password -cacerts -nokeys -chain | openssl x509 -out cert/ca.crt
```
## To export the public key

```bash
openssl x509 -pubkey -in cert/snowdrop.crt -noout > cert/snowdrop_pub.key
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