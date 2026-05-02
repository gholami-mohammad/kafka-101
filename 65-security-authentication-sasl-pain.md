# احرازهویت کلاینت به روش SASL_PLAIN

**اخطار: به هیچ عنوان از این روش برای تنظیم کافکا در محیط پروداکشن استفاده نکنید.**

## مرحله اول: تنظیمات سرور

در فایل server.properties موارد زیر را تغییر دهید یا اضافه کنید.

```conf
listeners=SASL_PLAINTEXT://:9092,CONTROLLER://:9093
controller.listener.names=CONTROLLER
advertised.listeners=SASL_PLAINTEXT://localhost:9092

inter.broker.listener.name=SASL_PLAINTEXT
listener.security.protocol.map=CONTROLLER:SASL_PLAINTEXT, SASL_PLAINTEXT:SASL_PLAINTEXT

# SASL settings
sasl.enabled.mechanisms=PLAIN
sasl.mechanism.inter.broker.protocol=PLAIN
sasl.mechanism.controller.protocol=PLAIN

# JAAS for the main broker listener
listener.name.sasl_plaintext.plain.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required \
    username="admin" \
    password="admin-secret" \
    user_admin="admin-secret" \
    user_producer="producer-secret" \
    user_consumer="consumer-secret" \
    user_mohammad="strongpassword";

# JAAS for Controller
listener.name.controller.plain.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required \
    username="admin" \
    password="admin-secret" \
    user_admin="admin-secret";
```

- مطمعن باشید که inter.broker.listener.name کامنت باشد.
- در تنظیمات نامهای کاربری، مقدار username برای ارتباط بین بروکر ها استفاده میشود.
- فیلد password همان رمز عبور سرور است که برای ارتباط بین بروکر ها استفاده میشود.
- فیلدهای user_admin, user_producer, user_consumer که به فرمت user_USERNAME=PASSWORD تنظیم میشوند، نام کاربری ها و پسورد های متناظری است که میتوان به کلاینت ها اختصاص داد.

پس از تغییر سرور را ری استارت کنید.

## مرحله دوم نتظیمات کلاینت

فایلی با نام producer.properties ایجاد کنید:

```sh
tee producer.properties <<EOF
bootstrap.servers=localhost:9092

security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN

sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required \\
    username="producer" \\
    password="producer-secret";
EOF
```

و سپس با دستور زیر متصل شوید:

```sh
kafka-console-producer --bootstrap-server localhost:9092 --command-config producer.properties --topic some-topic
```

برای انتخاب نام کاربری و رمز عبور، میتوانید از هریک از مواردی که در سرور تنظیم کرده این استفاده کنید.
