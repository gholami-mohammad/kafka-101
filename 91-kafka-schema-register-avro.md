<div dir="rtl">

# راهنمای راه اندازی کافکا با اسکیما رجیستری فرمت های Avro, Json

در این راهنما مراحل راه‌اندازی یک kafka و schema register به صورت مرحله به مرحله توصیح میدهد
در این جا با استفاده از فرمت Avro ساختار schema register  رو تنظیم کرده‌ایم



## معماری کلی سیستم


```bash
       ┌─────────────────────┐
       │  Schema Registry    │
       │  (HTTP 8081)        │
       └──────────┬──────────┘
                  │
                  ▼
       ┌─────────────────────┐
       │   Kafka (KRaft)     │
       │   Broker + Ctrl     │
       │   Port 9092         │
       └─────────────────────┘
```

---

## مرحله 1: ساخت یک پوشه پروژه

```bash
    mkdir kafka-schema
    cd kafka-schema
```

---

## مرحله 2: فایل docker-compose.yml

در ادامه، فایل پیکربندی برای استفاده از kafka به همراه Schema Registry آورده شده است:
و از ایمیج‌های سری confluentinc/cp-kafka استفاده می‌کنیم
```bash
services:
  kafka:
    image: confluentinc/cp-kafka:7.6.0
    container_name: kafka
    hostname: kafka
    ports:
      - "9092:9092"  
    environment:
      KAFKA_NODE_ID: 1
      KAFKA_PROCESS_ROLES: broker,controller

      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093
      
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092

      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,EXTERNAL:PLAINTEXT,CONTROLLER:PLAINTEXT

      KAFKA_CONTROLLER_QUORUM_VOTERS: 1@kafka:9093
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      CLUSTER_ID: 1cPr_gg8R0iGWbVpNAefFA

  schema-registry:
    image: confluentinc/cp-schema-registry:7.6.0
    container_name: schema-registry
    depends_on:
      - kafka
    ports:
      - "8081:8081" 
    environment:
      SCHEMA_REGISTRY_HOST_NAME: schema-registry
      SCHEMA_REGISTRY_LISTENERS: http://0.0.0.0:8081
      SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS: PLAINTEXT://kafka:9092
  tools:
    image: confluentinc/cp-schema-registry:7.6.0
    container_name: kafka-tools
    hostname: kafka-tools
    depends_on:
      - kafka
      - schema-registry
    entrypoint: ["/bin/bash", "-lc", "sleep infinity"]
    tty: true

```
این compose سه سرویس می‌سازد:

1.Kafka
2.Schema Registry
3.یک Container ابزار برای تست (بسیار مهم)

---

## مرحله 3: بالا آوردن Kafka و Schema Registry

```bash
  docker compose up -d
```

و وضعیت را چک کن:

```bash
  docker compose ps
```

باید ببینی:
```bash
kafka              running
schema-registry    running
kafka-tools        running
```

---

## مرحله 4 — تست Schema Registry

بزن:
```bash
curl http://localhost:8081/subjects
```

خروجی باید:
```bash
[]
```
یعنی سالم بالا آمده.


## مرحله 5 — استفاده از Container ابزار (tools)


داخلش برو:

```bash
docker exec -it kafka-tools bash
```
حالا این ابزارها را داری:


- kafka-avro-console-producer
- kafka-avro-console-consumer
- kafka-json-schema-console-producer
- kafka-json-schema-console-consumer
- kafka-console-producer
- kafka-console-consumer
- kafka-topics (مهم)


## مرحله 6 — ساخت اولین Topic

با دستور زیر اولین topic را بساز:
```bash
kafka-topics \
  --create \
  --topic orders \
  --bootstrap-server kafka:9092 \
  --partitions 3 \
  --replication-factor 1
```

تأیید:

```bash
kafka-topics \
  --describe \
  --topic orders \
  --bootstrap-server kafka:9092

```

## مرحله 7 — ارسال پیام Avro (Production Test)

در داخل kafka-tools:

```bash
kafka-avro-console-producer \
  --broker-list kafka:9092 \
  --topic orders \
  --property schema.registry.url=http://schema-registry:8081 \
  --property value.schema='{"type":"record","name":"Order","fields":[{"name":"id","type":"string"},{"name":"product","type":"string"},{"name":"quantity","type":"int"}]}'

```
بعد از اجرای دستور، یک خط بنویس:

```bash
{"id":"1","product":"laptop","quantity":2}
```
Enter بزن → پیام ارسال شد.


## مرحله 8 — خواندن پیام‌ها

در یک ترمینال جدید وارد kafka-tools شو :
```bash
docker exec -it kafka-tools bash
```

و اجرا کن:
```bash
kafka-avro-console-consumer \
  --bootstrap-server kafka:9092 \
  --topic orders \
  --from-beginning \
  --property schema.registry.url=http://schema-registry:8081
```

خروجی باید:

```bash
{"id":"1","product":"laptop","quantity":2}
```


# اگر بخواهید با فرمت Json مراحل را جلو ببرید به شکل زیر می‌شود:
## مرحله 7 — ارسال پیام Json (Production Test)


## مرحله 6 — ساخت اولین Topic

با دستور زیر اولین topic را بساز:
```bash
kafka-topics \
  --create \
  --topic users-topic \
  --bootstrap-server kafka:9092 \
  --partitions 3 \
  --replication-factor 1
```

در داخل kafka-tools:

```bash
kafka-json-schema-console-producer \
  --broker-list kafka:9092 \
  --topic users-topic \
  --property schema.registry.url=http://schema-registry:8081 \
  --property value.schema='{"type":"object","properties":{"name":{"type":"string"},"age":{"type":"integer"}}}'


```
بعد از اجرای دستور، یک خط بنویس:

```bash
{"name": "Ali", "age": 30}
```
Enter بزن → پیام ارسال شد.


## مرحله 8 — خواندن پیام‌ها

در یک ترمینال جدید وارد kafka-tools شو :
```bash
docker exec -it kafka-tools bash
```

و اجرا کن:
```bash
kafka-json-schema-console-consumer \
  --bootstrap-server kafka:9092 \
  --topic users-topic \
  --property schema.registry.url=http://schema-registry:8081 \
  --from-beginning
```

خروجی باید:

```bash
{"name": "Ali", "age": 30}
```



