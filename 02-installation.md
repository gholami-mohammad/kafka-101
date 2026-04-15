# Installation (Single Node)

**NOTE: We will cover single node installation for development environment. Later, we will cover production ready cluster.**

## MacOs

```sh
brew install kafka
```

You can run kafka in the background using:

```sh
brew start kafka
```

Or manually run it:

```sh
/opt/homebrew/bin/kafka-server-start /opt/homebrew/etc/kafka/server.properties
```

## Linux (Ubuntu/Debian)

**NOTE: In this setup, we are working with openjdk version 21 and Kafka version 4.2.0 build 2.13-4.2.0. You should update commands based on your downloaded versions.**

1. Install openjdk

    ```sh
    sudo apt-get update
    sudo apt-get install -y openjdk-21-jdk # you can set jdk version as you wish
    ```

1. Download Kafka binary file from [kafka official website](https://kafka.apache.org/community/downloads/)

    ```sh
    wget https://www.apache.org/dyn/closer.lua/kafka/4.2.0/kafka_2.13-4.2.0.tgz?action=download
    ```

1. Extract the file and go to the extracted directory.

```sh
tar -xvf kafka_2.13-4.2.0.tgz
cd kafka_2.13-4.2.0
```

1. Setting Log directory:
    - Create log directory: `mkdir /home/kafka/kraft-combined-logs`
    - Open server properties file and set `log.dirs` to `/home/kafka/kraft-combined-logs`.

1. Generate ID and format storage

```sh
./bin/kafka-storage.sh format --standalone -t `./bin/kafka-storage.sh random-uuid` -c ./config/server.properties
```

1. Start server:

```sh
./bin/kafka-server-start.sh config/server.properties
```

**NOTE: KEEP THIS TERMINAL OPEN. Otherwise, Kafka server will be stopped.**

1. Config installation:

```sh
./bin/kafka-topics.sh --bootstrap-server localhost:9092 --create --topic testing
```

You should see `Created topic testing.` message.
