#! /bin/bash
export KEYSTORE_PASSWORD=keystoreTKtPspFDZ2CYz3EluZMha24Drp
export TRUSTSTORE_PASSWORD=truststroreXa6DlDATAOHLTaIOcbRGZdpEYOx0
export CA_PASSWORD=caRstSWx9LvFSs3cjnBVkk1UhMyQQ
export CLIENT_PASS=clinetOLPrcS2pLLeN8WJmr1EVmEFCc

mkdir -p /var/kafka/secrets/ca
mkdir -p /var/kafka/secrets/server
mkdir -p /var/kafka/secrets/client

cd /var/kafka/secrets/server

if [ -f "kafka.server.keystore.jks" ]; then
    echo "Certificates already exist. Skipping generation."
    exit 0
fi

echo "Generating SSL Certificates..."

# all steps have same order as they are in 61-security-encryption.md

# 1. Generate CA
cd /var/kafka/secrets/ca
openssl req -new -x509 -newkey rsa:4096 -keyout ca-key -out ca-cert -days 3650 -subj "/CN=Kafka-Security-CA" -passout pass:$CA_PASSWORD

# 2. Create Truststore and import the CA
cd /var/kafka/secrets/server
cp /var/kafka/secrets/ca/ca-cert /var/kafka/secrets/server

keytool -keystore kafka.server.truststore.jks -alias CARoot -import -file ca-cert -storepass $TRUSTSTORE_PASSWORD -keypass $TRUSTSTORE_PASSWORD -noprompt

# 3. Generate Keystore
cd /var/kafka/secrets/server

keytool -genkeypair -keystore kafka.server.keystore.jks -keyalg RSA -keysize 2048 -alias kafka-broker -validity 3650 -storepass $KEYSTORE_PASSWORD -keypass $KEYSTORE_PASSWORD -storetype pkcs12 -dname "CN=192.168.150.100" -ext SAN=DNS:localhost,IP:127.0.0.1,IP:192.168.150.100

# 4. Create Certificate Signing Request (CSR)
keytool -keystore kafka.server.keystore.jks -certreq -alias kafka-broker -file server-cert-sign-request -storepass $KEYSTORE_PASSWORD -keypass $KEYSTORE_PASSWORD -ext SAN=DNS:localhost,IP:127.0.0.1,IP:192.168.150.100

# 5. Sign the Certificate with the CA
cp /var/kafka/secrets/server/server-cert-sign-request /var/kafka/secrets/ca

cd /var/kafka/secrets/ca

tee san.ext <<EOF
[ v3_req ]
subjectAltName = DNS:localhost,IP:127.0.0.1,IP:192.168.150.100
EOF

openssl x509 -req -CA ca-cert -CAkey ca-key -in server-cert-sign-request -out cert-signed -days 3650 -CAcreateserial -passin pass:$CA_PASSWORD -extfile /var/kafka/secrets/ca/san.ext -extensions v3_req

# 6. Import CA into Keystore
cp /var/kafka/secrets/ca/ca-cert /var/kafka/secrets/server
cd /var/kafka/secrets/server


keytool -importcert -keystore kafka.server.keystore.jks -alias CARoot -file ca-cert -storepass $KEYSTORE_PASSWORD -keypass $KEYSTORE_PASSWORD -noprompt

# 7. Import Signed Certificate into Keystore
cp /var/kafka/secrets/ca/cert-signed /var/kafka/secrets/server

keytool -importcert -keystore kafka.server.keystore.jks -alias kafka-broker -file cert-signed -storepass $KEYSTORE_PASSWORD -keypass $KEYSTORE_PASSWORD -noprompt

# 8. nothing to do

# 9. Creating client truststore
cd /var/kafka/secrets/client
cp /var/kafka/secrets/ca/ca-cert /var/kafka/secrets/client/ca-cert

keytool -importcert -keystore kafka.client.truststore.jks -alias CARoot -file ca-cert -storepass $CLIENT_PASS -keypass $CLIENT_PASS -noprompt

# 10. create client properties
tee client.properties <<EOF
security.protocol=SSL
ssl.truststore.location=./kafka.client.truststore.jks
ssl.truststore.password=$CLIENT_PASS
EOF

# 11. Cleanup and Permissions
# chmod 644 /var/kafka/secrets/server/kafka.server.keystore.jks 
# chmod 644 /var/kafka/secrets/server/kafka.server.truststore.jks
# chmod 644 /var/kafka/secrets/client/kafka.client.truststore.jks

echo "SSL Certificates generated successfully!"
echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="

sudo chown -R kafka:kafka /var/kafka