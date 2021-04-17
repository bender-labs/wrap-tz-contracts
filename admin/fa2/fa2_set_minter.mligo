#include "../multisig_interface.mligo"
#include "../build/common_vars.mligo"
#include "../build/fa2_set_minter.mligo"

let set_minter  = 
    fun (u:unit) -> 
        match ((Tezos.get_entrypoint_opt "%set_minter" contract_address): address contract option) with 
        | Some v ->
            ([Tezos.transaction new_minter 0tez v]: operation list)
        | None -> (failwith "not_found": operation list) 
    

let fa2_set_minter_payload = 
    let l = Operation set_minter in
    let p = (chain, multisig_address), (counter, l) in
    Bytes.pack p