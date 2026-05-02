#! /bin/bash

mkdir -p /etc/kafka/secrets/client
cd /etc/kafka/secrets/client


echo "Generating producer properties file..."
tee sasl-producer.properties <<EOF
bootstrap.servers=localhost:9092

security.protocol=SASL_SSL
sasl.mechanism=PLAIN

sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required \\
    username="producer" \\
    password="producer-secret";

# SSL Truststore (Client side)
ssl.truststore.location=./kafka.client.truststore.jks
ssl.truststore.password=$CLIENT_PASS
ssl.endpoint.identification.algorithm=
EOF


echo "Generating consumer properties file..."
tee sasl-consumer.properties <<EOF
bootstrap.servers=localhost:9092

security.protocol=SASL_SSL
sasl.mechanism=PLAIN

sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required \\
    username="consumer" \\
    password="consumer-secret";

# SSL Truststore (Client side)
ssl.truststore.location=./kafka.client.truststore.jks
ssl.truststore.password=$CLIENT_PASS
ssl.endpoint.identification.algorithm=
EOF
