## Spring Boot TLS

To be able to expose this Spring Boot application as HTTPS/TLS Server project, copy first the files `keystore.p12` and `truststore.p12`
available under the folder `_temp/cert-manager` within the resource folder of the Spring Boot project `./spring-boot/src/main/resources`

```bash
cp ./_temp/cert-manager/*.p12 ./spring-boot/src/main/resources
```

Next compile and launch the project
```bash
cd spring-boot
mvn package spring-boot:run
cd ..
```
Finally use curl to call the HTTPS endpoint

```bash
curl --cacert _temp/root/ca.pem https://localhost:8443
```


