#include "../../ligo/minter/governance_interface.mligo"
#include "../multisig_interface.mligo"
#include "../build/common_vars.mligo"
#include "../build/minter_set_dev_pool.mligo"

let set_dev_pool  = 
    fun (u:unit) -> 
        match ((Tezos.get_entrypoint_opt "%set_dev_pool" contract_address): address contract option) with 
        | Some v ->
            ([Tezos.transaction new_dev_pool_address 0tez v]: operation list)
        | None -> (failwith "not_found": operation list) 
    

let minter_set_dev_pool_payload = 
    let l = Operation set_dev_pool in
    let p = (chain, multisig_address), (counter, l) in
    Bytes.pack p