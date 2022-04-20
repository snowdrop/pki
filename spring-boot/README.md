## Spring Boot TLS


To be able to expose a Spring Boot application as a HTTPS/TLS Server, it is needed to first populate a new CA Selfsigned certificate
using the Certificate Manager deployed on a k8s cluster.

This can be achieved by running the following bash scripts:
```bash
HOSTNAME=localhost ./scripts/gen-ca-selfsign-cert-manager.sh

PASSWORD=supersecret ./scripts/get_store.sh

./scripts/get_cert_from_secret.sh ca.crt
./scripts/get_cert_from_secret.sh tls.crt
```

Next copy the files `keystore.p12` and `truststore.p12` available under the folder `_temp/cert-manager` within
the resource folder of the Spring Boot project `./spring-boot/src/main/resources`

```bash
cp ./_temp/cert-manager/*.p12 ./spring-boot/src/main/resources
```

Next compile and launch the project
```bash
cd spring-boot
mvn package spring-boot:run
cd ..
```
Finally, use curl to call the HTTPS endpoint

```bash
curl --cacert _temp/cert-manager/ca.crt https://localhost:8443
```


