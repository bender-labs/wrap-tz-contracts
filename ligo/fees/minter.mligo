#include "minter_interface.mligo"
#include "storage.mligo"
#include "../fa2/common/fa2_interface.mligo"

let minter_main (p, s: minter_entry_points*minter_storage): (operation list) * minter_storage =
    match p with 
    | Add_token t -> 
        let fa2_entry : ((transfer list) contract) option = Tezos.get_entrypoint_opt "%transfer"  t in
        let r =  match fa2_entry with
            | None -> (failwith "NOT A FA2 contract" : (operation list) * minter_storage)
            | Some ignore -> ([]:operation list), {s with listed_tokens = (Set.add t s.listed_tokens)}
            in
        r
    | Set_minter_contract a -> 
        ([]: operation list), {s with contract = a}
