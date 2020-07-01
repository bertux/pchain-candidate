curl -X POST --data '{"jsonrpc":"2.0","method":"tdm_getNextEpochValidators","params":[],"id":67}' -H 'content-type:application/json;' localhost:6969/pchain | jq .result > result.json
