#!/bin/bash

#set -e
set -x

ROOT_DIR=~
LOG_DIR=~/"log"
LOG_FILE="$LOG_DIR/monitor.log"
RPCPORT="6969"
CHAINID="pchain"
CHILD_CHAINID="child_0"
MAIN_CHAIN_FLAG=-1
CHILD_CHAIN_FLAG=-1

date > $LOG_FILE

#check if pchain dir exist
if [[ ! -d $ROOT_DIR ]]; then
	echo "pchain not installed, please install pchain" >> $LOG_FILE
	exit 1
fi

#check if pchain is updating
n=`ps -ax|grep $ROOT_DIR/scripts/updatefile.sh | wc -l`
if [[ n -gt 1 ]]; then
	echo "pchain is updating, exit" >> $LOG_FILE 
	exit 0
fi

#check if this node running child_0
if [[ -d $ROOT_DIR/$CHILD_CHAINID ]]; then
	echo "child_0 dir exist" >> $LOG_FILE 
fi

end_height_dec=-1
old_height=-1
stuck_times=0

if [[ -e $ROOT_DIR/.pchain/$CHAINID/priv_validator.json ]]; then
	echo "I am main chain's validator" >> $LOG_FILE 
	MAIN_CHAIN_FLAG=1
	address=`cat $ROOT_DIR/.pchain/$CHAINID/priv_validator.json | jq .address`
fi

if [[ -e $ROOT_DIR/.pchain/$CHILD_CHAINID/priv_validator.json ]]; then
	echo "I am child chain's validator" >> $LOG_FILE 
	CHILD_CHAIN_FLAG=1
fi

version=`$ROOT_DIR/bin/pchain version`;

#check if pchain is running
n=`netstat -tan | grep :$RPCPORT | grep LISTEN | wc -l`
if [[ n -lt 1 ]]; then
	echo "pchain not started, starting pchain now" >> $LOG_FILE 
	$ROOT_DIR/run.sh >> $LOG_FILE 
	echo "pchain started, wait a few seconds" >> $LOG_FILE 
	sleep 40
fi

n=`netstat -tan | grep :$RPCPORT | grep LISTEN | wc -l`

if [[ n -lt 1 ]]; then
	echo "pchain still not started, don't know why" >> $LOG_FILE 
	exit 0
fi 

#check main chain's status
if [[ $MAIN_CHAIN_FLAG -eq 1 ]]; then
	echo "-------------------main chain--------------------------" >> $LOG_FILE 

	#check last time's height
	if [[ ! -e "$ROOT_DIR/stuck_times" ]]; then
		stuck_times=0
		old_height=0
	else
		stuck_times=`cat $ROOT_DIR/stuck_times | head -1`
		old_height=`cat $ROOT_DIR/stuck_times | head -2 | tail -1`
		len_stuck=`cat $ROOT_DIR/stuck_times | wc -l`
	fi

	#check last time's epoch
	if [[ ! -e "$ROOT_DIR/epoch" ]]; then
		epoch=0
	else
		epoch=`cat $ROOT_DIR/epoch | head -1`
	fi

	#check if preimage log exist
	if [[ ! -e "$LOG_DIR/pchain/preimages/preimages.log" ]]; then
		preimage=0
	else
		preimage=`ls -l $LOG_DIR/pchain/preimages/preimages.log | cut -f 5 -d ' '`
		rm -f $LOG_DIR/pchain/preimages/preimages.log
	fi


	len=`curl -s -X POST --connect-timeout 30 -m 20 -H "Content-Type:application/json" --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", true],"id":1}' localhost:$RPCPORT/$CHAINID | wc -L`

	if [[ $len -le 20 ]]; then
		echo "rpc no response 404 page not found, exit" >> $LOG_FILE 
		# killall pchain
		# $ROOT_DIR/run.sh >> $LOG_FILE
		exit 1
	fi

	block=`curl -s -X POST --connect-timeout 30 -H "Content-Type:application/json" --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", true],"id":1}' localhost:$RPCPORT/$CHAINID | jq .result`

	if [[ ! -n $block ]]; then 
		echo "cannot get main chain's rpc result, exit" >> $LOG_FILE 
		exit 1
	fi

	txpool=`curl -s -X POST -H "Content-Type:application/json" --data '{"jsonrpc":"2.0","method":"txpool_status","params":[],"id":1}' localhost:$RPCPORT/$CHAINID | jq .result`
	peers=`curl -s -X POST -H "Content-Type:application/json" --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' localhost:$RPCPORT/$CHAINID | jq .result`

	height=`echo $block | jq .number | cut -f 2 -d '"'`
	height_dec=`printf %d $height` 

	#if height not change
	if [[ $old_height -eq $height_dec ]]; then
		stuck_times=`expr $stuck_times + 1`
	else
		stuck_times=0
		old_height=$height_dec
	fi	


	cur_epoch=`curl -s -X POST -H "Content-Type:application/json"  --data '{"jsonrpc":"2.0","method":"tdm_getCurrentEpochNumber","params":[],"id":1}' localhost:$RPCPORT/$CHAINID | jq .result | cut -f 2 -d '"'`
	cur_epoch_dec=`printf %d $cur_epoch`
	echo "epoch: $epoch cur_epoch_dec : $cur_epoch_dec" >> $LOG_FILE 

	#check if epoch change
	if [[ $epoch -lt $cur_epoch_dec ]]; then
		echo "need to update epoch" >> $LOG_FILE 
		epoch=`curl -s -X POST -H "Content-Type:application/json" --data '{"jsonrpc":"2.0","method":"tdm_getEpoch","params":["'$cur_epoch'"],"id":1}' localhost:$RPCPORT/$CHAINID | jq .result`
		ep_number=`echo $epoch | jq .number`
		reward_per_block=`echo $epoch | jq .reward_per_block`
		start_height=`echo $epoch | jq .start_block`
		end_height=`echo $epoch | jq .end_block`
		#end_height_dec=$end_height
		end_height_dec=`echo $epoch | jq .end_block | cut -f 2 -d '"'`
		end_height_dec=`printf %d $end_height_dec`
		validator=`curl -s -X POST -H "Content-Type:application/json" --data '{"jsonrpc":"2.0","method":"tdm_getEpoch","params":["'$cur_epoch'"],"id":1}' localhost:$RPCPORT/$CHAINID | cut -f 2 -d '[' | cut -f 1 -d ']'`
		result_2="{\"number\":\"$cur_epoch\",\"reward_per_block\":$reward_per_block,\"start_height\":$start_height,\"end_height\":$end_height,\"validators\":[$validator],\"chainId\":\"0\"}"
