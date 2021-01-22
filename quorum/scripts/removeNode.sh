#!/bin/sh

green=`tput setaf 2`
reset=`tput sgr0`

echo "${green}Enter the node id to be removed: (e.g. 5 for node5):$reset"
read NODE_NUM_REMOVE

NODE_NAME_REMOVE="node$NODE_NUM_REMOVE"
POD=$(kubectl get pod -l app=quorum -n quorum-network -o jsonpath="{.items[0].metadata.name}")

# Remove peer from values.yaml
echo "${green}Deleting $NODE_NAME_REMOVE$reset"
NODES_LENGTH=$(yq eval '.nodes | length' ../values.yaml)
yq eval -i "del(.nodes.$NODE_NAME_REMOVE)" ../values.yaml

#Get Raft ID and remove
kubectl exec -n quorum-network $POD -- geth --exec "raft.cluster" attach ipc:etc/quorum/qdata/dd/geth.ipc >> temp/cluster.yml 
QUORUM_NODE_ID="quorum-$NODE_NAME_REMOVE"
RAFT_ID_REMOVE=$(yq eval '.[] | select(.hostname=="'$QUORUM_NODE_ID'") | .raftId' temp/cluster.yml)
> temp/cluster.yml 

echo "${green}Removing $NODE_NAME_REMOVE from raft cluster $reset"
echo "raftId: " $(kubectl exec -n quorum-network $POD -- geth --exec "raft.removePeer($RAFT_ID_REMOVE)" attach ipc:etc/quorum/qdata/dd/geth.ipc)

echo "${green}Updating network$reset"
cd ../.. && helm upgrade nnodes quorum -n quorum-network && cd quorum/scripts/