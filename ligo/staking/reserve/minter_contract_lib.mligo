#if !MINTER_CONTRACT_LIB
#define MINTER_CONTRACT_LIB

#include "../../minter/fees_interface.mligo" 

let get_minter_withdraw_token_ep(addr:address): withdraw_token_param contract =
    match (Tezos.get_entrypoint_opt "%withdraw_token" addr :withdraw_token_param contract option) with
    | Some v -> v
    | None -> (failwith "not_minter_contract": withdraw_token_param contract)


let get_minter_withdraw_xtz_ep(addr:address): tez contract =
    match (Tezos.get_entrypoint_opt "%withdraw_xtz" addr : tez contract option) with
    | Some v -> v
    | None -> (failwith "not_minter_contract": tez contract)

#endif