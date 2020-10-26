# Setup ligo

(compile it, or use the docker script. must be in the $PATH)

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