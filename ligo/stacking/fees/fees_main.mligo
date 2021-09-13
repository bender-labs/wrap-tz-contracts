#include "../storage.mligo"
#include "../common/utils.mligo"
#include "../common/errors.mligo"

type fees_entrypoints = 
| Set_blocks_per_cycle of nat
| Set_default_fees of nat
| Set_fees_per_cycles of (nat, nat) map


let fees_main (p, s: fees_entrypoints * storage) : contract_return =
    match p with
    | Set_default_fees p -> 
        let fees = {s.fees with default_fees = p} in
        ([]:operation list), {s with fees = fees}
    | Set_blocks_per_cycle p -> 
        let a = check_amount(p, bad_amount) in
        let fees = {s.fees with blocks_per_cycle = a} in
        ([]:operation list), {s with fees = fees}
    | Set_fees_per_cycles p -> 
        let fees = {s.fees with fees_per_cycles = p} in
        ([]: operation list), {s with fees = fees}