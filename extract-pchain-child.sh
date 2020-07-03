#!/bin/bash
set -e
mkdir -p ~/s3
cd ~/s3
rm -f blockDataWithChild.tar.gz
wget https://pchainblockdata.s3-us-west-2.amazonaws.com/blockDataWithChild.tar.gz
tar -xzf blockDataWithChild.tar.gz
rm -rf ~/export/
mv .pchain ~/export
