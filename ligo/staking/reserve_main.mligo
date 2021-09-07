#include "./reserve/reserve_api.mligo"
#include "./reserve/storage.mligo"
#include "./reserve/staking_contract.mligo"
#include "./reserve/contract.mligo"
#include "./reserve/admin.mligo"
#include "./reserve/withdraw.mligo"

type contract_entrypoint = 
| Staking of staking_contract_entrypoints
| Admin of admin_entrypoints
| Contract_management of contract_management_entrypoints
| Withdraw of withdraw_entrypoint

let main (p, s: contract_entrypoint * storage): contract_return = 
    match p with
    | Staking p -> staking_main(p, s)
    | Admin p -> admin_main(p, s)
    | Contract_management p -> 
        let s = check_admin(s) in
        contract_management_main(p, s)
    | Withdraw p -> 
        let s = check_admin(s) in
        withdraw_main(p, s)