#include "./reserve/reserve_api.mligo"

type storage = unit

type contract_return = (operation list) * storage

type contract_entrypoint = 
| Claim_fees of claim_fees
| Admin

let main (p, s: contract_entrypoint * storage): contract_return = 
    match p with
    | Claim_fees -> ([]:operation list), s
    | Admin -> ([]:operation list), s