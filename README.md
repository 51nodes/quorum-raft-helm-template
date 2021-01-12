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

# Remove template from namespace
helm uninstall nnodes quorum -n quorum-network
```

## Adding & Removing Nodes Dynamically (Running Network)
To use the following scripts you need to have [yq](https://github.com/mikefarah/yq) and [jq](https://stedolan.github.io/jq/) installed on your machine.

- Add `one or multiple` nodes with the [addNodes](quorum/scripts/addNodes.sh) script.  
- Remove one `specific` node with the [removeNode](quorum/scripts/removeNode.sh) script.

## Adding & Removing Nodes Manually  

### Add Node
To add nodes `manually`, generate your own enode and account key material and edit the [values.yaml](quorum/values.yaml) file in the [root](quorum) directory.

```
node<n>: 
    nodekey: <nodekey>
    enode: <enode>
    key: |- 
      <key>
```

After saving your changes to the [values.yaml](quorum/values.yaml) file run following command to update the kubernetes deployment. 

```
helm upgrade nnodes quorum -n quorum-network
```

Lastly use [Accessing a Specific Node](accessing-a-specific-node) to get a shell to one of the inital nodes and access geth. Then run following command to add the new node to the cluster: 
```
raft.addPeer(<enode>)
```

### Remove Node

To remove nodes simply delete the according yaml value and run `helm upgrade` to confirm the changes. 

## Accessing the Network
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
# Get list of running nodes 
kubectl -n quorum-network get pods

# Get logs of running nodes 
kubectl -n quorum-network logs <pod>
```
---
Note: the Kubernetes configuration was created with the help of Qubernetes (https://github.com/ConsenSys/qubernetes).
