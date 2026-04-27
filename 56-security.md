# Security

Kafka security protocols:

- PLAINTEXT: not secure
- SASL_PLAINTEXT: not secure
- SSL: secure
- SASL_SSL: secure

SASL = Simple Authentication Security Layer

Different protocols can be applied to different connection protocols.

We have 2 types of connections:

- Client - Broker
- Broker - Broker

Kafka supports 4 different authentication mechanism:

- GSSAPI: Kerberos (active directory, open LDAP)
- Plain: (username/password)
- SCAM-SHA: (username/password)
- OAUTHBEARER: Machine to machine Single Sign On

Kafka also support ACL (Access Control List) to allow users to perform specific tasks when Authenticated on Kafka.

ACLs describe which user is permitted to perform certain operation on specific resources.

ACL binding: Principal + Permission Type + Operation + Resource
Example: [User:Bob] has [Allow] permission for [Write] operation to [Topic:customers].

NOTES: Principal should be in this format: User:Username or User:\* for all users.

## Defining ACLs

Here is a simple example of how can define an ACL:

```sh
kafka-acls --bootstrap-server localhost:9092 --add --allow-principal User:Bob --allow-principal User:John --operation read --operation write --topic finance
```

# Setting up SSL Encryption

# General Security recommendations

- Using full dist encryption or volume encryption is highly recommended for secure data store.
-