#		echo $result_2 | jq . >> $LOG_FILE 
		curl -s -X POST -H "Content-Type:application/json" --data $result_2 https://api.pchain.org/sendEpoch >> $LOG_FILE 
	fi
	echo $cur_epoch_dec > "$ROOT_DIR/epoch"

	hash=`echo $block | jq .hash`
	num_txs=`echo $block | jq .transactions | jq length`

	pending=`echo $txpool | jq .pending | cut -f 2 -d '"'`
	pending_dec=`printf %d $pending`
	queued=`echo $txpool | jq .queued | cut -f 2 -d '"'`
	queued_dec=`printf %d $queued`

	num_peers=`echo $peers | jq length`
	if [[ ! -n $num_peers ]]; then
		num_peers=0
	fi

	pid=`pgrep pchain`
	nodestatus=`ps -aux | grep $pid`
	cpu=`echo $nodestatus | cut -f 3 -d ' '`
	memory=`echo $nodestatus | cut -f 4 -d ' '`
	echo "cpu:$cpu, memory:$memory, preimage:$preimage" >> $LOG_FILE 

	cpu=$cpu"_"$version

	result_1="{\"height\":$height_dec,\"hash\":$hash,\"num_txs\":$num_txs,\"pending\":$pending_dec,\"queued\":$queued_dec,\"num_peers\":$num_peers,\"address\":$address,\"chainId\":\"0\",\"cpu\":\"$cpu\",\"memory\":\"$memory\",\"preimage\":\"$preimage\"}"

#	echo $result_1 | jq . >> $LOG_FILE 
	curl -s -X POST -H "Content-Type:application/json" --data $result_1 https://api.pchain.org/sendBlock >> $LOG_FILE 

	chmod 777 $ROOT_DIR/stuck_times
	echo $stuck_times > "$ROOT_DIR/stuck_times"
	echo $height_dec >> "$ROOT_DIR/stuck_times"
	echo ""  >> $LOG_FILE
	echo "main chain stuck on height $height_dec for $stuck_times times" >> $LOG_FILE 
fi


child_end_height_dec=-1
child_old_height=-1
child_stuck_times=0

