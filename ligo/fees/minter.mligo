#include "minter_interface.mligo"
#include "storage.mligo"

let minter_main (p, s: minter_entry_points*minter_storage): (operation list) * minter_storage =
    match p with 
    | Add_token t -> 
        ([]:operation list), {s with listed_tokens = (Set.add t s.listed_tokens)}
    | Set_minter_contract a -> 
        ([]: operation list), {s with contract = a}
