FROM confluentinc/cp-kafka-connect:latest

# ENV CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components"

# Install Debezium connectors (add/remove as needed)
RUN confluent-hub install --no-prompt debezium/debezium-connector-mysql:latest && \
    confluent-hub install --no-prompt debezium/debezium-connector-postgresql:latest && \
    confluent-hub install --no-prompt debezium/debezium-connector-mongodb:latest && \
    confluent-hub install --no-prompt debezium/debezium-connector-sqlserver:latest