#!/bin/bash

set -eu

echo "k3s installed ..."
sleep 30

# apply files to k3s
echo "Applying configuration files to k3s..."
kubectl apply -f /vagrant/confs/.

echo "Waiting 30s for pods to build..."
sleep 30

echo "Waiting 30s for pods to build..."

# verify running pods
echo "Verifying running pods..."
kubectl get pods

echo "Waiting 10s..."
sleep 10

# check deployement status
echo "Checking deployment status..."
kubectl get deployments

echo "Waiting 10s..."
sleep 10

# check the service
echo "Checking services..."
kubectl get services

echo "Waiting 10s..."
sleep 10

# view logs of app one
echo "Viewing logs for app-one..."
kubectl logs -l app=app-one

echo "Waiting 10s..."
sleep 10

# view logs of app two
echo "Viewing logs for app-two..."
kubectl logs -l app=app-two
