# راه‌اندازی مانیتورینگ Kafka با Prometheus ،Kafka Exporter و JMX Exporter


<div dir="rtl">
در این راهنما نحوه راه‌اندازی یک سیستم مانیتورینگ برای **Apache Kafka** با استفاده از ابزارهای زیر توضیح داده می‌شود:

- **Prometheus** برای جمع‌آوری و ذخیره متریک‌ها  
- **Kafka Exporter** برای دریافت متریک‌های Kafka  
- **JMX Exporter** برای دریافت متریک‌های داخلی JVM و Kafka  
- **Grafana (اختیاری)** برای نمایش گرافیکی متریک‌ها  

هدف از این سیستم مانیتورینگ این است که بتوانیم وضعیت Kafka را از نظر موارد زیر مشاهده کنیم:

- وضعیت Broker ها  
- تعداد Topic ها و Partition ها  
- وضعیت Leader ها  
- Consumer Lag  
- مصرف حافظه JVM  
- Garbage Collection  
- تعداد Thread ها  
- مصرف CPU و Memory

این اطلاعات برای **تشخیص سریع مشکلات سیستم** و **پایش سلامت کلاستر Kafka** بسیار مهم هستند.


---

# معماری سیستم مانیتورینگ

در این معماری، متریک‌ها از Kafka استخراج شده و در Prometheus ذخیره می‌شوند.

```
Kafka Cluster
   │
   ├── Kafka Exporter
   │      (Kafka metrics: topics, partitions, lag)
   │
   ├── JMX Exporter
   │      (JVM metrics: memory, GC, threads)
   │
   ▼
Prometheus
   (جمع‌آوری و ذخیره متریک‌ها)
   │
   ▼
Grafana
   (نمایش داشبوردها)
```

Prometheus به صورت **Pull-Based** کار می‌کند. یعنی خودش به صورت دوره‌ای به سرویس‌ها متصل می‌شود و متریک‌ها را دریافت می‌کند.

---

# 1. نصب پیش‌نیازها

ابتدا ابزارهای لازم برای دانلود و استخراج فایل‌ها را نصب می‌کنیم.

```bash
sudo apt update
sudo apt install -y wget curl tar
```

سپس یک مسیر برای نگهداری ابزارهای مانیتورینگ ایجاد می‌کنیم:

```bash
sudo mkdir -p /opt/kafka
cd /opt/kafka
```

در این راهنما همه ابزارها داخل مسیر `/opt/kafka` نصب می‌شوند.

---

# 2. نصب Prometheus

Prometheus یک سیستم **Monitoring و Time-Series Database** است که متریک‌ها را جمع‌آوری و ذخیره می‌کند.


### دانلود Prometheus

```bash
cd /opt/kafka

sudo wget https://github.com/prometheus/prometheus/releases/download/v2.52.0/prometheus-2.52.0.linux-amd64.tar.gz
```

### استخراج فایل

```bash
sudo tar -xzf prometheus-2.52.0.linux-amd64.tar.gz
```

برای راحتی نام پوشه را تغییر می‌دهیم:

```bash
sudo mv prometheus-2.52.0.linux-amd64 prometheus
```

### ساخت پوشه دیتابیس

Prometheus متریک‌ها را در یک پایگاه داده داخلی ذخیره می‌کند.

```bash
sudo mkdir /opt/kafka/prometheus/data
```

### تنظیم permission ها (اختیاری)

در بعضی سیستم‌ها ممکن است به دلیل permission خطا دریافت کنید. در این صورت می‌توانید دسترسی‌ها را تغییر دهید:

```bash
sudo chown -R $USER:$USER /opt/kafka/prometheus
sudo chmod -R 775 /opt/kafka/prometheus
```

این مرحله **اختیاری** است و فقط در صورت بروز مشکل لازم می‌شود.

---

# 3. تنظیم Prometheus

Prometheus از فایل **prometheus.yml** برای مشخص کردن سرویس‌هایی که باید مانیتور شوند استفاده می‌کند.


فایل را ویرایش کنید:

```bash
nano /opt/kafka/prometheus/prometheus.yml
```

محتوای نمونه:

```yaml
global:
  scrape_interval: 15s

scrape_configs:

  - job_name: prometheus
    static_configs:
      - targets: ['localhost:9090']

  - job_name: kafka_exporter
    static_configs:
      - targets: ['localhost:9308']

  - job_name: kafka_jmx
    static_configs:
      - targets: ['localhost:7071']
```

### توضیح تنظیمات

**scrape_interval**

مشخص می‌کند Prometheus هر چند ثانیه متریک‌ها را جمع‌آوری کند.

**job_name**

نام سرویس مانیتور شده.

**targets**

آدرس endpoint که متریک‌ها از آن خوانده می‌شوند.

---

# 4. اجرای Prometheus

```bash
cd /opt/kafka/prometheus

./prometheus --config.file=prometheus.yml --storage.tsdb.path=data
```

بعد از اجرا، رابط کاربری Prometheus در آدرس زیر در دسترس خواهد بود:

