---
layout: post
title: "Running the same Docker Compose file multiple times"
tags: infra docker
---

## Why?

This feels like an issue that is better solved in another way, but I'll still explain how we solved the issue of running
the same [Docker Compose][docker-compose] file concurrently multiple times without interference.

In our setup we didn't want to duplicate configuration, so we wanted to use the same Docker Compose file to run both
in development mode and for integration tests on the same machine. This is actually pretty easy if you use dynamic port
mapping so that integration tests and development don't use the same ones. Why is that? We
use [Testcontainers][testcontainers] to run integration tests and how it works is that it assigns a random 6
letter [Base58][base58] string as a [Compose Project Name][compose-project-name], so you can run the same Docker Compose
file as many times as you want. You can do it manually as well by appending a different project name
with `-p projectname` option to the `docker compose up` command.

So if it works out of the box, what's the issue?

In our setup we have three services: Postgres, Redis and Kafka and we didn't want to search for ports every time we
start up Docker Compose for development. We wanted to use static ports for development and dynamic ports for integration
tests while still using only a single Docker Compose file.

## Solution

Docker Compose has [.env file support][compose-env-file], which means we can use environment variables inside or Docker
Compose file with different values for different environments.

For example if you want your Postgres to use port `5432` in development you need to specify the port as:

```yaml

services:
  postgres:
    image: postgres:latest
    ports:
      - "5432${POSTGRES_PORT}"
```

And your .env file as:

```
POSTGRES_PORT=:5432
```

Now, by default the env variable gets replaced when you run `docker compose up` and your Postgres instance uses 5432
port on the host.

With Testcontainers you can specify:

```java
final var composeContainer = new ComposeContainer(composeFile)
  .withEnv("POSTGRES_PORT", "")
  .withExposedService("postgres", 1, POSTGRES_PORT, Wait.forLogMessage(".*database system is ready to accept connections.*\\s", 2));


// Get the actual port
final var dbPort = composeContainer.getServicePort("postgres", 5432);
```

Now your development setup and integration tests will not interfere, and you will have fixed ports for development.

## What about Kafka?

What about it? Oh yeah, Kafka doesn't really like dynamic ports. Let's say our Docker Compose looks like this:

```yaml
services:
  kafka:
    image: bitnami/kafka:3.6.0
    depends_on:
      - zookeeper
    ports:
      - "9094${KAFKA_PORT}"
    volumes:
      - "kafka:/bitnami"
    environment:
      - KAFKA_CFG_BROKER_ID=1
      - KAFKA_CFG_ZOOKEEPER_CONNECT=zookeeper:2181
      - KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093,EXTERNAL://:9094
      - KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092,EXTERNAL://localhost:9094
      - KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,EXTERNAL:PLAINTEXT,PLAINTEXT:PLAINTEXT
  zookeeper:
    image: bitnami/zookeeper:3.9.1
    ports:
      - "2181${ZOOKEEPER_PORT}"
    volumes:
      - "zookeeper:/bitnami"
    environment:
      ALLOW_ANONYMOUS_LOGIN: "yes"

volumes:
  kafka:
  zookeeper:
```

This works fine in development mode where our ports are fixed, but when we use dynamic ports then Kafka will still try
to advertise the port `9094`, which is not the correct port to use on the host.

To get around this issue you can use this "hack" with Testcontainers after the containers are started:

```java

final var kafkaPort = composeContainer.getServicePort("kafka", 9094);

composeContainer.getContainerByServiceName("kafka").map(it -> {
  final var result = it.execInContainer("/opt/bitnami/kafka/bin/kafka-configs.sh",
    "--bootstrap-server", "localhost:9092",
    "--entity-type", "brokers",
    "--entity-name", "1",
    "--alter", "--add-config", "advertised.listeners=[PLAINTEXT://kafka:9092,EXTERNAL://localhost:%s]".formatted(kafkaPort));
  if(result.exitCode !=0) {
    throw new IllegalStateException("Could not override advertised listeners");
  }
});
```

[docker-compose]: https://docs.docker.com/compose/

[bitnami-kafka]: https://github.com/bitnami/containers/tree/main/bitnami/kafka#readme

[testcontainers]: https://testcontainers.com

[base58]: https://learnmeabitcoin.com/technical/base58

[compose-project-name]: https://docs.docker.com/compose/project-name/

[compose-env-file]: https://docs.docker.com/compose/environment-variables/set-environment-variables/#substitute-with-an-env-file
