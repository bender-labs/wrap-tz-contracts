#include "../multisig_interface.mligo"
#include "../build/common_vars.mligo"
#include "../build/transfer_fa2.mligo"
#include "../../ligo/fa2/common/fa2_interface.mligo"

let transfer_fa2  = 
    fun (u:unit) -> 
        match ((Tezos.get_entrypoint_opt "%transfer" contract_address): transfer list contract option) with 
        | Some v ->
            let dest = {
                to_ = destination;
                token_id = token_id;
                amount = token_amount;
            } in
            ([Tezos.transaction [{from_=Tezos.self_address;txs=[dest]}] 0tez v]: operation list)
        | None -> (failwith "not_found": operation list) 
    

let transfer_fa2_payload = 
    let l = Operation transfer_fa2 in
    let p = (chain, multisig_address), (counter, l) in
    Bytes.pack p