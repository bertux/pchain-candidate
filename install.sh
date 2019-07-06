# Updating Ubuntu
sudo apt-get update && sudo apt-get upgrade -y
# Installing PCHAIN
wget https://github.com/pchain-org/pchain/releases/download/v1.0.23/pchain_mainnet_v1.0.23.tar.gz -P ~
cd ~
tar -zxf pchain_mainnet_v1.0.23.tar.gz
mkdir -p pchain/log pchain/bin pchain/.pchain pchain/scripts
cp ~/pchain_mainnet_v1.0.23/pchain ~/pchain/bin/
cp ~/pchain_mainnet_v1.0.23/run.sh ~/pchain/
# Set up an auto-update service
sudo apt-get install -y jq
cd ~
cp ~/pchain_mainnet_v1.0.23/pchain.cron ~/pchain/scripts/
cp ~/pchain_mainnet_v1.0.23/scripts/* ~/pchain/scripts/
sudo crontab -u $USER ~/pchain/scripts/pchain.cron
crontab -l
