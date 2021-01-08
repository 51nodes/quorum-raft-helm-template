#!/bin/sh

echo "Enter the nodes name: "  
read NODE_NAME

# get name of pod
POD=$(kubectl get pod -l app=quorum -n quorum-network -o jsonpath="{.items[0].metadata.name}")

# generate new enode
echo $(kubectl exec -n quorum-network $POD -- bootnode -genkey $NODE_NAME.key)
ENODE=$(kubectl exec -n quorum-network $POD -- bootnode -nodekey $NODE_NAME.key -writeaddress)
NODEKEY=$(kubectl exec -n quorum-network $POD -- cat $NODE_NAME.key)

# generate new account
kubectl exec -n quorum-network $POD -c quorum -it -- touch etc/quorum/qdata/dd/password.txt
RES=$(kubectl exec -n quorum-network $POD -c quorum -it -- geth --datadir $NODE_NAME account new --password etc/quorum/qdata/dd/password.txt)
echo "$RES" >> temp/res.txt
KSID=$(awk '/Path of the secret key file:/{print $NF}' temp/res.txt)
> temp/res.txt

# get keystore
RL=$'\r'
KSF=$(kubectl exec -n quorum-network $POD -c quorum -it -- cat ${KSID%$RL})

# update genesis.json
ACCOUNT="0x$(jq -r '.address' <<< $KSF)"
BALANCE="1000000000000000000000000000"
GENESIS_UPDATED=$(yq eval .data ../templates/01-quorum-genesis.yaml | sed -e '1,1d' | jq ".alloc.\"$ACCOUNT\" += {balance: \"$BALANCE\"}")
# echo $GENESIS_UPDATED
echo $(yq e ".data.genesis = \"$GENESIS_UPDATED\"" -i ../templates/01-quorum-genesis.yaml)

export node_name=$NODE_NAME
export enode=$ENODE
export nodekey=$NODEKEY
export key=$KSF

rm -f temp/final.yaml temp/temp.yaml  
( echo "cat <<EOF >temp/final.yaml";
  cat template.yaml;
) >temp/temp.yaml
. temp/temp.yaml
cat temp/final.yaml

chmod +r temp/final.yaml

cat temp/final.yaml | sed 's/^/  /' >> ../values.yaml