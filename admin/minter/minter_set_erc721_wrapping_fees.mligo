#include "../../ligo/minter/governance_interface.mligo"
#include "../multisig_interface.mligo"
#include "../build/common_vars.mligo"
#include "../build/minter_set_erc721_wrapping_fees.mligo"

let set_erc721_wrapping_fees  = 
    fun (u:unit) -> 
        match ((Tezos.get_entrypoint_opt "%set_erc721_wrapping_fees" contract_address): nat contract option) with 
        | Some v ->
            ([Tezos.transaction new_erc721_wrapping_fees 0tez v]: operation list)
        | None -> (failwith "not_found": operation list) 
    

let minter_set_erc721_wrapping_fees_payload = 
    let l = Operation set_erc721_wrapping_fees in
    let p = (chain, multisig_address), (counter, l) in
    Bytes.pack p