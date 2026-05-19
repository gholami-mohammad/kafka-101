<div dir="rtl">

# راهنمای مانیتورینگ کافکا با استفاده از Prometheus و Grafana

در این راهنما مراحل راه‌اندازی یک سیستم مانیتورینگ برای کلاستر کافکا توضیح داده شده است. هدف این است که بتوانیم وضعیت پیام‌ها، مصرف‌کننده‌ها، منابع سرور و سلامت بروکرها را مشاهده و تحلیل کنیم.

## معماری کلی سیستم

معماری مانیتورینگ به شکل زیر است:

kafka cluster → Kafka Exporter و JMX Exporter → Prometheus → Grafana

در این ساختار ابزارهای exporter متریک‌ها را جمع‌آوری می‌کنند، پرومتئوس آن‌ها را ذخیره می‌کند و گرافانا آن‌ها را به‌صورت داشبورد نمایش می‌دهد.

---

## معرفی اجزای سیستم

### پرومتئوس (Prometheus)

 پرومتئوس یک سیستم مانیتورینگ و جمع‌آوری متریک است که داده‌ها را به‌صورت time‑series ذخیره می‌کند.

ویژگی‌های مهم:

- جمع‌آوری متریک‌ها از سرویس‌ها
- ذخیره‌سازی داده‌ها در پایگاه داده زمانی
- امکان جستجو با زبان کوئری PromQL
- امکان تعریف هشدار

مدل کاری پرومتئوس از نوع Pull است؛ یعنی خود پرومتئوس به سرویس‌ها مراجعه می‌کند و متریک‌ها را دریافت می‌کند. این عملیات Scrape نام دارد.

---

### گرافانا (Grafana)

 گرافانا برای نمایش داده‌های مانیتورینگ استفاده می‌شود. این ابزار به منابع داده مانند پرومتئوس متصل می‌شود و داشبوردهای گرافیکی می‌سازد.

قابلیت‌های مهم:

- ساخت داشبوردهای گرافیکی
- نمایش نمودار، Gauge و جدول
- پشتیبانی از منابع داده مختلف
- امکان تعریف هشدار

---

### ابزار Kafka Exporter

ابزار Kafka Exporter متریک‌های مربوط به کافکا را جمع‌آوری می‌کند و آن‌ها را در قالبی که پرومتئوس می‌تواند بخواند منتشر می‌کند.

نمونه متریک‌هایی که این ابزار ارائه می‌دهد:

- تعداد بروکرها
- تعداد تاپیک‌ها
- تعداد پارتیشن‌ها
- مقدار Consumer Lag

مفهوم Consumer Lag یکی از مهم‌ترین شاخص‌ها در مانیتورینگ کافکا است.

فرمول آن به شکل زیر است:

آخرین Offset تولید شده − آخرین Offset مصرف شده

اگر این مقدار زیاد شود یعنی مصرف‌کننده‌ها از تولیدکننده‌ها عقب افتاده‌اند.

---

### ابزار JMX Exporter

در کافکا بسیاری از متریک‌های داخلی از طریق فناوری JMX در دسترس هستند. ابزار JMX Exporter این متریک‌ها را به فرمت قابل خواندن برای پرومتئوس تبدیل می‌کند.

نمونه متریک‌هایی که از طریق JMX دریافت می‌شوند:

- مصرف حافظه JVM
- وضعیت Garbage Collection
- تعداد Thread ها
- مصرف CPU

---


## Linux (Ubuntu/Debian)

## مرحله اول: نصب پیش‌نیازها

ابتدا ابزارهای پایه را نصب می‌کنیم:

```bash
sudo apt update
sudo apt install wget curl tar -y
```

سپس مسیر اصلی پروژه را ایجاد می‌کنیم:

```bash
sudo mkdir -p /opt/kafka
```

---

## مرحله دوم: نصب kafka

برای نصب کافکا به [اینجا](02-installation.md) مراجعه کنید

## مرحله سوم: نصب Prometheus

