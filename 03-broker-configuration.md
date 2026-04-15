# Broker Configuration

## General Broker

- `broker.id`
    - An integer value and default is 0.
    - Must be UNIQUE in a kafka cluster.
- `port`
    - default to 9092
    - can be any available port number
    - for ports less than 1024, kafka should run as root and it is not recommended.
- `log.dirs`
    - persistence location of disk to store logs.
    - a comma-separated list of paths on the local system
    - If more than one path is specified, the broker will store partitions on them in a “least-used” fashion with one partition’s log segments stored within the same path.
    - broker will place a new partition in the path that has the **least number of partitions** currently stored in it, not the least amount of disk space
- `num.recovery.threads.per.data.dir`
    - Kafka uses a configurable pool of threads for handling log segments. Currently, this thread pool is used:
        - When starting normally, to open each partition’s log segments
        - When starting after a failure, to check and truncate each partition’s log segments
        - When shutting down, to cleanly close log segments
    - default is one thread per log directory
    - As these threads are only used during startup and shutdown, it is reasonable to set a larger number of threads in order to parallelize operations. Specifically, when recovering from an unclean shutdown, **this can mean the difference of several hours when restarting a broker with a large number of partitions!**
    - the number configured is per log directory specified with log.dirs.
    - if `num.recovery.threads.per.data.dir=8`, and there are 3 paths specified in log.dirs, this is a total of 24 threads.
- `auto.create.topics.enable`
    - when set to true, topic will be created:
        - When a producer starts writing messages to the topic
        - When a consumer starts reading messages from the topic
        - When any client requests metadata for the topic
    - If you are managing topic creation explicitly, whether manually or through a provisioning system, you can set the `auto.create.topics.enable` configuration to false.

## Topic Defaults

- `num.partitions`
    - how many partitions a new topic is created with, primarily when automatic topic creation is enabled
    - the number of partitions for a topic can only be increased, never decreased.
    - Many users will have the partition count for a topic be equal to, or a multiple of, the number of brokers in the cluster.
    - **How to Choose the Number of Partitions**
        - What is the throughput you expect to achieve for the topic? For example, do you expect to write 100 KB per second or 1 GB per second?
        - What is the maximum throughput you expect to achieve when consuming from a single partition? **You will always have, at most, one consumer reading from a partition**, so if you know that your slower consumer writes the data to a database and this database never handles more than 50 MB per second from each thread writing to it, then you know you are limited to 60MB throughput when consuming from a partition.
        - Consider the number of partitions you will place on each broker and available disk space and network bandwidth per broker.
        - Avoid overestimating, as each partition uses memory and other resources on the broker and will increase the time for leader elections.
        - **EXAMPLE**: if I want to be able to write and read 1 GB/sec from a topic, and I know each consumer can only process 50 MB/s, then I know I need at least 20 partitions. This way, I can have 20 consumers reading from the topic and achieve 1 GB/sec.
- `log.retention.hours`, `log.retention.minutes`, `log.retention.ms`
    - how long Kafka will retain messages.
    - If more than one is specified, the smaller unit size will take precedence.
    - default value is `log.retention.hours=168` = one week
    - Retention by time is performed by examining the last modified time (mtime) on each log segment file on disk.
- `log.retention.bytes`
    - Another way to expire messages is based on the total number of bytes of messages retained.
    - it is applied per-partition. => topic with 8 partitions and log.retention.bytes= 1000000000 (1GB) => we retain 8GB for the topic.
    - **If both `log.retention.bytes` and `log.retention.[hours,minutes,ms]` is set, messages may be removed when either criteria is met.**

- `log.segment.bytes`
    - The log-retention settings previously mentioned operate on log segments, not individual messages.
    - As messages are produced to the Kafka broker, they are appended to the current log segment for the partition.
    - Once the log segment has reached the size specified by the `log.segment.bytes` parameter, which defaults to 1 GB, the log segment is closed and a new one is opened.
    - Once a log segment has been closed, it can be considered for expiration.
    - **A smaller log-segment size means that files must be closed and allocated more often, which reduces the overall efficiency of disk writes.**
    - IMPORTANT NOTE: Adjusting the size of the log segments can be important if topics have a low produce rate. For example, if a topic receives only 100 megabytes per day of messages, and `log.segment.bytes` is set to the default, it will take 10 days to fill one segment. As messages cannot be expired until the log segment is closed, if `log.retention.ms` is set to 604800000 (1 week), there will actually be up to 17 days of messages retained until the closed log segment expires. This is because once the log segment is closed with the current 10 days of messages, that log segment must be retained for 7 days before it expires based on the time policy (as the segment cannot be removed until the last message in the segment can be expired).
    - The size of the log segment also affects the behavior of fetching offsets by timestamp.
- `log.segment.ms`
    - specifies the amount of time after which a log segment should be closed.
    - Kafka will close a log segment either when the size limit is reached or when the time limit is reached, whichever comes first
    - By default, there is no setting for log.segment.ms, which results in only closing log segments by size.
- `message.max.bytes`
    - limits the maximum size of a message that can be produced.
    - default is 1000000, or 1 MB.
    - message with sized larger than this value will not be accepted.
    - this configuration deals with compressed message size, which means that producers can send messages that are much larger than this value uncompressed.
    - compress value should be under the configured message.max.bytes size.
    - There are noticeable performance impacts from increasing the allowable message size.
    - Larger messages will have impact on the broker threads, network connections, I/O throughput.
    - **BE CAREFUL:Coordinating Message Size Configurations**
        - The message size configured on the Kafka broker must be coordinated with the `fetch.message.max.bytes` configuration on consumer clients.
        - If this value is smaller than `message.max.bytes`, then consumers that encounter larger messages will fail to fetch those messages, resulting in a situation where the consumer gets stuck and cannot proceed.
        - The same rule applies to the `replica.fetch.max.bytes` configuration on the brokers when configured in a cluster.
