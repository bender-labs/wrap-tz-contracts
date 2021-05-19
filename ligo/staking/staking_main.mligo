#include "./storage.mligo"
#include "./wallet/wallet_main.mligo"
#include "./plan/plan_main.mligo"

type contract_entrypoins = 
| Wallet of wallet_entrypoints
| Update_plan of update_plan

let main ((p , s): (contract_entrypoins * storage)): contract_return = 
    match p with 
    | Wallet w -> wallet_main(w, s)
    | Update_plan p -> plan_main(p, s)