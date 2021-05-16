#include "../multisig_interface.mligo"
#include "../build/common_vars.mligo"
#include "../build/transfer_fa2.mligo"
#include "../../ligo/fa2/common/fa2_interface.mligo"

let transfer_fa2  = 
    fun (u:unit) -> 
        match ((Tezos.get_entrypoint_opt "%transfer" contract_address): transfer list contract option) with 
        | Some v ->

            let to_dest (acc, e: transfer_destination list * (nat * nat)): transfer_destination list = 
                let token_id, amnt = e in
                {to_ = destination;token_id = token_id; amount = amnt} :: acc
            in

            let txs = List.fold_left to_dest ([]: transfer_destination list) tokens_and_amounts in

            
            ([Tezos.transaction [{from_=Tezos.self_address;txs=txs}] 0tez v]: operation list)
        | None -> (failwith "not_found": operation list) 
    

let transfer_fa2_payload = 
    let l = Operation transfer_fa2 in
    let p = (chain, multisig_address), (counter, l) in
    Bytes.pack p