# Broker Configuration

## General Broker

- `node.id`(broker.id in v3 and before)
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
    - **If retention bytes is 1GB, it means when partition size exceeds 1GB of size, for example 1.1GB, 100MB of oldest data will be removed and 1GB will be retained.**

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

---

---

---

# Questions:

> ## Why does apache Kafka store logs in Segment files?

In Kafka, a topic is divided into partitions, and each partition is fundamentally an **append-only** log. Kafka breaks this log down into smaller files called segments. Here is why this design is essential:

### 1. Efficient Data Purging (Retention Policies)

Kafka is designed to retain data for a specific period (e.g., 7 days) or up to a specific size limit.

- **If it used a single file:** Deleting old messages from the _beginning_ of a massive, single file would require rewriting the entire file, which is an immensely expensive I/O operation.
- **With segments:** Kafka can simply delete the oldest segment files entirely when their data expires. Deleting a file from the file system is an $O(1)$ operation that requires minimal CPU and disk I/O.

### 2. Log Compaction

Kafka offers a feature called "log compaction," which ensures that Kafka retains at least the last known value for each message key. To achieve this, Kafka runs a background cleaner thread that reads older files, removes duplicated keys, and creates new, smaller compacted files. This process would be nearly impossible—and highly inefficient—if it had to parse and rewrite one gigantic monolithic file.

### 3. Memory Mapping and OS Page Cache

Kafka relies heavily on the operating system's page cache and memory-mapped files (mmap) for high performance.

- Memory mapping works best with files of a manageable size.
- By keeping segments relatively small (the default is usually $1 \text{ GB}$), Kafka allows the OS to easily load active segments into memory, ensuring rapid read and write access without overwhelming the system's RAM or hitting OS-level mmap limits.

### 4. Efficient Indexing and Lookups

Kafka consumers often need to read from a specific offset (a specific message number). To find a message quickly, Kafka maintains an index file for each log segment.

- When a consumer requests an offset, Kafka first uses a binary search to find the correct segment file.
- Then, it uses the segment's index to find the exact physical position of the message within that specific file.
- Managing indexes for smaller, immutable segment files is much faster and less memory-intensive than managing a continually updating index for one massive file.

### 5. Managing File System Limits

Operating systems and file systems have limits on maximum file sizes. A highly active Kafka partition can generate terabytes of data. Breaking the data into segments prevents Kafka from hitting OS file size limits and makes the underlying files easier to back up, move, or manage using standard Unix tools.

---

> ## How `log.retention.bytes` and `log.segment.bytes` can affect each other?

To understand how they interact, it helps to quickly define what they do:

- **`log.segment.bytes`**: Kafka topics are divided into partitions, and partitions are further divided into files called "segments." This setting dictates the maximum size of a single segment file (default is 1 GB). Once a segment hits this size, Kafka "closes" it and opens a new "active" segment to accept new messages.
- **`log.retention.bytes`**: This is the maximum amount of data Kafka will keep _per partition_ before it starts deleting old data (default is -1, meaning infinite retention by size).

### How They Affect Each Other

The crucial rule that connects them is this: **Kafka only deletes closed (inactive) segments.** It will _never_ delete the active segment that is currently being written to, regardless of your retention settings.

Because of this rule, `log.segment.bytes` directly affects how accurately Kafka can enforce `log.retention.bytes`.

#### 1. Total Disk Space Used Can Exceed `log.retention.bytes`

If you set `log.retention.bytes` to $10 \text{ GB}$ and `log.segment.bytes` to $1 \text{ GB}$, your partition size will usually hover between $10 \text{ GB}$ and $11 \text{ GB}$. Kafka will wait for the active segment to reach $1 \text{ GB}$, close it, realize the total partition size is now $11 \text{ GB}$, and then delete the oldest $1 \text{ GB}$ segment to get back down to $10 \text{ GB}$.

#### 2. The "Anti-Pattern": Segment Size > Retention Size

If you configure `log.segment.bytes` to be **larger** than or equal to `log.retention.bytes`, your retention policy will behave very unpredictably.

For example, if both are set to $10 \text{ GB}$:

- Kafka will keep writing to the active segment until it reaches $10 \text{ GB}$.
- Even though the partition has reached the retention limit, Kafka cannot delete the active segment.
- Kafka opens a new active segment. Now you have $10 \text{ GB}$ (closed) + new data (active).
- At this point, the closed segment is eligible for deletion.
- Effectively, your partition will grow to nearly $20 \text{ GB}$ before Kafka cleans up, making your $10 \text{ GB}$ retention setting essentially useless.

#### 3. Granularity of Deletion

`log.segment.bytes` determines the "chunk size" of your deletions. If you have a massive segment size, Kafka will delete data in massive chunks, causing sudden spikes in freed disk space. Smaller segment sizes allow Kafka to delete data more smoothly and stick much closer to your exact `log.retention.bytes` limit.

### Best Practices

- **Keep Segment Size Smaller:** As a general rule, `log.segment.bytes` should be a small fraction of `log.retention.bytes`. If you want to retain $100 \text{ GB}$ per partition, a segment size of $1 \text{ GB}$ (the default) is great.
- **Don't make segments too small:** Making `log.segment.bytes` extremely small (e.g., $10 \text{ MB}$) to get precise retention will result in thousands of open files and high disk/OS overhead, which degrades broker performance. The default $1 \text{ GB}$ is usually optimal unless you have very low traffic.
