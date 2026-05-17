<div dir="rtl">

# راهنمای مانیتورینگ کافکا با استفاده از Prometheus و Grafana

در این راهنما مراحل راه‌اندازی یک سیستم مانیتورینگ برای کلاستر کافکا توضیح داده شده است. هدف این است که بتوانیم وضعیت پیام‌ها، مصرف‌کننده‌ها، منابع سرور و سلامت بروکرها را مشاهده و تحلیل کنیم.

## معماری کلی سیستم

معماری مانیتورینگ به شکل زیر است:

کلاستر کافکا → ابزار Kafka Exporter و ابزار JMX Exporter → Prometheus → Grafana

در این ساختار ابزارهای exporter متریک‌ها را جمع‌آوری می‌کنند، پرومتئوس آن‌ها را ذخیره می‌کند و گرافانا آن‌ها را به‌صورت داشبورد نمایش می‌دهد.

---

## معرفی اجزای سیستم

### Prometheus

 پرومتئوس یک سیستم مانیتورینگ و جمع‌آوری متریک است که داده‌ها را به‌صورت time‑series ذخیره می‌کند.

ویژگی‌های مهم:

- جمع‌آوری متریک‌ها از سرویس‌ها
- ذخیره‌سازی داده‌ها در پایگاه داده زمانی
- امکان جستجو با زبان کوئری PromQL
- امکان تعریف هشدار

مدل کاری پرومتئوس از نوع Pull است؛ یعنی خود پرومتئوس به سرویس‌ها مراجعه می‌کند و متریک‌ها را دریافت می‌کند. این عملیات Scrape نام دارد.

---

### Grafana

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

## مرحله دوم: نصب Prometheus

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

## مرحله سوم: تنظیم فایل پیکربندی پرومتئوس

فایل تنظیمات در مسیر زیر قرار دارد:

```
/opt/kafka/prometheus/prometheus.yml
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

## مرحله چهارم: اجرای Prometheus

برای اجرای پرومتئوس از دستور زیر استفاده می‌کنیم:

```bash
/opt/kafka/prometheus/prometheus \
  --config.file=/opt/kafka/prometheus/prometheus.yml \
  --storage.tsdb.path=/opt/kafka/prometheus/data
```

پس از اجرا رابط کاربری از طریق آدرس زیر در دسترس خواهد بود:

```
http://SERVER_IP:9090
```

برای بررسی وضعیت تارگت‌ها:

```
http://SERVER_IP:9090/targets
```

---

## مرحله پنجم: نصب ابزار Kafka Exporter

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

## مرحله ششم: اجرای ابزار Kafka Exporter

نمونه اجرای exporter:

```bash
/opt/kafka/kafka_exporter/kafka_exporter \
  --kafka.server=localhost:9392 \
  --kafka.server=localhost:9492 \
  --kafka.server=localhost:9592
```

پس از اجرا متریک‌ها از طریق آدرس زیر قابل مشاهده هستند:

```
http://localhost:9308/metrics
```

---

## مرحله هفتم: نصب ابزار JMX Exporter

ابتدا مسیر مربوط به JMX را ایجاد می‌کنیم:

```bash
sudo mkdir -p /opt/kafka/kafka-jmx
```

سپس فایل Java Agent را دانلود می‌کنیم:

```bash
wget https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.20.0/jmx_prometheus_javaagent-0.20.0.jar
```

---

## مرحله هشتم: اتصال JMX Exporter به بروکر کافکا

برای فعال کردن JMX Exporter باید متغیر زیر به تنظیمات اجرای بروکر اضافه شود:

```bash
export KAFKA_OPTS="-javaagent:/opt/kafka/kafka-jmx/jmx_prometheus_javaagent-0.20.0.jar=7071:/opt/kafka/kafka-jmx/kafka_jmx.yml"
```

پس از راه‌اندازی مجدد بروکر متریک‌ها در آدرس زیر در دسترس خواهند بود:

```
http://localhost:7071/metrics
```

---

## مرحله نهم: بررسی متریک‌ها در پرومتئوس

در رابط کاربری پرومتئوس می‌توان کوئری‌های زیر را اجرا کرد:

- kafka_brokers
- kafka_topic_partitions
- jvm_memory_bytes_used

این متریک‌ها وضعیت کلاستر کافکا و JVM را نشان می‌دهند.

</div>
