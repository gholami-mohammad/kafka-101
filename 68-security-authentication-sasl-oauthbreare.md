# احراز هویت به روش OAUTHBREARE

**در این بخش از آموزش فرض بر این است که شما در حال تنظیم کافکا در یک سرور لینوکس میباشید. پیش از این آموزش نصب در لینوکس در [بخش](./02-installation.md#linux-ubuntudebian) توضیح داده شده است.**

**همچنین، در این مرحله، نیاز است که مطابق آموزش [رمزنگاری](./61-security-encryption.md) ابتدا گواهینامه ssl را برای کافکا فعال کنید.**

### بخش اول: OAUTHBEARER چیست و دقیقاً چه کار می‌کند؟

در کافکا، ما مکانیزم‌های مختلفی برای احراز هویت تحت استاندارد SASL داریم (مثل PLAIN، SCRAM، GSSAPI/Kerberos). `OAUTHBEARER` یکی از این مکانیزم‌هاست که بر اساس استاندارد OAuth 2.0 کار می‌کند.

**مفهوم فنی:**
به جای اینکه کلاینت‌ها (Producer/Consumer) یا خود بروکرهای کافکا با نام کاربری و رمز عبور مستقیم به یکدیگر متصل شوند، از **Token (معمولاً JWT)** استفاده می‌کنند.

**جریان کار (Flow) چگونه است؟**

1. **درخواست توکن:** کلاینت (یا یک بروکر که می‌خواهد با بروکر دیگر صحبت کند) به Identity Provider یا IdP متصل می‌شود و با ارائه `Client ID` و `Client Secret` درخواست توکن می‌کند (این روش `Client Credentials Flow` نام دارد).
2. **صدور توکن:** سرویس Identity Provider یک `Access Token` (از نوع JWT) با اعتبار محدود (مثلاً ۵ دقیقه) صادر می‌کند.
3. **ارائه به کافکا:** کلاینت این توکن را در هدر اتصال خود به کافکا می‌فرستد.
4. **اعتبارسنجی (Validation):** کافکا نیازی ندارد برای چک کردن این توکن به Identity Provider وصل شود. کافکا فقط یک بار کلیدهای عمومی (Public Keys) را از یک آدرس مشخص در Identity Provider به نام **JWKS (JSON Web Key Set)** دانلود می‌کند و با استفاده از آن، امضای دیجیتال (Signature) توکن JWT را به صورت Local اعتبارسنجی می‌کند.

**مزیت:** امنیت بسیار بالا به دلیل عمر کوتاه توکن‌ها، عدم ذخیره پسورد در سمت کافکا، و مدیریت یکپارچه کاربران در Identity Provider.

---

### بخش دوم: تنظیمات Authentik (Identity Provider)

ما در این بخش از سرویس متن باز Authentik به عنوان Identity Provider استفاده خواهیم کرد.

در این آموزش فرض شده است که سرویس Authentik در سروری با آدرس 192.168.1.26 نصب شده است.

در Authentik شما باید تنظیمات زیر را انجام دهید تا کافکا بتواند با آن کار کند:

- **ساخت Provider:**
    - یک `OAuth2/OpenID Provider` بسازید.
    - نوع Client Type را روی `Confidential` قرار دهید.
    - مقادیر بسیار مهمی که از اینجا نیاز دارید و باید کپی کنید:
        - **آدرس Token URL:** آدرسی که کلاینت‌ها از آن توکن می‌گیرند.
        - **آدرس JWKS URL:** آدرسی که کافکا کلیدهای عمومی را از آن می‌خواند.
- **ساخت Application:**
    - یک Application بسازید و Provider مرحله قبل را به آن متصل کنید.

---

### بخش سوم: تنظیمات کافکا

ابتدا تنظیمات زیر را در فایل server.propertis اعمال نمایید:

```conf
listeners=BROKER://:9092,CONTROLLER://:9093

advertised.listeners=BROKER://localhost:9092,CONTROLLER://localhost:9093

inter.broker.listener.name=BROKER
controller.listener.names=CONTROLLER

listener.security.protocol.map=BROKER:SASL_SSL,CONTROLLER:SASL_SSL

# SSL Settings
ssl.keystore.location=/var/kafka/secrets/server/kafka.server.keystore.jks
ssl.keystore.password=keystoreTKtPspFDZ2CYz3EluZMha24Drp
ssl.key.password=keystoreTKtPspFDZ2CYz3EluZMha24Drp
ssl.truststore.location=/var/kafka/secrets/server/kafka.server.truststore.jks
ssl.truststore.password=truststroreXa6DlDATAOHLTaIOcbRGZdpEYOx0

# SASL settings
sasl.enabled.mechanisms=OAUTHBEARER
sasl.mechanism.inter.broker.protocol=OAUTHBEARER
sasl.mechanism.controller.protocol=OAUTHBEARER

# JWT settings
listener.name.broker.oauthbearer.sasl.server.callback.handler.class=org.apache.kafka.common.security.oauthbearer.OAuthBearerValidatorCallbackHandler
listener.name.broker.oauthbearer.sasl.login.callback.handler.class=org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginCallbackHandler
listener.name.broker.oauthbearer.sasl.oauthbearer.token.endpoint.url=http://192.168.1.26:9000/application/o/token/
listener.name.broker.oauthbearer.sasl.oauthbearer.jwks.endpoint.url=http://192.168.1.26:9000/application/o/kafka/jwks/
listener.name.broker.oauthbearer.sasl.oauthbearer.expected.audience=dKNm1s2X7Ka1R4ERD7lLZRzlNXTwsaDxN1WEfHuu
listener.name.broker.oauthbearer.sasl.jaas.config=org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required clientId='dKNm1s2X7Ka1R4ERD7lLZRzlNXTwsaDxN1WEfHuu' clientSecret='2h8B1PKXTRVYcB3O5iP9xIN3Y4WOV4upYhFKnSboYKSfGP8Phka2txVoXHfjNpdVuY4RotUnci0ZKlDU87j2ujFTagRnt35ypoa6o9hRLOQqXwRSZg3l5sRgd0H4xRF7' scope="openid profile email";

listener.name.controller.oauthbearer.sasl.server.callback.handler.class=org.apache.kafka.common.security.oauthbearer.OAuthBearerValidatorCallbackHandler
listener.name.controller.oauthbearer.sasl.login.callback.handler.class=org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginCallbackHandler
listener.name.controller.oauthbearer.sasl.oauthbearer.token.endpoint.url=http://192.168.1.26:9000/application/o/token/
listener.name.controller.oauthbearer.sasl.oauthbearer.jwks.endpoint.url=http://192.168.1.26:9000/application/o/kafka/jwks/
listener.name.controller.oauthbearer.sasl.oauthbearer.expected.audience=dKNm1s2X7Ka1R4ERD7lLZRzlNXTwsaDxN1WEfHuu
listener.name.controller.oauthbearer.sasl.jaas.config=org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required clientId='dKNm1s2X7Ka1R4ERD7lLZRzlNXTwsaDxN1WEfHuu' clientSecret='2h8B1PKXTRVYcB3O5iP9xIN3Y4WOV4upYhFKnSboYKSfGP8Phka2txVoXHfjNpdVuY4RotUnci0ZKlDU87j2ujFTagRnt35ypoa6o9hRLOQqXwRSZg3l5sRgd0H4xRF7' scope="openid profile email";
```

سپس تنظیمات سرویس کافکا را مطابق زیر بروز رسانی کنید:

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

با اجرای دستور `sudo journalctl -u kafka.service -f` مطمئن باشید که Kafka Server started را خواهید دید و خطایی در اجرا رخ نداده است.

در صورتیکه این مرحله با موفقیت به پایان رسید، میتوانید به مرحله بعدی بروید.

---

### بخش چهارم: تنظیمات کلاینت (Producer/Consumer)

حالا که کافکای شما امن شده است، اگر یک برنامه (مثلاً با پایتون یا جاوا) بخواهد به کافکا وصل شود، باید تنظیمات کلاینت را به این شکل ست کند.

نمونه تنظیمات `client.properties` (برای کلاینت جاوایی):

```sh
tee client.sasl_oauthbearer.properties <<EOF
bootstrap.servers=192.168.150.100:9092
security.protocol=SASL_SSL

# SSL
ssl.truststore.location=./kafka.client.truststore.jks
ssl.truststore.password=clinetOLPrcS2pLLeN8WJmr1EVmEFCc
# SASL
sasl.mechanism=OAUTHBEARER
sasl.oauthbearer.client.credentials.client.id=dKNm1s2X7Ka1R4ERD7lLZRzlNXTwsaDxN1WEfHuu
sasl.oauthbearer.client.credentials.client.secret=2h8B1PKXTRVYcB3O5iP9xIN3Y4WOV4upYhFKnSboYKSfGP8Phka2txVoXHfjNpdVuY4RotUnci0ZKlDU87j2ujFTagRnt35ypoa6o9hRLOQqXwRSZg3l5sRgd0H4xRF7
sasl.oauthbearer.scope="openid profile email"
sasl.jaas.config=org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required;
sasl.login.callback.handler.class=org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginCallbackHandler
sasl.oauthbearer.token.endpoint.url=http://192.168.1.26:9000/application/o/token/
sasl.oauthbearer.jwks.endpoint.url=http://192.168.1.26:9000/application/o/kafka/jwks/
sasl.oauthbearer.expected.audience=dKNm1s2X7Ka1R4ERD7lLZRzlNXTwsaDxN1WEfHuu
EOF
```

**لطفا در فایل ساخته شده، آدرس ssl.truststore.location را مطابق کلاینت خود تنظیم کنید.**

سپس با استفاده از دستورات زیر میتوانید عملکرد کلاینت خود را بررسی کنید:

```sh
KAFKA_OPTS="-Dorg.apache.kafka.sasl.oauthbearer.allowed.urls=http://192.168.1.26:9000/application/o/kafka/jwks/,http://192.168.1.26:9000/application/o/token/" sudo kafka-topics.sh --bootstrap-server 192.168.150.100:9092 --command-config ./client.sasl_oauthbearer.properties --create --topic some-topic

KAFKA_OPTS="-Dorg.apache.kafka.sasl.oauthbearer.allowed.urls=http://192.168.1.26:9000/application/o/kafka/jwks/,http://192.168.1.26:9000/application/o/token/" kafka-console-producer.sh --bootstrap-server 192.168.150.100:9092 --command-config ./client.sasl_oauthbearer.properties --topic some-topic
```

### نکات حیاتی یک متخصص:

1. **امنیت شبکه:** استفاده از `SASL_PLAINTEXT` یعنی توکن شما در شبکه به صورت متن باز (Clear Text) منتقل می‌شود که خطر سرقت توکن (Token Hijacking) دارد. در محیط پروداکشن حتماً از `SASL_SSL` استفاده کنید تا ترافیک TLS/SSL رمزنگاری شود.
2. **همگام‌سازی زمان (NTP):** چون اعتبارسنجی JWT بر اساس زمان است (فیلدهای `exp` و `nbf`)، حتماً سرورهای کافکا و سرور Authentik باید از نظر زمانی سینک باشند (با سرویس NTP). در غیر این صورت توکن‌ها بی‌دلیل نامعتبر شناخته می‌شوند.

---

---

---

---

```sh
openssl s_client -showcerts -connect 192.168.1.26:6443 </dev/null 2>/dev/null | openssl x509 -outform PEM > /tmp/authentik.pem

sudo mv /tmp/authentik.pem /var/kafka/secrets/server
sudo chown -R kafka:kafka /var/kafka

sudo keytool -import -alias authentik-cert -file /var/kafka/secrets/server/authentik.pem -keystore /var/kafka/secrets/server/kafka.server.truststore.jks -storepass truststroreXa6DlDATAOHLTaIOcbRGZdpEYOx0 -noprompt

```
