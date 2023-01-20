
* install AMQ Streams Operator 
* install Red Hat gitops Operator

```
oc adm policy add-role-to-user admin system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller -n <Namespace_Name> 
```

Producer
```
oc run kafka-producer -ti --image=quay.io/strimzi/kafka:latest-kafka-3.2.3 --rm=true --restart=Never -- /bin/bash -c "cat >/tmp/producer.properties <<EOF 
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username=user1 password=k5CtKkp30xai;
EOF
bin/kafka-console-producer.sh --broker-list my-cluster-kafka-bootstrap:9094 --topic user1.topic1 --producer.config=/tmp/producer.properties --timeout 5000 --retry-backoff-ms 3000
"
```

Consumer
```
oc run kafka-consumer -ti --image=quay.io/strimzi/kafka:latest-kafka-3.2.3 --rm=true --restart=Never -- /bin/bash -c "cat >/tmp/consumer.properties <<EOF
bootstrap.servers=my-cluster-kafka-bootstrap:9094
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username=user2 password=aZiKxlR44goL;
EOF
bin/kafka-console-consumer.sh --bootstrap-server my-cluster-kafka-bootstrap:9094 --topic user1.topic1 --consumer.config=/tmp/consumer.properties --group user2.testing
"
```

Performance Tool
```
oc run kafka-producer-perf-test-metrics -ti --image=quay.io/strimzi/kafka:latest-kafka-3.2.3 --rm=true --restart=Never -- /bin/bash -c "cat >/tmp/producer.properties <<EOF 
bootstrap.servers=my-cluster-kafka-bootstrap:9094
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username=user1 password=k5CtKkp30xai;
EOF
bin/kafka-producer-perf-test.sh --topic user1.topic1 --num-records 1000000 --throughput 5000 --record-size 2048 --print-metrics --producer.config=/tmp/producer.properties
"
```

Consumer 
```
oc run kafka-consumer-perf-test-metrics -ti --image=quay.io/strimzi/kafka:latest-kafka-3.2.3 --rm=true --restart=Never -- /bin/bash -c "cat >/tmp/consumer.properties <<EOF 
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username=user1 password=k5CtKkp30xai;
EOF
bin/kafka-consumer-perf-test.sh --broker-list my-cluster-kafka-bootstrap:9094 --topic user1.topic1 --consumer.config=/tmp/consumer.properties --group user1.perform --from-latest --messages 1000000 --reporting-interval 1000 --show-detailed-stats
"
```


Cluster Scaling

Producer
```
oc run kafka-producer -ti --image=quay.io/strimzi/kafka:latest-kafka-3.2.3 --rm=true --restart=Never -- /bin/bash -c "
bin/kafka-console-producer.sh --broker-list my-cluster-kafka-bootstrap.kafka-test.svc.cluster.local:9092 --topic my-topic --timeout 5000 --retry-backoff-ms 3000
"
```
```
oc run kafka-consumer -ti --image=quay.io/strimzi/kafka:latest-kafka-3.2.3 --rm=true --restart=Never -- /bin/bash -c "
bin/kafka-console-consumer.sh --bootstrap-server my-cluster-kafka-bootstrap.kafka-test.svc.cluster.local:9092 --topic my-topic --group my-testing
"
```