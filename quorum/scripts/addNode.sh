#!/bin/sh

green=`tput setaf 2`
reset=`tput sgr0`

echo "${green}Enter nodekey: $reset"
read NODEKEY
echo "${green}Enter enode: $reset"
read ENODE
echo "${green}Enter keystore: $reset"
read KSF

NODES_LENGTH=$(yq eval '.nodes | length' ../values.yaml)
echo "${green}Current amount of nodes: $NODES_LENGTH $reset"

# get name of pod
POD=$(kubectl get pod -l app=quorum -n quorum-network -o jsonpath="{.items[0].metadata.name}")

NODE_NAME="node$((NODES_LENGTH+1))"
echo "${green}Adding $NODE_NAME to the network $reset"

# add new node to values.yaml
export node_name=$NODE_NAME
export enode=$ENODE
export nodekey=$NODEKEY
export key=$KSF

rm -f temp/final.yaml temp/temp.yaml  
( echo "cat <<EOF >temp/final.yaml";
cat node.yaml;
) >temp/temp.yaml
. temp/temp.yaml
chmod +r temp/final.yaml

cat temp/final.yaml | sed 's/^/  /' >> ../values.yaml

echo "${green}Updating network $reset"
cd ../.. && helm upgrade nnodes quorum -n quorum-network && cd quorum/scripts/

echo "${green}Adding peer to raft cluster $reset"
PORT=$(yq eval '.geth.port' ../values.yaml)
RAFTPORT=$(yq eval '.geth.raftPort' ../values.yaml)
ENODE_ADDRESS="enode://$ENODE@quorum-$NODE_NAME:$PORT?discport=0&raftport=$RAFTPORT"
echo $ENODE_ADDRESS
kubectl exec -n quorum-network $POD -- geth --exec "raft.addPeer('$ENODE_ADDRESS')" attach ipc:etc/quorum/qdata/dd/geth.ipc