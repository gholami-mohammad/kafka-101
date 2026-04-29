#! /bin/bash

echo "Generating SSL authentication files"

# 1. create client keystore
cd /etc/kafka/secrets/client

keytool -genkeypair -keystore kafka.client.keystore.jks -keyalg RSA -keysize 2048 -alias price-feed-client -validity 3650 -storepass $CLIENT_PASS -keypass $CLIENT_PASS -storetype pkcs12 -dname "CN=price-updater-client"

# 2. create CSR
keytool -keystore kafka.client.keystore.jks -certreq -alias price-feed-client -file client-cert-sign-request -storepass $CLIENT_PASS -keypass $CLIENT_PASS

# 3. sing CSR in CA
cp /etc/kafka/secrets/client/client-cert-sign-request /etc/kafka/secrets/ca
cd /etc/kafka/secrets/ca

openssl x509 -req -CA ca-cert -CAkey ca-key -in client-cert-sign-request -out client-cert-signed -days 3650 -CAcreateserial -passin pass:$CA_PASSWORD

# 4. import ca public key into keystore
cp /etc/kafka/secrets/ca/ca-cert /etc/kafka/secrets/client
cd /etc/kafka/secrets/client

keytool -importcert -keystore kafka.client.keystore.jks -alias CARoot -file ca-cert -storepass $CLIENT_PASS -keypass $CLIENT_PASS -noprompt

# 5. import signed certification into keystore
cp /etc/kafka/secrets/ca/client-cert-signed /etc/kafka/secrets/client

keytool -importcert -keystore kafka.client.keystore.jks -alias price-feed-client -file client-cert-signed -storepass $CLIENT_PASS -keypass $CLIENT_PASS -noprompt

# 6. config kafka server
# 7. generate client properties
touch client.auth.properties
echo security.protocol=SSL > client.auth.properties
echo ssl.truststore.location=./kafka.client.truststore.jks >> client.auth.properties
echo ssl.truststore.password=$CLIENT_PASS >> client.auth.properties
echo ssl.keystore.location=./kafka.client.keystore.jks >> client.auth.properties
echo ssl.keystore.password=$CLIENT_PASS >> client.auth.properties
echo ssl.key.password=$CLIENT_PASS >> client.auth.properties

echo Client SSL authentication files generated.