ابتدا نسخه مورد نظر پرومتئوس را دانلود می‌کنیم:

```bash
wget https://github.com/prometheus/prometheus/releases/download/v2.52.0/prometheus-2.52.0.linux-amd64.tar.gz
```

فایل دانلود شده را استخراج می‌کنیم:

```bash
tar -xvf prometheus-2.52.0.linux-amd64.tar.gz
```

پوشه را به مسیر مورد نظر منتقل می‌کنیم:

```bash
sudo mv prometheus-2.52.0.linux-amd64 /opt/kafka/prometheus
```

سپس پوشه داده را می‌سازیم:

```bash
sudo mkdir /opt/kafka/prometheus/data
```

---

## مرحله چهارم: تنظیم فایل پیکربندی Prometheus

فایل تنظیمات در مسیر زیر قرار دارد:

```bash
vim /opt/kafka/prometheus/prometheus.yml
```

نمونه تنظیمات:

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'kafka_exporter'
    static_configs:
      - targets: ['localhost:9308']

  - job_name: 'kafka_jmx'
    static_configs:
      - targets: ['localhost:7071']
```

---

## مرحله پنجم: اجرای Prometheus

برای اجرای پرومتئوس از دستور زیر استفاده می‌کنیم:

```bash
sudo /opt/kafka/prometheus/prometheus \
  --config.file=/opt/kafka/prometheus/prometheus.yml \
  --storage.tsdb.path=/opt/kafka/prometheus/data
```

پس از اجرا رابط کاربری از طریق آدرس زیر در دسترس خواهد بود:

```bash
http://SERVER_IP:9090
```

برای بررسی وضعیت تارگت‌ها:

```bash
http://SERVER_IP:9090/targets
```

---

## مرحله ششم: نصب Kafka Exporter

ابتدا نسخه مناسب را دانلود می‌کنیم:

```bash
wget https://github.com/danielqsj/kafka_exporter/releases/download/v1.7.0/kafka_exporter-1.7.0.linux-amd64.tar.gz
```

سپس آن را استخراج می‌کنیم:

```bash
tar -xvf kafka_exporter-1.7.0.linux-amd64.tar.gz
```

پوشه را به مسیر پروژه منتقل می‌کنیم:

```bash
sudo mv kafka_exporter-1.7.0.linux-amd64 /opt/kafka/kafka_exporter
```

---

## مرحله هفتم: اجرای Kafka Exporter

نمونه اجرای exporter:

```bash
/opt/kafka/kafka_exporter/kafka_exporter \
  --kafka.server=localhost:9392 \
  --kafka.server=localhost:9492 \
  --kafka.server=localhost:9592
```

پس از اجرا متریک‌ها از طریق آدرس زیر قابل مشاهده هستند:

```bash
http://localhost:9308/metrics
```

---

## مرحله هشتم: نصب JMX Exporter

ابتدا مسیر مربوط به JMX را ایجاد می‌کنیم:

```bash
sudo mkdir -p /opt/kafka/kafka_jmx
```

سپس فایل Java Agent را دانلود می‌کنیم:

```bash
wget https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.20.0/jmx_prometheus_javaagent-0.20.0.jar
```

فایل رو به مسیر زیر انتقال می دهیم
```bash
sudo mv jmx_prometheus_javaagent-0.20.0.jar /opt/kafka/kafka_jmx
```

حالا یک فایل config می سازیم

```bash
vim /opt/kafka_jmx.yml
```

داخلش
```bash
startDelaySeconds: 0
ssl: false

lowercaseOutputName: true
lowercaseOutputLabelNames: true

rules:
  - pattern: ".*"

