#if !TOKENS
#define TOKENS

#include "../fa2/common/fa2_interface.mligo"
#include "ethereum.mligo"
#include "interface.mligo"


let get_fa2_token_id (eth_contract, tokens : eth_address * (eth_address,token_address) map): token_address = 
  match Map.find_opt eth_contract tokens with
  | Some(n) -> n
  | None -> (failwith ("UNKNOWN_TOKEN"): token_address)
  

let token_tokens_entry_point (token_contract_address:address): token_manager contract = 
  match (Tezos.get_entrypoint_opt "%tokens" token_contract_address : token_manager contract option) with
  | Some(n) -> n
  | None -> (failwith ("CONTRACT_NOT_COMPATIBLE"): token_manager contract)


let token_admin_entry_point (token_contract_address:address): token_admin contract = 
  match (Tezos.get_entrypoint_opt "%admin" token_contract_address : token_admin contract option) with 
  | Some(n) -> n
  | None -> (failwith ("CONTRACT_NOT_COMPATIBLE") : token_admin contract)
  

#endif