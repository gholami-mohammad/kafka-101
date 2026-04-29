#! /bin/bash

mkdir -p /etc/kafka/secrets/ca
mkdir -p /etc/kafka/secrets/server
mkdir -p /etc/kafka/secrets/client

cd /etc/kafka/secrets/server

if [ -f "kafka.server.keystore.jks" ]; then
    echo "Certificates already exist. Skipping generation."
    exit 0
fi

echo "Generating SSL Certificates..."

# all steps have same order as they are in 61-security-encryption.md

# 1. Generate CA
cd /etc/kafka/secrets/ca
openssl req -new -x509 -newkey rsa:4096 -keyout ca-key -out ca-cert -days 3650 -subj "/CN=Kafka-Security-CA" -passout pass:$CA_PASSWORD

# 2. Create Truststore and import the CA
cd /etc/kafka/secrets/server
cp /etc/kafka/secrets/ca/ca-cert /etc/kafka/secrets/server

keytool -keystore kafka.server.truststore.jks -alias CARoot -import -file ca-cert -storepass $TRUSTSTORE_PASSWORD -keypass $TRUSTSTORE_PASSWORD -noprompt

# 3. Generate Keystore
cd /etc/kafka/secrets/server

keytool -genkeypair -keystore kafka.server.keystore.jks -keyalg RSA -keysize 2048 -alias kafka-broker -validity 3650 -storepass $KEYSTORE_PASSWORD -keypass $KEYSTORE_PASSWORD -storetype pkcs12 -dname "CN=localhost" -ext SAN=DNS:broker-1,DNS:broker-2,DNS:broker-3,DNS:controller-1,DNS:controller-2,DNS:localhost,IP:127.0.0.1

# 4. Create Certificate Signing Request (CSR)
keytool -keystore kafka.server.keystore.jks -certreq -alias kafka-broker -file server-cert-sign-request -storepass $KEYSTORE_PASSWORD -keypass $KEYSTORE_PASSWORD

# 5. Sign the Certificate with the CA
cp /etc/kafka/secrets/server/server-cert-sign-request /etc/kafka/secrets/ca

cd /etc/kafka/secrets/ca

openssl x509 -req -CA ca-cert -CAkey ca-key -in server-cert-sign-request -out cert-signed -days 3650 -CAcreateserial -passin pass:$CA_PASSWORD

# 6. Import CA into Keystore
cp /etc/kafka/secrets/ca/ca-cert /etc/kafka/secrets/server
cd /etc/kafka/secrets/server


keytool -importcert -keystore kafka.server.keystore.jks -alias CARoot -file ca-cert -storepass $KEYSTORE_PASSWORD -keypass $KEYSTORE_PASSWORD -noprompt

# 7. Import Signed Certificate into Keystore
cp /etc/kafka/secrets/ca/cert-signed /etc/kafka/secrets/server

keytool -importcert -keystore kafka.server.keystore.jks -alias kafka-broker -file cert-signed -storepass $KEYSTORE_PASSWORD -keypass $KEYSTORE_PASSWORD -noprompt

# 8. nothing to do

# 9. Creating client truststore
cd /etc/kafka/secrets/client
cp /etc/kafka/secrets/ca/ca-cert /etc/kafka/secrets/client/ca-cert

keytool -importcert -keystore kafka.client.truststore.jks -alias CARoot -file ca-cert -storepass $CLIENT_PASS -keypass $CLIENT_PASS -noprompt

# 10. create client properties
touch client.properties
echo security.protocol=SSL > client.properties
echo ssl.truststore.location=./kafka.client.truststore.jks >> client.properties
echo ssl.truststore.password=$CLIENT_PASS >> client.properties

# 11. Cleanup and Permissions
# chmod 644 /etc/kafka/secrets/server/kafka.server.keystore.jks 
# chmod 644 /etc/kafka/secrets/server/kafka.server.truststore.jks
# chmod 644 /etc/kafka/secrets/client/kafka.client.truststore.jks

echo "SSL Certificates generated successfully!"
echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
