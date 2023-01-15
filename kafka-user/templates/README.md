
* install AMQ Streams Operator 
* install Red Hat gitops Operator

```
oc adm policy add-role-to-user admin system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller -n <Namespace_Name> 
```

oc run kafka-producer-perf-test-metrics -ti --image=quay.io/strimzi/kafka:latest-kafka-3.2.3 --rm=true --restart=Never -- /bin/bash -c "cat >/tmp/producer.properties <<EOF 
bootstrap.servers=my-cluster-kafka-bootstrap:9092
EOF
bin/kafka-producer-perf-test.sh --topic monitor.test --num-records 1000000 --throughput 5000 --record-size 2048 --print-metrics --producer.config=/tmp/producer.properties
"

oc run kafka-producer-perf-test-metrics -ti --image=quay.io/strimzi/kafka:latest-kafka-2.5.0 --rm=true --restart=Never -- /bin/bash -c "cat >/tmp/producer.properties <<EOF 
bootstrap.servers=event-bus-kafka-bootstrap:9092
security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=org.apache.kafka.common.security.scram.ScramLoginModule required username=admin-user-scram password=YZlv9tXGjYhF;
EOF
bin/kafka-producer-perf-test.sh --topic monitor.ocp.metrics --num-records 1000000 --throughput 5000 --record-size 2048 --print-metrics --producer.config=/tmp/producer.properties
"