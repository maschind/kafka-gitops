
oc apply -f amq-streams-operator.yml
oc apply -f gitops-operator.yml
oc new-project kafka

oc apply -f cluster/cluster-monitoring-config.yaml
oc apply -f cluster/user-workload-monitoring-config.yaml

oc apply -f gitops-kafka-application.yaml

oc adm policy add-role-to-user admin system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller -n kafka
