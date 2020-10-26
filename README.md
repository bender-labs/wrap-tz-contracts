# Setup ligo

Compiling ligo from source: 

```
brew install libev
opan init --bare # if not done yet
opam switch create tezos 4.09.1
opam install -y --deps-only --with-test ./ligo.opam $(find vendors -name \*.opam)
opam install -y $(find vendors -name \*.opam)
dune build -p ligo
ln -sf ${PWD}/_build/install/default/bin/ligo /usr/local/bin/
```


# Setup PyTezos

Install native dependencies :
```
brew tap cuber/homebrew-libsecp256k1
brew install libsodium libsecp256k1 gmp
```

Setup a venv :
```
python3 -m venv venv
```

activate: 
```
source venv/bin/activate
```

install dependencies :
```
pip install -r requirements.txt
```