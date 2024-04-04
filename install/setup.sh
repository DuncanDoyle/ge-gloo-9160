#!/bin/sh

pushd ..

printf "\nDeploy Services ...\n"
kubectl apply -f apis/httpbin.yaml
kubectl apply -f apis/bookstore/bookstore.yaml

printf "\nDeploy Upstreams ...\n"
kubectl apply -f upstreams/bookstore-upstream.yaml

printf "\nDeploy RouteTables ...\n"
kubectl apply -f routetables/bookstore-routetable.yaml
kubectl apply -f routetables/httpbin-routetable.yaml

printf "\nDeploy VirtualServices ...\n"
kubectl apply -f virtualservices/api-example-com-vs.yaml
kubectl apply -f virtualservices/grpc-example-com-vs.yaml

popd