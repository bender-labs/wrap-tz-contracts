#include "./storage.mligo"
#include "./wallet/wallet_main.mligo"

type contract_entrypoins = 
| Wallet of wallet_entrypoints

let main ((p , s): (contract_entrypoins * storage)): contract_return = 
    match p with 
    | Wallet w -> wallet_main(w, s)