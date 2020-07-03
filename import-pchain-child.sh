#!/bin/bash
set -e
mkdir -p ~/.pchain
rsync -av --delete ~/export/ ~/.pchain/
cp ~/export-more/priv_validator.json ~/.pchain/child_0/priv_validator.json
#cp ~/export-more/keystore/UTC* ~/.pchain/child_0/keystore/
~/bin/pchain --rpc --gcmode=full --verbosity=3 --childChain=child_0 --ethstats NAMEYOURNODE:pChain4EVER@stats.pchain.site:80
