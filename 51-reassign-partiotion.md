# Reassign Partitions

In Apache Kafka, the **Partition Reassignment Tool** (`kafka-reassign-partitions.sh`) is a built-in administrative command-line utility used to change the replica assignment of partitions across brokers in a cluster.

Here are its core features and workflow:

## **Core Features & Workflow:**

- **Three-Step Process:** The tool operates in three distinct phases:
    1.  **Generate:** You provide a list of topics and target brokers. The tool generates a proposed reassignment plan in JSON format. It does not apply the changes yet.
    2.  **Execute:** You submit the JSON reassignment plan to the cluster. The controller then initiates the process of moving the partitions to their new broker destinations.
    3.  **Verify:** You use this step to check the status of an ongoing reassignment. It tells you which partitions have successfully moved and which are still in progress.
- **Replication-Based Movement:** Kafka moves partitions by using its standard inter-broker replication mechanism. The new broker adds itself as a follower, replicates the data from the leader, joins the In-Sync Replica (ISR) list, and then the old broker deletes its copy.
- **Throttling (Bandwidth Control):** Moving massive amounts of data can saturate network bandwidth and disk I/O, impacting real-time clients. The tool allows you to pass a `--throttle` flag (measured in bytes per second) to limit the speed of the data transfer.
- **Custom Reassignments:** While the "Generate" step creates a balanced plan automatically, administrators can manually author the JSON file to dictate exactly which partition replica goes to which specific broker.

## Three-Step Process How to

**Prerequisite: Create `topics.json`**

```json
{
	"topics": [{ "topic": "first-topic" }, { "topic": "second-topic" }],
	"version": 1
}
```

### 1. Generate

Generates the proposed reassignment plan for the topics across the specified brokers (e.g., brokers 0, 1, and 2).

```bash
kafka-reassign-partitions \
  --bootstrap-server localhost:9092 \
  --topics-to-move-json-file topics.json \
  --broker-list "0,1,2" \
  --generate
```

_The command will output the "Current partition replica assignment" and the "Proposed partition reassignment". Copy the JSON for the **Proposed** reassignment and save it to a new file named `reassignment.json`._

You can also edit the file as you wish and save it for the next step.

### 2. Execute

Submits the `reassignment.json` plan to the cluster to begin moving the partitions.

```bash
kafka-reassign-partitions.sh \
  --bootstrap-server localhost:9092 \
  --reassignment-json-file reassignment.json \
  --execute
```

_(Optional: You can add a throttle limit by appending e.g., `--throttle 50000000` to limit bandwidth to ~50 MB/s)._

### 3. Verify

Checks the status of the ongoing reassignment. Run this periodically until it reports that all reassignments have completed successfully.

```bash
kafka-reassign-partitions.sh \
  --bootstrap-server localhost:9092 \
  --reassignment-json-file reassignment.json \
  --verify
```

## **Primary Use Cases:**

- **Cluster Expansion:** When you add new brokers to an existing cluster, they start empty. You use this tool to move existing partitions onto the new brokers to distribute the storage and processing load.
- **Broker Decommissioning:** Before removing a broker for maintenance or permanent retirement, you must use this tool to safely evacuate all of its partitions to other active brokers.
- **Load Balancing:** If some brokers are running out of disk space or handling too much traffic, you can reassign specific heavy partitions to brokers with more capacity.
- **Changing Replication Factor:** You can manually create a JSON plan to increase or decrease the number of replicas for an existing topic.
