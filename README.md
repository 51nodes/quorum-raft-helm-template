# Helm Templates for n-Nodes Raft Quorum Network

## Requirements
- A Running [Kubernetes](https://kubernetes.io/) cluster e. g. [minikube](https://minikube.sigs.k8s.io/docs/start/)
- [Helm](https://helm.sh/) to deploy the charts to your running cluster

## Configuring the Network
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

## Deploy & Remove
Use the templates in this repository to deploy a quorum network with n nodes. It might take some time for the nodes to be up and in sync.
```
# Create namespace
kubectl create ns quorum-network

# Deploy template to namespace
helm install nnodes quorum -n quorum-network

# List running nodes 
kubectl -n quorum-network get pods

# Remove template from namespace
helm uninstall nnodes quorum -n quorum-network
```

## Adding & Removing Nodes
After deploying the initial cluster use following scripts to add or remove `specific` or `multiple` nodes dynamically. 

Note: To use these scripts you need to have [yq](https://github.com/mikefarah/yq) installed on your machine.

### Multiple

- Upgrade the cluster to a desired amount of nodes - [addNodes.sh](quorum/scripts/addNodes.sh)

### Specific
- Generate bootnode and geth account keys for an additonal node - [keygen.sh](quorum/scripts/keygen.sh)
- Add a node by providing bootnode and geth account keys - [addNode.sh](quorum/scripts/addNode.sh)  
- Remove a node by providing the enode id - [removeNode.sh](quorum/scripts/removeNode.sh)



## Accessing Nodes
The configuration exposes an RPC endpoint for every Quorum node at `<cluster-ip>:<rpcPort>`. To get the endpoint URL you can run the following commands:
```
#Get the cluster-ip
kubectl -n quorum-network cluster-info 

#Get the service port mapping
kubectl -n quorum-network get svc

#If you use minikube you can also run to get the full endpoint url. The first value of the resulting output should be the RPC endpoint. 
minikube -n quorum-network service quorum-node1 --url
```

## Accessing a Specific Node
```
# Get a shell to a container running a node
kubectl exec -n quorum-network <pod> -i -t -- /bin/sh

    # Then run the following command to access geth running in the container 
    geth attach ./etc/quorum/qdata/dd/geth.ipc

    # After accessing geth run the following command to inspect the network status
    raft.cluster
```

## Other useful Commands
```
# Get logs of running nodes 
kubectl -n quorum-network logs <pod>
```
---
Note: the Kubernetes configuration was created with the help of Qubernetes (https://github.com/ConsenSys/qubernetes).
