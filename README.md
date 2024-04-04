# Gloo-9160 Reproducer


## Installation

Add Gloo EE Helm repo:
```
helm repo add glooe https://storage.googleapis.com/gloo-ee-helm
```

Export your Gloo Edge License Key to an environment variable:
```
export GLOO_EDGE_LICENSE_KEY={your license key}
```

Install Gloo Edge:
```
cd install
./install-gloo-edge-enterprise-with-helm.sh
```

> NOTE
> The Gloo Edge version that will be installed is set in a variable at the top of the `install/install-gloo-edge-enterprise-with-helm.sh` installation script.

## Setup the environment

Run the `install/setup.sh` script to setup the environment:

- Deploy the HTTPBin service
- Deploy the Bookstore gRPC service
- Deploy the Upstream with `grpcJsonTranscoder` configured
- Deploy the Routetables
- Deploy the VirtualServices

```
./setup.sh
```

## Run the test

Check the HTTPBin service:

```
curl -v http://api.example.com
```

Check the gRPC Bookstore service

```
curl -v http://grpc.example.com/shelf -d '{"theme": "music"}'
curl -v http://grpc.example.com/shelves
```

Check the status of the `bookstore-routetable`:

```
kubectl -n gloo-system get rt bookstore-routes -o yaml
```

The `status` field should print "Accepted" and show no errors.

## Triggering the Issue

To trigger the problem, apply the (completely unrelated), `virtualservices/wtf-example-com-vs-https.yaml` VirtualService:

```
kubectl apply -f virtualservices/wtf-example-com-vs-https.yaml
```

When you now check the `bookstore-routetable` again, you can see the status now shows a warning:

```
kubectl -n gloo-system get rt bookstore-routes -o yaml
```

Output:
```
status:
  statuses:
    gloo-system:
      reportedBy: gloo
      state: Accepted
      subresourceStatuses:
        '*v1.Proxy.gateway-proxy_gloo-system':
          reason: "1 error occurred:\n\t* Route Error: ProcessingError. Reason: *grpcjson.plugin:
            invalid route. Route Name: gloo-system_wtf-service-v1-http-to-https-route-0-matcher-0;
            Route Error: ProcessingError. Reason: *grpcjson.plugin: invalid route.
            Route Name: gloo-system_wtf-service-v1-http-to-https-route-0-matcher-1;
            Route Error: ProcessingError. Reason: *grpcjson.plugin: invalid route.
            Route Name: gloo-system_wtf-service-v1-http-to-https-route-0-matcher-2\n\n"
          reportedBy: gloo
          state: Rejected
```

Note that the Bookstore service is still accessible, and so is the HTTPBin service:

```
curl -v http://grpc.example.com/shelves
curl -v http://api.example.com/get
```

Next, change the `bookstore-upstream` so it no longer configures the `grpcJsonTranscoder` (the yaml we apply is the exact same Upstream, except for the `grpcJsonTranscoder` related configuration):

```
kubectl apply -f upstreams/bookstore-upstream-no-grpc.yaml
```

Check the `bookstore-routetable` again, and notice that the error is gone:

```
kubectl -n gloo-system get rt bookstore-routes -o yaml
```

> [!NOTE]
> Sometimes the routetable status does not update after a change in the Upstream. You can trigger a status update by simply adding a random label to, for example, one of the virtualservices:
> ```
> kubectl -n gloo-system label vs wtf-service-v1-http-to-https --overwrite random=value
> ```

Apply the Upstream with `grpcJsonTranscoder` again:

```
kubectl apply -f upstreams/bookstore-upstream.yaml 
```

and notice the `bookstore-routetable` shows the error again (if the error is not shown, apply another random label to the virtualservice to trigger the update):

```
kubectl -n gloo-system get rt bookstore-routes -o yaml
```

## Conclusion
I have no idea ....