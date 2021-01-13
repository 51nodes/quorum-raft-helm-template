#!/bin/sh

echo "Enter the node id to be removed: (e.g. 5 for node5):"
read NODE_NUM

NODE_NAME_OLD="node$NODE_NUM"

echo "Deleting $NODE_NAME_OLD"
NODES_LENGTH=$(yq eval '.nodes | length' ../values.yaml)
yq eval -i "del(.nodes.$NODE_NAME_OLD)" ../values.yaml

# echo "${green}Removing peer to raft cluster $reset"
# PORT=$(yq eval '.geth.port' ../values.yaml)
# RAFTPORT=$(yq eval '.geth.raftPort' ../values.yaml)
# ENODE_ADDRESS="enode://$ENODE@quorum-$NODE_NAME:$PORT?discport=0&raftport=$RAFTPORT"
# echo $ENODE_ADDRESS
# kubectl exec -n quorum-network $POD -- geth --exec "raft.addPeer('$ENODE_ADDRESS')" attach ipc:etc/quorum/qdata/dd/geth.ipc

NODE_NAME_NEXT="node$((NODE_NUM+1))"

echo $NODE_NAME_NEXT

if [[ $(yq eval '.nodes | has('\"$NODE_NAME_NEXT\"')' ../values.yaml) == true ]]
then
ENODE=$(yq eval ".nodes.$NODE_NAME_NEXT.enode" ../values.yaml)
NODEKEY=$(yq eval ".nodes.$NODE_NAME_NEXT.nodekey" ../values.yaml)
KSF=$(yq eval ".nodes.$NODE_NAME_NEXT.key" ../values.yaml)

export node_name=$NODE_NAME_OLD
export enode=$ENODE
export nodekey=$NODEKEY
export key=$KSF

rm -f temp/final.yaml temp/temp.yaml  
( echo "cat <<EOF >temp/final.yaml";
  cat node.yaml;
) >temp/temp.yaml
. temp/temp.yaml
chmod +r temp/final.yaml

yq eval -i "del(.nodes.$NODE_NAME_NEXT)" ../values.yaml

cat temp/final.yaml | sed 's/^/  /' >> ../values.yaml

fi

echo "New values.yaml: "
yq eval .nodes ../values.yaml

cd ../.. && helm upgrade nnodes quorum -n quorum-network && cd quorum/scripts/