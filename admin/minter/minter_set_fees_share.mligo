#include "../../ligo/minter/governance_interface.mligo"
#include "../multisig_interface.mligo"
#include "../build/common_vars.mligo"
#include "../build/minter_set_fees_share.mligo"

let set_fees_share  = 
    fun (u:unit) -> 
        match ((Tezos.get_entrypoint_opt "%set_fees_share" contract_address): fees_share contract option) with 
        | Some v ->
            ([Tezos.transaction { dev_pool = dev_pool ; staking = staking ; signers = quorum} 0tez v]: operation list)
        | None -> (failwith "not_found": operation list) 
    

let minter_set_fees_share_payload = 
    let l = Operation set_fees_share in
    let p = (chain, multisig_address), (counter, l) in
    Bytes.pack p