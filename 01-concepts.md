# Kafka 101

## Why Kafka?

- Multiple Producers
- Multiple Consumers
- Disk-Based Retention: Durable retention means that if a consumer falls behind, either due to slow processing or a burst in traffic, there is no danger of losing data.
- Scalable
- High Performance
- The Data Ecosystem: Apache Kafka provides the circulatory system for the data ecosystem. It carries messages between the various members of the infrastructure, providing a consistent interface for all clients.

## Apache Kafka: Use cases

- Messaging System
- Activity Tracking
- Gather metrics from many different locations
- Application Logs gathering
- Stream processing (with the Kafka Streams API for example)
- De-coupling of system dependencies
- Integration with Spark, Flink, Storm, Hadoop, and many other Big Data technologies
- Micro-services pub/sub

# Main Concepts and Terminology

## Event

An event records the fact that “something happened” in the world or in your business.
An event has a key, value, timestamp, and optional metadata headers.

## Producers

- Are those client applications that publish (write) events to Kafka.

- Kafka Messages anatomy
    - Key - binary (Can be null)
        - Producers can choose to send a key with the message (string, number, binary, etc..)
        - If key=null, data is sent round robin (partition 0, then 1, then 2...)
        - If key!=null, then all messages for that key will always go to the same partition (hashing)
        - A key are typically sent if you need message ordering for a specific field
    - Value - binary (Can be null)
    - Compression Type (none, gzip, snappy, lz4, zstd)
    - Headers (optional) [key,value]
    - Partition + Offset
    - Timestamp (system or user set)

- Kafka Message Serializer
    - Kafka only accepts bytes as an input from producers and sends bytes out as an output to consumers
    - Message Serialization means transforming objects / data into bytes

- Kafka Message Key Hashing
    - A Kafka partitioner is a code logic that takes a record and determines to which partition to send it into.
    - Key Hashing is the process of determining the mapping of a key to a partition
    - In the default Kafka partitioner, the keys are hashed using the murmur2 algorithm, with the formula below for the curious:

    ```
    targetPartition = Math.abs(Utils.murmur2(keyBytes)) % (numPartitions - 1)
    ```

## Consumers

- Are those that subscribe to (read and process) these events.
- Consumers read data from a topic (identified by name) - pull model
- Consumers automatically know which broker to read from
- In case of broker failures, consumers know how to recover
- Data is read in order from low to high offset within each partitions

## Consumer Groups

- All the consumers in an application read data as a consumer groups
- Each consumer within a group reads from exclusive partitions
- Each consumer in a group can read from multiple partitions
- Each partition can be read only one consumer
- If you have more consumers than partitions, some consumers will be inactive
- It is acceptable to have multiple consumer groups on the same topic
- Consumer Offsets
    - Kafka stores the offsets at which a consumer group has been reading
    - The offsets committed are in Kafka topic named `__consumer_offsets`
    - When a consumer in a group has processed data received from Kafka, it should be periodically committing the offsets (the Kafka broker will write to `__consumer_offsets`, not the group itself)
    - If a consumer dies, it will be able to read back from where it left off from the committed consumer offsets!

## Topic

- Events are organized and durably stored in topics.
- Topics in Kafka are always multi-producer and multi-subscriber: a topic can have zero, one, or many producers that write events to it, as well as zero, one, or many consumers that subscribe to these events.
- Events in a topic can be read as often as needed—unlike traditional messaging systems, events are not deleted after consumption.
- You define for how long Kafka should retain your events through a per-topic configuration setting, after which old events will be discarded.
- Once the data is written to a partition, it cannot be changed (immutability).
- Data is kept only for a limited time (default is one week - configurable).
- Offset only have a meaning for a specific partition. E.g. offset 3 in partition 0 doesn't represent the same data as offset 3 in partition 1.
- Offsets are not re-used even if previous messages have been deleted.
- Order is guaranteed only within a partition (not across partitions).
- Data is assigned randomly to a partition unless a key is provided.
- You can have as many partitions per topic as you want.

## Partition

- Topics are partitioned , meaning a topic is spread over a number of “buckets” located on different Kafka brokers
- This distributed placement of your data is very important for scalability because it allows client applications to both read and write the data from/to many brokers at the same time.
- Events with the same event key (e.g., a customer or vehicle ID) are written to the same partition, and Kafka guarantees that any consumer of a given topic-partition will always read that partition’s events in exactly the same order as they were written.

