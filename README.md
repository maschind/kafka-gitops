WIP...

# Demo description
In the world of big data, Apache Kafka has become the go-to platform for building real-time data pipelines and streaming applications. However, managing a Kafka cluster in a multi-tenant environment can be complex, especially when different users require access to specific topics and resources. That's where Helm, Strimzi, and ArgoCD come in. These three powerful tools can be combined to create and manage a multi-tenant Kafka cluster with a GitOps approach, enabling you to manage Kafka resources through declarative configuration files stored in a Git repository.

This demo code will demonstrated how to deploy a production like setup of Red Hat AMQ Streams (Kafka) in a modern Infrastructure as a Code approach. An easy way to manage Kafka topics, users, and authorization is through simple Helm charts and fully automated GitOps synchronization and the power of the AMQ Streams Operator.


Tested on Openshift 4.12 / 4.13


# Instructions to setup the demo
This demo will deploy the following components on an Openshift Cluster:
* Red Hat GitOps (ArgoCD)
* AMQ Streams (Strimzi/Kafka)
* Configuration of user defined project for Openshift's Monitoring
* Grafana, using the Grafana Operator 


You can use the script `bootstrap/prepare-cluster.sh` to install GitOps and the needed ArgoCD Applications. 


After all applications in argoCD are synchronized, a small post-installation step will be needed to grant permission to grafana to use prometheus as datasource. 

```
oc adm policy add-cluster-role-to-user cluster-monitoring-view -z grafana-serviceaccount
TOKEN=$(oc create token grafana-serviceaccount --duration=8760h -n grafana)
oc create secret generic grafana-serviceaccount-token --from-literal=token=$TOKEN -n grafana

```
The token displayed as outpt will be later used to create a grafana datasource. 

```
apiVersion: integreatly.org/v1alpha1
kind: GrafanaDataSource
metadata:
  name: prometheus-grafanadatasource
  namespace: grafana
spec:
  datasources:
    - access: proxy
      editable: true
      isDefault: true
      jsonData:
        httpHeaderName1: 'Authorization'
        timeInterval: 5s
        tlsSkipVerify: true
      name: Prometheus
      secureJsonData:
        httpHeaderValue1: 'Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6ImxnNGNJMmt4Ymg5aW5nM3FQbllWVE16emVaYlZsS2M5SExTdGIwT0F1Q2cifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjIl0sImV4cCI6MTcyMjYwNzQ4MywiaWF0IjoxNjkxMDcxNDgzLCJpc3MiOiJodHRwczovL2t1YmVybmV0ZXMuZGVmYXVsdC5zdmMiLCJrdWJlcm5ldGVzLmlvIjp7Im5hbWVzcGFjZSI6ImdyYWZhbmEiLCJzZXJ2aWNlYWNjb3VudCI6eyJuYW1lIjoiZ3JhZmFuYS1zZXJ2aWNlYWNjb3VudCIsInVpZCI6IjUxNjgwNjg2LWEzNWYtNDZlMi1iNGVmLWRmOWUwYzlkM2VkNCJ9fSwibmJmIjoxNjkxMDcxNDgzLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6Z3JhZmFuYTpncmFmYW5hLXNlcnZpY2VhY2NvdW50In0.Gm88RIEQzryuUjZcjkWkq1EhUaYzUmq5_D2m05_GdwjEJU7Wx86IKmbukpYF01dxmGszrnuaQDjJLbEKh2GyWDBfoSMLGuNwnbtax0U0c3k-tu0p9qchG6FQ0yce-BXbn04PmOFZTi7jVy_1VGiSVEikt-bL7zjnWTOJ80VJvHBuzSoH9wykv5wZUUesGlla-O_ynMPZnxW5MTXcDjYJbA8DX4xp6Ekvc2OpKYFLerqHF7n_EIcPvhgAK3S26kUhRY2R2sfwQWVuQEI2RWHGjVgZRQJmtjfdsYG7dFzZ8vQlrT2r0uDyVYn9iWxVv6_NcjadA6pqjJGa3JZ9UNzFuI929aP8Udt0b3YnDDWrO2A1FLs6PCjzR4pTVVq62m90U8Y6uf0-hvVSu3I4nRqyWI5Bi6hkseumKur9MLzxJNkDmJEqPoWBbwhAWO6wNvfvfgVoeS0XQ5xRhdbGB5mxJvapetVEAEh77FPdooYGu2yMukL6wR9NCCs-JosUBsF3JhPg-RqkLnQk2PKyC8evTjXRv8pEVZ7iBXuxswKA-QvB-AulPhrkes5_EiwfE5AFskuD26Xq3Lj83rsxxeK0AcEMCMCr7MuYcl6S_5kmif3s5tzsbDUGkh6vtiZy05ZGyKz0FN4U0CrK7UHHOaGS3L-Gd9MjovV4v9yzWMpjWRw'
      type: prometheus
      url: 'https://thanos-querier.openshift-monitoring.svc.cluster.local:9091'
  name: prometheus-grafanadatasource.yaml
```



