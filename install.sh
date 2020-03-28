# Updating Ubuntu
sudo apt-get update && sudo apt-get upgrade -y & sudo apt-get install -y jq
# Installing PCHAIN
export PCHAIN_LATEST=v1.0.24
mkdir -p ~/src ~/bin ~/scripts
rm -rf ~/.pchain/child_0/
wget https://github.com/pchain-org/pchain/releases/download/$PCHAIN_LATEST/pchain_mainnet_$PCHAIN_LATEST.tar.gz -P ~/src
wget https://github.com/pchain-org/pchain/releases/download/v1.0.01/child_0_config.tar.gz -P ~/src
cd ~/src
tar -zxf pchain_mainnet_$PCHAIN_LATEST.tar.gz
tar -zxf child_0_config.tar.gz
cp pchain_mainnet_$PCHAIN_LATEST/pchain ~/bin/
cp pchain_mainnet_$PCHAIN_LATEST/run.sh ~/scripts
# Set up an auto-update service
cp ~/pchain_mainnet_$PCHAIN_LATEST/pchain.cron ~/scripts
cp ~/pchain_mainnet_$PCHAIN_LATEST/scripts/* ~/scripts
# Set up child chain
mkdir -p ~/.pchain/child_0/
cp ~/src/child_0_config/*.json ~/.pchain/child_0/
pchain init ~/.pchain/child_0/eth_genesis.json child_0
# cp ~/.pchain/pchain/priv_validator.json ~/.pchain/child_0/
