#include "../../ligo/quorum/multisig.mligo"
#include "../multisig_interface.mligo"
#include "../build/common_vars.mligo"
#include "../build/quorum_set_admin.mligo"

let set_admin  = 
    fun (u:unit) -> 
        match ((Tezos.get_entrypoint_opt "%set_admin" contract_address): address contract option) with 
        | Some v ->
            ([Tezos.transaction new_admin 0tez v]: operation list)
        | None -> (failwith "not_found": operation list) 
    

let quorum_set_admin_payload = 
    let l = Operation set_admin in
    let p = (chain, multisig_address), (counter, l) in
    Bytes.pack p

