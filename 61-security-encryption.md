# رمزنگاری - Encryption

- رمزنگاری در کافکا، این اطمینان را میدهد که داده بین کلاینت و broker به صورت ایمن منتقل میشود و از دید روتر های مسیر و سایر افراد در این شبکه مخفی است.
  ![ssl encryption](ssl-encryption.png)

در ادامه، ابتدا به ساخت یک Certificate Authority (CA) خواهیم پرداخت.

### مرحله اول راه اندازی CA (اجرا در سرور CA)

**درصورتیکه از یک CA معتبر یا CA در شبکه استفاده میکنید، میتوانید این مرحله را عبور کنید.**

```sh
mkdir -p ~/Desktop/workspace/kafka/secrets/ca
cd ~/Desktop/workspace/kafka/secrets/ca

export CA_PASSWORD=caRstSWx9LvFSs3cjnBVkk1UhMyQQ
openssl req -new -x509 -newkey rsa:4096 -keyout ca-key -out ca-cert -days 3650 -subj "/CN=Kafka-Security-CA" -passout pass:$CA_PASSWORD
```

درصورتیکه میخواهید کلید CA فاقد رمز باشد از این دستور استفاده کنید:

```sh
openssl req -new -x509 -newkey rsa:4096 -keyout ca-key -out ca-cert -days 3650 -subj "/CN=Kafka-Security-CA" -noenc
```

توضیحات:

سوییچ = flag

- سوییچ `-new`: ایجاد کلید جدید
- سوییچ `-newkey rsa:4096`: ایجاد کلید RSA با طول ۴۰۹۶ بیت
- سوییچ `-days 365`: مدت زمان اعتبار ۳۶۵ روز
- سوییچ `-x509`: جهت امضا کردن گواهینامه (self signed certificate)
- سوییچ `-subj "/CN=Kafka-Security-CA"`: اضافه کردن اطلاعات شناسایی یه گواهینامه. در این دستور مقدار CN یا همان Common Name به مقدار Kafka-Security-CA تنظیم شده است.
- سوییچ `-keyout ca-key`: خروجی دادن کلید خصوصی در فایلی به نام ca-key
- سوییچ `-out ca-cert`: خروجی دادن گواهینامه عمومی در فایلی به نام ca-cert
- سوییچ `-noenc`: به این معنی است که کلید خصوصی را رمزنگاری نکن. در نسخه های قدیمی تر این سوییچ با -nodes اعمال میشد.

### مرحله دوم: تنظیمات Truststore (اجرا در سرور کافکا)

در این مرحله، یک truststore ایجاد میکنیم و کلید عمومی CA را در آن اضافه میکنیم.

```sh
mkdir -p ~/Desktop/workspace/kafka/secrets/server
cd ~/Desktop/workspace/kafka/secrets/server

# copy ca-cert from CA into kafka server
cp ~/Desktop/workspace/kafka/secrets/ca/ca-cert ./

export TRUSTSTORE_PASSWORD=truststroreXa6DlDATAOHLTaIOcbRGZdpEYOx0

keytool -importcert -keystore kafka.server.truststore.jks -alias CARoot -file ca-cert -storepass $TRUSTSTORE_PASSWORD -keypass $TRUSTSTORE_PASSWORD -noprompt
```

### مرحله سوم: ساخت Keystore (اجرا در سرور کافکا)

```sh
export KEYSTORE_PASSWORD=keystoreTKtPspFDZ2CYz3EluZMha24Drp

keytool -genkeypair -keystore kafka.server.keystore.jks -keyalg RSA -keysize 2048 -alias kafka-broker -validity 3650 -storepass $KEYSTORE_PASSWORD -keypass $KEYSTORE_PASSWORD -storetype pkcs12 -dname "CN=localhost" -ext SAN=DNS:localhost,IP:127.0.01
```

مقدار CN در گواهینامه باید با آدرس بروکر در شبکه یکی باشد. در غیر اینصورت امکان ارتباط با بروکر میسر نخواهد بود.
این مقدار، میتواند آدرس آی پی سرور یا نام هاست سرور باشد.