# Testing the Kafka setup

The follwoing commands do have a placeholder `<password>` which needs to be replaced with the actual password.
The password is stored in the kafka namespace in the respective secret of the provisioned user. To retrieve the password the following command can be issued: 
```
oc .....
```



## Simple Consumer / Producer
### Producer 
Ingest messages as kafka-user-1 to shared-topic1
```
oc run kafka-producer -ti --image=quay.io/strimzi/kafka:latest-kafka-3.2.3 --rm=true --restart=Never -- /bin/bash -c "cat >/tmp/producer.properties <<EOF 
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username=kafka-user-1 password=<password>;
EOF
bin/kafka-console-producer.sh --broker-list kafka01-kafka-bootstrap:9094 --topic shared-topic1 --producer.config=/tmp/producer.properties --timeout 5000 --retry-backoff-ms 3000
"
```

### Consumer
Read as kafka-user-2 from shared-topic1
```
oc run kafka-consumer -ti --image=quay.io/strimzi/kafka:latest-kafka-3.2.3 --rm=true --restart=Never -- /bin/bash -c "cat >/tmp/consumer.properties <<EOF
bootstrap.servers=kafka01-kafka-bootstrap:9094
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username=kafka-user-2 password=<password>;
EOF
bin/kafka-console-consumer.sh --bootstrap-server kafka01-kafka-bootstrap:9094 --topic shared-topic1 --consumer.config=/tmp/consumer.properties --group kafka-user-2-group
"
```

## Performance Testing
### Performance Producer
```
oc run kafka-producer-perf-test-metrics -ti --image=quay.io/strimzi/kafka:latest-kafka-3.2.3 --rm=true --restart=Never -- /bin/bash -c "cat >/tmp/producer.properties <<EOF 
bootstrap.servers=kafka01-kafka-bootstrap:9094
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username=kafka-user-1  password=<password>;
EOF
bin/kafka-producer-perf-test.sh --topic shared-topic1 --num-records 1000000 --throughput 5000 --record-size 2048 --print-metrics --producer.config=/tmp/producer.properties
"
```

### Performance Consumer
 
```
oc run kafka-consumer-perf-test-metrics -ti --image=quay.io/strimzi/kafka:latest-kafka-3.2.3 --rm=true --restart=Never -- /bin/bash -c "cat >/tmp/consumer.properties <<EOF 
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username=kafka-user-2 password=<password>;
EOF
bin/kafka-consumer-perf-test.sh --broker-list kafka01-kafka-bootstrap:9094 --topic shared-topic1 --consumer.config=/tmp/consumer.properties --group kafka-user-2-group --from-latest --messages 1000000 --reporting-interval 1000 --show-detailed-stats
"
```


Cluster Scaling

Producer
```
oc run kafka-producer -ti --image=quay.io/strimzi/kafka:latest-kafka-3.2.3 --rm=true --restart=Never -- /bin/bash -c "
bin/kafka-console-producer.sh --broker-list kafka01-kafka-bootstrap.kafka-test.svc.cluster.local:9092 --topic my-topic --timeout 5000 --retry-backoff-ms 3000
"
```
```
oc run kafka-consumer -ti --image=quay.io/strimzi/kafka:latest-kafka-3.2.3 --rm=true --restart=Never -- /bin/bash -c "
bin/kafka-console-consumer.sh --bootstrap-server kafka01-kafka-bootstrap.kafka-test.svc.cluster.local:9092 --topic my-topic --group my-testing
"
```
