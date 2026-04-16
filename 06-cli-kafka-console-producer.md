# Producer CLI

First, create a topic.

```sh
kafka-topics --bootstrap-server localhost:9092 --create --topic first-topic --partition 1
```

## Producing

```sh
kafka-console-producer --bootstrap-server localhost:9092 --topic first-topic
```

When connected, you can send message. Also you can exit from producer using `ctrl+c`.

## Producing with properties

```sh
kafka-console-producer --bootstrap-server localhost:9092 --topic first-topic --command-property ack=all
```

You can set producer property using `--command-property` flag.

`ack=all` means: Leader + replicas acknowledgment.

**NOTE**: if you try to send message on a topic which does no exist, the behavior can be different based on broker settings. If topic auto create is enabled, it will create it first, then message will be sent. Otherwise, you may get an error like this:

> [2026-04-16 22:32:21,313] WARN [Producer clientId=console-producer] The metadata response from the cluster reported a recoverable issue with correlation id 5 : {new-topic=UNKNOWN_TOPIC_OR_PARTITION} (org.apache.kafka.clients.NetworkClient)

**NOTE:** It is recommended to disable topic auto create. Each topic should be created first.

## Producing with key

We need to apply 2 property to do that: `--reader-property parse.key=true` and `--reader-property key.separator=:`.

The `key.separator` value can be any character. Producer will use this character to separate message key and value. For example: if `key.separator=:` then `a:b` a will be message key and b will be message value.

```sh
kafka-console-producer --bootstrap-server localhost:9092 --topic first-topic --reader-property parse.key=true --reader-property key.separator=:
```

If the key separator property applied, you _MUST_ provide a key for any message you are sending.
