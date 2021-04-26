#include "../../ligo/quorum/multisig.mligo"
#include "../multisig_interface.mligo"
#include "../build/common_vars.mligo"
#include "../build/quorum_set_payment_address.mligo"

let set_payment_address  = 
    fun (u:unit) -> 
        match ((Tezos.get_entrypoint_opt "%set_signer_payment_address" contract_address): payment_address_parameter contract option) with 
        | Some v ->
            ([Tezos.transaction {minter_contract=minter_contract;signer_id=signer_id;signature=signer_sig} 0tez v]: operation list)
        | None -> (failwith "not_found": operation list) 
    

let quorum_set_payment_address_payload = 
    let l = Operation set_payment_address in
    let p = (chain, multisig_address), (counter, l) in
    Bytes.pack p

