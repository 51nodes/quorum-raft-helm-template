#!/bin/sh

green=`tput setaf 2`
cyan=`tput setaf 6`
reset=`tput sgr0`

NODES_LENGTH=$(yq eval '.nodes | length' ../values.yaml)

# get name of pod
POD=$(kubectl get pod -l app=quorum -n quorum-network -o jsonpath="{.items[0].metadata.name}")

CURRENT_NODES=($(yq eval  '.nodes.[] | path | .[-1]' ../values.yaml))
LAST_NODE=${CURRENT_NODES[@]:(-1)}
LAST_NODE_NUM=$(tr -d -c 0-9 <<< $LAST_NODE)
NODE_NAME="node$((LAST_NODE_NUM+1))"
echo "${green}Generating keys for $NODE_NAME $reset"

# generate new enode
kubectl exec -n quorum-network $POD -- bootnode -genkey $NODE_NAME.key
ENODE=$(kubectl exec -n quorum-network $POD -- bootnode -nodekey $NODE_NAME.key -writeaddress)
NODEKEY=$(kubectl exec -n quorum-network $POD -- cat $NODE_NAME.key)

# generate new account
kubectl exec -n quorum-network $POD -- touch etc/quorum/qdata/dd/password.txt
RES=$(kubectl exec -n quorum-network $POD -- geth --datadir $NODE_NAME account new --password etc/quorum/qdata/dd/password.txt 2> /dev/null)
echo "$RES" >> temp/res.txt
KSID=$(awk '/Path of the secret key file:/{print $NF}' temp/res.txt)
> temp/res.txt

# get keystore
RL=$'\r'
KSF=$(kubectl exec -n quorum-network $POD -- cat ${KSID%$RL})

# print values
echo "${green}nodekey: ${cyan}$NODEKEY"
echo "${green}enode: ${cyan}$ENODE"
echo "${green}keystore: ${cyan}$KSF"