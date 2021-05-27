#include "./storage.mligo"
#include "./wallet/wallet_main.mligo"
#include "./plan/plan_main.mligo"
#include "./admin/admin_main.mligo"

type contract_entrypoins = 
| Wallet of wallet_entrypoints
| Plan of plan_entrypoints
| Admin of admin_entrypoints

let main ((p , s): (contract_entrypoins * storage)): contract_return = 
    match p with 
    | Wallet w -> wallet_main(w, s)
    | Plan p -> 
        let s = check_admin(s) in
        plan_main(p, s)
    | Admin p -> admin_main(p, s)