نکته: در سوییچ ext میتوان لیست تمام بروکر ها و کنترلر ها را ذکر کرد.

جهت مشاهده محتوای کلید تولید شده را مشاهده کنیم از دستور زیر استفاده میکنیم:

```sh
keytool -list -v -keystore kafka.server.keystore.jks
```

### مرحله چهارم: ایجاد درخواست گواهینامه یا CSR (Certificate Signing Request) - (اجرا در سرور کافکا)

```sh
## دریافت فایل درخواست امضای گواهینامه - Sign request
keytool -keystore kafka.server.keystore.jks -certreq -alias kafka-broker -file server-cert-sign-request -storepass $KEYSTORE_PASSWORD -keypass $KEYSTORE_PASSWORD
```

نکته: مقدار تنظیم شده برای سوییچ alias باید همانند مقداری باشد که زمان ساخت keystore استفاده شده است.

### مرحله پنجم: امضای CSR در CA - (اجرا در CA)

درصورتیکه از یک CA معتبر یا CA شبکه بخواهیم گواهینامه دریافت کنیم، این فایل را برای آنها ارسال میکنیم و آنها یک گواهینامه برای ما تولید میکنند.
حال اگر بخواهیم خودمان به صورت self signed این گواهینامه را تولید کنیم، مرحله بعد را نیز انجام میدهیم:

```sh
cp ~/Desktop/workspace/kafka/secrets/server/server-cert-sign-request ~/Desktop/workspace/kafka/secrets/ca
cd ~/Desktop/workspace/kafka/secrets/ca

openssl x509 -req -CA ca-cert -CAkey ca-key -in server-cert-sign-request -out cert-signed -days 3650 -CAcreateserial -passin pass:$CA_PASSWORD
```

جهت مشاهده جزییات گواهینامه از دستور زیر استفاده میشود:

```sh
keytool -printcert -v -file cert-signed
```

### مرحله ششم: افزودن گواهینامه عمومی CA به keystore - (اجرا در سرور کافکا)

```sh
cp ~/Desktop/workspace/kafka/secrets/ca/ca-cert ~/Desktop/workspace/kafka/secrets/server
cd ~/Desktop/workspace/kafka/secrets/server

keytool -importcert -keystore kafka.server.keystore.jks -alias CARoot -file ca-cert -storepass $KEYSTORE_PASSWORD -keypass $KEYSTORE_PASSWORD -noprompt
```

### مرحله هفتم اضافه کردن کلید امضا شده به keystore (اجرا در سرور کافکا)

در این مرحله نیز باید کلید امضا شده ای که در مرحله پنجم ایجاد شده را به keystore ایمپورت کنیم.

```sh
cp ~/Desktop/workspace/kafka/secrets/ca/cert-signed ~/Desktop/workspace/kafka/secrets/server
cd ~/Desktop/workspace/kafka/secrets/server

keytool -importcert -keystore kafka.server.keystore.jks -alias kafka-broker -file cert-signed -storepass $KEYSTORE_PASSWORD -keypass $KEYSTORE_PASSWORD -noprompt
```

---

### مرحله هشتم: تنظیمات سرور کافکا (اجرا در سرور کافکا)

برای فعال سازی رمزنگاری ارتباط، تغییرات زیر را در فایل server.properties و broker.properties اعمال کنید:

```conf
listeners=SSL://0.0.0.0:29092 # ادرس را میتوان مطابق نیاز تغییر داد.
advertised.listeners=SSL://localhost:29092 # این مقدار میتواند معادل آدرس هاست دی ان اس این سرور باشد

# آدرس فایل های زیر مطابق سرور شما باید تغییر کند
ssl.keystore.location=/Users/sam/Desktop/workspace/kafka/secrets/server/kafka.server.keystore.jks
ssl.keystore.password=keystoreTKtPspFDZ2CYz3EluZMha24Drp
ssl.key.password=keystoreTKtPspFDZ2CYz3EluZMha24Drp
ssl.truststore.location=/Users/sam/Desktop/workspace/kafka/secrets/server/kafka.server.truststore.jks
ssl.truststore.password=truststroreXa6DlDATAOHLTaIOcbRGZdpEYOx0

```

