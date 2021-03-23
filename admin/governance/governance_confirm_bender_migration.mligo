#include "../../ligo/fa2/governance/bender.mligo"
#include "../multisig_interface.mligo"
#include "../build/common_vars.mligo"
#include "../build/governance_confirm_bender_migration.mligo"

let confirm_migration  = 
    fun (u:unit) -> 
        match ((Tezos.get_entrypoint_opt "%confirm_bender_migration" contract_address): unit contract option) with 
        | Some v ->
            ([Tezos.transaction () 0tez v]: operation list)
        | None -> (failwith "not_found": operation list) 
    

let governance_confirm_bender_migration_payload = 
    let l = Operation confirm_migration in
    let p = (chain, multisig_address), (counter, l) in
    Bytes.pack p
