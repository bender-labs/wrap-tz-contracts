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

We have a little bit more [documentation](doc)

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