# احراز هویت به روش SASL_SSL

این روش در حقیقت ترکیبی از رمزنگاری ssl و احرازهویت sasl است.

مراحل انجام کار:

## مرحله اول: تنظیهات SSL

برای حفظ یکپارچگی مستندات و جلوگیری از تکرار، برای تنظیمات ssl لطفا از بخش [رمزنگاری ssl](./61-security-encryption.md) مراحل اول تا پایان مرحله هفتم و همچنین مرحله نهم را انجام دهید.

پس از اتمام، مراحل زیر را دنبال کنید.

## مرحله دوم: تنظیمات سرور

فایل server.properties را باز کنید و تغییرات زیر را اعمال کنید:

```conf
# ======================
# SSL Configuration
# ======================
# آدرس فایل های زیر مطابق سرور شما باید تغییر کند
ssl.keystore.location=/Users/sam/Desktop/workspace/kafka/secrets/server/kafka.server.keystore.jks
ssl.keystore.password=keystoreTKtPspFDZ2CYz3EluZMha24Drp
ssl.key.password=keystoreTKtPspFDZ2CYz3EluZMha24Drp
ssl.truststore.location=/Users/sam/Desktop/workspace/kafka/secrets/server/kafka.server.truststore.jks
ssl.truststore.password=truststroreXa6DlDATAOHLTaIOcbRGZdpEYOx0

listeners=SASL_SSL://:9092
advertised.listeners=SASL_SSL://localhost:9092

listener.security.protocol.map=CONTROLLER:SASL_SSL,SSL:SSL,SASL_SSL:SASL_SSL

# ======================
# SASL + SSL Settings
# ======================
sasl.enabled.mechanisms=PLAIN
sasl.mechanism.inter.broker.protocol=PLAIN
sasl.mechanism.controller.protocol=PLAIN

security.inter.broker.protocol=SASL_SSL

# ======================
# JAAS Configuration - Broker Listener
# ======================
listener.name.sasl_ssl.plain.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required \
    username="admin" \
    password="admin-secret" \
    user_admin="admin-secret" \
    user_producer="producer-secret" \
    user_consumer="consumer-secret" \
    user_mohammad="strongpassword";

# ======================
# JAAS Configuration - Controller
# ======================
listener.name.controller.plain.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required \
    username="admin" \
    password="admin-secret" \
    user_admin="admin-secret";
```

- دقت کنید که از تنظیم های security.inter.broker.protocol و inter.broker.listener.name فقط یک مورد موجود باشد.

پس از اعمال تغییرات، سرور کافکا را ری استارت کنید و در صورتیکه با موفقیت انجام شد به مرحله بعد بروید.

## مرحله سوم: تنظیمات کلاینت

برای اتصال به سرور، تنظیمات زیر را اعمال کنید. دقت کنید که نام کاربری و رمز عبور را میتواند از هر مورد دلخواهی مطابق با سرور انتخاب کنید.

```sh
tee producer.properties <<EOF
bootstrap.servers=localhost:9092

security.protocol=SASL_SSL
sasl.mechanism=PLAIN

sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required \\
    username="producer" \\
    password="producer-secret";

# SSL Truststore (Client side)
ssl.truststore.location=/Users/sam/Desktop/workspace/kafka/secrets/client/kafka.client.truststore.jks
ssl.truststore.password=clinetOLPrcS2pLLeN8WJmr1EVmEFCc
ssl.endpoint.identification.algorithm=
EOF
```

دقت کنید که در تمامی مراحل، در صورتیکه آدرس فایلی ذکر شده شما می بایست مطابق سرور خودتان تغییر دهید.

## مرحله چهار: تست عملکرد

```sh
kafka-console-producer --bootstrap-server localhost:9092 --command-config producer.properties --topic some-topic
```

سپس اقدام به ارسال پیام کنید.