#check child chain's status
if [[ $CHILD_CHAIN_FLAG -eq 1 ]]; then
	echo "-------------------child chain--------------------------" >> $LOG_FILE 
	#check last time's height
	if [[ ! -e "$ROOT_DIR/.pchain/child_0/stuck_times" ]]; then
		stuck_times=0
		old_height=0
	else
		stuck_times=`cat $ROOT_DIR/.pchain/child_0/stuck_times | head -1`
		old_height=`cat $ROOT_DIR/.pchain/child_0/stuck_times | head -2 | tail -1`
	fi

	#check last time's epoch
	if [[ ! -e "$ROOT_DIR/epoch" ]]; then
		epoch=0
	else
		epoch=`cat $ROOT_DIR/epoch | tail -1`
	fi

	#check if preimage log exist
	if [[ ! -e "$LOG_DIR/child_0/preimages/preimages.log" ]]; then
		preimage=0
	else
		preimage=`ls -l $LOG_DIR/child_0/preimages/preimages.log | cut -f 5 -d ' '`
		rm -f $LOG_DIR/pchain/preimages/preimages.log
	fi

	len=`curl -s -X POST --connect-timeout 30 -m 20 -H "Content-Type:application/json" --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", true],"id":1}' localhost:$RPCPORT/$CHAINID | wc -L`

	if [[ $len -le 20 ]]; then
		# killall pchain
		# $ROOT_DIR/run.sh >> $LOG_FILE
	 	echo "rpc no response or 404 page not found, exit" >> $LOG_FILE 
		exit 1
	fi

	block=`curl -s -X POST --connect-timeout 30 -H "Content-Type:application/json" --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", true],"id":1}' localhost:$RPCPORT/$CHILD_CHAINID | jq .result`

	if [[ ! -n $block ]]; then 
		echo "cannot get child chain's rpc result, exit" >> $LOG_FILE 
		exit 1
	fi

	txpool=`curl -s -X POST -H "Content-Type:application/json" --data '{"jsonrpc":"2.0","method":"txpool_status","params":[],"id":1}' localhost:$RPCPORT/$CHILD_CHAINID | jq .result`
	peers=`curl -s -X POST -H "Content-Type:application/json" --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' localhost:$RPCPORT/$CHILD_CHAINID | jq .result`

	height=`echo $block | jq .number | cut -f 2 -d '"'`
	height_dec=`printf %d $height` 

	# if height not change
	if [[ $old_height -eq $height_dec ]]; then
		stuck_times=`expr $stuck_times + 1`
	else
		stuck_times=0
		old_height=$height_dec
	fi	


	cur_epoch=`curl -s -X POST -H "Content-Type:application/json"  --data '{"jsonrpc":"2.0","method":"tdm_getCurrentEpochNumber","params":[],"id":1}' localhost:$RPCPORT/$CHILD_CHAINID | jq .result | cut -f 2 -d '"'`
	cur_epoch_dec=`printf %d $cur_epoch`
	echo "epoch: $epoch cur_epoch_dec : $cur_epoch_dec" >> $LOG_FILE 

	#check if epoch change
	if [[ $epoch -lt $cur_epoch_dec ]]; then
		echo "need to update epoch" >> $LOG_FILE 
		epoch=`curl -s -X POST -H "Content-Type:application/json" --data '{"jsonrpc":"2.0","method":"tdm_getEpoch","params":["'$cur_epoch'"],"id":1}' localhost:$RPCPORT/$CHILD_CHAINID | jq .result`
		ep_number=`echo $epoch | jq .number`
		reward_per_block=`echo $epoch | jq .reward_per_block`
		start_height=`echo $epoch | jq .start_block`
		end_height=`echo $epoch | jq .end_block`
		end_height_dec=`echo $epoch | jq .end_block | cut -f 2 -d '"'`
		end_height_dec=`printf %d $end_height_dec`
		validator=`curl -s -X POST -H "Content-Type:application/json" --data '{"jsonrpc":"2.0","method":"tdm_getEpoch","params":["'$cur_epoch'"],"id":1}' localhost:$RPCPORT/$CHILD_CHAINID | cut -f 2 -d '[' | cut -f 1 -d ']'`
		result_2="{\"number\":\"$cur_epoch\",\"reward_per_block\":$reward_per_block,\"start_height\":$start_height,\"end_height\":$end_height,\"validators\":[$validator],\"chainId\":\"1\"}"
#		echo $result_2 | jq . >> $LOG_FILE 
		curl -s -X POST -H "Content-Type:application/json" --data $result_2 https://api.pchain.org/sendEpoch >> $LOG_FILE 
	fi
	echo $cur_epoch_dec >> "$ROOT_DIR/epoch"

	hash=`echo $block | jq .hash`
	num_txs=`echo $block | jq .transactions | jq length`

	pending=`echo $txpool | jq .pending | cut -f 2 -d '"'`
	pending_dec=`printf %d $pending`
	queued=`echo $txpool | jq .queued | cut -f 2 -d '"'`
	queued_dec=`printf %d $queued`

	num_peers=`echo $peers | jq length`
	if [[ ! -n $num_peers ]]; then
		num_peers=0
	fi

	pid=`pgrep pchain`
	nodestatus=`ps -aux | grep $pid`
	cpu=`echo $nodestatus | cut -f 3 -d ' '`
	memory=`echo $nodestatus | cut -f 4 -d ' '`
	echo "cpu:$cpu, memory:$memory, preimage:$preimage" >> $LOG_FILE

	result_1="{\"height\":$height_dec,\"hash\":$hash,\"num_txs\":$num_txs,\"pending\":$pending_dec,\"queued\":$queued_dec,\"num_peers\":$num_peers,\"address\":$address,\"chainId\":\"1\",\"cpu\":\"$cpu\",\"memory\":\"$memory\",\"preimage\":\"$preimage\"}"

#	echo $result_1 | jq . >> $LOG_FILE 
	curl -s -X POST -H "Content-Type:application/json" --data $result_1 https://api.pchain.org/sendBlock >> $LOG_FILE 
#	chmod 777 $ROOT_DIR/stuck_times
	echo $stuck_times > "$ROOT_DIR/.pchain/child_0/stuck_times"
	echo $height_dec >> "$ROOT_DIR/.pchain/child_0/stuck_times"
	echo ""  >> $LOG_FILE
	echo "child chain stuck on height $height_dec for $stuck_times times" >> $LOG_FILE 
fi
