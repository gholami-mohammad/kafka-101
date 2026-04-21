# Table of contents

- [Concepts](./01-concepts.md)
- [Installation](./02-installation.md)
- [Broker Configuration](./03-broker-configuration.md)
- [Hardware Selection](./04-hardware-selection.md)
- [Kafka Topics CLI](./05-cli-kafka-topics.md)
- [Kafka Console Producer CLI](./06-cli-kafka-console-producer.md)
- [Performance Benchmarking](./50-tuning.md)
- [Reassigning partition](./51-reassign-partiotion.md)
- [Mirror Maker](./52-mirror-maker.md)

TODO:

# Schema Registry

**Kafka Schema Registry** is a centralized service that stores and manages data schemas (such as Avro, Protobuf, and JSON Schema) used for messages published to Apache Kafka. It acts as a shared repository that allows producers and consumers to coordinate and validate the structure of the data they are exchanging without attaching the full schema to every single message, thereby significantly reducing payload size. By enforcing compatibility rules, the Schema Registry enables safe schema evolution over time, ensuring that changes made to a data format by a producer do not break downstream consumers, ultimately providing robust data governance and reliability within event-driven architectures.

# Kafka Connect

**Kafka Connect** is a scalable and reliable framework included with Apache Kafka that simplifies the continuous streaming of data between Kafka and external systems. It utilizes ready-made, configuration-driven "connectors" to seamlessly pull data from external sources (such as databases, message queues, or APIs) into Kafka topics using Source Connectors, or to push data from Kafka topics out to external destinations (like data warehouses, search indexes, or cloud storage) using Sink Connectors. By operating as a distributed and fault-tolerant service, Kafka Connect eliminates the need to write custom integration code, enabling developers to build robust, high-throughput data pipelines through simple configurations.
