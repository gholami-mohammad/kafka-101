# احراز هویت به روش OAUTHBREARE

```sh
openssl s_client -showcerts -connect 192.168.1.26:6443 </dev/null 2>/dev/null | openssl x509 -outform PEM > /tmp/authentik.pem

sudo mv /tmp/authentik.pem /var/kafka/secrets/server
sudo chown -R kafka:kafka /var/kafka

sudo keytool -import -alias authentik-cert -file /var/kafka/secrets/server/authentik.pem -keystore /var/kafka/secrets/server/kafka.server.truststore.jks -storepass truststroreXa6DlDATAOHLTaIOcbRGZdpEYOx0 -noprompt

```

```sh
sudo tee /etc/systemd/system/kafka.service <<EOF
[Unit]
Description=Apache Kafka
After=network.target

[Service]
Type=simple
User=kafka
Group=kafka

Environment="KAFKA_OPTS=-Dorg.apache.kafka.sasl.oauthbearer.allowed.urls=http://192.168.1.26:9000/application/o/kafka/jwks/,http://192.168.1.26:9000/application/o/token/"
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
Restart=on-abnormal

# Security Hardening
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/kafka /var/kafka
LimitNOFILE=100000

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl restart kafka.service
sudo journalctl -u kafka.service -f
```

```conf
listeners=SASL_PLAINTEXT://:9092,CONTROLLER://:9093

advertised.listeners=CLIENT://localhost:9092,CONTROLLER://localhost:9093,BROKER://localhost:9094

inter.broker.listener.name=BROKER
controller.listener.names=CONTROLLER

security.inter.broker.protocol=SASL_PLAINTEXT

listener.security.protocol.map=CLIENT:SASL_SSL,BROKER:SASL_SSL,CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL

# SSL Settings
ssl.keystore.location=/var/kafka/secrets/server/kafka.server.keystore.jks
ssl.keystore.password=keystoreTKtPspFDZ2CYz3EluZMha24Drp
ssl.key.password=keystoreTKtPspFDZ2CYz3EluZMha24Drp
ssl.truststore.location=/var/kafka/secrets/server/kafka.server.truststore.jks
ssl.truststore.password=truststroreXa6DlDATAOHLTaIOcbRGZdpEYOx0

# SASL settings
sasl.enabled.mechanisms=OAUTHBEARER
sasl.mechanism.inter.broker.protocol=OAUTHBEARER

# JWT settings
listener.name.sasl_plaintext.oauthbearer.sasl.server.callback.handler.class=org.apache.kafka.common.security.oauthbearer.OAuthBearerValidatorCallbackHandler
listener.name.sasl_plaintext.oauthbearer.sasl.login.callback.handler.class=org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginCallbackHandler
listener.name.sasl_plaintext.oauthbearer.sasl.oauthbearer.token.endpoint.url=http://192.168.1.26:9000/application/o/token/
listener.name.sasl_plaintext.oauthbearer.sasl.oauthbearer.expected.audience=dKNm1s2X7Ka1R4ERD7lLZRzlNXTwsaDxN1WEfHuu
sasl.oauthbearer.jwks.endpoint.url=http://192.168.1.26:9000/application/o/kafka/jwks/
listener.name.sasl_plaintext.oauthbearer.sasl.jaas.config=org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required clientId='dKNm1s2X7Ka1R4ERD7lLZRzlNXTwsaDxN1WEfHuu' clientSecret='2h8B1PKXTRVYcB3O5iP9xIN3Y4WOV4upYhFKnSboYKSfGP8Phka2txVoXHfjNpdVuY4RotUnci0ZKlDU87j2ujFTagRnt35ypoa6o9hRLOQqXwRSZg3l5sRgd0H4xRF7' scope="openid";
```
