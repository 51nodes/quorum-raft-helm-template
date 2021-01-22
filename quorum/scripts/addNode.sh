#!/bin/sh

green=`tput setaf 2`
reset=`tput sgr0`

echo "${green}Enter nodekey: $reset"
read NODEKEY
echo "${green}Enter enode: $reset"
read ENODE
echo "${green}Enter keystore: $reset"
read KSF

# get name of pod
POD=$(kubectl get pod -l app=quorum -n quorum-network -o jsonpath="{.items[0].metadata.name}")

CURRENT_NODES=($(yq eval  '.nodes.[] | path | .[-1]' ../values.yaml))
LAST_NODE=${CURRENT_NODES[@]:(-1)}
LAST_NODE_NUM=$(tr -d -c 0-9 <<< $LAST_NODE)
NODE_NAME="node$((LAST_NODE_NUM+1))"
echo "${green}Adding $NODE_NAME to values.yaml$reset"

# create raftId and add new peer to cluster
echo "${green}Adding peer to raft cluster $reset"
PORT=$(yq eval '.geth.port' ../values.yaml)
RAFTPORT=$(yq eval '.geth.raftPort' ../values.yaml)
ENODE_ADDRESS="enode://$ENODE@quorum-$NODE_NAME:$PORT?discport=0&raftport=$RAFTPORT"
echo $ENODE_ADDRESS
RAFT_ID=$(kubectl exec -n quorum-network $POD -- geth --exec "raft.addPeer('$ENODE_ADDRESS')" attach ipc:etc/quorum/qdata/dd/geth.ipc 2> /dev/null)
echo "${green}Peer with id:$reset" $RAFT_ID "${green}joined the cluster$reset"

# add new node to values.yaml
export node_name=$NODE_NAME
export raftId=$RAFT_ID
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