# Intel CS for WebRTC Deployment on Kubernetes

Container images, configurations and [Helm](https://helm.sh/) charts for installing
[Intel CS for WebRTC](https://software.intel.com/en-us/webrtc-sdk) on [Kubernetes](https://kubernetes.io/).

# Docker images

Images to run a Intel CS for WebRTC MCU for multi-party conferences.

## Building images

### Universal MCU components image

You will create universal MCU components image which can be used as any MCU components like nuve, cluster-manager, portal, so on.

First, download the latest release from [here](https://software.intel.com/en-us/webrtc-sdk/download).

Unzip it and copy the MCU package file to `docker/conference` folder.

```sh
cp CS_WebRTC_Conference_Server_MCU.v<Version>.tgz <Project Root>/docker/conference
```

To build the image, docker-compose command can be used:

```sh
cd docker/conference
docker-compose build
```

It will create `intelcs` image which is universal MCU components image.

### coturn image

This project uses the coturn as a turn server.

To build the image, the `create_image.sh`-script in the `docker/coturn` folder can be used:

```sh
cd docker/coturn
./create_image.sh
```

It will create `coturn` image.

### Peer server image

You can also create the peer server image if you want to deploy it.

copy the peer server release package file to `docker/peer` folder.

```sh
cp CS_WebRTC_Conference_Server_Peer.v<Version>.tgz <Project Root>/docker/peer
```

To build the image, docker-compose command can be used:

```sh
cd docker/peer
docker-compose build
```

It will create `intelcspeer` image.

## Publishing images

[Push](https://docs.docker.com/engine/reference/commandline/push/) the intelcs, coturn and intelcspeer(option) to the configured registry.

## Running images in Docker

You can run MCU and peer servers on Docker.

### Runnning MCU in Docker

Run the MongoDB and the RabbitMQ

```sh
cd docker/conference
docker-compose up -d mongo rabbit
```

Run the other components after the MongoDB and the RabbitMQ initialized

```sh
docker-compose up -d
```

Print log to find the sample service ID and service Key.

```sh
docker-compose logs nuve | grep sample
```

It will display something like this.

```text
nuve_1             | sampleServiceId: <Service ID>
nuve_1             | sampleServiceKey: <Service Key>
```

Edit the Docker environment file.

```sh
cp app.env.sample app.env
vi app.env
```

Replace `_service_ID_` with `<Service ID>` and `_service_KEY_` with `<Service Key>`.

Restart the sample application.

```sh
docker-compose restart app
```

_**Note:** You only need to restart app first time since the service ID and service Key are stored in DB and won't change.

To check the sample MCU application, access to following URL on your browser.

```
http://localhost:3001
```

### Running peer server in Docker

```sh
cd docker/peer
docker-compose up -d
```

# Helm Charts

These Helm charts can be used to install a Intel CS for WebRTC cluster consisting of a
MCU and a peer server on a Kubernetes cluster.

The following tutorial will show how you deploy a Intel CS for WebRTC on a Kubernetes cluster which was created by kops on AWS.

## Prerequisites

+ Released [nginx-ingress](https://github.com/helm/charts/tree/master/stable/nginx-ingress) with [default-ssl-certificate](https://github.com/helm/charts/blob/master/stable/nginx-ingress/values.yaml#L72)
+ Released [external-dns](https://github.com/helm/charts/tree/master/stable/external-dns)

## Create Instance Groups
Create two [instance groups](https://github.com/kubernetes/kops/blob/master/docs/instance_groups.md).
+ intelcs
+ coturn

The following ports should be open in the firewall for coturn.
+ 3478 TCP & UDP
+ 49152 - 65535 UDP

Create an additional security group to open those ports.

Add it to the coturn instance group by setting additionalSecurityGroups.

```yaml
apiVersion: kops/v1alpha2
kind: InstanceGroup
metadata:
  labels:
    kops.k8s.io/cluster: my-beloved-cluster
  name: coturn
spec:
  additionalSecurityGroups:
  - sg-xxxxxxxx
  - sg-xxxxxxxx
```

## Deploy MongoDB, RabbitMQ and Coturn

Deploy the MongoDB, the RabbitMQ and the coturn.

```sh
cd helm
helm install ./mongo \
  -n intelcs-mongo \
  -f ../supplements/kops/intelcs-mongo.yaml
helm install stable/rabbbitmq \
  -n intelcs-rabbit \
  -f ../supplements/kops/intelcs-rabbit.yaml
helm install ./coturn \
  -n intelcs-coturn \
  -f ../supplements/kops/intelcs-coturn.yaml
```

## Deploy Nuve

Deploy the nuve.

```sh
cd helm
helm install ./nuve \
  -n intelcs-nuve \
  -f ../supplements/kops/intelcs-nuve.yaml
```

## Configure Custom Values

### Get Service ID and Service Key

```sh
kubectl logs -l app=nuve -c nuve | grep sample
```

It will display something like this.

```text
sampleServiceId: <Service ID>
sampleServiceKey: <Service Key>
```

### Get public DNS of coturn node.

```sh
kubectl describe node -l kops.k8s.io/instancegroup=coturn | grep ExternalDNS
```

### Edit Sample MCU Application Custom Values

```sh
cd supplements/kops
vi intelcs-app.yaml
```

Replace value of `basicapp.env.SERVICE_ID` in intecs-app.yaml with `<Service ID>`.

Replace value of `basicapp.env.SERVICE_KEY` in intecs-app.yaml with `<Service Key>`.

Replace value of `basicapp.env.TURN_HOST` in intecs-app.yaml with public DNS of coturn node.

Replace `basicapp.example.com` with your desired host name for sample MCU application URL.

### Edit Management Console Custom Values

```sh
cd supplements/kops
vi intelcs-management-console.yaml
```

Replace `icsconsole.example.com` with your desired host name for Management Console URL.

### Edit Portal Custom Values

```sh
cd supplements/kops
vi intelcs-portal.yaml
```

Replace `portal.example.com` with your desired host name for portal.

### Edit Peer Server Custom Values

```sh
cd supplements/kops
vi intelcs-peer.yaml
```

Replace `peer.example.com` with your desired host name for peer server.

## Deploy Other Components

```sh
cd helm
helm install ./cluster_manager \
  -n intelcs-cluster-manager \
  -f ../supplements/kops/intelcs-cluster-manager.yaml
helm install ./portal \
  -n intelcs-portal \
  -f ../supplements/kops/intelcs-portal.yaml
helm install ./audio \
  -n intelcs-audio \
  -f ../supplements/kops/intelcs-audio.yaml
helm install ./video \
  -n intelcs-video \
  -f ../supplements/kops/intelcs-video.yaml
helm install ./conference \
  -n intelcs-conference \
  -f ../supplements/kops/intelcs-conference.yaml
helm install ./webrtc \
  -n intelcs-webrtc \
  -f ../supplements/kops/intelcs-webrtc.yaml
helm install ./streaming \
  -n intelcs-streaming \
  -f ../supplements/kops/intelcs-streaming.yaml
helm install ./recording \
  -n intelcs-recording \
  -f ../supplements/kops/intelcs-recording.yaml
helm install ./app \
  -n intelcs-app \
  -f ../supplements/kops/intelcs-app.yaml
helm install ./peer \
  -n intelcs-peer \
  -f ../supplements/kops/intelcs-peer.yaml
```

To check the sample MCU application, access to following URL on your browser.

```
https://<sample MCU application host name>:3001
```