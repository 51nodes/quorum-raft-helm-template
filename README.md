# Helm Templates for n-Nodes Raft Quorum Network
This repository provides templates for a basic quorum setup using 3 nodes. By using the provided [scripts](quorum/scripts/) you can add and remove nodes to the existing raft cluster. Nodes will be available at `http://<cluster-ip>/quorum-node<n>-rpc`.  Note that this repository is currently designed to be used in development and testing only, do not use this in a production environment! Please do not reuse the account credentials provided in this repository. 

## Requirements
- [minikube](https://minikube.sigs.k8s.io/docs/start/) (optional) to create a local kubernetes cluster
- [helm](https://helm.sh/) to deploy the charts to your running cluster
- [yq](https://github.com/mikefarah/yq) version 4 and higher, to modify the cluster using the provided [scripts](quorum/scripts/)
- [k8s 1.23](https://kubernetes.io/releases/#release-v1-23)

## Configuring Geth
To set different quorum and geth parameters use the `quorum`, `geth` and `getParams` values in the [values.yaml](quorum/values.yaml) file. If you want add initial accounts or in general want to modify the `geth genesis` you can do so in the [01-quorum-genesis.yaml](quorum/templates/01-quorum-genesis.yaml).
```bash
quorum: 
  version: 22.4
  storageSize: 1Gi
geth:
  networkId: 10
  port: 30303
  raftPort: 50401
  verbosity: 3
  gethParams: 
    --permissioned \
    --nodiscover \
    --nat=none \
    --unlock 0 \
    --emitcheckpoints \
    --http.corsdomain '*' \
    --http.vhosts '*' \
```

## Deploy, Inspect & Remove
Use the templates in this repository to deploy a quorum network with n nodes. It might take some time for the nodes to be up and in sync. Please do not modify the initial 3 nodes provided in this repository, as they are needed for the raft consensus to function properly. The helm chart is named `nnodes`, changing the charts name will lead to problems with the provided [scripts](quorum/scripts). 

### (Optional) If using minikube
```bash
# Bring up minikube in vm-mode (Note that with ARM Processors the vm=true flag will not be working. minikube 1.26-beta includes a not yet fully functional fix using qemu https://github.com/kubernetes/minikube/issues/11885)
minikube start --memory='6144' --vm=true

# Enable nginx ingress controller for minikube
minikube addons enable ingress

# Open Tunnel 
minikube tunnel
```

### Start deploying the templates
```bash
# Create namespace
kubectl create ns quorum-network

# Deploy template to namespace
helm install nnodes quorum -n quorum-network
```

### Inspect the deployments
```bash
# List running nodes 
kubectl -n quorum-network get pods

# Inspect raft cluster
kubectl exec -n quorum-network <pod> -- geth --exec "raft.cluster" attach ipc:etc/quorum/qdata/dd/geth.ipc
```

## Adding & Removing Nodes
After deploying the initial cluster run the following scripts from the [quorum/scripts/](quorum/scripts/) directory to add or remove `single` or `multiple` nodes dynamically. The scripts will wait for user prompts and edit the [values.yaml](quorum/values.yaml) file accordingly. The `values.yaml`-file will then be used in the helm templates for deploying a quorum raft cluster with multiple nodes. Keep in mind the inital cluster with 3 nodes has to be running and the nodes have to be in snyc to use these scripts. Nodes which are not initial (node4 and higher) will have an additional value `raftId` which is needed to join them to the existing cluster. 

You can see if a node is in sync by inspecting the `nodeActive` value for the according node in the raft cluster state. To get the raft cluster state run:
```bash
kubectl exec -n quorum-network <pod> -- geth --exec "raft.cluster" attach ipc:etc/quorum/qdata/dd/geth.ipc
```

### Adding Multiple Nodes
- Upgrade the cluster to a desired amount of nodes - [addNodes.sh](quorum/scripts/addNodes.sh)

### Adding/Removing Specific Nodes
- Generate bootnode and geth account keys for an additonal node - [keygen.sh](quorum/scripts/keygen.sh)
- Add a node by providing bootnode and geth account keys - [addNode.sh](quorum/scripts/addNode.sh)  
- Remove a node by providing the nodes id - [removeNode.sh](quorum/scripts/removeNode.sh)

## Accessing Node Endpoints
The configuration by default enables Ingress to expose an RPC endpoint for every quorum node at `http://<cluster-ip>/quorum-node<n>-rpc` and a WebSocket endpoint on `http://<cluster-ip>/quorum-node<n>-ws`. You can always decide to disable Ingress endpoints if you do not want to expose the nodes to someone outside the cluster. 

```bash
# Get the cluster ip
kubectl -n quorum-network cluster-info 

# Access the enabled Ingress via 
http://<cluster-ip>/quorum-node<n>-rpc
http://<cluster-ip>/quorum-node<n>-ws

# Disable Ingress by changing the according value in the values.yaml. Remember to upgrade the helm deployment after saving the changes. 
  node3:
    endpoints:
      rpc: true 
      ws: true
      ingress: 
        rpc: false
        ws: false
```

## Epirus Chain Explorer
In the [values.yaml](quorum/values.yaml) file you can choose to enable the Epirus Free Chain Explorer for your Cluster. Set the ingress option to `true` to make it accessible locally. With the node option you can controll on which specific quorum node the epirus explorer will listen. 

```bash
# Get the cluster ip
kubectl -n quorum-network cluster-info 

# Access the explorer at
http://<cluster-ip>/dashboard
```

## Other useful Commands
```bash
# Get logs of running nodes 
kubectl -n quorum-network logs <pod>

#Access container
kubectl exec -n quorum-network <pod> -i -t -- /bin/sh

    # Access geth running in the container 
    geth attach ./etc/quorum/qdata/dd/geth.ipc

    # Inspect raft cluster state
    raft.cluster

# Upgrade deployed templates
helm upgrade nnodes quorum -n quorum-network

# Remove the deployed templates
helm uninstall nnodes quorum -n quorum-network
```
---
Note: the template files have been created with the help of Qubernetes (https://github.com/ConsenSys/qubernetes).