#if !TOKENS
#define TOKENS

#include "../fa2/common/fa2_interface.mligo"
#include "ethereum_lib.mligo"
#include "storage.mligo"


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


#endif