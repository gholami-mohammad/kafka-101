در این مثال، یک نمونه اپلیکیشن پیاده سازی شده است که با استفاده از دبیزیم، پترن آوت باکس را پیاده سازی میکنیم.

در این مثال، فرض بر این است که یک سرویس ثبت سفارش وجود دارد. پس از ثبت یا بروزرسانی سفارش، تغییرات توسط دیبیزیم از جدول outbox خوانده میشود و ایونتی به کافکا ارسال میشود.

نمونه کد، با گولنگ توسعه داده شده است.

## اجرای سرویس ها

جهت اجرای برنامه مراحل زیر را دنبال کنید:

```sh
cd examples/debesium-outbox-2

docker build --rm -f './connect.Dockerfile' -t 'kafka-connect-with-debezium:latest' .

docker-compose -f docker-compose.yaml up -d
```

پس از اینکه کانتینر های لازم اجرا شد، میتوانیم به اجرای برنامه و تنظیمات دبیزیم بپردازیم.

## تنظیمات دبیزیم و کانکتور

ابتدا آدرس http://localhost:8080 را در مرورگر خود باز کنید.
این آدرس پنل kafka-ui است که در داکر کمپوز ایجاد شده است.

سپس از بخش Kafka Connect یک کانکتور جدید ایجاد کنید و مقادیر زیر را تنظیم نمایید:

Name: outbox-connector

Config:

```json
{
	"connector.class": "io.debezium.connector.postgresql.PostgresConnector",

	"transforms": "outbox",
	"transforms.outbox.type": "io.debezium.transforms.outbox.EventRouter",

	"database.server.name": "orderdb",
	"database.hostname": "postgres",
	"database.port": "5432",
	"database.user": "debezium",
	"database.dbname": "orderdb",
	"database.password": "debezium",
	"tombstones.on.delete": "false",
	"table.include.list": "outbox_schema.outbox",

	"plugin.name": "pgoutput",

	"publication.name": "outbox_publication",
	"publication.autocreate.mode": "disabled",

	"topic.prefix": "outbox",

	"slot.name": "debezium_outbox_slot",
	"tasks.max": "1",
	"name": "outbox-connector",
	"value.converter": "org.apache.kafka.connect.storage.StringConverter",
	"key.converter": "org.apache.kafka.connect.storage.StringConverter"
}
```

توجه کنید که پس از ساخت کانکتور، وضعیت کانکتور و همچنین تسک آن در حال Running باشد.

حال درصورتیکه هر داده ای در جدول outbox_schema.outbox وارد کنید، در تاپیکی به این شکل ارسال میشود:

```
${topic.prefix}.event.${outbox.aggregatetype}
```

مقدار topic.prefix از تنظیمات کانکتور می آید.

مقدار outbox.aggregatetype مطابق با مقداری است که در جدول outbox در ستون aggregatetype وارد شده باشد.

آنچه در این نوشتار تنظیم شد، یکی از مدل های ترنسفورمر در دبیزیم است. جهت مشاهده سایر انواع و تنظیمات به [مستندات رسمی](https://debezium.io/documentation/reference/3.5/transformations/index.html) آن مراجعه کنید.

## تست عملکرد توسط کد

```sh
docker exec -it debezium-postgres psql -U tibobit -d orderdb -c "
INSERT INTO outbox_schema.outbox (id, aggregatetype, aggregateid, type, payload)
VALUES (
    gen_random_uuid(),
    'order-aggregate',
    'order-123',
    'OrderCreated',
    '{\"id\": 1, \"amount\": \"150.00\", \"base\": \"usdt\", \"quote\": \"btc\"}'::jsonb
);"
```

پس از اجرای این دستور، پیامی به تاپیک `outbox.event.order-aggregate` ارسال خواهد شد که از طریق kafka-ui به راحتی قابل مشاهده است.
