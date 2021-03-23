#include "../../ligo/quorum/multisig.mligo"
#include "../multisig_interface.mligo"
#include "../build/common_vars.mligo"
#include "../build/quorum_change_threshold.mligo"

let change_threshold  = 
    fun (u:unit) -> 
        match ((Tezos.get_entrypoint_opt "%change_threshold" contract_address): nat contract option) with 
        | Some v ->
            ([Tezos.transaction threshold 0tez v]: operation list)
        | None -> (failwith "not_found": operation list) 
    

let quorum_change_threshold_payload = 
    let l = Operation change_threshold in
    let p = (chain, multisig_address), (counter, l) in
    Bytes.pack p