```

---

## مرحله نهم: اتصال JMX Exporter به بروکر کافکا

برای فعال کردن JMX Exporter باید متغیر زیر به تنظیمات اجرای بروکر اضافه شود:
اگر systemd داری:

فایل سرویس را پیدا کن:
```bash
sudo systemctl status kafka
```

داخل سرویس اضافه کن:
```bash
Environment="KAFKA_OPTS=-javaagent:/opt/kafka/kafka_jmx/jmx_prometheus_javaagent-0.20.0.jar=7071:/opt/kafka/kafka_jmx/kafka_jmx.yml"
```


یا اگر با script اجرا می‌کنی:
در فایل kafka-server-start.sh قبل اجرا:
```bash
export KAFKA_OPTS="-javaagent:/opt/kafka/kafka-jmx/jmx_prometheus_javaagent-0.20.0.jar=7071:/opt/kafka/kafka-jmx/kafka_jmx.yml"
```

خوب حالا systemd رو reload (اگر با systemd کافکا را اجرا می کنی)کن 

```bash
sudo systemctl daemon-reload
```

حالا Kafka را restart کن
```bash
systemctl restart kafka
```
یا اگر دستی اجرا می‌کنی stop/start.


پس از راه‌اندازی مجدد بروکر متریک‌ها در آدرس زیر در دسترس خواهند بود:

```bash
http://localhost:7071/metrics
```

---

## مرحله دهم: بررسی متریک‌ها در پرومتئوس

در رابط کاربری پرومتئوس می‌توان کوئری‌های زیر را اجرا کرد:

- kafka_brokers
- kafka_topic_partitions
- jvm_memory_bytes_used

این متریک‌ها وضعیت کلاستر کافکا و JVM را نشان می‌دهند.





---


## With Docker


## 1. پیش نیاز ها
 
فایل Java Agent را دانلود می‌کنیم:

```bash
wget https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.20.0/jmx_prometheus_javaagent-0.20.0.jar
```

## 2. ساختار پوشه‌ها

داخل یک پوشه (مثلاً kafka-project) فایل‌ها را به شکل زیر بچینید:

```bash
/opt/kafka-project/
├── docker-compose.yml
├── prometheus.yml
└── jmx-exporter/
    └── jmx-exporter-config.yml
```


فایل رو به مسیر زیر انتقال می دهیم
```bash
sudo mv jmx_prometheus_javaagent-0.20.0.jar /opt/kafka-project/jmx_prometheus_javaagent.jar
```

در نهایت:
```bash
/opt/kafka-project/
├── docker-compose.yml
├── prometheus.yml
└── jmx-exporter/
    ├── jmx_prometheus_javaagent.jar
    └── jmx-exporter-config.yml
```


## 3. تنظیم فایل‌های پیکربندی

```bash
jmx-exporter-config.yml
```
برای تست، فقط یک قانون ساده بنویسید تا همه متریک‌ها جمع‌آوری شوند:

```bash
startDelaySeconds: 0
ssl: false

lowercaseOutputName: true
lowercaseOutputLabelNames: true

rules:
  - pattern: ".*"

```

سپس فایل prometheus:
```bash
prometheus.yml
```

Prometheus را طوری تنظیم کنید که هم داده‌های JMX و هم Kafka Exporter را بخواند:
```bash
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: 'kafka-jmx'
    static_configs:
      - targets: ['kafka1:9101', 'kafka2:9101', 'kafka3:9101']

  - job_name: 'kafka-exporter'
    static_configs:
      - targets: ['kafka-exporter:9308']
