#if !TOKENS
#define TOKENS

#include "../fa2/common/fa2_interface.mligo"
#include "ethereum.mligo"
#include "interface.mligo"


let get_fa2_token_id (eth_contract, tokens : eth_address * (eth_address,token_address) map): token_address = 
  match Map.find_opt eth_contract tokens with
  | Some(n) -> n
  | None -> (failwith ("UNKNOWN_TOKEN"): token_address)

let get_nft_contract (eth_contract, tokens : eth_address * (eth_address,address) map): address = 
  match Map.find_opt eth_contract tokens with
  | Some(n) -> n
  | None -> (failwith ("UNKNOWN_TOKEN"): address)  

let token_tokens_entry_point (token_contract_address:address): token_manager contract = 
  match (Tezos.get_entrypoint_opt "%tokens" token_contract_address : token_manager contract option) with
  | Some(n) -> n
  | None -> (failwith ("CONTRACT_NOT_COMPATIBLE"): token_manager contract)


let token_admin_entry_point (token_contract_address:address): token_admin contract = 
  match (Tezos.get_entrypoint_opt "%admin" token_contract_address : token_admin contract option) with 
  | Some(n) -> n
  | None -> (failwith ("CONTRACT_NOT_COMPATIBLE") : token_admin contract)
  
let fail_if_amount (v:unit) =
  if Tezos.amount > 0tez then failwith("FORBIDDEN_XTZ")

let check_fees_high_enough (v, min : nat * nat) =
  if v < min then failwith("FEES_TOO_LOW")

let check_nft_fees_high_enough (v, min : tez * tez) =
  if v < min then failwith("FEES_TOO_LOW")  

let check_amount_large_enough (v:nat) =
  if v < 1n then failwith("AMOUNT_TOO_SMALL")

let fees_contract (a:address): unit contract = 
    let maybe_contract : unit contract option = Tezos.get_contract_opt a in
    match maybe_contract with 
    | Some c -> c
    | None -> (failwith "FEES_CONTRACT_NOT_FOUND" : unit contract)

#endif