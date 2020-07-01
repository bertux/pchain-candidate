curl -X POST --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":67}' -H 'content-type:application/json;' localhost:6969/pchain | jq .result