پس از اعمال تغییرات، سرویس کافکا را ری استارت کنید. در صورتیکه با موفقیت ری استارت شد، با دستور زیر میتوانید مطمئن شوید که کافکا در پورت تعیین شده در حال گوش دادن به درخواست هست:

```sh
openssl s_client -connect localhost:29092
```

تا این مرحله ما سرور کافکا را تنظیم کرده ایم. در ادامه به تنظیمات کلاینت کافکا خواهیم پرداخت.

### تنظیمات کلاینت کافکا (اجرا در کلاینت)

برای اضافه کردن کلیدهای عمومی کافکا در کلاینت، ۲ راه وجود دارد:
اول: در keystore کلاینت، تمام کلید هایی که بوسیله CA معتبر شبکه تولید شده اند، معتبر دانسته شوند.

دوم: تک تک گواهینامه های عمومی تولید شده یک یک در keystore کلاینت اضافه شود. این روش سربار تنظیمات بسیار بالایی دارد خصوصا زمانیکه تعداد بروکر های شبکه زیاد باشد.

در ادامه تنها به بررسی روش اول خواهیم پرداخت.

ابتدا فایل کلید عمومی که توسط CA تولید شده است را به پوشه ای به نام ssl کپی کنید.

در این مستند، در زمان تنظیم سرور،‌این فایل به نام ca-cert ساخته شده است.

### مرحله نهم: افزودن کلید عمومی CA به truststore کلاینت (اجرا در کلاینت)

حال، میبایست یک truststore برای کلاینت ایجاد کنیم و فایل ca-cert موجود را در آن اضافه نماییم.

```sh
mkdir ~/Desktop/workspace/kafka/secrets/client
cd ~/Desktop/workspace/kafka/secrets/client

cp ~/Desktop/workspace/kafka/secrets/ca/ca-cert ./

export CLIENT_PASS=clinetOLPrcS2pLLeN8WJmr1EVmEFCc

keytool -importcert -keystore kafka.client.truststore.jks -alias CARoot -file ca-cert -storepass $CLIENT_PASS -keypass $CLIENT_PASS -noprompt
```

برای مشاهده جزییات این truststore میتوانید از این دستور استفاده کنید:

```sh
keytool -list -v -keystore kafka.client.truststore.jks
```

پس از اتمام این مرحله، سرور کافکا را راه اندازی مجدد کنید و از اجرای صحیح آن مطمئن شوید.

### مرحله دهم: ایجاد تنظیمات کلاینت - (اجرا در کلاینت)

حال نیاز به ساخت یک فایل تنظیمات برای کلاینت جهت ارتباط با سرور کافکا داریم:

```sh
tee client.properties <<EOF
security.protocol=SSL
ssl.truststore.location=/Users/sam/Desktop/workspace/kafka/secrets/client/kafka.client.truststore.jks
ssl.truststore.password=clinetOLPrcS2pLLeN8WJmr1EVmEFCc
EOF
```

توجه: آدرس فایل ssl.truststore.location را مطابق سرور خودتان تنظیم نمایید

### مرحله یازدهم: تست عملکرد (اجرا در کلاینت)

در ادامه میتوان به کمک دستورات کافکا به سرور ارتباط امن گرفت. برای مثال جهت اجرای دستور producer میتوان به شکل زیر عمل کرد:

```sh
kafka-topics --bootstrap-server localhost:29092 --command-config ./client.properties --create --topic some-topic

kafka-console-producer --bootstrap-server localhost:29092 --topic some-topic --command-config ./client.properties
```

توجه کنید که localhost:29092 آدرس سرور کافکا است که ssl است.

همچنین برای خواندن پیام های تاپیک:

```sh
kafka-console-consumer --bootstrap-server localhost:29092 --command-config ./client.properties --topic some-topic --from-beginning
```

### سخن آخر

زمانی که رمزنگاری ارتباط برای کلاینت و سرور کافکا فعال شود، تاثیر قابل مشاهده ای در میزان مصرف رم و سی پی یو سرور و کلاینت خود مشاهده خواهید کرد که به علت سربار موردنیاز برای رمزنگاری و رمزگشایی پیام ها میباشد.
