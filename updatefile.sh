#!/bin/bash
date
PCHAIN_DIR=~/"pchain"
CHAIN_ID="pchain"

version_info=`curl -s -X POST -H "Content-Type:application/json" https://api.pchain.org/getLastVersion`
state=`echo $version_info | jq .result`

if [[ $state != \"success\" ]]; then
	echo "cannot get the version info, something wrong"
	exit 1
fi

latest_version=`echo $version_info | jq .data[0].v`

if [[ ! -e "$PCHAIN_DIR/version" ]]; then
	echo \"0.0.00\" > "$PCHAIN_DIR/version"
fi

local_version=`cat $PCHAIN_DIR/version`

echo "local version is $local_version, latest version is $latest_version"

if [[ $latest_version > $local_version ]]; then
	url=`echo $version_info | jq .data[0].url | cut -f 2 -d '"'`
	filename_tar=`echo $url | cut -f 9 -d '/'`
	filename=${filename_tar%.*}
	filename=${filename%.*}
	echo "updating/installing pchain, please wait"
	sleep 1
	echo "killing pchain"
	killall pchain
	echo "clean pchain's log"
	rm -r $PCHAIN_DIR/log/* ~/log/*

	sleep 10
	wget $url -P ~
	tar -xzf ~/$filename_tar -C ~
	echo "this is new"
	mv ~/$filename/pchain $PCHAIN_DIR/bin/
	mv ~/$filename/run.sh $PCHAIN_DIR/run.sh.new
	mv ~/$filename/pchain.cron $PCHAIN_DIR/scripts/
	mv ~/$filename/scripts/updatefile.sh $PCHAIN_DIR/scripts/updatefile.sh.new
	mv ~/$filename/scripts/monitor.sh $PCHAIN_DIR/scripts/monitor.sh.new
#	 mv ~/$filename/scripts/pchainser /etc/init.d/
#	 chmod +x /etc/init.d/pchainser
	rm -f ~/$filename_tar
	rm -rf ~/$filename

	echo "update finished, starting pchain now"
	$PCHAIN_DIR/run.sh
	sleep 10
#	 chmod -R 777 ~/pchain
	sleep 1
	crontab -l

	echo $latest_version > "$PCHAIN_DIR/version"

	echo "pchain started, exit now"
else
	echo "nothing new"
fi
