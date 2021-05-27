#include "../../ligo/minter/governance_interface.mligo"
#include "../multisig_interface.mligo"
#include "../build/common_vars.mligo"
#include "../build/minter_set_staking.mligo"

let set_staking  = 
    fun (u:unit) -> 
        match ((Tezos.get_entrypoint_opt "%set_staking" contract_address): address contract option) with 
        | Some v ->
            ([Tezos.transaction new_staking_address 0tez v]: operation list)
        | None -> (failwith "not_found": operation list) 
    

let minter_set_staking_payload = 
    let l = Operation set_staking in
    let p = (chain, multisig_address), (counter, l) in
    Bytes.pack p