```
http://SERVER_IP:9090
```

برای مشاهده سرویس‌های مانیتور شده:

```
http://SERVER_IP:9090/targets
```

اگر همه چیز درست باشد وضعیت سرویس‌ها باید **UP** باشد.

---

# 5. نصب Kafka Exporter

Kafka Exporter متریک‌های Kafka را در قالبی که Prometheus بتواند بخواند ارائه می‌دهد.

متریک‌هایی که Kafka Exporter ارائه می‌دهد شامل موارد زیر هستند:

- تعداد broker ها  
- تعداد topic ها  
- تعداد partition ها  
- leader partition ها  
- consumer lag  
- offsets  

### دانلود Kafka Exporter

```bash
cd /opt/kafka

sudo wget https://github.com/danielqsj/kafka_exporter/releases/download/v1.7.0/kafka_exporter-1.7.0.linux-amd64.tar.gz
```

### استخراج فایل

```bash
sudo tar -xzf kafka_exporter-1.7.0.linux-amd64.tar.gz
```

تغییر نام پوشه:

```bash
sudo mv kafka_exporter-1.7.0.linux-amd64 kafka_exporter
```

---

# 6. اجرای Kafka Exporter

```bash
cd /opt/kafka/kafka_exporter
```

اجرای exporter و اتصال به broker ها:

```bash
./kafka_exporter \
--kafka.server=localhost:9392 \
--kafka.server=localhost:9492 \
--kafka.server=localhost:9592
```

Kafka Exporter متریک‌ها را روی پورت زیر منتشر می‌کند:

```
http://localhost:9308/metrics
```

---

# 7. تست Kafka Exporter

```bash
curl localhost:9308/metrics
```

نمونه متریک‌ها:

```
kafka_brokers
kafka_topic_partitions
kafka_topic_partition_leader
```

---

# 8. نصب JMX Exporter

Kafka با **Java** نوشته شده است و بسیاری از متریک‌های داخلی آن از طریق **JMX** قابل دریافت هستند.

JMX Exporter این متریک‌ها را به فرمت Prometheus تبدیل می‌کند.

### ساخت پوشه

```bash
cd /opt/kafka

sudo mkdir kafka-jmx
cd kafka-jmx
```

### دانلود JMX Exporter

```bash
sudo wget https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.20.0/jmx_prometheus_javaagent-0.20.0.jar
```

تغییر نام:

```bash
sudo mv jmx_prometheus_javaagent-0.20.0.jar jmx_exporter.jar
```

---

# 9. ساخت فایل تنظیمات JMX

```bash
nano /opt/kafka/kafka-jmx/kafka_jmx.yml
```

```yaml
lowercaseOutputName: true
lowercaseOutputLabelNames: true

rules:
  - pattern: ".*"
```

---

# 10. اتصال JMX Exporter به Kafka

## حالت اول — اجرای Kafka با script

```bash
export KAFKA_OPTS="-javaagent:/opt/kafka/kafka-jmx/jmx_exporter.jar=7071:/opt/kafka/kafka-jmx/kafka_jmx.yml"
```

سپس Kafka را restart کنید.

---

## حالت دوم — اجرای Kafka با systemd

```bash
sudo nano /etc/systemd/system/kafka.service
```

در بخش `[Service]` اضافه کنید:

```
Environment="KAFKA_OPTS=-javaagent:/opt/kafka/kafka-jmx/jmx_exporter.jar=7071:/opt/kafka/kafka-jmx/kafka_jmx.yml"
```

سپس:

```bash
sudo systemctl daemon-reload
sudo systemctl restart kafka
```

---

# 11. تست JMX Exporter

```bash
curl localhost:7071/metrics
```

نمونه متریک‌ها:

```
jvm_memory_bytes_used
jvm_gc_collection_seconds
```

---

# 12. تست در Prometheus

Prometheus UI:

```
http://SERVER_IP:9090
```

نمونه Query:

```
kafka_brokers
```

```
jvm_memory_bytes_used
```

---

# آدرس‌های مهم

Prometheus

```
http://SERVER_IP:9090
```

Kafka Exporter

```
http://SERVER_IP:9308/metrics
```

JMX Exporter

```
http://SERVER_IP:7071/metrics
```

---

# مراحل بعدی پیشنهادی

برای محیط production بهتر است:

- Prometheus و Kafka Exporter را به صورت **systemd service** اجرا کنید
- **Grafana** نصب کنید
- **Alerting در Prometheus** فعال کنید
- **Consumer Lag monitoring** تنظیم کنید
---

# جمع‌بندی

در این راهنما یک استک مانیتورینگ برای Kafka راه‌اندازی شد که شامل موارد زیر است:
- Kafka Exporter → متریک‌های Kafka
- JMX Exporter → متریک‌های JVM
- Prometheus → جمع‌آوری و ذخیره متریک‌ها
- Grafana → نمایش داشبوردها

این معماری یکی از رایج‌ترین روش‌های مانیتورینگ Kafka در محیط‌های production است.
</div>