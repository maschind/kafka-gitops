#!/bin/bash

# Function to check if an operator is successfully installed
# Usage: wait_for_operator_installation operator_name operator_namespace [max_wait_time]
wait_for_operator_installation() {
  operator_name=$1
  operator_namespace=$2
  max_wait_time=${3:-300}  # Default to 5 minutes (300 seconds)

  echo "Waiting for operator $operator_name to be successfully installed..."

  start_time=$(date +%s)
  while [[ $(oc get csv -n $operator_namespace | grep $operator_name | awk '{print $NF}') != "Succeeded" ]]; do
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))
    if [[ $elapsed_time -gt $max_wait_time ]]; then
      echo "Timeout waiting for operator $operator_name to be successfully installed."
      return 1
    fi
    echo "Operator $operator_name is not yet ready, waiting..."
    sleep 5
  done

  echo "Operator $operator_name is now successfully installed."
  return 0
}

# MAIN SCRIPT

echo "Start bootstrapping the cluster... "

oc apply -f gitops-operator.yml

operator_name="openshift-gitops-operator"
operator_namespace="openshift-operators"
wait_for_operator_installation "$operator_name" "$operator_namespace" 300  # Wait up to 5 minutes (300 seconds)

oc new-project kafka 

oc adm policy add-role-to-user admin system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller -n kafka
oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller

oc apply -f gitops-applications/gitops-bootstrap-application.yaml
oc apply -f gitops-applications/gitops-kafka-application.yaml


#oc apply -f cluster/cluster-monitoring-config.yaml
#oc apply -f cluster/user-workload-monitoring-config.yaml

#operator_name="openshift-gitops-operator"
#operator_namespace="openshift-operators"
#wait_for_operator_installation "$operator_name" "$operator_namespace" 300  # Wait up to 5 minutes (300 seconds)

#operator_name="amqstreams"
#operator_namespace="openshift-operators"
#wait_for_operator_installation "$operator_name" "$operator_namespace" 300  # Wait up to 5 minutes (300 seconds)

#oc apply -f gitops-kafka-application.yaml
