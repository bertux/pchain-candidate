# Updating Ubuntu
sudo apt-get update && sudo apt-get upgrade -y
# Installing PCHAIN
export PCHAIN_LATEST=v1.0.24
wget https://github.com/pchain-org/pchain/releases/download/$PCHAIN_LATEST/pchain_mainnet_$PCHAIN_LATEST.tar.gz -P ~
cd ~
tar -zxf pchain_mainnet_$PCHAIN_LATEST.tar.gz
mkdir -p pchain/log pchain/bin pchain/.pchain pchain/scripts
cp ~/pchain_mainnet_$PCHAIN_LATEST/pchain ~/pchain/bin/
cp ~/pchain_mainnet_$PCHAIN_LATEST/run.sh ~/pchain/
# Set up an auto-update service
sudo apt-get install -y jq
cd ~
cp ~/pchain_mainnet_$PCHAIN_LATEST/pchain.cron ~/pchain/scripts/
cp ~/pchain_mainnet_$PCHAIN_LATEST/scripts/* ~/pchain/scripts/
sudo crontab -u $USER ~/pchain/scripts/pchain.cron
crontab -l
