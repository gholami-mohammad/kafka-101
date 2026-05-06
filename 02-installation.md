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

1. Create kafka user

    ```sh
    sudo useradd --system --no-create-home --shell /bin/false kafka
    ```

1. Extract the file and go to the extracted directory.

    ```sh
    cd ~
    tar -xvf kafka_2.13-4.2.0.tgz
    sudo mv kafka_2.13-4.2.0 /opt/kafka
    sudo chown -R kafka:kafka /opt/kafka
    cd /opt/kafka/
    ```

1. Setting Log directory:
    - Create log directory:
        ```sh
        sudo mkdir -p /var/kafka/kraft-combined-logs
        ```
    - Open server properties file and set `log.dirs` to `/var/kafka/kraft-combined-logs`.

1. Adding kafka bin to PATH:
    - if using bash:
        ```
        echo 'export PATH="$PATH:/opt/kafka/bin"' >> ~/.bashrc
        source ~/.bashrc
        ```
    - if using zsh:
        ```
        echo 'export PATH="$PATH:/opt/kafka/bin"' >> ~/.zshrc
        source ~/.bashrc
        ```

1. Generate ID and format storage

    ```sh
    CLUSTER_ID=$(/opt/kafka/bin/kafka-storage.sh random-uuid)
    sudo /opt/kafka/bin/kafka-storage.sh format --standalone -t $CLUSTER_ID -c /opt/kafka/config/server.properties

    sudo chown -R kafka:kafka /var/kafka
    ```

1. Start server:

    ```sh
    kafka-server-start.sh /opt/kafka/config/server.properties
    ```

    **NOTE: KEEP THIS TERMINAL OPEN. Otherwise, Kafka server will be stopped.**

1. Config installation:

    ```sh
    kafka-topics.sh --bootstrap-server localhost:9092 --create --topic testing
    ```

    You should see `Created topic testing.` message.

### تنظیم به عنوان سرویس

درصورتیکه تمایل داشته باشید که کافکا به عنوان یک سرویس systemd در بکگراند اجرا شود، می توانید این بخش را نیز مطالعه کنید.

```sh
sudo tee /etc/systemd/system/kafka.service <<EOF
[Unit]
Description=Apache Kafka
After=network.target

[Service]
Type=simple
User=kafka
Group=kafka
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
Restart=on-abnormal

# Security Hardening
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/kafka /var/kafka
LimitNOFILE=100000

[Install]
WantedBy=multi-user.target

EOF

sudo systemctl enable kafka.service
sudo systemctl start kafka.service
sudo systemctl status kafka.service
```

در صورت بروز خطا، میتوانید جزییات لاگ سرویس را با دستور زیر مشاهده کنید:

```sh
sudo journalctl -u kafka.service -f
```
