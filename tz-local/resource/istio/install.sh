#!/usr/bin/env bash

#bash /vagrant/tz-local/resource/istio/install.sh
cd /vagrant/tz-local/resource/istio

kubectl delete -f 2-istio-eks.yaml
kubectl delete -f 1-istio-init.yaml

kubectl apply -f 1-istio-init.yaml
kubectl apply -f 2-istio-eks.yaml

#echo YWRtaW4= | base64 -d
#echo admin | base64
#echo xxxxx | base64

kubectl delete -f 3-kiali-secret.yaml
kubectl apply -f 3-kiali-secret.yaml

# label namespace
kubectl describe ns tgd
kubectl label namespace tgd istio-injection=enabled

kubectl apply -f 4-example.yaml

kubectl -n istio-system apply -f istio-ingress.yaml
curl --insecure https://kiali.istio-system.es-eks-a.tztest.com/kiali


