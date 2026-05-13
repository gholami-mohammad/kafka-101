در این مثال، یک نمونه اپلیکیشن پیاده سازی شده است که با استفاده از دبیزیم، پترن آوت باکس را پیاده سازی میکنیم.

در این مثال، فرض بر این است که یک سرویس ثبت سفارش وجود دارد. پس از ثبت یا بروزرسانی سفارش، تغییرات توسط دیبیزیم از جدول outbox خوانده میشود و ایونتی به کافکا ارسال میشود.

نمونه کد، با گولنگ توسعه داده شده است.

جهت اجرای برنامه مراحل زیر را دنبال کنید:

```sh
docker-compose -f docker-compose.yaml up -d
```

پس از اینکه کانتینر های لازم اجرا شد، میتوانیم به اجرای برنامه و تنظیمات دبیزیم بپردازیم.

ابتدا آدرس http://localhost:8080 را در مرورگر خود باز کنید.
این آدرس پنل kafka-ui است که در داکر کمپوز ایجاد شده است.

سپس از بخش Kafka Connect یک کانکتور جدید ایجاد کنید و مقادیر زیر را تنظیم نمایید:

Name: outbox-connector

Config:

```json
{
	"connector.class": "io.debezium.connector.postgresql.PostgresConnector",
	"database.user": "postgres",
	"database.dbname": "orderdb",
	"transforms.outbox.type": "io.debezium.transforms.outbox.EventRouter",
	"slot.name": "debezium_outbox_slot",
	"tasks.max": "1",
	"transforms": "outbox",
	"database.server.name": "orderdb",
	"database.port": "5432",
	"plugin.name": "pgoutput",
	"tombstones.on.delete": "false",
	"topic.prefix": "outbox",
	"database.hostname": "postgres",
	"database.password": "postgres",
	"name": "outbox-connector",
	"table.include.list": "outbox_schema.outbox",
	"value.converter": "org.apache.kafka.connect.storage.StringConverter",
	"key.converter": "org.apache.kafka.connect.storage.StringConverter"
}
```

حال درصورتیکه هر داده ای در جدول outbox_schema.outbox وارد کنید، در تاپیکی به این شکل ارسال میشود:

```
${topic.prefix}.event.${outbox.aggregatetype}
```

مقدار topic.prefix از تنظیمات کانکتور می آید.

مقدار outbox.aggregatetype مطابق با مقداری است که در جدول outbox در ستون aggregatetype وارد شده باشد.
