#include "./wallet_lib.mligo"
#include "./stake.mligo"
#include "./withdraw.mligo"
#include "./claim.mligo"

type wallet_entrypoints = 
| Stake of nat
| Withdraw of nat
| Claim

let wallet_main ((p, s): (wallet_entrypoints * storage)): contract_return = 
    match p with
    | Stake a -> stake(a, s) 
    | Withdraw a -> withdraw(a, s)
    | Claim -> claim(s)