#!/bin/sh

echo "Enter the amount of overall desired nodes:"
read NODES_DESIRED

NODES_LENGTH=$(yq eval '.nodes | length' ../values.yaml)

# get name of pod
POD=$(kubectl get pod -l app=quorum -n quorum-network -o jsonpath="{.items[0].metadata.name}")

for((i=$NODES_LENGTH;i<$NODES_DESIRED;i++)) do
  NODE_NAME="node$((i+1))"
  echo "Adding $NODE_NAME to the network"

  # generate new enode
  kubectl exec -n quorum-network $POD -- bootnode -genkey $NODE_NAME.key
  ENODE=$(kubectl exec -n quorum-network $POD -- bootnode -nodekey $NODE_NAME.key -writeaddress)
  NODEKEY=$(kubectl exec -n quorum-network $POD -- cat $NODE_NAME.key)

  # generate new account
  kubectl exec -n quorum-network $POD -- touch etc/quorum/qdata/dd/password.txt
  RES=$(kubectl exec -n quorum-network $POD -- geth --datadir $NODE_NAME account new --password etc/quorum/qdata/dd/password.txt)
  echo "$RES" >> temp/res.txt
  KSID=$(awk '/Path of the secret key file:/{print $NF}' temp/res.txt)
  > temp/res.txt

  # get keystore
  RL=$'\r'
  KSF=$(kubectl exec -n quorum-network $POD -- cat ${KSID%$RL})

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

  echo "Updating network"
  cd ../.. && helm upgrade nnodes quorum -n quorum-network && cd quorum/scripts/

  echo "Adding peer to raft cluster"
  PORT=$(yq eval '.geth.port' ../values.yaml)
  RAFTPORT=$(yq eval '.geth.raftPort' ../values.yaml)
  ENODE_ADDRESS="enode://$ENODE@quorum-$NODE_NAME:$PORT?discport=0&raftport=$RAFTPORT"
  echo $ENODE_ADDRESS
  kubectl exec -n quorum-network $POD -- geth --exec "raft.addPeer('$ENODE_ADDRESS')" attach ipc:etc/quorum/qdata/dd/geth.ipc
done