#include "../../ligo/fa2/governance/bender.mligo"
#include "../multisig_interface.mligo"
#include "../build/common_vars.mligo"
#include "../build/governance_distribute.mligo"

let distribute  = 
    fun (u:unit) -> 
        match ((Tezos.get_entrypoint_opt "%distribute" contract_address): distribute_param contract option) with 
        | Some v ->
            ([Tezos.transaction distribution 0tez v]: operation list)
        | None -> (failwith "not_found": operation list) 
    

let governance_distribute_payload = 
    let l = Operation distribute in
    let p = (chain, multisig_address), (counter, l) in
    Bytes.pack p
