#include "./wallet_lib.mligo"
#include "./stake.mligo"
#include "./withdraw.mligo"
#include "./claim.mligo"


type withdraw_parameters = 
[@layout:comb]
{
    stake_index: nat;
    amount: nat;
}

type wallet_entrypoints = 
| Stake of nat
| Withdraw of withdraw_parameters
| Claim

let wallet_main ((p, s): (wallet_entrypoints * storage)): contract_return = 
    match p with
    | Stake a -> stake(a, s) 
    | Withdraw {stake_index;amount=a} -> withdraw(stake_index, a, s)
    | Claim -> claim(s)