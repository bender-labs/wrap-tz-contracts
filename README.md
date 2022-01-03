# TL;DR

In this repository you'll find all tezos contracts in use in $WRAP protocol.
$WRAP protocol let you import ERC20 and ERC721 from ethereum to tezos, using a strong federation to secure the assets. 

Compile contracts :

`make clean compile`

Run test:

`make test`

make test will create a venv if none found, but installing native deps for PyTezos is on you :

On macos: 
```
brew tap cuber/homebrew-libsecp256k1
brew install libsodium libsecp256k1 gmp
```

We have a little bit more [documentation](https://github.com/bender-labs/wrap-tz-contracts/wiki)

# Repository structure:

* `/src`: python utils to deploy and interact with different contracts. 
* `/test`: smart contracts test written with PyTezos
* `/michelson`: compiled versions of the contracts
* `/ligo/fa2`: implementation for a multi asset FA2, and single NFT fa2, tailored for wrap use case. Forked from [smart-contracts](https://github.com/tqtezos/smart-contracts)
* `/ligo/minter`: minter contract code
* `/ligo/quorum`: quorum contract code
* `/scripts`: helpers to spin up/down a tezos sandbox

# CLI

To see a list of available commands:
`python -m client`

For instance, here is how to deploy all contracts:
```shell
python -m client \
--shell=https://hangzhounet.api.tez.ie --key=$FAUCET_JSON_FILE \
deploy all \
'{"k51qzi5uqu5dge5i7atd5503txbd10oqb4bfo4d0tk8tw7ka8bk4p7g7kt299r":"sppk7a8xPov96ZwVh7mKi6nkkQS8r8ycYHDp7YahhnF3q1Xb3AQmBpL"}' \
'fab46e002bbf0b4509813474841e0716e6730136' \
'[{"eth_contract":"0xfab46e002bbf0b4509813474841e0716e6730136","eth_name":"USDC","eth_symbol":"USDC","symbol":"wUSDC", "name":"Wrapped USDC","decimals":6, "thumbnailUri": "ipfs://QmQfHU9mYLRDU4yh2ihm3zrvVFxDrLPiXNYtMovUQE2S2t"}, {"eth_contract":"0xfab46e002bbf0b4509813474841e0716e6730136","eth_name":"WETH","eth_symbol":"WETH","symbol":"wWETH", "name":"Wrapped WETH","decimals":18, "thumbnailUri": "ipfs://Qmezz1ztvo5JFshHupBEdUzVppyMfJH6K4kPjQRSZp8cLq"}]'```

# Manual venv setup

Setup a venv :
```
python3 -m venv venv
```

activate: 
```
source venv/bin/activate
```
install native dependencies: (macos) 
```
brew tap cuber/homebrew-libsecp256k1
brew install libsodium libsecp256k1 gmp
```

install dependencies :
```
pip install -r requirements.txt
```