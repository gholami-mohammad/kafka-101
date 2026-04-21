# Kafka Tuning

## Getting ready

Create a topic to test performance on producing and consuming:

```sh
kafka-topics --create --bootstrap-server localhost:9092 --topic perf-test --partitions 6
```

## Testing

The `linger.ms` and `batch.size` are 2 of most important configs for tuning kafka. Using the following commands, you can see how changing them can affect throughput and latency.

```sh
kafka-producer-perf-test \
    --bootstrap-server localhost:9092 \
    --topic perf-test \
    --num-records 3000 \
    --record-size 1000 \
    --throughput 200 \
    --command-property linger.ms=0 batch.size=16384 \
    --print-metrics | grep "producer-metrics:batch-size-avg\|\
producer-metrics:request-latency-avg\|\
producer-metrics:record-queue-time-avg\|\
producer-metrics:bufferpool-wait-ratio\|\
producer-metrics:outgoing-byte-rate"
```

```sh
kafka-producer-perf-test \
    --bootstrap-server localhost:9092 \
    --topic perf-test \
    --num-records 3000 \
    --record-size 1000 \
    --throughput 200 \
    --command-property linger.ms=100 batch.size=16384 \
    --print-metrics | grep "producer-metrics:batch-size-avg\|\
producer-metrics:request-latency-avg\|\
producer-metrics:record-queue-time-avg\|\
producer-metrics:bufferpool-wait-ratio\|\
producer-metrics:outgoing-byte-rate"
```

```sh
kafka-producer-perf-test \
    --bootstrap-server localhost:9092 \
    --topic perf-test \
    --num-records 3000 \
    --record-size 1000 \
    --throughput 200 \
    --command-property linger.ms=100 batch.size=300000 \
    --print-metrics | grep "producer-metrics:batch-size-avg\|\
producer-metrics:request-latency-avg\|\
producer-metrics:record-queue-time-avg\|\
producer-metrics:bufferpool-wait-ratio\|\
producer-metrics:outgoing-byte-rate"
```

```sh
kafka-producer-perf-test \
    --bootstrap-server localhost:9092 \
    --topic perf-test \
    --num-records 3000 \
    --record-size 1000 \
    --throughput 200 \
    --command-property linger.ms=1500 batch.size=300000 \
    --print-metrics | grep "producer-metrics:batch-size-avg\|\
producer-metrics:request-latency-avg\|\
producer-metrics:record-queue-time-avg\|\
producer-metrics:bufferpool-wait-ratio\|\
producer-metrics:outgoing-byte-rate"
```

```sh
kafka-producer-perf-test \
    --bootstrap-server localhost:9092 \
    --topic perf-test \
    --num-records 3000 \
    --record-size 1000 \
    --throughput -1 \
    --command-property linger.ms=1500 batch.size=300000 \
    --print-metrics | grep \
"producer-metrics:batch-size-avg\|\
producer-metrics:request-latency-avg\|\
producer-metrics:record-queue-time-avg\|\
producer-metrics:bufferpool-wait-ratio\|\
producer-metrics:outgoing-byte-rate"
```