```

## 4. فایل نهایی docker

در نهایت نوبت به فایل docker می رسد
```bash
docker-compose.yml
```

برای تست، فقط یک قانون ساده بنویسید تا همه متریک‌ها جمع‌آوری شوند:
```bash
services:
  kafka1:
    image: bitnami/kafka:latest
    container_name: kafka1
    hostname: kafka1
    ports:
      - "9192:9092"
      - "9101:9101"
    environment:
      - KAFKA_CFG_NODE_ID=1
      - KAFKA_CFG_PROCESS_ROLES=broker,controller
      - KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093
      - KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka1:9092
      - KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT
      - KAFKA_CFG_INTER_BROKER_LISTENER_NAME=PLAINTEXT
      - KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER
      - KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=1@kafka1:9093,2@kafka2:9093,3@kafka3:9093
      - KAFKA_KRAFT_CLUSTER_ID=abcdefghijklmnopqrstuv
      - KAFKA_OPTS=-javaagent:/opt/kafka-project/jmx-exporter/jmx_prometheus_javaagent.jar=9101:/opt/kafka-project/jmx-exporter/jmx-exporter-config.yml
      - ALLOW_PLAINTEXT_LISTENER=yes
    volumes:
      - kafka1_data:/bitnami/kafka
      - ./jmx-exporter:/opt/kafka-project/jmx-exporter
    networks:
      - kafka-net

  kafka2:
    image: bitnami/kafka:latest
    container_name: kafka2
    hostname: kafka2
    depends_on:
      - kafka1
    ports:
      - "9292:9092"
      - "9102:9101"
    environment:
      - KAFKA_CFG_NODE_ID=2
      - KAFKA_CFG_PROCESS_ROLES=broker,controller
      - KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093
      - KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka2:9092
      - KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT
      - KAFKA_CFG_INTER_BROKER_LISTENER_NAME=PLAINTEXT
      - KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER
      - KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=1@kafka1:9093,2@kafka2:9093,3@kafka3:9093
      - KAFKA_KRAFT_CLUSTER_ID=abcdefghijklmnopqrstuv
      - KAFKA_OPTS=-javaagent:/opt/kafka-project/jmx-exporter/jmx_prometheus_javaagent.jar=9101:/opt/kafka-project/jmx-exporter/jmx-exporter-config.yml
      - ALLOW_PLAINTEXT_LISTENER=yes
    volumes:
      - kafka2_data:/bitnami/kafka
      - ./jmx-exporter:/opt/kafka-project/jmx-exporter
    networks:
      - kafka-net

  kafka3:
    image: bitnami/kafka:latest
    container_name: kafka3
    hostname: kafka3
    depends_on:
      - kafka1
      - kafka2
    ports:
      - "9392:9092"
      - "9103:9101"
    environment:
      - KAFKA_CFG_NODE_ID=3
      - KAFKA_CFG_PROCESS_ROLES=broker,controller
      - KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093
      - KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka3:9092
      - KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT
      - KAFKA_CFG_INTER_BROKER_LISTENER_NAME=PLAINTEXT
      - KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER
      - KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=1@kafka1:9093,2@kafka2:9093,3@kafka3:9093
      - KAFKA_KRAFT_CLUSTER_ID=abcdefghijklmnopqrstuv
      - KAFKA_OPTS=-javaagent:/opt/kafka-project/jmx-exporter/jmx_prometheus_javaagent.jar=9101:/opt/kafka-project/jmx-exporter/jmx-exporter-config.yml
      - ALLOW_PLAINTEXT_LISTENER=yes
    volumes:
      - kafka3_data:/bitnami/kafka
      - ./jmx-exporter:/opt/kafka-project/jmx-exporter
    networks:
      - kafka-net

  kafka-exporter:
    image: danielqsj/kafka-exporter
    container_name: kafka-exporter
    command:
      - "--kafka.server=kafka1:9092"
      - "--kafka.server=kafka2:9092"
      - "--kafka.server=kafka3:9092"
    ports:
      - "9308:9308"
    networks:
      - kafka-net

  prometheus:
    image: prom/prometheus
    container_name: prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
    networks:
      - kafka-net

volumes:
  kafka1_data:
  kafka2_data:
  kafka3_data:

networks:
  kafka-net:
    driver: bridge

```


## 5. اجرای پروژه

```bash
docker compose up -d
```

و برای مشاهده وضعیت سلامت هر سرویس:
```bash
docker compose ps
```


## 6. دسترسی‌ها پس از اجرا

سرویس JMX Exporter
```bash
http://localhost:9101, 9102, 9103
```

سرویس Kafka Exporter
```bash
http://localhost:9308/metric
```

سرویس Prometheus UI
```bash
http://localhost:9090
```
</div>
