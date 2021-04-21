#include "../multisig_interface.mligo"
#include "../build/common_vars.mligo"
#include "../build/transfer_tez.mligo"

let transfer_tez  = 
    fun (u:unit) -> 
        match ((Tezos.get_contract_opt contract_address): unit contract option) with 
        | Some v ->
            ([Tezos.transaction () total v]: operation list)
        | None -> (failwith "not_found": operation list) 
    

let transfer_tez_payload = 
    let l = Operation transfer_tez in
    let p = (chain, multisig_address), (counter, l) in
    Bytes.pack p