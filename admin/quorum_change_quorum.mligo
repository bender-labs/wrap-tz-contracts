#include "../ligo/quorum/multisig.mligo"
#include "multisig_interface.mligo"
#include "build/common_vars.mligo"
#include "build/quorum_change_quorum.mligo"

type quorum = nat * (signer_id, key) map

let change_quorum  = 
    fun (u:unit) -> 
        match ((Tezos.get_entrypoint_opt "%change_quorum" contract_address): quorum contract option) with 
        | Some v ->
            ([Tezos.transaction (threshold, new_quorum) 0tez v]: operation list)
        | None -> (failwith "not_found": operation list) 
    

let quorum_change_quorum_payload = 
    let l = Operation change_quorum in
    let p = (chain, multisig_address), (counter, l) in
    Bytes.pack p

