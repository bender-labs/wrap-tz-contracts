#include "governance_interface.mligo"
#include "storage.mligo"

let governance_main (p, s: governance_entry_points * governance_storage): operation list * governance_storage = 
    match p with 
    | Set_governance a -> 
        ([]:operation list), {s with contract = a}
    | Set_fees_ratio p ->
        if (p.dev + p.staking + p.signers) <> 100n then
            (failwith "BAD_FEES_RATIO": (operation list) * governance_storage)
        else 
            ([]:operation list), {s with dev_fees = p.dev; staking_fees = p.staking; signers_fees = p.signers}
    