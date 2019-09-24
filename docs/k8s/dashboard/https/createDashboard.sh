#!/usr/bin/env bash
sh createCerts.sh
kubectl create secret generic kubernetes-dashboard-certs --from-file=./ -n kube-system
kubectl apply -f kubernetes-dashboard-official-https.yaml