## Replication

- To make your data fault-tolerant and highly-available, every topic can be replicated.
- A common production setting is a replication factor of 3

## Delivery semantics for consumers

- By default, Java Consumers will automatically commit offsets (at least once)
- There are 3 delivery semantics if you choose to commit manually
    - At least once (usually preferred)
        - Offsets are committed after the message is processed
        - If the processing goes wrong, the message will be read again
        - This can result in duplicate processing of messages. Make sure your processing is idempotent (i.e. processing again the messages won't impact your systems)
    - At most once
        - Offsets are committed as soon as messages are received
        - If the processing goes wrong, some messages will be lost (they won't be read again)
    - Exactly once
        - For Kafka => Kafka workflows: use the Transactional API (easy with Kafka Streams API)
        - For Kafka => External System workflows: use an idempotent consumer

# Kafka Brokers

- A Kafka cluster is composed of multiple brokers (servers)
- Each broker is identified with its ID (integer)
- Each broker contains certain topic partitions
- After connecting to any broker (called a bootstrap broker), you will be connected to the entire cluster (Kafka clients have smart mechanics for that)
- A good number to get started is 3 brokers, but some big clusters have over 100 brokers

## Kafka Broker Discovery

- Every Kafka broker is also called a "bootstrap server"
- That means that you only need to connect to one broker, and the Kafka clients will know how to be connected to the entire cluster (smart clients)
- Each broker knows about all brokers, topics and partitions (metadata)

## Topic replication factor

- Topics should have a replication factor > 1 (usually between 2 and 3)
- This way if a broker is down, another broker can serve the data

Example: Topic-A with 2 partitions and replication factor of 2:

| Broker 101         | Broker 102         | Broker 103         |
| ------------------ | ------------------ | ------------------ |
| Topic-A partition0 |                    | Topic-A partition0 |
|                    | Topic-A partition1 | Topic-A partition1 |

## Concept of Leader for a Partition

- At any time only ONE broker can be a leader for a given partition
- **Producers can only send data to the broker that is leader of a partition**
- Since Kafka 2.4, it is possible to configure consumers to read from the closest instead on the leader
- The other brokers will replicate the data
- Therefore, each partition has one leader and multiple ISR (in-sync replica)

| Broker 101                  | Broker 102              | Broker 103                 |
| --------------------------- | ----------------------- | -------------------------- |
| Topic-A partition0 (Leader) |                         | Topic-A partition0 (ISR)   |
|                             | Topic-A partition1(ISR) | Topic-A partition1(Leader) |

## Producer Acknowledgements (acks)

- Producers can choose to receive acknowledgment of data writes:
    - acks=0: Producer won't wait for acknowledgment (possible data loss)
    - acks=1: Producer will wait for leader acknowledgment (limited data loss)
    - acks=a11: Leader + replicas acknowledgment (no data loss)

## Kafka Topic Durability

- For a topic replication factor of 3, topic data durability can withstand 2 brokers loss.
- As a rule, for a replication factor of N, you can permanently lose up to N-1 brokers and still recover your data.

# Zookeeper

- Zookeeper manages brokers (keeps a list of them)
- Zookeeper helps in performing leader election for partitions
- Zookeeper sends notifications to Kafka in case of changes (e.g. new topic, broker dies, broker comes up, delete topics, etc....)
- Kafka 2.x can't work without Zookeeper
- Kafka 3.x can work without Zookeeper (KIP-500) - using Kafka Raft instead
- Kafka 4.x does not have Zookeeper
- Zookeeper by design operates with an odd number of servers (1, 3, 5, 7)
- Zookeeper has a leader (writes) the rest of the servers are followers (reads)
- (Zookeeper does NOT store consumer offsets with Kafka > v0.10)

# About Kafka KRaft

- In 2020, the Apache Kafka project started to work to remove the Zookeeper dependency from it (KIP-500)
- Zookeeper shows scaling issues when Kafka clusters have > 100,000 partitions
- By removing Zookeeper, Apache Kafka can
    - Scale to millions of partitions, and becomes easier to maintain and set-up
    - Improve stability, makes it easier to monitor, support and administer
    - Single security model for the whole system
    - Single process to start with Kafka
    - Faster controller shutdown and recovery time
