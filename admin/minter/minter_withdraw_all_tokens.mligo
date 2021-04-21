#include "../../ligo/minter/fees_interface.mligo"
#include "../multisig_interface.mligo"
#include "../build/common_vars.mligo"
#include "../build/minter_withdraw_all_tokens.mligo"

let withdraw_all_tokens  = 
    fun (u:unit) -> 
        match ((Tezos.get_entrypoint_opt "%withdraw_all_tokens" contract_address): withdraw_tokens_param contract option) with 
        | Some v ->
            ([Tezos.transaction {fa2=fa2_contract;tokens=tokens} 0tez v]: operation list)
        | None -> (failwith "not_found": operation list) 
    

let minter_withdraw_all_tokens_payload = 
    let l = Operation withdraw_all_tokens in
    let p = (chain, multisig_address), (counter, l) in
    Bytes.pack p