#include "./reserve/reserve_api.mligo"
#include "./reserve/storage.mligo"
#include "./reserve/claim_fees.mligo"
#include "./reserve/contract.mligo"
#include "./reserve/admin.mligo"

type contract_entrypoint = 
| Claim_fees of claim_fees_param
| Admin of admin_entrypoints
| Contract_management of contract_management_entrypoints

let main (p, s: contract_entrypoint * storage): contract_return = 
    match p with
    | Claim_fees p -> claim_fees(p, s)
    | Admin p -> admin_main(p, s)
    | Contract_management p -> 
        let s = check_admin(s) in
        contract_management_main(p, s)