# Kafka Connect example

Reading data from a topic and sink it into postgres table.

- Make sure you already downloaded `confluentinc-kafka-connect-jdbc` connector.(you can download from https://www.confluent.io/hub/confluentinc/kafka-connect-jdbc)
- Add `confluentinc-kafka-connect-jdbc`'s lib directory to `plugin.path` of `connect-distributed.properties` file.
- Make sure you already downloaded postgres jdbc connector from https://jdbc.postgresql.org/download/
- Add it to connector plugins

### Run connect: (set properties file path based on your installation)

```sh
connect-distributed /opt/homebrew/etc/kafka/connect-distributed.properties
```

### Make sure jdbc plugins are loaded:

```sh
curl -X GET http://localhost:8083/connector-plugins | jq . | grep jdbc
```

you should see these lines:

```
    "class": "io.confluent.connect.jdbc.JdbcSinkConnector",
    "class": "io.confluent.connect.jdbc.JdbcSourceConnector",
```

### Create postgres Database:(replace host, port, and user based on your postgres setup)

```sh
createdb psql_sink_example  --encoding=UTF-8 --owner=dev --host localhost -U dev
```

### Create postgres table

```sql
CREATE TABLE public.test_table (
	id bigserial NOT NULL,
	"name" varchar NULL,
	email varchar NULL,
	CONSTRAINT test_table_pk PRIMARY KEY (id)
);
```

### Create kafka topic:

```sh
kafka-topics --bootstrap-server localhost:9092 --create --topic test-topic
```

### Create the Connector Configuration:

```sh
tee postgres-sink.json <<EOF
{
  "name": "postgres-sink-connector",
  "config": {
    "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
    "tasks.max": "1",
    "topics": "test-topic",
    "connection.url": "jdbc:postgresql://localhost:5432/psql_sink_example",
    "connection.user": "dev",
    "connection.password": "dev",
    "insert.mode": "upsert",
    "pk.mode": "record_value",
    "pk.fields": "id",
    "auto.create": "true",
    "auto.evolve": "true",
    "table.name.format": "test_table"
  }
}
EOF
```

Key configurations explained:

- `insert.mode`: Can be insert, upsert, or update. If using upsert, you need to define primary keys.
- `pk.mode` & `pk.fields`: Defines how the connector identifies the primary key (e.g., using the Kafka record key or a specific field in the value).
- `auto.create` & `auto.evolve`: If true, Kafka Connect will automatically create the Postgres table and add new columns if your schema changes.

### Deploy connector:

```sh
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @postgres-sink.json
```

### Verify

```sh
curl -s http://localhost:8083/connectors/postgres-sink-connector/status | jq .
```

You should see RUNNING state for the connector.

### Create example data with schema

```sh
tee data.txt <<EOF
{"schema":{"type":"struct","fields":[{"type":"int32","optional":false,"field":"id"},{"type":"string","optional":true,"field":"name"},{"type":"string","optional":true,"field":"email"}],"optional":false,"name":"UserRecord"},"payload":{"id":123,"name":"Alice Doe","email":"alice@example.com"}}
EOF
```

### Send data to kafka

```sh
kafka-console-producer --bootstrap-server localhost:9092 --topic test-topic < data.txt
```

**NOTE: If table does not exist, connector will create it based on defined schema.**
