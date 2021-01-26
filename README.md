# Helm Templates for n-Nodes Raft Quorum Network
This repository provides templates for a basic quorum setup using 3 nodes. By using the provided [scripts](quorum/scripts/) you can add and remove nodes to the existing raft cluster. Nodes will be available at `http://<cluster-ip>/quorum-node<n>-rpc`.  Note that this repository is currently designed to be used in development and testing only, do not use this in a production environment!

## Requirements
- [minikube](https://minikube.sigs.k8s.io/docs/start/) to create a local kubernetes cluster
- [helm](https://helm.sh/) to deploy the charts to your running cluster
- [yq](https://github.com/mikefarah/yq) version 4 and higher, to modify the cluster using the provided [scripts](quorum/scripts/)

## Configuring Geth
To set different geth parameters use the `geth` and `getParams` values in the [values.yaml](quorum/values.yaml) file.
```
geth:
  networkId: 10
  rpc: true
  ws: true 
  port: 30303
  raftPort: 50401
  verbosity: 3
  gethParams: 
    --permissioned \
    --nodiscover \
    --nat=none \
    --unlock 0 \
    --emitcheckpoints \
    --rpccorsdomain '*' \
    --rpcvhosts '*' \
```

## Deploy, Inspect & Remove
Use the templates in this repository to deploy a quorum network with n nodes. It might take some time for the nodes to be up and in sync. The helm chart is named `nnodes`, changing the charts name will lead to problems with the provided [scripts](quorum/scripts/). 

### Start deploying the templates using the following commands: 
```
# Bring up minikube in vm-mode
minikube start --memory='6144' --vm=true

# Enable nginx ingress controller for minikube
minikube addons enable ingress

# Create namespace
kubectl create ns quorum-network

# Deploy template to namespace
helm install nnodes quorum -n quorum-network

# List running nodes 
kubectl -n quorum-network get pods

# Inspect raft cluster
kubectl exec -n quorum-network <pod> -- geth --exec "raft.cluster" attach ipc:etc/quorum/qdata/dd/geth.ipc
```

## Adding & Removing Nodes
After deploying the initial cluster run following scripts from the [quorum/scripts/](quorum/scripts/) directory to add or remove `specific` or `multiple` nodes dynamically. The scripts will wait for user prompts once started and edit the [values.yaml](quorum/values.yaml) file accordingly, which then will be used in the helm templates for deploying a quorum raft cluster with multiple nodes. Keep in mind the inital cluster with 3 nodes has to be running and the nodes have to be in snyc to use these scripts. Nodes which are not initial (node4 and higher) will have an additional value `raftId` which is needed to join them to the existing cluster. 

You can see if a node is in sync by inspecting the `nodeActive` value for the according node in the raft cluster state. To get the raft cluster state run:
```
kubectl exec -n quorum-network <pod> -- geth --exec "raft.cluster" attach ipc:etc/quorum/qdata/dd/geth.ipc
```

### Adding Multiple Nodes
- Upgrade the cluster to a desired amount of nodes - [addNodes.sh](quorum/scripts/addNodes.sh)

### Adding/Removing Specific Nodes
- Generate bootnode and geth account keys for an additonal node - [keygen.sh](quorum/scripts/keygen.sh)
- Add a node by providing bootnode and geth account keys - [addNode.sh](quorum/scripts/addNode.sh)  
- Remove a node by providing the nodes id - [removeNode.sh](quorum/scripts/removeNode.sh)

## Accessing Node Endpoints
The configuration uses Ingress to expose an RPC endpoint for every quorum node at `http://<cluster-ip>/quorum-node<n>-rpc` and a WS endpoint on `http://<cluster-ip>/quorum-node<n>-ws`.

For `node1` this would be: 
```
http://<cluster-ip>/quorum-node1-rpc
http://<cluster-ip>/quorum-node1-ws
```

To get the `cluster-ip` you can run the following command:
```
kubectl -n quorum-network cluster-info 
```

## Other useful Commands
```
# Get logs of running nodes 
kubectl -n quorum-network logs <pod>

#Access container
kubectl exec -n quorum-network <pod> -i -t -- /bin/sh

    # Access geth running in the container 
    geth attach ./etc/quorum/qdata/dd/geth.ipc

    # Inspect raft cluster state
    raft.cluster

# Remove the deployed template
helm uninstall nnodes quorum -n quorum-network

# Stop minikube
minikube stop

# Delete minikube
minikube delete
```
---
Note: the Kubernetes configuration was created with the help of Qubernetes (https://github.com/ConsenSys/qubernetes).